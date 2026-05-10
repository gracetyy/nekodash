param(
    [string]$JavaHome = 'C:\Program Files\Microsoft\jdk-17.0.18.8-hotspot',
    [string]$ProjectRoot = '',
    [switch]$InstallToConnectedDevice
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-ProjectRoot {
    if ($ProjectRoot -ne '') {
        return (Resolve-Path $ProjectRoot).Path
    }
    return (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}

function Get-ExistingToolPath {
    param(
        [string[]]$Candidates,
        [string]$Label
    )

    foreach ($candidate in $Candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            return $candidate
        }
    }

    throw "Could not find $Label. Checked: $($Candidates -join ', ')"
}

function Get-CommandSourceOrNull {
    param([string]$Name)

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }
    return $null
}

function Convert-ConfigValue {
    param([string]$Value)

    if ($Value.StartsWith('"') -and $Value.EndsWith('"')) {
        return $Value.Substring(1, $Value.Length - 2)
    }
    return $Value
}

function Get-AndroidExportPreset {
    param([string]$ExportPresetsPath)

    $sections = @{}
    $currentSection = ''

    foreach ($rawLine in Get-Content $ExportPresetsPath) {
        $line = $rawLine.Trim()
        if ($line -eq '' -or $line.StartsWith(';')) {
            continue
        }

        if ($line -match '^\[(.+)\]$') {
            $currentSection = $Matches[1]
            if (-not $sections.ContainsKey($currentSection)) {
                $sections[$currentSection] = @{}
            }
            continue
        }

        if ($currentSection -eq '' -or $line -notmatch '^([^=]+)=(.*)$') {
            continue
        }

        $key = $Matches[1].Trim()
        $value = $Matches[2].Trim()
        $sections[$currentSection][$key] = $value
    }

    $presetSection = $null
    foreach ($sectionName in $sections.Keys) {
        if ($sectionName -notmatch '^preset\.\d+$') {
            continue
        }

        $section = $sections[$sectionName]
        if ($section.ContainsKey('name') -and (Convert-ConfigValue $section['name']) -eq 'Android') {
            $presetSection = $sectionName
            break
        }
    }

    if ($null -eq $presetSection) {
        throw "Could not find the Android export preset in $ExportPresetsPath"
    }

    $optionsSection = "$presetSection.options"
    if (-not $sections.ContainsKey($optionsSection)) {
        throw "Could not find the Android export options section in $ExportPresetsPath"
    }

    $options = $sections[$optionsSection]
    $enabledAbis = @()
    foreach ($abi in @('armeabi-v7a', 'arm64-v8a', 'x86', 'x86_64')) {
        $abiKey = "architectures/$abi"
        if ($options.ContainsKey($abiKey) -and (Convert-ConfigValue $options[$abiKey]) -eq 'true') {
            $enabledAbis += $abi
        }
    }

    return [PSCustomObject]@{
        PackageName = if ($options.ContainsKey('package/unique_name')) { Convert-ConfigValue $options['package/unique_name'] } else { '' }
        VersionCode = if ($options.ContainsKey('version/code')) { Convert-ConfigValue $options['version/code'] } else { '' }
        VersionName = if ($options.ContainsKey('version/name')) { Convert-ConfigValue $options['version/name'] } else { '' }
        MinSdk = if ($options.ContainsKey('gradle_build/min_sdk')) { Convert-ConfigValue $options['gradle_build/min_sdk'] } else { '' }
        TargetSdk = if ($options.ContainsKey('gradle_build/target_sdk')) { Convert-ConfigValue $options['gradle_build/target_sdk'] } else { '' }
        EnabledAbis = $enabledAbis
    }
}

function Invoke-GradleAssembleDebug {
    param(
        [string]$BuildRoot,
        [string]$JavaHomePath,
        [psobject]$PresetConfig
    )

    $originalJavaHome = $env:JAVA_HOME
    $originalPath = $env:Path
    $env:JAVA_HOME = $JavaHomePath
    $env:Path = "$JavaHomePath\bin;$originalPath"

    Push-Location $BuildRoot
    try {
        $escapedEnabledAbis = ($PresetConfig.EnabledAbis -join '|') -replace '\|', '^|'
        $gradleArgs = @(
            'assembleDebug',
            '-Pperform_signing=true',
            "-Pexport_package_name=$($PresetConfig.PackageName)",
            "-Pexport_version_code=$($PresetConfig.VersionCode)",
            "-Pexport_version_name=$($PresetConfig.VersionName)",
            "-Pexport_enabled_abis=$escapedEnabledAbis",
            '--console=plain'
        )

        if ($PresetConfig.MinSdk -ne '') {
            $gradleArgs += "-Pexport_version_min_sdk=$($PresetConfig.MinSdk)"
        }

        if ($PresetConfig.TargetSdk -ne '') {
            $gradleArgs += "-Pexport_version_target_sdk=$($PresetConfig.TargetSdk)"
        }

        & .\gradlew.bat @gradleArgs
        if ($LASTEXITCODE -ne 0) {
            throw "Gradle assembleDebug failed with exit code $LASTEXITCODE."
        }
    }
    finally {
        Pop-Location
        $env:JAVA_HOME = $originalJavaHome
        $env:Path = $originalPath
    }
}

$repoRoot = Get-ProjectRoot
$sourceBuildRoot = Join-Path $repoRoot 'android\build'
$exportPresetsPath = Join-Path $repoRoot 'export_presets.cfg'

if (-not (Test-Path $JavaHome)) {
    throw "Java 17 home not found: $JavaHome"
}

if (-not (Test-Path $sourceBuildRoot)) {
    throw "Generated Android Gradle project not found: $sourceBuildRoot"
}

if (-not (Test-Path $exportPresetsPath)) {
    throw "Export preset file not found: $exportPresetsPath"
}

$presetConfig = Get-AndroidExportPreset -ExportPresetsPath $exportPresetsPath

if ($presetConfig.PackageName -eq '') {
    throw 'Android export preset is missing package/unique_name.'
}

$sdkRoot = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
$apksigner = Get-ExistingToolPath -Label 'apksigner' -Candidates @(
    (Get-CommandSourceOrNull -Name 'apksigner'),
    (Join-Path $sdkRoot 'build-tools\35.0.0\apksigner.bat'),
    (Join-Path $sdkRoot 'build-tools\34.0.0\apksigner.bat')
)

$adb = $null
$adbCandidates = @(
    (Get-CommandSourceOrNull -Name 'adb'),
    (Join-Path $sdkRoot 'platform-tools\adb.exe')
)
foreach ($candidate in $adbCandidates) {
    if ($candidate -and (Test-Path $candidate)) {
        $adb = $candidate
        break
    }
}

$tempBuildRoot = Join-Path $env:TEMP ('nekodash_android_build_' + [guid]::NewGuid().ToString('N'))
$itemsToCopy = @(
    'AndroidManifest.xml',
    'assetPacks',
    'assets',
    'build.gradle',
    'config.gradle',
    'gradle',
    'gradle.properties',
    'gradlew',
    'gradlew.bat',
    'libs',
    'res',
    'settings.gradle',
    'src'
)

New-Item -ItemType Directory -Force -Path $tempBuildRoot | Out-Null

foreach ($item in $itemsToCopy) {
    $sourcePath = Join-Path $sourceBuildRoot $item
    if (Test-Path $sourcePath) {
        Copy-Item $sourcePath $tempBuildRoot -Recurse -Force
    }
}

Invoke-GradleAssembleDebug -BuildRoot $tempBuildRoot -JavaHomePath $JavaHome -PresetConfig $presetConfig

$tempApk = Join-Path $tempBuildRoot 'build\outputs\apk\debug\android_debug.apk'
if (-not (Test-Path $tempApk)) {
    throw "Signed debug APK was not produced at $tempApk"
}

& $apksigner verify --verbose --print-certs $tempApk
if ($LASTEXITCODE -ne 0) {
    throw 'APK signature verification failed.'
}

$destinations = @(
    (Join-Path $sourceBuildRoot 'nekodash.apk'),
    (Join-Path $sourceBuildRoot 'NekoDash.apk')
)

foreach ($destination in $destinations) {
    Copy-Item $tempApk $destination -Force
}

if ($InstallToConnectedDevice) {
    if (-not $adb) {
        throw 'adb not found, but -InstallToConnectedDevice was requested.'
    }

    $devicesOutput = & $adb devices 2>&1 | Out-String
    if ($devicesOutput -notmatch '\tdevice') {
        throw 'No connected Android device or emulator found.'
    }

    & $adb install -r -t -g $tempApk
    if ($LASTEXITCODE -ne 0) {
        throw 'adb install failed.'
    }
}

Write-Host "Signed Android debug APK copied to $(Join-Path $sourceBuildRoot 'nekodash.apk')"
Write-Host "Signed Android debug APK copied to $(Join-Path $sourceBuildRoot 'NekoDash.apk')"