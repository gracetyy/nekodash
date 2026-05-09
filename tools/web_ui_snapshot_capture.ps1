param(
    [string]$UrlBase = "http://localhost:8060/index.html",
    [string]$OutDir = "$env:APPDATA\Godot\app_userdata\NekoDash\playtest_screenshots\ui_verify_web",
    [int]$DelayMs = 4000,
    [string]$BrowserPath = ""
)

$ErrorActionPreference = "Stop"

function Resolve-BrowserPath {
    if ($BrowserPath -ne "") {
        if (Test-Path $BrowserPath) {
            return $BrowserPath
        }
        throw "BrowserPath not found: $BrowserPath"
    }

    $candidates = @(
        (Get-Command msedge -ErrorAction SilentlyContinue).Source,
        "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
        "$env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe",
        (Get-Command chrome -ErrorAction SilentlyContinue).Source,
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe"
    ) | Where-Object { $_ -and $_ -ne "" }

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    throw "No supported browser found. Install Edge or Chrome, or pass -BrowserPath."
}

function Assert-UrlReachable {
    try {
        Invoke-WebRequest -Uri $UrlBase -Method Head -TimeoutSec 5 | Out-Null
    } catch {
        throw "URL not reachable: $UrlBase. Start a local server for export/web (e.g., python -m http.server 8060)."
    }
}

function Capture-Screen {
    param(
        [string]$Screen,
        [string]$OutputName,
        [int]$Width,
        [int]$Height,
        [string]$SizeLabel,
        [string]$BrowserExe,
        [int]$DelayMsOverride,
        [int]$BudgetMsOverride
    )

    $delayToUse = $DelayMsOverride
    if ($delayToUse -le 0) {
        $delayToUse = $DelayMs
    }

    $query = "capture_ui=1&screen=$Screen&delay_ms=$delayToUse"
    $url = "$UrlBase`?$query"
    $outputPath = Join-Path $OutDir "$OutputName`_$SizeLabel`_web.png"
    $budget = $BudgetMsOverride
    if ($budget -le 0) {
        $budget = [Math]::Max(20000, $delayToUse + 15000)
    }

    $browserArgs = @(
        '--headless=new',
        '--disable-gpu',
        '--hide-scrollbars',
        '--force-device-scale-factor=1',
        "--window-size=$Width,$Height",
        "--virtual-time-budget=$budget",
        "--screenshot=$outputPath",
        $url
    )

    & $BrowserExe @browserArgs | Out-Null

    if (-not (Test-Path $outputPath)) {
        Write-Warning "Failed to capture $OutputName ($SizeLabel)"
    } else {
        Write-Host "Captured $OutputName ($SizeLabel) -> $outputPath"
    }
}

Write-Host "[WebCapture] Output directory: $OutDir"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Assert-UrlReachable
$browserExe = Resolve-BrowserPath

$targets = @(
    @{ Name = "main_menu"; Screen = "main_menu"; DelayMs = 4000; BudgetMs = 20000 },
    @{ Name = "world_map"; Screen = "world_map"; DelayMs = 12000; BudgetMs = 30000 },
    @{ Name = "skin_select"; Screen = "skin_select"; DelayMs = 5000; BudgetMs = 20000 },
    @{ Name = "options"; Screen = "options"; DelayMs = 5000; BudgetMs = 20000 },
    @{ Name = "pause"; Screen = "pause"; DelayMs = 7000; BudgetMs = 22000 },
    @{ Name = "level_complete_plain"; Screen = "level_complete_plain"; DelayMs = 6000; BudgetMs = 22000 },
    @{ Name = "level_complete"; Screen = "level_complete"; DelayMs = 7000; BudgetMs = 22000 },
    @{ Name = "level_complete_perfect"; Screen = "level_complete_perfect"; DelayMs = 7000; BudgetMs = 22000 },
    @{ Name = "level_complete_overlay"; Screen = "level_complete_overlay"; DelayMs = 8000; BudgetMs = 24000 },
    @{ Name = "gameplay_hud"; Screen = "gameplay"; DelayMs = 12000; BudgetMs = 30000 }
)

$sizes = @(
    @{ Label = "mobile"; Width = 540; Height = 960 },
    @{ Label = "desktop"; Width = 1280; Height = 720 }
)

foreach ($size in $sizes) {
    Write-Host "[WebCapture] Capturing $($size.Label) ($($size.Width)x$($size.Height))"
    foreach ($target in $targets) {
        Capture-Screen -Screen $target.Screen -OutputName $target.Name `
            -Width $size.Width -Height $size.Height -SizeLabel $size.Label -BrowserExe $browserExe `
            -DelayMsOverride $target.DelayMs -BudgetMsOverride $target.BudgetMs
    }
}

Write-Host "[WebCapture] Complete."
