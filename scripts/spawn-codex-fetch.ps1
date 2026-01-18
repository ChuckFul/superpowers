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

$argList = @("exec")
if ($CodexArgs.Count -gt 0) {
    $argList += $CodexArgs
}

if ($argList -contains "{prompt}") {
    $argList = $argList | ForEach-Object {
        if ($_ -eq "{prompt}") { $prompt } else { $_ }
    }
} else {
    $argList += $prompt
}

$process = Start-Process `
    -FilePath $CodexCommand `
    -ArgumentList $argList `
    -RedirectStandardOutput $stdoutPath `
    -RedirectStandardError $stderrPath `
    -NoNewWindow `
    -PassThru

Write-Host "Spawned Codex process. PID: $($process.Id)"
Write-Host "Stdout: $stdoutPath"
Write-Host "Stderr: $stderrPath"

if ($Wait) {
    $process.WaitForExit()
    Write-Host "Exit code: $($process.ExitCode)"
}
