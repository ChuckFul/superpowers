<#
.SYNOPSIS
    Converts superpowers skills to Cursor rules format.

.DESCRIPTION
    Reads SKILL.md files from the superpowers skills directory and converts them
    to Cursor-compatible .mdc rule files with appropriate frontmatter.

    Cursor rules support these application modes:
    - alwaysApply: true  - Always included in every chat
    - alwaysApply: false - Agent decides based on description (default)
    - globs: "pattern"   - Applied when files match pattern

.PARAMETER SkillsPath
    Path to the superpowers skills directory.
    Default: Script's parent directory's skills folder.

.PARAMETER OutputPath
    Path to output Cursor rules.
    Default: ~/.cursor/rules

.PARAMETER IncludeSupporting
    If specified, includes supporting files (non-SKILL.md) as separate rules.

.PARAMETER Force
    Overwrite existing rules without prompting.

.PARAMETER WhatIf
    Show what would be done without making changes.

.EXAMPLE
    .\Convert-SkillsToCursorRules.ps1
    # Converts all skills to ~/.cursor/rules

.EXAMPLE
    .\Convert-SkillsToCursorRules.ps1 -OutputPath "D:\my-project\.cursor\rules" -Force
    # Converts to project-specific rules, overwriting existing

.EXAMPLE
    .\Convert-SkillsToCursorRules.ps1 -IncludeSupporting -WhatIf
    # Shows what would be converted including supporting files
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string]$SkillsPath,

    [Parameter()]
    [string]$OutputPath,

    [Parameter()]
    [switch]$IncludeSupporting,

    [Parameter()]
    [switch]$Force
)

# Determine default paths
if (-not $SkillsPath) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $SkillsPath = Join-Path (Split-Path -Parent $scriptDir) "skills"
}

if (-not $OutputPath) {
    $OutputPath = Join-Path $env:USERPROFILE ".cursor\rules"
}

# Validate skills path exists
if (-not (Test-Path $SkillsPath)) {
    Write-Error "Skills path not found: $SkillsPath"
    exit 1
}

# Create output directory if needed
if (-not (Test-Path $OutputPath)) {
    if ($PSCmdlet.ShouldProcess($OutputPath, "Create directory")) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
    }
}

function Parse-SkillFrontmatter {
    <#
    .SYNOPSIS
        Parses YAML frontmatter from a skill file.
    #>
    param([string]$Content)

    $result = @{
        Name = $null
        Description = $null
        Body = $Content
    }

    # Check for frontmatter
    if ($Content -match "^---\s*\r?\n([\s\S]*?)\r?\n---\s*\r?\n([\s\S]*)$") {
        $frontmatter = $Matches[1]
        $result.Body = $Matches[2]

        # Parse name
        if ($frontmatter -match "name:\s*(.+)") {
            $result.Name = $Matches[1].Trim().Trim('"').Trim("'")
        }

        # Parse description
        if ($frontmatter -match 'description:\s*"([^"]+)"') {
            $result.Description = $Matches[1]
        }
        elseif ($frontmatter -match "description:\s*'([^']+)'") {
            $result.Description = $Matches[1]
        }
        elseif ($frontmatter -match "description:\s*(.+)") {
            $result.Description = $Matches[1].Trim()
        }
    }

    return $result
}

function Convert-ToCursorRule {
    <#
    .SYNOPSIS
        Converts a skill to Cursor rule format.
    #>
    param(
        [string]$Name,
        [string]$Description,
        [string]$Body,
        [string]$SkillDir
    )

    # Determine if this rule should always apply
    # using-superpowers establishes how to use all other skills - needs to be always on
    $alwaysApply = if ($Name -eq "using-superpowers") { "true" } else { "false" }

    # Build Cursor frontmatter
    $cursorFrontmatter = @"
---
description: "$Description"
alwaysApply: $alwaysApply
---
"@

    # Add reference to original skill location
    $header = @"

<!-- Converted from superpowers skill: $Name -->
<!-- Source: $SkillDir -->

"@

    # Clean up any Claude-specific references in body
    $cleanBody = $Body -replace 'Use the `Skill` tool', 'Reference this rule'
    $cleanBody = $cleanBody -replace 'superpowers:', '@'
    $cleanBody = $cleanBody -replace 'Invoke Skill tool', 'Apply rule'

    return "$cursorFrontmatter$header$cleanBody"
}

function Get-SupportingFiles {
    <#
    .SYNOPSIS
        Gets non-SKILL.md files from a skill directory.
    #>
    param([string]$SkillDir)

    $files = Get-ChildItem -Path $SkillDir -File | Where-Object {
        $_.Name -ne "SKILL.md" -and
        $_.Name -ne "CREATION-LOG.md" -and
        $_.Extension -in @('.md', '.txt')
    }

    return $files
}

# Track statistics
$stats = @{
    Converted = 0
    Skipped = 0
    Errors = 0
    Supporting = 0
}

# Find all SKILL.md files
$skillFiles = Get-ChildItem -Path $SkillsPath -Recurse -Filter "SKILL.md"

Write-Host "`nConverting superpowers skills to Cursor rules..." -ForegroundColor Cyan
Write-Host "Source: $SkillsPath" -ForegroundColor Gray
Write-Host "Output: $OutputPath" -ForegroundColor Gray
Write-Host ""

foreach ($skillFile in $skillFiles) {
    $skillDir = $skillFile.DirectoryName
    $skillName = Split-Path -Leaf $skillDir

    try {
        # Read and parse skill
        $content = Get-Content -Path $skillFile.FullName -Raw -Encoding UTF8
        $parsed = Parse-SkillFrontmatter -Content $content

        # Use directory name if no name in frontmatter
        if (-not $parsed.Name) {
            $parsed.Name = $skillName
        }

        # Create output filename in superpowers subfolder
        $superpowersDir = Join-Path $OutputPath "superpowers"
        if (-not (Test-Path $superpowersDir)) {
            if ($PSCmdlet.ShouldProcess($superpowersDir, "Create directory")) {
                New-Item -ItemType Directory -Path $superpowersDir -Force | Out-Null
            }
        }
        $outputFile = Join-Path $superpowersDir "$($parsed.Name).mdc"

        # Check if exists
        if ((Test-Path $outputFile) -and -not $Force) {
            if (-not $PSCmdlet.ShouldContinue("Overwrite $outputFile?", "File exists")) {
                Write-Host "  SKIP: $($parsed.Name) (exists)" -ForegroundColor Yellow
                $stats.Skipped++
                continue
            }
        }

        # Convert to Cursor format
        $cursorContent = Convert-ToCursorRule `
            -Name $parsed.Name `
            -Description ($parsed.Description ?? "Superpowers skill: $($parsed.Name)") `
            -Body $parsed.Body `
            -SkillDir $skillDir

        # Write output
        if ($PSCmdlet.ShouldProcess($outputFile, "Create Cursor rule")) {
            $cursorContent | Out-File -FilePath $outputFile -Encoding UTF8 -NoNewline
            Write-Host "  OK: $($parsed.Name)" -ForegroundColor Green
            $stats.Converted++
        }

        # Handle supporting files if requested
        if ($IncludeSupporting) {
            $supportingFiles = Get-SupportingFiles -SkillDir $skillDir

            foreach ($supportFile in $supportingFiles) {
                $supportName = [System.IO.Path]::GetFileNameWithoutExtension($supportFile.Name)
                $supportOutputFile = Join-Path $superpowersDir "$($parsed.Name)-$supportName.mdc"

                $supportContent = Get-Content -Path $supportFile.FullName -Raw -Encoding UTF8
                $supportParsed = Parse-SkillFrontmatter -Content $supportContent

                $supportCursorContent = Convert-ToCursorRule `
                    -Name "$($parsed.Name)-$supportName" `
                    -Description ($supportParsed.Description ?? "Supporting doc for $($parsed.Name): $supportName") `
                    -Body ($supportParsed.Body ?? $supportContent) `
                    -SkillDir $skillDir

                if ($PSCmdlet.ShouldProcess($supportOutputFile, "Create supporting rule")) {
                    $supportCursorContent | Out-File -FilePath $supportOutputFile -Encoding UTF8 -NoNewline
                    Write-Host "    + $supportName" -ForegroundColor DarkGreen
                    $stats.Supporting++
                }
            }
        }
    }
    catch {
        Write-Host "  ERROR: $skillName - $_" -ForegroundColor Red
        $stats.Errors++
    }
}

# Summary
Write-Host "`n--- Summary ---" -ForegroundColor Cyan
Write-Host "Converted: $($stats.Converted)" -ForegroundColor Green
if ($stats.Supporting -gt 0) {
    Write-Host "Supporting files: $($stats.Supporting)" -ForegroundColor DarkGreen
}
if ($stats.Skipped -gt 0) {
    Write-Host "Skipped: $($stats.Skipped)" -ForegroundColor Yellow
}
if ($stats.Errors -gt 0) {
    Write-Host "Errors: $($stats.Errors)" -ForegroundColor Red
}

Write-Host "`nCursor rules written to: $OutputPath" -ForegroundColor Cyan

# Provide usage hint
Write-Host "`nUsage in Cursor:" -ForegroundColor Gray
Write-Host "  - Rules with alwaysApply: false are applied when Cursor's agent decides they're relevant" -ForegroundColor Gray
Write-Host "  - To manually apply a rule, use @<name> in chat (e.g., @brainstorming)" -ForegroundColor Gray
Write-Host "  - To always apply a rule, edit the .mdc file and set alwaysApply: true" -ForegroundColor Gray
Write-Host "  - Rules are in: $OutputPath\superpowers\" -ForegroundColor Gray
