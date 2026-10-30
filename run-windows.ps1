$ErrorActionPreference = "Stop"
$ProjectDir = $PSScriptRoot
$EnvExample = Join-Path $ProjectDir ".env.example"
$EnvFile = Join-Path $ProjectDir ".env"
$BundledExe = Join-Path $ProjectDir "qualtrics-migrator.exe"

if (-not (Test-Path $BundledExe)) {
    throw "qualtrics-migrator.exe is missing. Extract the complete Windows release ZIP and try again."
}

if (-not (Test-Path $EnvFile)) {
    Copy-Item -LiteralPath $EnvExample -Destination $EnvFile
    Write-Host "Created .env. Configure your source and destination tokens before migrating."
}

$env:QUALTRICS_MIGRATOR_DATA_DIR = $ProjectDir
$env:QUALTRICS_MIGRATOR_ENV_FILE = $EnvFile
& $BundledExe
exit $LASTEXITCODE
