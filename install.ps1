Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$palette = Invoke-WebRequest -Uri "https://github.com/catppuccin/palette/raw/v1.1.0/palette.json" | ConvertFrom-Json -AsHashtable

$flavorChoices = @()
$i = 1
foreach ($flavor in $palette.Keys) {
    $flavorChoices += "$flavor (&$i)"
    $i++
}

$flavor = $Host.UI.PromptForChoice("Flavor", "Which flavor do you want to use?", $flavorChoices, 3)
$flavor = $palette.Keys[$flavor]

$flatAppearance = $Host.UI.PromptForChoice("Appearance", "Do you want to use the flat appearance?", ('&Yes', '&No'), 1)
$flatAppearance = $flatAppearance -eq 0

# remap the palette to a K/V hashmap of the chosen flavor
$colors = @{}
$palette[$flavor].colors.Keys | ForEach-Object { 
    $colors.add($_, $palette[$flavor].colors[$_].hex.replace("#", "#ff"))
}

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

$runningProcesses = @()
$runningProcesses += Get-Process -Name "Files" -ErrorAction Ignore
$runningProcesses += Get-Process -Name "Files.App.Server" -ErrorAction Ignore
if ($runningProcesses.Count -gt 0) {
    Write-Host "Killing running Files processes..." -ForegroundColor Yellow
    $runningProcesses | ForEach-Object { $_.Kill() }
    # wait for the processes to die
    Start-Sleep -Seconds 2
}

$configFile = "LocalState\settings\user_settings.json"
$configPaths = @(
    # classic
    "$env:LOCALAPPDATA\Packages\Files_wvne1zexy08sa\$configFile",
    # classic preview
    "$env:LOCALAPPDATA\Packages\FilesPreview_1y0xx7n9077q4\$configFile",
    # Microsoft Store
    "$env:LOCALAPPDATA\Packages\49306atecsolution.FilesUWP_et10x9a9vyk8t\$configFile"
)

$locatedPaths = @()
foreach ($path in $configPaths) {
    if (Test-Path $path) {
        $locatedPaths += $path
    }
}

if ($locatedPaths.Count -eq 0) {
    Write-Host "Could not locate the Files configuration file." -ForegroundColor Red
    return
}

foreach ($path in $locatedPaths) {
    Update-Config -path $path -colors $colors
}

Write-Host "Catppuccin for Files has been installed! 🎉" -ForegroundColor Green