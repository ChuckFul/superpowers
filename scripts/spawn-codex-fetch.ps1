[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Url,

    [string]$Agent,

    [string]$AgentPath,

    [string]$AgentRoot = (Join-Path (Split-Path $PSScriptRoot -Parent) "codex-agents"),

    [string]$OutputDir = (Join-Path ([System.IO.Path]::GetTempPath()) "codex-agent-output"),

    [string]$CodexCommand = "codex",

    [string[]]$CodexArgs = @(),

    [string]$WorkDir,

    [switch]$Wait
)

$ErrorActionPreference = "Stop"

if ($Agent -and $AgentPath) {
    throw "Specify only one of -Agent or -AgentPath."
}

function Parse-TomlValue {
    param([string]$Value)

    $trimmed = $Value.Trim()

    if ($trimmed.StartsWith("[")) {
        $items = @()
        $matches = [regex]::Matches($trimmed, '"((?:[^"\\]|\\.)*)"')
        foreach ($match in $matches) {
            $items += ($match.Groups[1].Value -replace '\\"', '"' -replace '\\\\', '\\')
        }
        return ,$items
    }

    if ($trimmed.StartsWith('"') -and $trimmed.EndsWith('"')) {
        $inner = $trimmed.Substring(1, $trimmed.Length - 2)
        return ($inner -replace '\\"', '"' -replace '\\\\', '\\')
    }

    if ($trimmed.StartsWith("'") -and $trimmed.EndsWith("'")) {
        return $trimmed.Substring(1, $trimmed.Length - 2)
    }

    return $trimmed
}

function Read-AgentSpec {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Agent spec not found: $Path"
    }

    $spec = @{}
    $lines = Get-Content -LiteralPath $Path
    $pendingKey = $null
    $pendingValue = $null

    foreach ($line in $lines) {
        $clean = ($line -replace '\s+#.*$', '').Trim()
        if ([string]::IsNullOrWhiteSpace($clean)) {
            continue
        }

        if ($pendingKey) {
            $pendingValue = ($pendingValue + " " + $clean).Trim()
            if ($pendingValue.Contains("]")) {
                $spec[$pendingKey] = Parse-TomlValue -Value $pendingValue
                $pendingKey = $null
                $pendingValue = $null
            }
            continue
        }

        $match = [regex]::Match($clean, '^(?<key>[\w\-]+)\s*=\s*(?<value>.+)$')
        if (-not $match.Success) {
            continue
        }

        $key = $match.Groups["key"].Value
        $value = $match.Groups["value"].Value

        if ($value.Trim().StartsWith("[") -and -not $value.Contains("]")) {
            $pendingKey = $key
            $pendingValue = $value
            continue
        }

        $spec[$key] = Parse-TomlValue -Value $value
    }

    if ($pendingKey) {
        throw "Unclosed array value for '$pendingKey' in $Path."
    }

    return $spec
}

$codex = Get-Command -Name $CodexCommand -ErrorAction SilentlyContinue
if (-not $codex) {
    throw "Command not found: $CodexCommand. Install Codex CLI or provide -CodexCommand."
}

if (-not (Test-Path -LiteralPath $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$stdoutPath = Join-Path $OutputDir ("codex-fetch-" + $timestamp + ".out.txt")
$stderrPath = Join-Path $OutputDir ("codex-fetch-" + $timestamp + ".err.txt")

$agentSpec = $null
$agentDir = $null

if ($AgentPath) {
    $agentPathResolved = Resolve-Path -LiteralPath $AgentPath
    $agentDir = Split-Path -Parent $agentPathResolved.Path
    $agentSpec = Read-AgentSpec -Path $agentPathResolved.Path
} elseif ($Agent) {
    $agentDir = Join-Path $AgentRoot $Agent
    $agentSpec = Read-AgentSpec -Path (Join-Path $agentDir "agent.toml")
}

if ($agentSpec -and $agentSpec.ContainsKey("workdir") -and -not $PSBoundParameters.ContainsKey("WorkDir")) {
    $WorkDir = $agentSpec["workdir"]
}

$prompt = $null
if ($agentSpec -and $agentSpec.ContainsKey("prompt")) {
    $promptPath = Join-Path $agentDir $agentSpec["prompt"]
    if (-not (Test-Path -LiteralPath $promptPath)) {
        throw "Prompt template not found: $promptPath"
    }
    $prompt = Get-Content -LiteralPath $promptPath -Raw
}

if (-not $prompt) {
    $prompt = @"
Fetch and read the webpage at: $Url
Summarize the content and key points. Note any access limitations.
"@.Trim()
}

$prompt = ($prompt -replace '\{\{\s*url\s*\}\}', $Url).Trim()
if ($prompt -notmatch '(?i)https?://') {
    $prompt = ($prompt.TrimEnd() + "`n`nURL: $Url")
}

function Quote-Argument {
    param([string]$Value)
    if ([string]::IsNullOrEmpty($Value)) {
        return '""'
    }

    $quoteMethod = [System.Management.Automation.Language.CodeGeneration].GetMethod(
        "QuoteArgument",
        [System.Reflection.BindingFlags] "Public,Static"
    )
    if ($quoteMethod) {
        return [System.Management.Automation.Language.CodeGeneration]::QuoteArgument($Value)
    }

    return '"' + ($Value -replace '"', '\"') + '"'
}

$specArgs = @()
if ($agentSpec -and $agentSpec.ContainsKey("codex_args")) {
    $specArgs = @($agentSpec["codex_args"])
}

$combinedArgs = @()
$hasProfile = ($specArgs -contains "--profile") -or ($CodexArgs -contains "--profile")
$profileValue = $null
if ($agentSpec -and $agentSpec.ContainsKey("profile")) {
    $profileValue = [string]$agentSpec["profile"]
}
if (-not $hasProfile -and -not [string]::IsNullOrWhiteSpace($profileValue)) {
    $combinedArgs += @("--profile", $profileValue)
}
$combinedArgs += $specArgs
$combinedArgs += $CodexArgs

$argList = @("exec")
if ($combinedArgs.Count -gt 0) {
    $argList += $combinedArgs
}

$useStdin = $true
if ($argList -contains "{prompt}") {
    $quotedPrompt = Quote-Argument -Value $prompt
    $argList = $argList | ForEach-Object {
        if ($_ -eq "{prompt}") { $quotedPrompt } else { $_ }
    }
    $useStdin = $false
} elseif ($argList -notcontains "-") {
    $argList += "-"
}

$promptPath = $null
if ($useStdin) {
    $promptPath = Join-Path $OutputDir ("codex-prompt-" + $timestamp + ".txt")
    Set-Content -LiteralPath $promptPath -Value $prompt -Encoding UTF8
}

$startInfo = @{
    FilePath = $CodexCommand
    ArgumentList = $argList
    RedirectStandardOutput = $stdoutPath
    RedirectStandardError = $stderrPath
    NoNewWindow = $true
    PassThru = $true
}
if ($useStdin) {
    $startInfo.RedirectStandardInput = $promptPath
}
if ($WorkDir) {
    $startInfo.WorkingDirectory = $WorkDir
}

$process = Start-Process @startInfo

Write-Host "Spawned Codex process. PID: $($process.Id)"
Write-Host "Stdout: $stdoutPath"
Write-Host "Stderr: $stderrPath"

if ($Wait) {
    $process.WaitForExit()
    Write-Host "Exit code: $($process.ExitCode)"
}
