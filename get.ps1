<#
.SYNOPSIS
    kmp-skills one-line bootstrap installer.

.DESCRIPTION
    Run this with a single command — no manual clone needed:

        irm https://raw.githubusercontent.com/YOUR_USERNAME/kmp-skills/main/get.ps1 | iex

    What this script does:
      1. Checks that git is available
      2. Clones kmp-skills repo into ~/.kmp-skills/  (or pulls if already cloned)
      3. Runs the installer for the requested target
      4. Optionally registers a 'kmp-skills' command in your PowerShell profile
         so you can run 'kmp-skills update' from anywhere

    After install, to update in future:
        kmp-skills update              -- if PATH alias was added
        kmp-skills update -Target all  -- update all IDEs

.PARAMETER Target
    antigravity  (default) -- Antigravity CLI + Gemini CLI
    claude                 -- Claude Code CLI
    all                    -- Both of the above

.PARAMETER InstallDir
    Where to clone the repo. Default: ~/.kmp-skills

.PARAMETER NoAlias
    Skip adding the 'kmp-skills' command to your PowerShell profile.

.EXAMPLES
    # Basic (Antigravity/Gemini only)
    irm https://raw.githubusercontent.com/iammohdzaki/kmp-skills/main/get.ps1 | iex

    # All IDEs
    iex "& { $(irm https://raw.githubusercontent.com/iammohdzaki/kmp-skills/main/get.ps1) } -Target all"

    # Specify a custom install directory
    iex "& { $(irm https://raw.githubusercontent.com/iammohdzaki/kmp-skills/main/get.ps1) } -InstallDir D:\Tools\kmp-skills"
#>

param(
    [ValidateSet("antigravity","claude","all")]
    [string]$Target = "antigravity",

    [string]$InstallDir = (Join-Path $env:USERPROFILE ".kmp-skills"),

    [switch]$NoAlias
)

$RepoUrl = "https://github.com/iammohdzaki/kmp-skills.git"
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Say($msg, $color = "White") { Write-Host "  $msg" -ForegroundColor $color }
function Ok($msg)   { Say "[OK]   $msg" "Green" }
function Warn($msg) { Say "[WARN] $msg" "Yellow" }
function Err($msg)  { Say "[ERR]  $msg" "Red"; exit 1 }
function Step($msg) { Say ">>     $msg" "Cyan" }

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "  ============================================" -ForegroundColor DarkCyan
Write-Host "   kmp-skills  --  KMP AI Skills Installer   " -ForegroundColor Cyan
Write-Host "   https://github.com/iammohdzaki/kmp-skills" -ForegroundColor DarkGray
Write-Host "  ============================================" -ForegroundColor DarkCyan
Write-Host ""
Say "Target  : $Target"
Say "Location: $InstallDir"
Write-Host ""

# ---------------------------------------------------------------------------
# Step 1 -- Check git
# ---------------------------------------------------------------------------
Step "Checking for git..."
try {
    $gitVersion = git --version 2>&1
    Ok "Found: $gitVersion"
} catch {
    Err "git is not installed or not in PATH. Install from https://git-scm.com and retry."
}

# ---------------------------------------------------------------------------
# Step 2 -- Clone or pull
# ---------------------------------------------------------------------------
if (Test-Path (Join-Path $InstallDir ".git")) {
    Step "Repo already cloned at $InstallDir -- pulling latest..."
    Push-Location $InstallDir
    try {
        $out = git pull 2>&1
        $out | ForEach-Object { Say "  $_" "DarkGray" }
        Ok "Repo updated"
    } catch {
        Warn "git pull failed. Continuing with existing local version."
    }
    Pop-Location
} else {
    Step "Cloning kmp-skills into $InstallDir ..."
    if (Test-Path $InstallDir) {
        # Directory exists but is not a git repo -- bail unless it's empty
        $items = Get-ChildItem -Path $InstallDir -Force
        if ($items.Count -gt 0) {
            Err "Directory $InstallDir already exists and is not empty. Remove it or use -InstallDir to choose a different path."
        }
    }
    git clone $RepoUrl $InstallDir 2>&1 | ForEach-Object { Say "  $_" "DarkGray" }
    if (-not (Test-Path (Join-Path $InstallDir ".git"))) {
        Err "Clone failed. Check that $RepoUrl is accessible and try again."
    }
    Ok "Repo cloned to $InstallDir"
}

# ---------------------------------------------------------------------------
# Step 3 -- Run the installer
# ---------------------------------------------------------------------------
$installerPath = Join-Path $InstallDir "install.ps1"
if (-not (Test-Path $installerPath)) {
    Err "install.ps1 not found at $installerPath -- the clone may be incomplete."
}

Step "Running installer (Target: $Target)..."
& $installerPath install -Target $Target
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    Err "Installer exited with code $LASTEXITCODE"
}

# ---------------------------------------------------------------------------
# Step 4 -- Register 'kmp-skills' command in PowerShell profile (optional)
# ---------------------------------------------------------------------------
if (-not $NoAlias) {
    $profilePath = $PROFILE.CurrentUserAllHosts
    $funcLine    = "function kmp-skills { & `"$installerPath`" @args }"
    $marker      = "# kmp-skills alias"

    $needsWrite = $true
    if (Test-Path $profilePath) {
        $profileContent = Get-Content $profilePath -Raw
        if ($profileContent -match [regex]::Escape($marker)) {
            $needsWrite = $false
        }
    }

    if ($needsWrite) {
        Step "Adding 'kmp-skills' command to PowerShell profile..."
        $profileDir = Split-Path $profilePath -Parent
        if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }

        Add-Content -Path $profilePath -Value "`n$marker"
        Add-Content -Path $profilePath -Value $funcLine
        Ok "'kmp-skills' command added to $profilePath"
        Warn "Reload your shell or run: . `$PROFILE  to activate it in this session"
    } else {
        Ok "'kmp-skills' command already registered in profile"
    }
}

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "  ============================================" -ForegroundColor DarkCyan
Write-Host "   Install complete!" -ForegroundColor Green
Write-Host "  ============================================" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "    kmp-skills list              -- see all available skills" -ForegroundColor DarkGray
Write-Host "    kmp-skills status -Target all -- check sync status" -ForegroundColor DarkGray
Write-Host "    kmp-skills update -Target all -- pull latest + re-sync" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Your skills are live. Open a new agy/gemini/claude session to use them." -ForegroundColor Cyan
Write-Host ""
