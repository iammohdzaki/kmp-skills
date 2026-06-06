<#
.SYNOPSIS
    kmp-skills installer

.DESCRIPTION
    Installs AI skills from this repo into your AI CLI tools.

    Antigravity / Gemini CLI  -- uses directory junctions so git pull auto-updates skills.
    Claude Code CLI           -- appends skills into ~/.claude/CLAUDE.md (opt-in).

    Junction strategy (Antigravity/Gemini):
      A junction is a Windows directory link. No admin rights needed.
      Once created, git pull in this repo = instant update. No re-install required.

    Copy strategy (Claude):
      Skills are appended into a clearly marked block in CLAUDE.md.
      Re-run 'install update' to sync after git pull.

.COMMANDS
    install    Install skills (default)
    update     git pull + re-sync
    status     Show what is installed and sync state
    uninstall  Remove installed skills
    list       List all skills in the repo

.PARAMETER Command
    install | update | status | uninstall | list

.PARAMETER Target
    antigravity  -- Antigravity CLI + Gemini CLI  (default, junction-based)
    claude       -- Claude Code CLI  (opt-in, appends to CLAUDE.md)
    all          -- Both of the above

.PARAMETER Category
    Filter to one skill category, e.g. create-project

.PARAMETER SkillName
    Filter to one skill by name, e.g. kmp-mvi-setup

.PARAMETER Force
    Overwrite existing installations without asking

.EXAMPLES
    # Install to Antigravity/Gemini (default, run once)
    .\install.ps1

    # Install to both Antigravity and Claude
    .\install.ps1 install -Target all

    # Check sync status
    .\install.ps1 status -Target all

    # Pull latest from GitHub and re-sync
    .\install.ps1 update -Target all

    # Install only one skill
    .\install.ps1 install -SkillName kmp-mvi-setup

    # Remove
    .\install.ps1 uninstall -Target all
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("install","update","status","uninstall","list")]
    [string]$Command = "install",

    [ValidateSet("antigravity","claude","all")]
    [string]$Target = "antigravity",

    [string]$Category  = "",
    [string]$SkillName = "",
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
$RepoRoot    = $PSScriptRoot
$SkillsRoot  = Join-Path $RepoRoot "skills"
$VersionFile = Join-Path $RepoRoot "VERSION"

# Antigravity + Gemini CLI both read from the same location
$AgySkillsDir = Join-Path $env:USERPROFILE ".gemini\config\skills"

# Claude Code CLI reads this file globally for every session
$ClaudeGlobalMd = Join-Path $env:USERPROFILE ".claude\CLAUDE.md"

$ManifestFile = ".kmp-skills.json"

# ---------------------------------------------------------------------------
# Console output helpers  (ASCII only -- avoids encoding issues on any locale)
# ---------------------------------------------------------------------------
function Print-Banner {
    $v = "?"
    if (Test-Path $VersionFile) { $v = (Get-Content $VersionFile -Raw).Trim() }
    Write-Host ""
    Write-Host "  kmp-skills v$v  |  $Command  ->  $Target" -ForegroundColor Cyan
    Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray
    Write-Host ""
}

function Print-Section($msg) { Write-Host "  [$msg]" -ForegroundColor Cyan }
function Print-Ok($msg)      { Write-Host "  OK  $msg" -ForegroundColor Green }
function Print-Warn($msg)    { Write-Host "  !!  $msg" -ForegroundColor Yellow }
function Print-Err($msg)     { Write-Host "  XX  $msg" -ForegroundColor Red }
function Print-Info($msg)    { Write-Host "      $msg" -ForegroundColor DarkGray }
function Print-Step($msg)    { Write-Host "  >>  $msg" -ForegroundColor White }

# ---------------------------------------------------------------------------
# Skill discovery
# ---------------------------------------------------------------------------
function Get-SkillName([string]$mdPath) {
    $text = Get-Content $mdPath -Raw -ErrorAction SilentlyContinue
    if ($text -match '(?m)^name:\s*(.+)$') { return $Matches[1].Trim() }
    return (Split-Path (Split-Path $mdPath -Parent) -Leaf)
}

function Get-SkillDesc([string]$mdPath) {
    $text = Get-Content $mdPath -Raw -ErrorAction SilentlyContinue
    if ($text -match '(?ms)^description:\s*>\s*\n(.*?)(?=\n\S|\n---)') {
        return ($Matches[1] -replace '\s+', ' ').Trim()
    }
    if ($text -match '(?m)^description:\s*(.+)$') { return $Matches[1].Trim() }
    return ""
}

function Get-AllSkills {
    $all = Get-ChildItem -Path $SkillsRoot -Recurse -Filter "SKILL.md" |
           Where-Object { $_.FullName -notlike "*\_template\*" }

    if ($Category)  { $all = $all | Where-Object { $_.FullName -like "*\$Category\*" } }
    if ($SkillName) {
        $all = $all | Where-Object {
            (Get-SkillName $_.FullName) -eq $SkillName -or
            (Split-Path $_.Directory -Leaf) -eq $SkillName
        }
    }
    return $all
}

# ---------------------------------------------------------------------------
# Hash helpers  (change detection for copy-based targets)
# ---------------------------------------------------------------------------
function Get-DirHash([string]$dirPath) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $sb  = New-Object System.Text.StringBuilder
    Get-ChildItem -Path $dirPath -Recurse -File | Sort-Object FullName | ForEach-Object {
        $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
        $h     = $sha.ComputeHash($bytes)
        $null  = $sb.Append(([System.BitConverter]::ToString($h)))
    }
    $final = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($sb.ToString()))
    return ([System.BitConverter]::ToString($final)) -replace '-',''
}

function Read-Manifest([string]$dir) {
    $p = Join-Path $dir $ManifestFile
    if (Test-Path $p) {
        try { return Get-Content $p -Raw | ConvertFrom-Json } catch {}
    }
    return $null
}

function Save-Manifest([string]$dir, $data) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $p = Join-Path $dir $ManifestFile
    $data | ConvertTo-Json -Depth 5 | Set-Content $p -Encoding UTF8
}

# ---------------------------------------------------------------------------
# ANTIGRAVITY / GEMINI CLI  --  junction-based
#
# Creates one junction per skill:
#   ~/.gemini/config/skills/<skill-name>  -->  <repo>/skills/<cat>/<skill-name>
#
# After initial install, "git pull" in this repo = instant update everywhere.
# No re-install needed.
# ---------------------------------------------------------------------------
function Install-Agy([array]$skills) {
    $dest = $AgySkillsDir
    Print-Section "Antigravity + Gemini CLI  ->  $dest"
    if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }

    $ver  = (Get-Content $VersionFile -Raw).Trim()
    $prev = Read-Manifest $dest
    $next = @{ version = $ver; installedAt = (Get-Date -Format "o"); skills = @{} }

    foreach ($sm in $skills) {
        $srcDir = $sm.Directory.FullName
        $name   = Get-SkillName $sm.FullName
        $jDest  = Join-Path $dest $name

        # Already a junction pointing at correct source -- skip
        if (Test-Path $jDest) {
            $attr      = (Get-Item $jDest -Force).Attributes
            $isLink    = ($attr -band [IO.FileAttributes]::ReparsePoint) -ne 0
            if ($isLink) {
                $currentTarget = (Get-Item $jDest -Force).Target
                if ($currentTarget -eq $srcDir) {
                    Print-Ok "$name  (junction already up to date)"
                    $next.skills[$name] = @{ type="junction"; source=$srcDir }
                    continue
                }
                Print-Step "Re-linking $name  (source path changed)"
                cmd /c rmdir `"$jDest`"
            } elseif ($Force) {
                Print-Step "Removing existing dir for $name  (-Force)"
                Remove-Item $jDest -Recurse -Force
            } else {
                Print-Warn "$name  exists but is not a junction. Use -Force to replace."
                continue
            }
        }

        # Create junction  (mklink /J requires no admin for same-user dirs)
        Print-Step "Linking $name"
        $out = cmd /c "mklink /J `"$jDest`" `"$srcDir`"" 2>&1
        if (Test-Path $jDest) {
            Print-Ok "$name  (junction created)"
            $next.skills[$name] = @{ type="junction"; source=$srcDir }
        } else {
            # Cross-drive fallback: copy
            Print-Warn "Junction failed for $name -- falling back to copy"
            Copy-Item $srcDir $jDest -Recurse -Force
            $next.skills[$name] = @{ type="copy"; source=$srcDir; hash=(Get-DirHash $jDest) }
            Print-Ok "$name  (copied)"
        }
    }

    Save-Manifest $dest $next
    Print-Ok "Manifest saved -> $(Join-Path $dest $ManifestFile)"
}

function Uninstall-Agy {
    $dest = $AgySkillsDir
    Print-Section "Uninstall: Antigravity  ->  $dest"
    if (-not (Test-Path $dest)) { Print-Warn "Nothing at $dest"; return }

    Get-ChildItem -Path $dest -Force |
        Where-Object { $_.Name -ne $ManifestFile } |
        ForEach-Object {
            Remove-Item $_.FullName -Force -Recurse
            Print-Ok "Removed $($_.Name)"
        }
    $mp = Join-Path $dest $ManifestFile
    if (Test-Path $mp) { Remove-Item $mp -Force }
}

function Status-Agy {
    $dest    = $AgySkillsDir
    $repoVer = (Get-Content $VersionFile -Raw).Trim()
    Print-Section "Status: Antigravity  ->  $dest"

    $m = Read-Manifest $dest
    if (-not $m) { Print-Warn "Not installed. Run: .\install.ps1"; return }

    if ($m.version -eq $repoVer) {
        Print-Ok "Version $($m.version)  (up to date)"
    } else {
        Print-Warn "Version $($m.version) installed, repo is $repoVer -- run: .\install.ps1 update"
    }

    foreach ($name in $m.skills.PSObject.Properties.Name) {
        $e     = $m.skills.$name
        $jPath = Join-Path $dest $name

        if ($e.type -eq "junction") {
            if (Test-Path $jPath) {
                $attr = (Get-Item $jPath -Force).Attributes
                if ($attr -band [IO.FileAttributes]::ReparsePoint) {
                    Print-Ok "$name  [junction -> live]"
                } else {
                    Print-Warn "$name  [junction BROKEN -- run update]"
                }
            } else {
                Print-Err "$name  [MISSING -- run update]"
            }
        } else {
            $liveHash = Get-DirHash $e.source
            if ($liveHash -eq $e.hash) {
                Print-Ok "$name  [copy -- in sync]"
            } else {
                Print-Warn "$name  [copy -- OUTDATED -- run update]"
            }
        }
    }
}

# ---------------------------------------------------------------------------
# CLAUDE CODE CLI  --  append to CLAUDE.md
#
# Claude Code reads ~/.claude/CLAUDE.md in every session.
# We write skills inside a clearly marked block so your own content is safe.
# Re-running replaces only our block.
# ---------------------------------------------------------------------------
$ClaudeBlockStart = "<!-- kmp-skills:start -->"
$ClaudeBlockEnd   = "<!-- kmp-skills:end -->"

function Install-Claude([array]$skills) {
    $target = $ClaudeGlobalMd
    Print-Section "Claude Code CLI  ->  $target"

    $dir = Split-Path $target -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    $ver   = (Get-Content $VersionFile -Raw).Trim()
    $date  = Get-Date -Format "yyyy-MM-dd"

    # Build the block content
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add($ClaudeBlockStart)
    $lines.Add("<!-- Generated by kmp-skills v$ver on $date. Do not edit this block. Re-run install.ps1 to update. -->")
    $lines.Add("")
    $lines.Add("# KMP Development Skills (kmp-skills v$ver)")
    $lines.Add("")
    $lines.Add("When working on Kotlin Multiplatform projects, apply the following guidelines.")
    $lines.Add("")

    foreach ($sm in $skills) {
        $name    = Get-SkillName $sm.FullName
        $desc    = Get-SkillDesc $sm.FullName
        $content = Get-Content $sm.FullName -Raw
        # Strip YAML frontmatter
        $body = $content -replace '(?s)^---.*?---\s*', ''
        $lines.Add("---")
        $lines.Add("")
        $lines.Add("## Skill: $name")
        if ($desc) { $lines.Add("> $desc") }
        $lines.Add("")
        $lines.Add($body.Trim())
        $lines.Add("")
        Print-Ok "$name  added"
    }

    $lines.Add($ClaudeBlockEnd)
    $block = $lines -join "`n"

    # Read existing file, preserve user content, replace only our block
    $existing = ""
    if (Test-Path $target) { $existing = Get-Content $target -Raw }

    $startEsc = [regex]::Escape($ClaudeBlockStart)
    $endEsc   = [regex]::Escape($ClaudeBlockEnd)

    if ($existing -match $startEsc) {
        $new = $existing -replace "(?s)$startEsc.*$endEsc", $block
    } else {
        $trimmed = $existing.TrimEnd()
        $new = if ($trimmed) { "$trimmed`n`n$block" } else { $block }
    }

    Set-Content $target -Value $new -Encoding UTF8
    Print-Ok "CLAUDE.md updated -> $target"
}

function Uninstall-Claude {
    $target = $ClaudeGlobalMd
    Print-Section "Uninstall: Claude  ->  $target"
    if (-not (Test-Path $target)) { Print-Warn "File not found: $target"; return }

    $content  = Get-Content $target -Raw
    $startEsc = [regex]::Escape($ClaudeBlockStart)
    $endEsc   = [regex]::Escape($ClaudeBlockEnd)

    if ($content -match $startEsc) {
        $cleaned = $content -replace "(?s)`n*$startEsc.*$endEsc`n*", "`n"
        Set-Content $target -Value $cleaned.TrimEnd() -Encoding UTF8
        Print-Ok "kmp-skills block removed from CLAUDE.md"
    } else {
        Print-Warn "No kmp-skills block found in CLAUDE.md"
    }
}

function Status-Claude {
    $target = $ClaudeGlobalMd
    Print-Section "Status: Claude  ->  $target"
    if (-not (Test-Path $target)) { Print-Warn "Not installed"; return }
    $content = Get-Content $target -Raw
    if ($content -match [regex]::Escape($ClaudeBlockStart)) {
        Print-Ok "Installed (kmp-skills block present)"
        if ($content -match 'kmp-skills v([\d.]+)') { Print-Info "Installed version: $($Matches[1])" }
    } else {
        Print-Warn "CLAUDE.md exists but no kmp-skills block found"
    }
}

# ---------------------------------------------------------------------------
# Update  --  git pull + re-sync
# ---------------------------------------------------------------------------
function Invoke-Update([string[]]$targets) {
    Print-Section "git pull -> $RepoRoot"
    Push-Location $RepoRoot
    try {
        $out = cmd /c "git pull 2>&1"
        $out | ForEach-Object { Print-Info $_ }
        Print-Ok "git pull complete"
    } catch {
        Print-Warn "git pull failed (offline or not a git repo) -- syncing local version"
    }
    Pop-Location

    $skills = @(Get-AllSkills)
    foreach ($t in $targets) {
        switch ($t) {
            "antigravity" { Install-Agy    $skills }
            "claude"      { Install-Claude $skills }
        }
    }
}

# ---------------------------------------------------------------------------
# List
# ---------------------------------------------------------------------------
function Show-List {
    Print-Section "Skills in this repo"
    $all = @(Get-AllSkills)
    $all | Group-Object { Split-Path (Split-Path $_.Directory -Parent) -Leaf } | ForEach-Object {
        Write-Host ""
        Write-Host "  [$($_.Name)]" -ForegroundColor Cyan
        foreach ($sm in $_.Group) {
            $n = Get-SkillName $sm.FullName
            $d = Get-SkillDesc $sm.FullName
            Write-Host "    $n" -ForegroundColor White
            if ($d) { Print-Info "    $($d.Substring(0, [Math]::Min($d.Length, 90)))" }
        }
    }
    Write-Host ""
    Print-Info "Total: $($all.Count) skill(s)"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
Print-Banner

$resolvedTargets = if ($Target -eq "all") {
    @("antigravity","claude")
} else {
    @($Target)
}

switch ($Command) {
    "list" {
        Show-List
    }
    "status" {
        foreach ($t in $resolvedTargets) {
            switch ($t) {
                "antigravity" { Status-Agy    }
                "claude"      { Status-Claude }
            }
        }
    }
    "install" {
        $skills = @(Get-AllSkills)
        if ($skills.Count -eq 0) {
            Print-Warn "No skills found. Check -Category or -SkillName filters."
            exit 0
        }
        Print-Info "Found $($skills.Count) skill(s) to install"
        foreach ($t in $resolvedTargets) {
            switch ($t) {
                "antigravity" { Install-Agy    $skills }
                "claude"      { Install-Claude $skills }
            }
        }
    }
    "update" {
        Invoke-Update $resolvedTargets
    }
    "uninstall" {
        foreach ($t in $resolvedTargets) {
            switch ($t) {
                "antigravity" { Uninstall-Agy    }
                "claude"      { Uninstall-Claude }
            }
        }
    }
}

Write-Host ""
Write-Host "  Done." -ForegroundColor Green
Write-Host ""
