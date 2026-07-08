param(
    [string]$EclipseHome = "D:\Software\eclipse",
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$portableRoot = Join-Path $scriptRoot "tools\eclipse-java-format-portable"
$libRoot = Join-Path $portableRoot "lib"
$helperBuildScript = Join-Path $scriptRoot "build-eclipse-jdt-helper.ps1"
$helperJar = Join-Path $scriptRoot "tools\eclipse-jdt-helper\build\com.silverlake.codex.jdthelper_1.0.1.jar"

$requiredPluginPatterns = @(
    "org.eclipse.jdt.core_*.jar",
    "org.eclipse.jdt.core.compiler.batch_*.jar",
    "org.eclipse.jface.text_*.jar",
    "org.eclipse.text_*.jar",
    "org.eclipse.core.runtime_*.jar",
    "org.eclipse.equinox.common_*.jar",
    "org.eclipse.osgi_*.jar",
    "org.eclipse.core.jobs_*.jar",
    "org.eclipse.core.resources_*.jar",
    "org.eclipse.core.contenttype_*.jar",
    "org.eclipse.core.expressions_*.jar",
    "org.eclipse.core.filesystem_*.jar",
    "org.eclipse.core.commands_*.jar",
    "org.eclipse.equinox.preferences_*.jar",
    "org.osgi.service.prefs_*.jar"
)

if (-not (Test-Path $libRoot)) {
    New-Item -Path $libRoot -ItemType Directory -Force | Out-Null
}

& $helperBuildScript -EclipseHome $EclipseHome -Force:$Force

if (-not (Test-Path $helperJar)) {
    throw "Helper jar not found: $helperJar"
}

$copiedFiles = New-Object System.Collections.Generic.List[string]

foreach ($pattern in $requiredPluginPatterns) {
    $match = Get-ChildItem -Path (Join-Path $EclipseHome "plugins") -Filter $pattern |
        Sort-Object Name -Descending |
        Select-Object -First 1

    if ($null -eq $match) {
        throw "Required Eclipse plugin not found for pattern: $pattern"
    }

    $destination = Join-Path $libRoot $match.Name
    Copy-Item -Path $match.FullName -Destination $destination -Force
    $copiedFiles.Add($destination) | Out-Null
}

$portableHelperJar = Join-Path $libRoot (Split-Path -Leaf $helperJar)
Copy-Item -Path $helperJar -Destination $portableHelperJar -Force
$copiedFiles.Add($portableHelperJar) | Out-Null

Get-ChildItem -Path $libRoot -File |
    Where-Object { $copiedFiles -notcontains $_.FullName } |
    Remove-Item -Force

Write-Host "Portable formatter runtime synced to:" $libRoot
