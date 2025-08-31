Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$palette = [ordered]@{
    "latte" = @{
        "base"   = "#eff1f5"
        "mantle" = "#e6e9ef"
        "crust"  = "#dce0e8"
    }
    "frappe" = @{
        "base"   = "#303446"
        "mantle" = "#292c3c"
        "crust"  = "#232634"
    }
    "macchiato" = @{
        "base"   = "#24273a"
        "mantle" = "#1e2030"
        "crust"  = "#181926"
    }
    "mocha" = @{
        "base"   = "#1e1e2e"
        "mantle" = "#181825"
        "crust"  = "#11111b"
    }
}

$flavorChoices = @()
$i = 1
foreach ($flavor in $palette.Keys) {
    $flavorChoices += "$flavor (&$i)"
    $i++
}

$flavor = $Host.UI.PromptForChoice("Flavor", "Which flavor do you want to use?", $flavorChoices, 3)
$colors = $palette[$flavor]

$flatAppearance = $Host.UI.PromptForChoice("Appearance", "Do you want to use the flat appearance?", ('&Yes', '&No'), 1)
$flatAppearance = $flatAppearance -eq 0

function Update-Config {
    param ([string]$path, [hashtable]$colors)

    if (-Not (Test-Path $path)) {
        Write-Host "File not found: $path" -ForegroundColor Yellow
        return
    }
    Write-Host "> Updating $path..."

    $config = Get-Content -Path $path | ConvertFrom-Json -AsHashtable -Depth 10

    $config.AppThemeAddressBarBackgroundColor = $colors["base"]
    $config.AppThemeFileAreaBackgroundColor = $colors["base"]
    $config.AppThemeSidebarBackgroundColor = $colors["mantle"]
    $config.AppThemeBackgroundColor = If ($flatAppearance) { $colors["mantle"] } else { $colors["crust"] }

    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $path
}

# from https://files.community/docs/contributing/updates
$possiblePackageNames = @(
    # Dev
    "FilesDev_ykqwq8d6ps0ag",
    # Classic
    "Files_wvne1zexy08sa",
    # Sideload
    "Files_1y0xx7n9077q4",
    # Sideload Preview
    "FilesPreview_1y0xx7n9077q4",
    # Microsoft Store
    "49306atecsolution.FilesUWP_et10x9a9vyk8t",
    # Microsoft Store Preview
    "49306atecsolution.FilesPreview_et10x9a9vyk8t"
)

$locatedPaths = @()
foreach ($name in $possiblePackageNames) {
    $fullPath = "$env:LOCALAPPDATA\Packages\$name\LocalState\settings\user_settings.json"
    if (Test-Path $fullPath) {
        $locatedPaths += $fullPath
    }
}

if ($locatedPaths.Count -eq 0) {
    Write-Host "Could not locate the Files configuration file." -ForegroundColor Red
    return
}

# shut down running Files processes
$runningProcesses = @()
$runningProcesses += Get-Process -Name "Files" -ErrorAction Ignore
$runningProcesses += Get-Process -Name "Files.App.Server" -ErrorAction Ignore
if ($runningProcesses.Count -gt 0) {
    Write-Host "Killing running Files processes..." -ForegroundColor Yellow
    $runningProcesses | ForEach-Object { $_.Kill() }
    # wait for the processes to die
    Start-Sleep -Seconds 3
}


foreach ($path in $locatedPaths) {
    Update-Config -path $path -colors $colors
}

Write-Host "Catppuccin for Files has been installed! 🎉" -ForegroundColor Green
