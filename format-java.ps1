param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Paths,
    [string]$ProfilePath,
    [string]$EclipsePath,
    [string]$WorkspacePath,
    [string]$ConfigurationPath,
    [string]$ConfigPath,
    [switch]$ShowEclipseOutput
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-ConfigPath {
    param(
        [string]$ExplicitPath
    )

    if (-not [string]::IsNullOrWhiteSpace($ExplicitPath)) {
        return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ExplicitPath)
    }

    return (Join-Path $PSScriptRoot "eclipse-java-helper.psd1")
}

function Load-HelperConfig {
    param(
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return @{}
    }

    return Import-PowerShellDataFile -Path $Path
}

function Resolve-SettingValue {
    param(
        $ExplicitValue,
        $ConfigValue,
        $FallbackValue
    )

    if ($null -ne $ExplicitValue -and (-not ($ExplicitValue -is [string]) -or -not [string]::IsNullOrWhiteSpace($ExplicitValue))) {
        return $ExplicitValue
    }

    if ($null -ne $ConfigValue -and (-not ($ConfigValue -is [string]) -or -not [string]::IsNullOrWhiteSpace($ConfigValue))) {
        return $ConfigValue
    }

    return $FallbackValue
}

function Resolve-EclipseExecutable {
    param(
        [string]$ExplicitPath,
        [string]$ConfiguredHome
    )

    $candidates = New-Object System.Collections.Generic.List[string]

    if ($ExplicitPath) {
        $candidates.Add($ExplicitPath)
    }

    if ($env:ECLIPSEC_PATH) {
        $candidates.Add($env:ECLIPSEC_PATH)
    }

    if ($env:ECLIPSE_HOME) {
        $candidates.Add((Join-Path $env:ECLIPSE_HOME "eclipsec.exe"))
        $candidates.Add((Join-Path $env:ECLIPSE_HOME "eclipse.exe"))
    }

    if (-not [string]::IsNullOrWhiteSpace($ConfiguredHome)) {
        $candidates.Add((Join-Path $ConfiguredHome "eclipsec.exe"))
        $candidates.Add((Join-Path $ConfiguredHome "eclipse.exe"))
    }

    $commands = @("eclipsec.exe", "eclipse.exe")
    foreach ($commandName in $commands) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command -and $command.Source) {
            $candidates.Add($command.Source)
        }
    }

    $commonCandidates = @(
        "D:\Software\eclipse\eclipsec.exe",
        "D:\Software\eclipse\eclipse.exe",
        "C:\eclipse\eclipsec.exe",
        "C:\eclipse\eclipse.exe",
        "C:\Program Files\eclipse\eclipsec.exe",
        "C:\Program Files\eclipse\eclipse.exe",
        "C:\Program Files\Eclipse\eclipsec.exe",
        "C:\Program Files\Eclipse\eclipse.exe",
        "C:\Program Files (x86)\eclipse\eclipsec.exe",
        "C:\Program Files (x86)\eclipse\eclipse.exe",
        "C:\Users\sdkhng\eclipse\eclipsec.exe",
        "C:\Users\sdkhng\eclipse\eclipse.exe"
    )

    foreach ($candidate in $commonCandidates) {
        $candidates.Add($candidate)
    }

    foreach ($candidate in $candidates) {
        if (-not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path $candidate)) {
            return (Resolve-Path $candidate).Path
        }
    }

    throw @"
Unable to find an Eclipse formatter executable.

Use one of these options:
1. Pass -EclipsePath "C:\path\to\eclipsec.exe"
2. Set ECLIPSEC_PATH to the full executable path
3. Set ECLIPSE_HOME to the Eclipse installation folder

Example:
  .\format-java.ps1 -EclipsePath "C:\eclipse\eclipsec.exe" product\product.app\src\main\java\com\silverlake\core\product\controller\ProductPrmDepositSubTypeController.java
"@
}

function TryResolve-EclipseExecutable {
    param(
        [string]$ExplicitPath,
        [string]$ConfiguredHome
    )

    try {
        return Resolve-EclipseExecutable -ExplicitPath $ExplicitPath -ConfiguredHome $ConfiguredHome
    } catch {
        return $null
    }
}

function Resolve-JavaExecutable {
    param(
        [string]$ConfiguredExecutable
    )

    $candidates = New-Object System.Collections.Generic.List[string]

    if (-not [string]::IsNullOrWhiteSpace($ConfiguredExecutable)) {
        $candidates.Add($ConfiguredExecutable)
    }

    if ($env:JAVA_HOME) {
        $candidates.Add((Join-Path $env:JAVA_HOME "bin\java.exe"))
    }

    $command = Get-Command java.exe -ErrorAction SilentlyContinue
    if ($command -and $command.Source) {
        $candidates.Add($command.Source)
    }

    foreach ($candidate in $candidates) {
        if (-not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path $candidate)) {
            return (Resolve-Path $candidate).Path
        }
    }

    return $null
}

function Resolve-TargetPaths {
    param(
        [string[]]$InputPaths
    )

    $resolvedPaths = New-Object System.Collections.Generic.List[string]

    foreach ($inputPath in $InputPaths) {
        $matches = Resolve-Path -Path $inputPath -ErrorAction Stop
        foreach ($match in $matches) {
            $resolvedPaths.Add($match.Path)
        }
    }

    return $resolvedPaths.ToArray()
}

function Test-PortableFormatterRuntime {
    param(
        [string]$LibRoot
    )

    if (-not (Test-Path $LibRoot)) {
        return $false
    }

    $requiredPatterns = @(
        "com.silverlake.codex.jdthelper_*.jar",
        "org.eclipse.jdt.core_*.jar",
        "org.eclipse.jdt.core.compiler.batch_*.jar",
        "org.eclipse.jface.text_*.jar",
        "org.eclipse.text_*.jar",
        "org.eclipse.core.runtime_*.jar",
        "org.eclipse.equinox.common_*.jar",
        "org.eclipse.equinox.preferences_*.jar",
        "org.eclipse.osgi_*.jar",
        "org.osgi.service.prefs_*.jar"
    )

    foreach ($pattern in $requiredPatterns) {
        $match = Get-ChildItem -Path $LibRoot -Filter $pattern -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -eq $match) {
            return $false
        }
    }

    return $true
}

function Get-PortableFormatterClassPath {
    param(
        [string]$LibRoot
    )

    return ((Get-ChildItem -Path $LibRoot -Filter *.jar -File | Sort-Object Name | Select-Object -ExpandProperty FullName) -join ';')
}

function Resolve-EclipseHome {
    param(
        [string]$ExecutablePath
    )

    return Split-Path -Parent $ExecutablePath
}

function Read-ToolOutput {
    param(
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return @()
    }

    return @(Get-Content -Path $Path)
}

$resolvedConfigPath = Resolve-ConfigPath -ExplicitPath $ConfigPath
$helperConfig = Load-HelperConfig -Path $resolvedConfigPath

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$buildScript = Join-Path $scriptRoot "build-eclipse-jdt-helper.ps1"
$bundleJar = Join-Path $scriptRoot "tools\eclipse-jdt-helper\build\com.silverlake.codex.jdthelper_1.0.1.jar"
$ProfilePath = Resolve-SettingValue -ExplicitValue $ProfilePath -ConfigValue $helperConfig.FormatterProfilePath -FallbackValue "D:\work\eclipse-java-google-style.xml"
$WorkspacePath = Resolve-SettingValue -ExplicitValue $WorkspacePath -ConfigValue $helperConfig.FormatterWorkspace -FallbackValue (Join-Path $scriptRoot ".formatter-workspace")
$ConfigurationPath = Resolve-SettingValue -ExplicitValue $ConfigurationPath -ConfigValue $helperConfig.FormatterConfiguration -FallbackValue (Join-Path $scriptRoot ".formatter-configuration")
$portableFormatterLibRoot = Resolve-SettingValue -ExplicitValue $null -ConfigValue $helperConfig["PortableFormatterLibRoot"] -FallbackValue (Join-Path $scriptRoot "tools\eclipse-java-format-portable\lib")
$configuredJavaExecutable = Resolve-SettingValue -ExplicitValue $null -ConfigValue $helperConfig["PortableJavaExecutable"] -FallbackValue $null
$configuredEclipseHome = Resolve-SettingValue -ExplicitValue $null -ConfigValue $helperConfig.EclipseHome -FallbackValue $null

if (-not (Test-Path $ProfilePath)) {
    throw "Formatter profile not found: $ProfilePath"
}

$resolvedTargets = @(Resolve-TargetPaths -InputPaths $Paths)
if ($resolvedTargets.Count -eq 0) {
    throw "No files matched the supplied paths."
}

$resolvedProfilePath = (Resolve-Path $ProfilePath).Path
$resolvedPortableFormatterLibRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($portableFormatterLibRoot)
$javaExecutable = Resolve-JavaExecutable -ConfiguredExecutable $configuredJavaExecutable
$portableFormatterAvailable = Test-PortableFormatterRuntime -LibRoot $resolvedPortableFormatterLibRoot
$availableEclipseExecutable = TryResolve-EclipseExecutable -ExplicitPath $EclipsePath -ConfiguredHome $configuredEclipseHome

if ($null -eq $availableEclipseExecutable -and $portableFormatterAvailable -and $null -ne $javaExecutable) {
    $stdoutPath = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-java-formatter-stdout-{0}.log" -f ([System.Guid]::NewGuid().ToString("N")))
    $stderrPath = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-java-formatter-stderr-{0}.log" -f ([System.Guid]::NewGuid().ToString("N")))
    $portableClassPath = Get-PortableFormatterClassPath -LibRoot $resolvedPortableFormatterLibRoot
    $processArguments = @(
        "-cp"
        $portableClassPath
        "com.silverlake.codex.jdthelper.PortableFormatSourceMain"
        "--profile-path"
        $resolvedProfilePath
    )
    $processArguments += $resolvedTargets

    Write-Host "Using portable Java formatter:" $javaExecutable
    Write-Host "Using portable formatter runtime:" $resolvedPortableFormatterLibRoot
    Write-Host "Using profile:" $resolvedProfilePath
    Write-Host "Formatting files:" $resolvedTargets.Count

    try {
        $process = Start-Process `
            -FilePath $javaExecutable `
            -ArgumentList $processArguments `
            -NoNewWindow `
            -PassThru `
            -Wait `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath

        $toolOutput = @(Read-ToolOutput -Path $stdoutPath) + @(Read-ToolOutput -Path $stderrPath)

        if ($process.ExitCode -ne 0) {
            if ($toolOutput.Count -gt 0) {
                $toolOutput | ForEach-Object { Write-Host $_ }
            }
            throw "Portable formatter exited with code $($process.ExitCode)"
        }

        if ($ShowEclipseOutput -and $toolOutput.Count -gt 0) {
            $toolOutput | ForEach-Object { Write-Host $_ }
        }
    } finally {
        Remove-Item -Path $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    }

    Write-Host "Formatting completed successfully."
    return
}

$eclipseExecutable = $availableEclipseExecutable
if ($null -eq $eclipseExecutable) {
    $eclipseExecutable = Resolve-EclipseExecutable -ExplicitPath $EclipsePath -ConfiguredHome $configuredEclipseHome
}
$eclipseHome = Resolve-EclipseHome -ExecutablePath $eclipseExecutable
$resolvedWorkspacePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($WorkspacePath)
$resolvedConfigurationPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ConfigurationPath)
$dropinsDir = Join-Path $eclipseHome "dropins"
$installedBundle = Join-Path $dropinsDir "com.silverlake.codex.jdthelper_1.0.1.jar"

if (-not (Test-Path $resolvedWorkspacePath)) {
    New-Item -Path $resolvedWorkspacePath -ItemType Directory | Out-Null
}

if (-not (Test-Path $resolvedConfigurationPath)) {
    New-Item -Path $resolvedConfigurationPath -ItemType Directory | Out-Null
}

Write-Host "Using Eclipse formatter:" $eclipseExecutable
Write-Host "Using Eclipse home:" $eclipseHome
Write-Host "Using profile:" $resolvedProfilePath
Write-Host "Using formatter workspace:" $resolvedWorkspacePath
Write-Host "Using formatter configuration:" $resolvedConfigurationPath
Write-Host "Formatting files:" $resolvedTargets.Count

& $buildScript -EclipseHome $eclipseHome

if (-not (Test-Path $dropinsDir)) {
    New-Item -Path $dropinsDir -ItemType Directory -Force | Out-Null
}

Get-ChildItem -Path $dropinsDir -Filter "com.silverlake.codex.jdthelper_*.jar" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -ne $installedBundle } |
    Remove-Item -Force -ErrorAction SilentlyContinue

$shouldInstallBundle = $true
if ((Test-Path $installedBundle) -and (Test-Path $bundleJar)) {
    $shouldInstallBundle = (Get-Item $bundleJar).LastWriteTimeUtc -gt (Get-Item $installedBundle).LastWriteTimeUtc
}

if ($shouldInstallBundle) {
    Copy-Item -Path $bundleJar -Destination $installedBundle -Force
    Write-Host "Installed helper bundle:" $installedBundle
} else {
    Write-Host "Helper bundle already current:" $installedBundle
}

$stdoutPath = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-java-formatter-stdout-{0}.log" -f ([System.Guid]::NewGuid().ToString("N")))
$stderrPath = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-java-formatter-stderr-{0}.log" -f ([System.Guid]::NewGuid().ToString("N")))
$processArguments = @(
    "-nosplash"
    "-clean"
    "-data"
    $resolvedWorkspacePath
    "-configuration"
    $resolvedConfigurationPath
    "-application"
    "com.silverlake.codex.jdthelper.formatSource"
    "--profile-path"
    $resolvedProfilePath
)
$processArguments += $resolvedTargets

try {
    $process = Start-Process `
        -FilePath $eclipseExecutable `
        -ArgumentList $processArguments `
        -NoNewWindow `
        -PassThru `
        -Wait `
        -RedirectStandardOutput $stdoutPath `
        -RedirectStandardError $stderrPath

    $toolOutput = @(Read-ToolOutput -Path $stdoutPath) + @(Read-ToolOutput -Path $stderrPath)

    if ($process.ExitCode -ne 0) {
        if ($toolOutput.Count -gt 0) {
            $toolOutput | ForEach-Object { Write-Host $_ }
        }
        throw "Formatter exited with code $($process.ExitCode)"
    }

    if ($ShowEclipseOutput -and $toolOutput.Count -gt 0) {
        $toolOutput | ForEach-Object { Write-Host $_ }
    }
} finally {
    Remove-Item -Path $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
}

Write-Host "Formatting completed successfully."
