param(
    [string]$EclipseHome = "D:\Software\eclipse",
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$helperRoot = Join-Path $scriptRoot "tools\eclipse-jdt-helper"
$sourceRoot = Join-Path $helperRoot "src"
$classesRoot = Join-Path $helperRoot "build\classes"
$jarRoot = Join-Path $helperRoot "build"
$bundleJar = Join-Path $jarRoot "com.silverlake.codex.jdthelper_1.0.1.jar"
$manifestPath = Join-Path $helperRoot "META-INF\MANIFEST.MF"
$pluginXmlPath = Join-Path $helperRoot "plugin.xml"
$justjHome = Get-ChildItem -Path (Join-Path $EclipseHome "plugins") -Directory `
    -Filter "org.eclipse.justj.openjdk.hotspot.jre.full.win32.x86_64_*" `
    | Sort-Object Name -Descending `
    | Select-Object -First 1 -ExpandProperty FullName

if (-not $justjHome) {
    throw "Unable to locate Eclipse JustJ runtime under $EclipseHome\plugins"
}

$javaHome = Join-Path $justjHome "jre\bin"
$javac = Join-Path $javaHome "javac.exe"
$jar = Join-Path $javaHome "jar.exe"
$classpath = Join-Path $EclipseHome "plugins\*"

if (-not (Test-Path $javac)) {
    throw "javac.exe not found at $javac"
}

$javaSources = Get-ChildItem -Path $sourceRoot -Recurse -Filter *.java | Select-Object -ExpandProperty FullName
if (-not $javaSources) {
    throw "No Java source files found under $sourceRoot"
}

$buildInputs = @($javaSources) + @($manifestPath, $pluginXmlPath)
if (-not $Force -and (Test-Path $bundleJar)) {
    $bundleTimestamp = (Get-Item $bundleJar).LastWriteTimeUtc
    $latestInputTimestamp = ($buildInputs | Get-Item | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1).LastWriteTimeUtc
    if ($bundleTimestamp -ge $latestInputTimestamp) {
        Write-Host "Helper bundle is up to date:" $bundleJar
        return
    }
}

if (Test-Path $classesRoot) {
    Remove-Item -Path $classesRoot -Recurse -Force
}

New-Item -Path $classesRoot -ItemType Directory -Force | Out-Null
New-Item -Path $jarRoot -ItemType Directory -Force | Out-Null

& $javac -cp $classpath -d $classesRoot $javaSources
if ($LASTEXITCODE -ne 0) {
    throw "javac failed with exit code $LASTEXITCODE"
}

Copy-Item -Path $pluginXmlPath -Destination (Join-Path $classesRoot "plugin.xml") -Force
Copy-Item -Path $manifestPath -Destination (Join-Path $jarRoot "MANIFEST.MF") -Force

if (Test-Path $bundleJar) {
    Remove-Item -Path $bundleJar -Force
}

Push-Location $classesRoot
try {
    & $jar cfm $bundleJar (Join-Path $jarRoot "MANIFEST.MF") .
    if ($LASTEXITCODE -ne 0) {
        throw "jar failed with exit code $LASTEXITCODE"
    }
} finally {
    Pop-Location
}

Write-Host "Built bundle:" $bundleJar
