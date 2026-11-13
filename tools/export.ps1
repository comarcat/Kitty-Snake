param(
    [ValidateSet("web", "windows", "android-debug", "all")]
    [string]$Target = "all"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

if ($env:GODOT_BIN) {
    $Godot = $env:GODOT_BIN
} else {
    $GodotCommand = Get-Command godot -ErrorAction Stop
    $Godot = $GodotCommand.Source
}

function Invoke-Godot {
    param([string[]]$Arguments)

    & $Godot @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Godot failed with exit code $LASTEXITCODE."
    }
}

Invoke-Godot @("--headless", "--path", ".", "--import")

function Export-Web {
    New-Item -ItemType Directory -Force -Path "builds\web" | Out-Null
    Invoke-Godot @("--headless", "--path", ".", "--export-release", "Web", "builds/web/index.html")
}

function Export-Windows {
    New-Item -ItemType Directory -Force -Path "builds\windows" | Out-Null
    Invoke-Godot @("--headless", "--path", ".", "--export-release", "Windows Desktop", "builds/windows/KittySnake.exe")

    $Executable = Join-Path $ProjectRoot "builds\windows\KittySnake.exe"
    $Pack = Join-Path $ProjectRoot "builds\windows\KittySnake.pck"
    if (-not (Test-Path $Executable) -or -not (Test-Path $Pack)) {
        throw "Windows export did not produce both KittySnake.exe and KittySnake.pck."
    }

    Compress-Archive -Path $Executable, $Pack -DestinationPath "builds\KittySnake-windows.zip" -Force
}

function Export-Android {
    New-Item -ItemType Directory -Force -Path "builds\android" | Out-Null
    Invoke-Godot @("--headless", "--path", ".", "--export-debug", "Android Debug", "builds/android/KittySnake-debug.apk")
}

switch ($Target) {
    "web" { Export-Web }
    "windows" { Export-Windows }
    "android-debug" { Export-Android }
    "all" {
        Export-Web
        Export-Windows
    }
}
