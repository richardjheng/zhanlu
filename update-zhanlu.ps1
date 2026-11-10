<#
.SYNOPSIS
    Updates an installed project from a verified GitHub Release asset.
.DESCRIPTION
    Uses module.json releaseRepository, never updates a Git working tree. The script's
    directory (if installed), or its nearest installed ancestor, is the default target.
    -WhatIf reads release metadata only: no downloads, temporary files or installer.
.PARAMETER Version
    An exact stable release tag, vX.Y.Z. Omit to use releases/latest.
.PARAMETER Local
    Use the kit-source directory containing this script without network access.
    NoPull is a compatibility alias. Installed copies cannot be local sources.
.PARAMETER Force
    Reapply the same version. Does not bypass validation or permit downgrades.
.PARAMETER AllowDowngrade
    Explicitly allow a version older than the installed version.
.PARAMETER RemoveStale
    Pass through to setup-zhanlu.ps1 -Update.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$TargetPath,
    [ValidatePattern('^v[0-9]+\.[0-9]+\.[0-9]+$')][string]$Version,
    [Alias('NoPull')][switch]$Local,
    [switch]$Force,
    [switch]$AllowDowngrade,
    [switch]$RemoveStale,
    # Offline regression inputs only. Both are required; all normal checks still apply.
    [Parameter(DontShow = $true)][string]$TestReleaseJson,
    [Parameter(DontShow = $true)][string]$TestAssetPath
)

$ErrorActionPreference = 'Stop'
$kitRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path
. (Join-Path $kitRoot '.agents/lib/module-safety.ps1')

function Read-UpdateManifest([string]$Root) {
    $path = Resolve-ModulePath $Root '.agents/module.json'
    return Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Test-InstalledProject([string]$Path) {
    if (-not (Test-Path -LiteralPath (Join-Path $Path '.agents/module.json') -PathType Leaf)) { return $false }
    $probe = Read-UpdateManifest $Path
    return ($probe.name -eq 'zhanlu' -and -not [string]::IsNullOrWhiteSpace($probe.projectKind) -and
        $probe.projectKind -ne 'kit-source')
}

function Get-UpdateVersion([string]$Value) {
    if ($Value -notmatch '^[0-9]+\.[0-9]+\.[0-9]+$') { throw "Invalid module version: $Value" }
    return [version]$Value
}

function Assert-ArchiveListing([string[]]$Lines, [string]$Destination) {
    $paths = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $entryHasPath = $false
    foreach ($line in $Lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { $entryHasPath = $false; continue }
        if ($line -notmatch '^([^=]+?) = (.*)$') { throw "Unrecognized archive listing: $line" }
        $key = $Matches[1]
        $value = $Matches[2]
        if ($key -eq 'Path') {
            if ($entryHasPath) { throw 'Ambiguous archive entry.' }
            $entryHasPath = $true
            [void](Resolve-ModulePath $Destination $value)
            if (-not $paths.Add($value.Replace('\', '/'))) { throw "Duplicate archive path: $value" }
        } elseif (-not $entryHasPath) {
            throw "Archive metadata without a path: $line"
        }
        # 7-Zip reports symbolic/hard links explicitly, and Unix symlinks in Attributes.
        if (($key -match '(?i)link|reparse' -and $value -and $value -ne '-') -or
            ($key -in @('Attributes', 'Mode') -and $value -match '(?i)(^|\s)l|reparse|^L|\bL\b')) {
            throw "Archive link entry is forbidden: $line"
        }
    }
    if ($paths.Count -eq 0) { throw 'Archive contains no entries.' }
}

$sourceManifest = Read-UpdateManifest $kitRoot
if ($Local -and ($Version -or $TestReleaseJson -or $TestAssetPath)) {
    throw '-Local cannot be combined with -Version or offline release test inputs.'
}
if ($Local -and $sourceManifest.projectKind -ne 'kit-source') {
    throw '-Local requires the script to reside in a kit-source directory.'
}
if ([bool]$TestReleaseJson -ne [bool]$TestAssetPath) {
    throw 'Offline tests require both -TestReleaseJson and -TestAssetPath.'
}
if ([string]::IsNullOrWhiteSpace($TargetPath)) {
    $probeRoot = $kitRoot
    while ($probeRoot) {
        if (Test-InstalledProject $probeRoot) { $TargetPath = $probeRoot; break }
        $parent = Split-Path -Parent $probeRoot
        if ($parent -eq $probeRoot) { break }
        $probeRoot = $parent
    }
    if (-not $TargetPath) { throw "No installed project found at or above $kitRoot. Pass -TargetPath." }
}
$targetRoot = (Resolve-Path -LiteralPath $TargetPath).Path
if (-not (Test-InstalledProject $targetRoot)) { throw "$targetRoot is not an installed project." }
$installed = Read-UpdateManifest $targetRoot
$currentVersion = Get-UpdateVersion ([string]$installed.version)
$releaseUrl = 'N/A (local kit)'
$expectedHash = 'N/A (local kit; no release asset)'
$asset = $null

if ($Local) {
    $targetVersion = Get-UpdateVersion ([string]$sourceManifest.version)
    $sourceDescription = "Local kit: $kitRoot"
} else {
    $repository = [string]$sourceManifest.releaseRepository
    if ($repository -notmatch '^[^/\s]+/[^/\s]+$') { throw 'module.json releaseRepository is missing or invalid.' }
    # Encode the two repository components rather than allowing URL query/fragment injection.
    $repoParts = $repository.Split('/')
    $apiRoot = 'https://api.github.com/repos/' + [uri]::EscapeDataString($repoParts[0]) + '/' + [uri]::EscapeDataString($repoParts[1])
    $apiUrl = if ($Version) { "$apiRoot/releases/tags/$Version" } else { "$apiRoot/releases/latest" }
    $sourceDescription = $apiUrl
    $headers = @{ 'User-Agent' = 'zhanlu-release-updater'; 'Accept' = 'application/vnd.github+json' }
    if ($TestReleaseJson) {
        $release = Get-Content -LiteralPath $TestReleaseJson -Raw -Encoding UTF8 | ConvertFrom-Json
        $sourceDescription += " (offline fixture: $TestReleaseJson)"
    } else {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers -UseBasicParsing
    }
    if ($release.draft -isnot [bool] -or $release.prerelease -isnot [bool] -or
        $release.draft -or $release.prerelease) { throw 'Draft or prerelease (or missing release flags) is forbidden.' }
    $tag = [string]$release.tag_name
    if ($tag -cnotmatch '^v[0-9]+\.[0-9]+\.[0-9]+$' -or ($Version -and $tag -cne $Version)) {
        throw "Invalid or unexpected release tag: $tag"
    }
    $targetVersion = Get-UpdateVersion $tag.Substring(1)
    $releaseUrl = [string]$release.html_url
    if ($releaseUrl -notmatch '^https://') { throw 'Release URL must use HTTPS.' }
    $assetName = "zhanlu-$tag.7z"
    $assets = @($release.assets | Where-Object { $_.name -ceq $assetName })
    if ($assets.Count -ne 1) { throw "Expected exactly one release asset named $assetName." }
    $asset = $assets[0]
    if ([string]$asset.digest -cnotmatch '^sha256:([a-fA-F0-9]{64})$') { throw 'Release asset SHA-256 digest is missing or invalid.' }
    $expectedHash = $Matches[1].ToUpperInvariant()
    if ([string]$asset.browser_download_url -notmatch '^https://') { throw 'Asset download URL must use HTTPS.' }
}

Write-Output "Project: $targetRoot"
Write-Output "Version: $currentVersion -> $targetVersion"
Write-Output "Source: $sourceDescription"
Write-Output "Release URL: $releaseUrl"
Write-Output "Asset SHA-256: $expectedHash"
if ($targetVersion -lt $currentVersion -and -not $AllowDowngrade) { throw 'Downgrade refused. Use -AllowDowngrade explicitly.' }
if ($targetVersion -eq $currentVersion -and -not $Force) {
    Write-Output 'Already up to date. Use -Force to reapply this version.'
    return
}
if (-not $PSCmdlet.ShouldProcess($targetRoot, "Update Zhanlu $currentVersion -> $targetVersion")) { return }

$stage = $null
$tempRoot = [System.IO.Path]::GetFullPath($env:TEMP)
try {
    $packageRoot = $kitRoot
    if (-not $Local) {
        $sevenZip = @('C:\Program Files\7-Zip\7z.exe', 'C:\Program Files (x86)\7-Zip\7z.exe') |
            Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
        if (-not $sevenZip) {
            $command = Get-Command 7z.exe -ErrorAction SilentlyContinue
            if ($command) { $sevenZip = $command.Source }
        }
        if (-not $sevenZip) { throw '7z.exe was not found. Install 7-Zip or add it to PATH.' }
        $candidate = Join-Path $tempRoot ('zhanlu-' + [guid]::NewGuid().ToString('N'))
        # Do not adopt or clean a pre-existing directory, even on a GUID collision.
        New-Item -ItemType Directory -Path $candidate -ErrorAction Stop | Out-Null
        $stage = $candidate
        $archive = Join-Path $stage $assetName
        if ($TestAssetPath) {
            Copy-Item -LiteralPath $TestAssetPath -Destination $archive
        } else {
            Invoke-WebRequest -Uri $asset.browser_download_url -Headers $headers -UseBasicParsing -OutFile $archive
        }
        $actualHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
        if ($actualHash -ne $expectedHash) { throw "Asset SHA-256 mismatch: expected $expectedHash; actual $actualHash" }
        & $sevenZip t $archive | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "7z integrity test failed with exit code $LASTEXITCODE." }
        $oldEncoding = [Console]::OutputEncoding
        try {
            [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
            $listing = @(& $sevenZip l -slt -ba -sccUTF-8 $archive)
            if ($LASTEXITCODE -ne 0) { throw "7z listing failed with exit code $LASTEXITCODE." }
        } finally { [Console]::OutputEncoding = $oldEncoding }
        $packageRoot = Join-Path $stage 'package'
        Assert-ArchiveListing $listing $packageRoot
        & $sevenZip x $archive "-o$packageRoot" -y | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "7z extraction failed with exit code $LASTEXITCODE." }
        $links = @(Get-ChildItem -LiteralPath $packageRoot -Recurse -Force | Where-Object {
            $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint
        })
        if ($links.Count) { throw 'Extracted package contains a reparse point.' }
        $packageManifest = Read-UpdateManifest $packageRoot
        if ($packageManifest.name -ne 'zhanlu' -or $packageManifest.projectKind -ne 'kit-source' -or
            [string]$packageManifest.version -cne $tag.Substring(1)) {
            throw 'Package version/projectKind does not match the release tag and kit-source contract.'
        }
    }
    $installer = Resolve-ModulePath $packageRoot 'setup-zhanlu.ps1'
    if (-not (Test-Path -LiteralPath $installer -PathType Leaf)) { throw "Installer is missing: $installer" }
    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $installer, '-Update', '-TargetPath', $targetRoot)
    if ($RemoveStale) { $arguments += '-RemoveStale' }
    & powershell.exe @arguments
    if ($LASTEXITCODE -ne 0) { throw "setup-zhanlu.ps1 -Update failed with exit code $LASTEXITCODE." }
    Write-Output 'Upgrade done. Reload the VSCode window so the tools rescan rules and skills.'
} finally {
    if ($stage -and (Test-Path -LiteralPath $stage)) {
        $resolvedStage = [System.IO.Path]::GetFullPath($stage)
        $tempPrefix = $tempRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
        if (-not $resolvedStage.StartsWith($tempPrefix, [System.StringComparison]::OrdinalIgnoreCase) -or
            (Split-Path -Leaf $resolvedStage) -notmatch '^zhanlu-[a-f0-9]{32}$') {
            throw 'Refusing to clean staging outside the verified temporary directory.'
        }
        # Never recurse through a link, including one substituted for the staging root.
        $stageItems = @((Get-Item -LiteralPath $resolvedStage -Force)) + @(Get-ChildItem -LiteralPath $resolvedStage -Recurse -Force)
        if (@($stageItems | Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint }).Count) {
            throw "Refusing to clean staging containing reparse points: $resolvedStage"
        }
        Remove-Item -LiteralPath $resolvedStage -Recurse -Force
    }
}
