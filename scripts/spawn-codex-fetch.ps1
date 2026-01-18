[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Url,

    [string]$OutputDir = (Join-Path ([System.IO.Path]::GetTempPath()) "codex-agent-output"),

    [string]$CodexCommand = "codex",

    [string[]]$CodexArgs = @(),

    [switch]$Wait
)

$ErrorActionPreference = "Stop"

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

$prompt = @"
Fetch and read the webpage at: $Url
Summarize the content and key points. Note any access limitations.
"@.Trim()

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

$argList = @("exec")
if ($CodexArgs.Count -gt 0) {
    $argList += $CodexArgs
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

$process = Start-Process @startInfo

Write-Host "Spawned Codex process. PID: $($process.Id)"
Write-Host "Stdout: $stdoutPath"
Write-Host "Stderr: $stderrPath"

if ($Wait) {
    $process.WaitForExit()
    Write-Host "Exit code: $($process.ExitCode)"
}
