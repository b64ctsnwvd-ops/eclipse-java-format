param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$FilePath,
    [string]$OutputRoot = "D:\ngkh\m2-core\.format-parity",
    [ValidateSet("FormatOnly", "OrganizeImportsAndFormat")]
    [string]$Mode = "FormatOnly"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function New-CleanDirectory {
    param(
        [string]$Path
    )

    if (Test-Path $Path) {
        Remove-Item -Path $Path -Recurse -Force
    }

    New-Item -Path $Path -ItemType Directory -Force | Out-Null
}

function Resolve-ProjectRoot {
    param(
        [string]$FilePath
    )

    $currentPath = Split-Path -Parent $FilePath
    while (-not [string]::IsNullOrWhiteSpace($currentPath)) {
        $projectFilePath = Join-Path $currentPath ".project"
        if (Test-Path $projectFilePath) {
            return $currentPath
        }

        $parentPath = Split-Path -Parent $currentPath
        if ($parentPath -eq $currentPath) {
            break
        }
        $currentPath = $parentPath
    }

    throw "Unable to locate Eclipse project root for $FilePath"
}

$resolvedFilePath = (Resolve-Path $FilePath).Path
$fileName = [System.IO.Path]::GetFileName($resolvedFilePath)
$projectRoot = Resolve-ProjectRoot -FilePath $resolvedFilePath
$projectDirectoryName = Split-Path -Leaf $projectRoot
$relativeFilePath = $resolvedFilePath.Substring($projectRoot.Length).TrimStart('\', '/')
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$runRoot = Join-Path $OutputRoot "$timestamp-$fileName"
$eclipseRoot = Join-Path $runRoot "eclipse-ui"
$codexRoot = Join-Path $runRoot "codex-helper"

New-CleanDirectory -Path $runRoot
New-CleanDirectory -Path $eclipseRoot
New-CleanDirectory -Path $codexRoot

$eclipseProjectRoot = Join-Path $eclipseRoot $projectDirectoryName
$codexProjectRoot = Join-Path $codexRoot $projectDirectoryName

Copy-Item -Path $projectRoot -Destination $eclipseRoot -Recurse -Force -Exclude ".git", "target"
Copy-Item -Path $projectRoot -Destination $codexRoot -Recurse -Force -Exclude ".git", "target"

$eclipseCopyPath = Join-Path $eclipseProjectRoot $relativeFilePath
$codexCopyPath = Join-Path $codexProjectRoot $relativeFilePath

$formatScript = Join-Path $PSScriptRoot "format-java.ps1"
$formatParams = @{
    ImportRoot = $codexRoot
}

if ($Mode -eq "OrganizeImportsAndFormat") {
    $formatParams.OrganizeImports = $true
}

& $formatScript @formatParams $codexCopyPath

$compareCommand = "git diff --no-index -- '$eclipseCopyPath' '$codexCopyPath'"

Write-Host ""
Write-Host "Parity workspace created:"
Write-Host "  Mode              :" $Mode
Write-Host "  Eclipse UI project :" $eclipseProjectRoot
Write-Host "  Eclipse UI file    :" $eclipseCopyPath
Write-Host "  Codex helper file  :" $codexCopyPath
Write-Host ""
Write-Host "Next in Eclipse:"
Write-Host "  1. Import or open the Eclipse UI project copy."
Write-Host "  2. Open the Eclipse UI file."
if ($Mode -eq "OrganizeImportsAndFormat") {
    Write-Host "  3. Run Source > Organize Imports."
    Write-Host "  4. Run Source > Format."
    Write-Host "  5. Save the file."
} else {
    Write-Host "  3. Press Ctrl + Shift + F."
    Write-Host "  4. Save the file."
}
Write-Host ""
Write-Host "Then compare with:"
Write-Host "  $compareCommand"
