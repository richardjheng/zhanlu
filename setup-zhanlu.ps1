<#
.SYNOPSIS
    Safely installs or updates the portable AI collaboration module in a target project.
.DESCRIPTION
    Install mode copies only module.json portableFiles and creates fresh project files
    from templates. It aborts before writing if any target file already exists.

    Update mode refreshes an already installed module in place. It overwrites portable
    files only and never touches the active project layer:
    .agents/project.md, .agents/context-index.md and .agents/TODO.md.
    The active project layer is copied to .agents/.backup-<timestamp> first, because the
    installed module is deliberately kept out of the target repository's version control
    and therefore has no other safety net.

    Both modes keep the module out of the target repository by writing an exclusion block
    to .git/info/exclude. The target's own .gitignore is never created or modified, so the
    module never becomes visible in the target project's history. When the kit directory
    itself sits inside the target project - the usual result of cloning the module into the
    project it serves - that directory is excluded as well.
.PARAMETER TargetPath
    Root directory of the target project.
.PARAMETER Update
    Refresh an existing installation instead of creating a new one.
.PARAMETER RemoveStale
    Update mode only. Delete files that the previously installed manifest listed but the
    current manifest no longer contains. Without this switch such files are only reported.
.PARAMETER Uninstall
    Remove an installed module. Only files listed by the installed manifest are deleted;
    the active project layer, its backups, history and the data mount points are kept, and
    exclusion patterns stay in place for every path that still exists.
.PARAMETER RemoveProjectLayer
    Uninstall mode only. Also delete the three active project files and their
    .agents/.backup-* copies. Data under .agents/resources and .agents/reference-projects
    is never deleted.
.EXAMPLE
    .\setup-zhanlu.ps1 -TargetPath D:\work\my-firmware
.EXAMPLE
    .\setup-zhanlu.ps1 -TargetPath D:\work\my-firmware -Update -WhatIf
.EXAMPLE
    .\setup-zhanlu.ps1 -TargetPath D:\work\my-firmware -Uninstall -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetPath,

    [switch]$Update,

    [switch]$RemoveStale,

    [switch]$Uninstall,

    [switch]$RemoveProjectLayer
)

$ErrorActionPreference = 'Stop'
$sourceRoot = $PSScriptRoot
. (Join-Path $sourceRoot '.agents/lib/module-safety.ps1')
$manifestPath = Join-Path $sourceRoot '.agents\module.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json

if ($RemoveStale -and -not $Update) {
    throw '-RemoveStale is only valid together with -Update.'
}
if ($Uninstall -and $Update) {
    throw '-Uninstall cannot be combined with -Update.'
}
if ($RemoveProjectLayer -and -not $Uninstall) {
    throw '-RemoveProjectLayer is only valid together with -Uninstall.'
}

if (-not (Test-Path -LiteralPath $TargetPath -PathType Container)) {
    throw "Target project directory does not exist: $TargetPath"
}

$targetRoot = (Resolve-Path -LiteralPath $TargetPath).Path.TrimEnd('\', '/')
$resolvedSourceRoot = (Resolve-Path -LiteralPath $sourceRoot).Path.TrimEnd('\', '/')
if ($targetRoot -eq $resolvedSourceRoot) {
    throw 'The source kit and target project must be different directories.'
}

# Cloning the module into the project it will serve leaves the clone inside the target
# work tree, where the target repository would otherwise see it as an untracked embedded
# repository. Its location is derived from the script's own path rather than guessed, so
# it can be excluded alongside the files the installer writes. A kit that lives outside
# the target yields nothing here and needs no rule.
$sourceInsideTarget = ''
$targetRootWithSeparator = $targetRoot + [System.IO.Path]::DirectorySeparatorChar
if ($resolvedSourceRoot.StartsWith($targetRootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) {
    $sourceInsideTarget = $resolvedSourceRoot.Substring($targetRootWithSeparator.Length).Replace('\', '/') + '/'
}

$portableFiles = @(Get-ModulePortableFiles $manifest)
$packageOnlyFiles = @($manifest.packageOnlyFiles)
$invalidPackageOnlyFiles = @($packageOnlyFiles | Where-Object { $portableFiles -notcontains $_ })
if ($invalidPackageOnlyFiles.Count -gt 0) {
    throw "packageOnlyFiles must also exist in portableFiles:`n  $($invalidPackageOnlyFiles -join "`n  ")"
}
$installFiles = @(Get-ModuleInstallFiles $manifest)

$activeFiles = @(
    '.agents/project.md',
    '.agents/context-index.md',
    '.agents/TODO.md'
)
foreach ($relativePath in $portableFiles) {
    if ($activeFiles -contains $relativePath) {
        throw "portableFiles must not contain an active project file: $relativePath"
    }
    [void](Resolve-ModulePath $sourceRoot $relativePath)
}
# Validate all target components before the first backup, copy or directory creation.
foreach ($relativePath in @($installFiles) + $activeFiles) {
    [void](Resolve-ModulePath $targetRoot $relativePath)
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Editor settings are generated from templates the first time they are missing. They are
# never part of the conflict check and never overwritten, so a target that already has its
# own .vscode/settings.json keeps it and the install still succeeds.
$generateOnce = @(
    @{ Template = '.agents/templates/vscode-settings.json'; Destination = '.vscode/settings.json' },
    @{ Template = '.agents/templates/workspace.code-workspace'; Destination = (Split-Path -Leaf $targetRoot) + '.code-workspace' }
)

# Paths that must never be tracked by the target repository.
$moduleGitPaths = @(Get-ModuleGitPaths $manifest)
foreach ($entry in $generateOnce) {
    [void](Resolve-ModulePath $targetRoot $entry.Destination)
}

$missing = foreach ($relativePath in $portableFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot $relativePath) -PathType Leaf)) {
        $relativePath
    }
}
if ($missing) {
    throw "Source kit is missing files:`n  $($missing -join "`n  ")"
}

# Hashing uses .NET directly so that -WhatIf does not propagate into provider cmdlets
# and flood the update plan with unrelated "What if" lines.
function Get-FileSha256([string]$Path) {
    if (-not [System.IO.File]::Exists($Path)) {
        return $null
    }
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $stream = [System.IO.File]::OpenRead($Path)
        try {
            return [System.BitConverter]::ToString($sha256.ComputeHash($stream)).Replace('-', '')
        } finally {
            $stream.Dispose()
        }
    } finally {
        $sha256.Dispose()
    }
}

if ($Uninstall) {
    $targetManifestPath = Join-Path $targetRoot '.agents\module.json'
    if (-not (Test-Path -LiteralPath $targetManifestPath -PathType Leaf)) {
        throw "No installed module found at $targetRoot; nothing to uninstall."
    }
    $targetManifest = Get-Content -LiteralPath $targetManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($targetManifest.projectKind -eq 'kit-source') {
        throw "Target is a kit source, not an installed project: $targetRoot"
    }

    # Ownership comes from the installed manifest, so files added by the user are never
    # matched. Every path is validated before the first deletion.
    $removeFiles = @(Get-ModuleInstallFiles $targetManifest | Where-Object { $activeFiles -notcontains $_ })
    foreach ($relativePath in $removeFiles) {
        [void](Resolve-ModulePath $targetRoot $relativePath)
    }
    $removeFiles = @($removeFiles | Where-Object { Test-Path -LiteralPath (Join-Path $targetRoot $_) -PathType Leaf })

    # Editor settings are removed only while they still match the template they came from.
    $keptGenerated = @()
    foreach ($entry in $generateOnce) {
        $destination = Resolve-ModulePath $targetRoot $entry.Destination
        if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) { continue }
        $templatePath = Join-Path $targetRoot ($entry.Template.Replace('/', '\'))
        if ((Get-FileSha256 $templatePath) -and (Get-FileSha256 $destination) -eq (Get-FileSha256 $templatePath)) {
            $removeFiles += $entry.Destination
        } else {
            $keptGenerated += $entry.Destination
        }
    }

    $backupDirectories = @()
    if ($RemoveProjectLayer) {
        foreach ($relativePath in $activeFiles) {
            [void](Resolve-ModulePath $targetRoot $relativePath)
            if (Test-Path -LiteralPath (Join-Path $targetRoot $relativePath) -PathType Leaf) {
                $removeFiles += $relativePath
            }
        }
        $agentsDirectory = Join-Path $targetRoot '.agents'
        if (Test-Path -LiteralPath $agentsDirectory -PathType Container) {
            $backupDirectories = @(Get-ChildItem -LiteralPath $agentsDirectory -Directory -Force -Filter '.backup-*' |
                ForEach-Object { '.agents/' + $_.Name })
        }
        foreach ($relativePath in $backupDirectories) {
            [void](Resolve-ModulePath $targetRoot $relativePath)
        }
    }

    Write-Output "Uninstall plan for: $targetRoot"
    Write-Output "  installed: $($targetManifest.name) $($targetManifest.version) ($($targetManifest.coreVersion))"
    foreach ($relativePath in $removeFiles) { Write-Output "    [delete]    $relativePath" }
    foreach ($relativePath in $backupDirectories) { Write-Output "    [delete]    $relativePath/" }
    foreach ($relativePath in $keptGenerated) { Write-Output "    [keep]      $relativePath (differs from template)" }
    if (-not $RemoveProjectLayer) {
        foreach ($relativePath in $activeFiles) { Write-Output "    [keep]      $relativePath" }
        Write-Output '    [keep]      .agents/.backup-*'
    }
    Write-Output '    [keep]      .agents/resources/ and .agents/reference-projects/ contents'

    if (-not $PSCmdlet.ShouldProcess($targetRoot, "Uninstall $($targetManifest.name) $($targetManifest.version)")) {
        return
    }

    foreach ($relativePath in $backupDirectories) {
        Remove-Item -LiteralPath (Resolve-ModulePath $targetRoot $relativePath) -Recurse -Force
    }
    foreach ($relativePath in $removeFiles) {
        $filePath = Resolve-ModulePath $targetRoot $relativePath
        Remove-Item -LiteralPath $filePath -Force
        # Prune directories the removed file left empty, stopping at the target root.
        $directory = Split-Path -Parent $filePath
        while ($directory -and $directory.StartsWith($targetRootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) {
            [void](Resolve-ModulePath $targetRoot $directory.Substring($targetRootWithSeparator.Length))
            if (@(Get-ChildItem -LiteralPath $directory -Force).Count -gt 0) {
                break
            }
            $parent = Split-Path -Parent $directory
            Remove-Item -LiteralPath $directory -Force
            $directory = $parent
        }
    }

    # Keep each exclusion pattern while its path still exists, so retained project data and
    # evidence stay out of version control. Other installations' blocks are left untouched.
    $gitCommand = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCommand) {
        Push-Location -LiteralPath $targetRoot
        try {
            $previousErrorAction = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            try {
                $insideWorkTree = & $gitCommand.Source rev-parse --is-inside-work-tree 2>$null
            } finally {
                $ErrorActionPreference = $previousErrorAction
            }
            if ($LASTEXITCODE -eq 0 -and $insideWorkTree -eq 'true') {
                $gitCommonDir = (& $gitCommand.Source rev-parse --git-common-dir).Trim()
                if (-not [System.IO.Path]::IsPathRooted($gitCommonDir)) {
                    $gitCommonDir = Join-Path $targetRoot $gitCommonDir
                }
                $pathPrefix = (& $gitCommand.Source rev-parse --show-prefix)
                if ($null -eq $pathPrefix) { $pathPrefix = '' } else { $pathPrefix = $pathPrefix.Trim() }
                $scopeLabel = if ($pathPrefix) { $pathPrefix.TrimEnd('/') } else { '.' }
                $gitDir = (& $gitCommand.Source rev-parse --absolute-git-dir).Trim()
                if ([System.IO.Path]::GetFullPath($gitDir) -ne [System.IO.Path]::GetFullPath($gitCommonDir)) {
                    $scopeLabel = 'worktree:' + (Split-Path -Leaf $gitDir) + '/' + $scopeLabel
                }
                $excludeFile = Join-Path $gitCommonDir 'info\exclude'
                if (Test-Path -LiteralPath $excludeFile -PathType Leaf) {
                    $markerName = [string]$manifest.name
                    $beginMarker = "# >>> $markerName [$scopeLabel] >>>"
                    $endMarker = "# <<< $markerName [$scopeLabel] <<<"
                    $scopedPattern = '(?ms)^' + [regex]::Escape($beginMarker) + '\r?\n.*?^' +
                        [regex]::Escape($endMarker) + '(?:\r?\n|\z)'
                    $existing = [System.IO.File]::ReadAllText($excludeFile)
                    $ownedPrefix = '/' + (ConvertTo-GitIgnoreLiteralPath $pathPrefix)
                    $remaining = @()
                    foreach ($match in [regex]::Matches($existing, $scopedPattern)) {
                        foreach ($line in @($match.Value -split '\r?\n' | Where-Object { $_.StartsWith('/') })) {
                            $relative = $line
                            if ($relative.StartsWith($ownedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                                $relative = $relative.Substring($ownedPrefix.Length)
                            } else {
                                $relative = $relative.Substring(1)
                            }
                            $relative = [regex]::Replace($relative, '\\(.)', '$1').TrimEnd('/')
                            if ($relative -and (Test-Path -LiteralPath (Join-Path $targetRoot $relative))) {
                                $remaining += $line
                            }
                        }
                    }
                    $updated = [regex]::Replace($existing, $scopedPattern, '')
                    if ($remaining.Count -gt 0) {
                        if ($updated.Length -gt 0 -and -not $updated.EndsWith("`n")) { $updated += "`n" }
                        $updated += ((@($beginMarker) + ($remaining | Select-Object -Unique) + @($endMarker)) -join "`n") + "`n"
                    }
                    [System.IO.File]::WriteAllText($excludeFile, $updated, $utf8NoBom)
                    Write-Output "Exclusion block updated: $excludeFile ($($remaining.Count) pattern(s) kept for remaining paths)"
                }
            }
        } finally {
            Pop-Location
        }
    }

    Write-Output "Uninstall complete: $targetRoot"
    if (Test-Path -LiteralPath (Join-Path $targetRoot '.agents')) {
        Write-Output '.agents/ was kept because it still holds project data; it stays excluded from version control.'
    }
    return
}

$staleFiles = @()

if ($Update) {
    $targetManifestPath = Join-Path $targetRoot '.agents\module.json'
    if (-not (Test-Path -LiteralPath $targetManifestPath -PathType Leaf)) {
        throw "No installed module found at $targetRoot. Run without -Update to install."
    }
    $missingActive = foreach ($relativePath in $activeFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $targetRoot $relativePath) -PathType Leaf)) {
            $relativePath
        }
    }
    if ($missingActive) {
        throw "Installed module is incomplete; update aborted. Missing active project files:`n  $($missingActive -join "`n  ")"
    }

    $targetManifest = Get-Content -LiteralPath $targetManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $installedPortableFiles = @(Get-ModulePortableFiles $targetManifest)
    foreach ($relativePath in $installedPortableFiles) {
        [void](Resolve-ModulePath $targetRoot $relativePath)
    }
    $installedInstallFiles = @(Get-ModuleInstallFiles $targetManifest)
    $staleFiles = @($installedInstallFiles |
        Where-Object { $portableFiles -notcontains $_ } |
        Where-Object { $activeFiles -notcontains $_ } |
        Where-Object { Test-Path -LiteralPath (Join-Path $targetRoot $_) -PathType Leaf })

    $newFiles = @()
    $changedFiles = @()
    $unchangedFiles = @()
    foreach ($relativePath in $installFiles) {
        $destination = Join-Path $targetRoot $relativePath
        if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) {
            $newFiles += $relativePath
        } elseif ((Get-FileSha256 $destination) -ne (Get-FileSha256 (Join-Path $sourceRoot $relativePath))) {
            $changedFiles += $relativePath
        } else {
            $unchangedFiles += $relativePath
        }
    }

    Write-Output "Update plan for: $targetRoot"
    Write-Output "  installed: $($targetManifest.name) $($targetManifest.version) ($($targetManifest.coreVersion))"
    Write-Output "  incoming:  $($manifest.name) $($manifest.version) ($($manifest.coreVersion))"
    Write-Output "  new: $($newFiles.Count) / overwritten: $($changedFiles.Count) / unchanged: $($unchangedFiles.Count)"
    foreach ($relativePath in $newFiles) { Write-Output "    [new]       $relativePath" }
    foreach ($relativePath in $changedFiles) { Write-Output "    [overwrite] $relativePath" }
    Write-Output '  preserved (never written by -Update):'
    foreach ($relativePath in $activeFiles) { Write-Output "    [keep]      $relativePath" }
    if ($staleFiles.Count -gt 0) {
        $staleAction = if ($RemoveStale) { 'delete' } else { 'report only' }
        Write-Output "  stale files from the installed manifest ($staleAction):"
        foreach ($relativePath in $staleFiles) { Write-Output "    [stale]     $relativePath" }
        if (-not $RemoveStale) {
            Write-Output '  Re-run with -RemoveStale to delete them.'
        }
    }

    if (-not $PSCmdlet.ShouldProcess($targetRoot, "Update $($manifest.name) to $($manifest.version)")) {
        return
    }

    # The installed module is not in version control, so an update has no git safety net.
    $backupDirectory = Join-Path $targetRoot ('.agents\.backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null
    foreach ($relativePath in $activeFiles) {
        Copy-Item -LiteralPath (Join-Path $targetRoot $relativePath) `
            -Destination (Join-Path $backupDirectory (Split-Path -Leaf $relativePath)) -Force
    }
    Write-Output "Active project layer backed up to: $backupDirectory"
} else {
    $conflicts = foreach ($relativePath in @($installFiles) + $activeFiles) {
        if (Test-Path -LiteralPath (Join-Path $targetRoot $relativePath)) {
            $relativePath
        }
    }
    if ($conflicts) {
        throw "Target files already exist; nothing was written:`n  $($conflicts -join "`n  ")`nUse -Update to refresh an existing installation."
    }

    if (-not $PSCmdlet.ShouldProcess($targetRoot, "Install $($manifest.name) $($manifest.version)")) {
        return
    }
}

foreach ($relativePath in $installFiles) {
    $source = Resolve-ModulePath $sourceRoot $relativePath
    $destination = Resolve-ModulePath $targetRoot $relativePath
    $destinationDirectory = Split-Path -Parent $destination
    if (-not (Test-Path -LiteralPath $destinationDirectory)) {
        New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
    }
    Copy-Item -LiteralPath $source -Destination $destination -Force
}

if ($Update -and $RemoveStale) {
    foreach ($relativePath in $staleFiles) {
        $stalePath = Resolve-ModulePath $targetRoot $relativePath
        Remove-Item -LiteralPath $stalePath -Force
        # Prune directories the removed file left empty, stopping at the target root.
        $directory = Split-Path -Parent $stalePath
        while ($directory -and $directory.StartsWith($targetRootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) {
            $relativeDirectory = $directory.Substring($targetRootWithSeparator.Length)
            [void](Resolve-ModulePath $targetRoot $relativeDirectory)
            if (@(Get-ChildItem -LiteralPath $directory -Force).Count -gt 0) {
                break
            }
            $parent = Split-Path -Parent $directory
            Remove-Item -LiteralPath $directory -Force
            $directory = $parent
        }
    }
}

if (-not $Update) {
    $projectId = (Split-Path -Leaf $targetRoot).ToLowerInvariant() -replace '[^a-z0-9]+', '-'
    $projectId = $projectId.Trim('-')
    if ([string]::IsNullOrWhiteSpace($projectId)) {
        $projectId = 'firmware-project'
    }

    $validationCode = "PROJECT-$(([guid]::NewGuid().ToString('N').Substring(0, 8)).ToUpperInvariant())"
    $contextCode = "CONTEXT-$(([guid]::NewGuid().ToString('N').Substring(0, 8)).ToUpperInvariant())"
    $contextRevision = "$projectId-CONTEXT-v1"

    $projectTemplate = Get-Content -LiteralPath (Join-Path $targetRoot '.agents\templates\project.md') -Raw -Encoding UTF8
    $projectContent = $projectTemplate.Replace('__PROJECT_ID__', $projectId)
    $projectContent = $projectContent.Replace('__REPOSITORY_NAME__', (Split-Path -Leaf $targetRoot))
    $projectContent = $projectContent.Replace('__VALIDATION_CODE__', $validationCode)
    [System.IO.File]::WriteAllText((Join-Path $targetRoot '.agents\project.md'), $projectContent, $utf8NoBom)

    $contextTemplate = Get-Content -LiteralPath (Join-Path $targetRoot '.agents\templates\context-index.md') -Raw -Encoding UTF8
    $contextContent = $contextTemplate.Replace('__PROJECT_ID__', $projectId)
    $contextContent = $contextContent.Replace('__CONTEXT_REVISION__', $contextRevision)
    $contextContent = $contextContent.Replace('__CONTEXT_CODE__', $contextCode)
    [System.IO.File]::WriteAllText((Join-Path $targetRoot '.agents\context-index.md'), $contextContent, $utf8NoBom)

    $todoTemplate = Get-Content -LiteralPath (Join-Path $targetRoot '.agents\templates\TODO.md') -Raw -Encoding UTF8
    $todoContent = $todoTemplate.Replace('__PROJECT_ID__', $projectId)
    [System.IO.File]::WriteAllText((Join-Path $targetRoot '.agents\TODO.md'), $todoContent, $utf8NoBom)
}

# The installed copy is a firmware project, not the kit source. Patching the value
# textually keeps the manifest's original formatting and non-ASCII text readable.
$targetManifestFile = Join-Path $targetRoot '.agents\module.json'
$manifestText = [System.IO.File]::ReadAllText($targetManifestFile)
$patchedManifestText = [regex]::Replace($manifestText, '"projectKind"\s*:\s*"[^"]*"', '"projectKind": "firmware"')
if ($patchedManifestText -ne $manifestText) {
    [System.IO.File]::WriteAllText($targetManifestFile, $patchedManifestText, $utf8NoBom)
}

$generatedFiles = @()
foreach ($entry in $generateOnce) {
    $destination = Join-Path $targetRoot $entry.Destination
    if (Test-Path -LiteralPath $destination) {
        Write-Output "Editor settings already present, left untouched: $($entry.Destination)"
        continue
    }
    $destinationDirectory = Split-Path -Parent $destination
    if (-not (Test-Path -LiteralPath $destinationDirectory)) {
        New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
    }
    Copy-Item -LiteralPath (Join-Path $targetRoot $entry.Template) -Destination $destination -Force
    Write-Output "Editor settings created: $($entry.Destination)"
    $generatedFiles += $entry.Destination
}

$excludeEntries = @($moduleGitPaths) + @($generatedFiles)
if ($sourceInsideTarget) {
    $excludeEntries += $sourceInsideTarget
}
$gitCommand = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitCommand) {
    Write-Warning 'git was not found; the module was NOT excluded from version control.'
    Write-Output  'Add these lines to <target>/.git/info/exclude manually:'
    foreach ($entry in $excludeEntries) { Write-Output "  /$entry" }
} else {
    Push-Location -LiteralPath $targetRoot
    try {
        # Windows PowerShell turns a native command's redirected stderr into an ErrorRecord,
        # which is terminating while ErrorActionPreference is 'Stop'. Outside a repository
        # git writes to stderr by design, so the preference is relaxed for this probe only.
        $previousErrorAction = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $insideWorkTree = & $gitCommand.Source rev-parse --is-inside-work-tree 2>$null
        } finally {
            $ErrorActionPreference = $previousErrorAction
        }
        if ($LASTEXITCODE -ne 0 -or $insideWorkTree -ne 'true') {
            Write-Output 'Target is not a git repository; version-control exclusion skipped.'
        } else {
            $gitCommonDir = (& $gitCommand.Source rev-parse --git-common-dir).Trim()
            if (-not [System.IO.Path]::IsPathRooted($gitCommonDir)) {
                $gitCommonDir = Join-Path $targetRoot $gitCommonDir
            }
            $pathPrefix = (& $gitCommand.Source rev-parse --show-prefix)
            if ($null -eq $pathPrefix) { $pathPrefix = '' } else { $pathPrefix = $pathPrefix.Trim() }
            if ($pathPrefix) {
                Write-Warning "Target is a subdirectory of a repository; patterns are prefixed with $pathPrefix"
            }

            $excludeFile = Join-Path $gitCommonDir 'info\exclude'
            $excludeDirectory = Split-Path -Parent $excludeFile
            if (-not (Test-Path -LiteralPath $excludeDirectory)) {
                New-Item -ItemType Directory -Path $excludeDirectory -Force | Out-Null
            }

            # Markers follow module.json name, so renaming the module needs no script edit.
            $markerNames = @([string]$manifest.name)
            if ($manifest.PSObject.Properties['legacyMarkerNames']) {
                $markerNames += @($manifest.legacyMarkerNames | ForEach-Object { [string]$_ })
            }
            $scopeLabel = if ($pathPrefix) { $pathPrefix.TrimEnd('/') } else { '.' }
            $gitDir = (& $gitCommand.Source rev-parse --absolute-git-dir).Trim()
            if ($LASTEXITCODE -ne 0) { throw 'Unable to determine worktree Git directory.' }
            if ([System.IO.Path]::GetFullPath($gitDir) -ne [System.IO.Path]::GetFullPath($gitCommonDir)) {
                $scopeLabel = 'worktree:' + (Split-Path -Leaf $gitDir) + '/' + $scopeLabel
            }
            $beginMarker = "# >>> $($markerNames[0]) [$scopeLabel] >>>"
            $endMarker = "# <<< $($markerNames[0]) [$scopeLabel] <<<"
            $existing = if (Test-Path -LiteralPath $excludeFile) {
                [System.IO.File]::ReadAllText($excludeFile)
            } else {
                ''
            }
            # Rewrite only this installation's scoped blocks. Migrate its entries from
            # legacy unscoped blocks while keeping every other installation's entries.
            $preservedEntries = New-Object 'System.Collections.Generic.List[string]'
            $ownedPrefix = '/' + (ConvertTo-GitIgnoreLiteralPath $pathPrefix)
            foreach ($markerName in $markerNames) {
                $scopedPattern = '(?ms)^' + [regex]::Escape("# >>> $markerName [$scopeLabel] >>>") + '\r?\n.*?^' +
                    [regex]::Escape("# <<< $markerName [$scopeLabel] <<<") + '(?:\r?\n|\z)'
                foreach ($match in [regex]::Matches($existing, $scopedPattern)) {
                    foreach ($line in @($match.Value -split '\r?\n' | Where-Object { $_.StartsWith('/') })) {
                        $preservedEntries.Add($line)
                    }
                }
                $existing = [regex]::Replace($existing, $scopedPattern, '')
                $legacyPattern = '(?ms)^' + [regex]::Escape("# >>> $markerName >>>") + '\r?\n.*?^' +
                    [regex]::Escape("# <<< $markerName <<<") + '(?:\r?\n|\z)'
                $existing = [regex]::Replace($existing, $legacyPattern, {
                    param($legacyMatch)
                    $foreignLines = @()
                    foreach ($line in @($legacyMatch.Value -split '\r?\n' | Where-Object { $_.StartsWith('/') })) {
                        if ($line.StartsWith($ownedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                            $preservedEntries.Add($line)
                        } else {
                            $foreignLines += $line
                        }
                    }
                    if ($foreignLines.Count -gt 0) {
                        return (@("# >>> $markerName >>>") + $foreignLines + @("# <<< $markerName <<<") -join "`n") + "`n"
                    }
                    return ''
                })
            }
            # A legacy pattern can protect a file in another worktree, even if it is
            # absent here. Carry patterns forward instead of pruning by local existence.
            if ($existing.Length -gt 0 -and -not $existing.EndsWith("`n")) {
                $existing += "`n"
            }
            $patterns = @($excludeEntries | ForEach-Object { '/' + (ConvertTo-GitIgnoreLiteralPath ($pathPrefix + $_)) })
            $patterns += @($preservedEntries | Select-Object -Unique | Where-Object { $patterns -notcontains $_ })
            $blockLines = @($beginMarker) + $patterns + @($endMarker)
            [System.IO.File]::WriteAllText($excludeFile, $existing + ($blockLines -join "`n") + "`n", $utf8NoBom)
            Write-Output "Module excluded from version control via: $excludeFile"
            if ($sourceInsideTarget) {
                Write-Output "Module source directory is inside the target and was excluded too: /$pathPrefix$sourceInsideTarget"
            }
        }
    } finally {
        Pop-Location
    }
}

$verifyScript = Join-Path $targetRoot 'verify-zhanlu.ps1'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $verifyScript -RootPath $targetRoot
if ($LASTEXITCODE -ne 0) {
    $phase = if ($Update) { 'Module files were updated' } else { 'Module files were copied' }
    throw "$phase, but verification failed with exit code $LASTEXITCODE."
}

if ($Update) {
    Write-Output "Update complete: $targetRoot"
    Write-Output 'The active project layer was preserved; review .agents/TODO.md for work still in progress.'
} else {
    Write-Output "Install complete: $targetRoot"
    Write-Output 'Fill .agents/project.md, .agents/context-index.md, and .agents/TODO.md before firmware work.'
    Write-Output 'The module is excluded from version control, so .agents/ is not covered by git.'
    Write-Output 'Include it in your own backup, and avoid running "git clean -x" in this project.'
}
