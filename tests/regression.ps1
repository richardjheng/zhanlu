<#
.SYNOPSIS
    Runs isolated regression cases for module safety, Git protection and packaging.
#>
[CmdletBinding()]
param([string]$RootPath)

$ErrorActionPreference = 'Stop'
if (-not $RootPath) { $RootPath = Split-Path -Parent $PSScriptRoot }
$sourceRoot = (Resolve-Path -LiteralPath $RootPath).Path
. (Join-Path $sourceRoot '.agents/lib/module-safety.ps1')
$manifest = Get-Content -LiteralPath (Join-Path $sourceRoot '.agents/module.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$utf8 = New-Object System.Text.UTF8Encoding($false)
$scratchName = 'zhanlu-regression-' + [guid]::NewGuid().ToString('N')
$scratch = Join-Path ([System.IO.Path]::GetFullPath($env:TEMP)) $scratchName
New-Item -ItemType Directory -Path $scratch | Out-Null
$script:checks = 0
$script:links = @()

function Assert-Case([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "Regression failed: $Message`n$script:lastChildOutput" }
    $script:checks++
    Write-Output "  [PASS] $Message"
}

function Invoke-Child([string]$Script, [string[]]$Arguments = @()) {
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.FileName = (Get-Command powershell.exe).Source
    $nativeArguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Script) + $Arguments
    $process.StartInfo.Arguments = ($nativeArguments | ForEach-Object {
        # Windows command-line quoting, without invoking another shell.
        $quoted = [regex]::Replace($_, '(\\*)"', '$1$1\"')
        $quoted = [regex]::Replace($quoted, '(\\+)$', '$1$1')
        '"' + $quoted + '"'
    }) -join ' '
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true
    $process.StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $process.StartInfo.RedirectStandardInput = $true
    try {
        [void]$process.Start()
        $process.StandardInput.Close()
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(120000)) {
            $process.Kill()
            $process.WaitForExit()
            throw "Child script timed out: $Script"
        }
        $script:lastChildOutput = $stdout.Result + $stderr.Result
        return @{ Exit = $process.ExitCode; Output = $script:lastChildOutput }
    } finally {
        $process.Dispose()
    }
}

function Run-Git([string]$Directory, [string[]]$Arguments) {
    $messages = @(& git -C $Directory @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "git failed: $($Arguments -join ' ')`n$($messages -join "`n")" }
}

function Write-Manifest([string]$Target, $Value) {
    [System.IO.File]::WriteAllText((Join-Path $Target '.agents/module.json'), ($Value | ConvertTo-Json -Depth 30), $utf8)
}

function Read-Manifest([string]$Target) {
    return Get-Content -LiteralPath (Join-Path $Target '.agents/module.json') -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Snapshot-Files([string]$Target) {
    return @(Get-ChildItem -LiteralPath $Target -Recurse -File -Force | Sort-Object FullName | ForEach-Object {
        $_.FullName.Substring($Target.Length) + ':' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    })
}

function Assert-Ignored([string]$Repo, [string]$Path) {
    & git -C $Repo check-ignore -q -- $Path
    Assert-Case ($LASTEXITCODE -eq 0) "Git ignores $Path"
}

try {
    Write-Output "Regression scratch: $scratch"
    $installer = Join-Path $sourceRoot 'setup-zhanlu.ps1'
    $verifier = Join-Path $sourceRoot 'verify-zhanlu.ps1'
    foreach ($badPath in @('../sentinel.txt', 'C:\sentinel.txt', '\\server\share\sentinel.txt',
        './AGENTS.md', '.agents/../project.md', '.agents//module.json', 'file.txt.')) {
        $rejected = $false
        try { [void](Resolve-ModulePath $scratch $badPath) } catch { $rejected = $true }
        Assert-Case $rejected "Reject unsafe path $badPath"
    }
    $duplicateRejected = $false
    try { [void](Get-ModulePortableFiles ([pscustomobject]@{ portableFiles = @('AGENTS.md', 'agents.md') })) } catch { $duplicateRejected = $true }
    Assert-Case $duplicateRejected 'Reject case-insensitive duplicate paths'

    $repo = Join-Path $scratch 'repo'
    $alpha = Join-Path $repo 'alpha'
    $beta = Join-Path $repo 'beta'
    New-Item -ItemType Directory -Path $alpha, $beta -Force | Out-Null
    Run-Git $repo @('init', '--quiet')
    $emptyExclude = Join-Path $scratch 'empty-exclude'
    [System.IO.File]::WriteAllText($emptyExclude, '', $utf8)
    Run-Git $repo @('config', 'core.excludesFile', $emptyExclude)
    [System.IO.File]::WriteAllText((Join-Path $repo '.gitignore'), '*.user-cache', $utf8)
    [System.IO.File]::WriteAllText((Join-Path $beta 'README.md'), 'Existing product readme', $utf8)
    New-Item -ItemType Directory -Path (Join-Path $beta '.vscode') | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $beta '.vscode/settings.json'), '{"user.setting":true}', $utf8)
    $userReadmeHash = (Get-FileHash -LiteralPath (Join-Path $beta 'README.md')).Hash
    $userSettingsHash = (Get-FileHash -LiteralPath (Join-Path $beta '.vscode/settings.json')).Hash
    $gitignoreHash = (Get-FileHash -LiteralPath (Join-Path $repo '.gitignore')).Hash
    foreach ($target in @($alpha, $beta)) {
        $result = Invoke-Child $installer @('-TargetPath', $target)
        Assert-Case ($result.Exit -eq 0) "Install $(Split-Path -Leaf $target)"
    }
    Assert-Ignored $repo 'alpha/AGENTS.md'
    Assert-Ignored $repo 'alpha/alpha.code-workspace'
    Assert-Ignored $repo 'beta/update-zhanlu.ps1'
    Assert-Case ((Get-FileHash -LiteralPath (Join-Path $beta 'README.md')).Hash -eq $userReadmeHash) 'Preserve product README'
    Assert-Case ((Get-FileHash -LiteralPath (Join-Path $beta '.vscode/settings.json')).Hash -eq $userSettingsHash) 'Preserve existing editor settings'
    Assert-Case ((Get-FileHash -LiteralPath (Join-Path $repo '.gitignore')).Hash -eq $gitignoreHash) 'Preserve product gitignore'

    $excludeFile = Join-Path $repo '.git/info/exclude'
    $beforePreview = @(Snapshot-Files $beta)
    $excludeBefore = [System.IO.File]::ReadAllText($excludeFile)
    $result = Invoke-Child $installer @('-TargetPath', $beta, '-Update', '-WhatIf')
    Assert-Case ($result.Exit -eq 0) 'Update preview succeeds'
    Assert-Case (-not (Compare-Object $beforePreview @(Snapshot-Files $beta))) 'Update preview writes no target files'
    Assert-Case ([System.IO.File]::ReadAllText($excludeFile) -eq $excludeBefore) 'Update preview leaves exclusion file unchanged'

    # The old manifest is untrusted input: reject it before even creating a backup.
    $sentinel = Join-Path $repo 'sentinel.txt'
    [System.IO.File]::WriteAllText($sentinel, 'Disposable outside-target sentinel', $utf8)
    foreach ($badPath in @('../sentinel.txt', $sentinel)) {
        $oldManifest = Read-Manifest $beta
        $oldManifest.portableFiles += $badPath
        Write-Manifest $beta $oldManifest
        $beforeRejected = @(Snapshot-Files $beta)
        $sentinelHash = (Get-FileHash -LiteralPath $sentinel).Hash
        $result = Invoke-Child $installer @('-TargetPath', $beta, '-Update', '-RemoveStale')
        Assert-Case ($result.Exit -ne 0 -and $result.Output -match 'safe relative') "Reject installed manifest path $badPath"
        Assert-Case (-not (Compare-Object $beforeRejected @(Snapshot-Files $beta))) 'Rejected update writes no files or backups'
        Assert-Case ((Get-FileHash -LiteralPath $sentinel).Hash -eq $sentinelHash) 'Outside-target sentinel is unchanged'
        $oldManifest.portableFiles = @($oldManifest.portableFiles | Where-Object { $_ -ne $badPath })
        Write-Manifest $beta $oldManifest
    }

    # A safe-looking relative path must not escape through a junction.
    $victim = Join-Path $scratch 'junction-victim'
    New-Item -ItemType Directory -Path $victim | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $victim 'sentinel.txt'), 'Junction sentinel', $utf8)
    $junction = Join-Path $beta 'linked'
    New-Item -ItemType Junction -Path $junction -Target $victim | Out-Null
    $script:links += $junction
    $oldManifest = Read-Manifest $beta
    $oldManifest.portableFiles += 'linked/sentinel.txt'
    Write-Manifest $beta $oldManifest
    $result = Invoke-Child $installer @('-TargetPath', $beta, '-Update', '-RemoveStale')
    Assert-Case ($result.Exit -ne 0 -and $result.Output -match 'reparse point') 'Reject stale path through a junction'
    Assert-Case (Test-Path -LiteralPath (Join-Path $victim 'sentinel.txt')) 'Junction target is preserved'
    $oldManifest.portableFiles = @($oldManifest.portableFiles | Where-Object { $_ -ne 'linked/sentinel.txt' })
    Write-Manifest $beta $oldManifest
    [System.IO.Directory]::Delete($junction)
    $script:links = @()

    # Migrate both old module names and the unscoped marker layout.
    $legacyExclude = [System.IO.File]::ReadAllText($excludeFile).Replace('# >>> zhanlu [beta] >>>', '# >>> embedded-firmware-ai-collaboration-kit >>>').Replace('# <<< zhanlu [beta] <<<', '# <<< embedded-firmware-ai-collaboration-kit <<<')
    $legacyExclude = $legacyExclude.Replace('# <<< embedded-firmware-ai-collaboration-kit <<<', "/alpha/AGENTS.md`n# <<< embedded-firmware-ai-collaboration-kit <<<")
    [System.IO.File]::WriteAllText($excludeFile, $legacyExclude, $utf8)
    $oldManifest = Read-Manifest $beta
    $oldManifest.version = '4.8.1'
    $oldManifest.portableFiles = @($oldManifest.portableFiles | Where-Object { $_ -ne '.agents/lib/module-safety.ps1' })
    Write-Manifest $beta $oldManifest
    $activeFiles = @('.agents/project.md', '.agents/context-index.md', '.agents/TODO.md')
    $activeHashes = @($activeFiles | ForEach-Object { (Get-FileHash -LiteralPath (Join-Path $beta $_)).Hash })
    $result = Invoke-Child $installer @('-TargetPath', $beta, '-Update')
    Assert-Case ($result.Exit -eq 0) 'Upgrade legacy metadata'
    $afterHashes = @($activeFiles | ForEach-Object { (Get-FileHash -LiteralPath (Join-Path $beta $_)).Hash })
    Assert-Case (-not (Compare-Object $activeHashes $afterHashes)) 'Upgrade preserves active project hashes'
    Assert-Ignored $repo 'alpha/AGENTS.md'
    Assert-Ignored $repo 'beta/beta.code-workspace'
    $excludeAfterMigration = [System.IO.File]::ReadAllText($excludeFile)
    $result = Invoke-Child $installer @('-TargetPath', $beta, '-Update')
    Assert-Case ($result.Exit -eq 0) 'Repeated update succeeds'
    Assert-Case ([System.IO.File]::ReadAllText($excludeFile) -eq $excludeAfterMigration) 'Scoped marker migration is idempotent'

    # Delete a legitimate retired file, and prune only directories within the target.
    $retired = Join-Path $beta '.agents/retired/retired.ps1'
    New-Item -ItemType Directory -Path (Split-Path -Parent $retired) | Out-Null
    [System.IO.File]::WriteAllText($retired, '# Disposable retired module file', $utf8)
    $oldManifest = Read-Manifest $beta
    $oldManifest.portableFiles += '.agents/retired/retired.ps1'
    Write-Manifest $beta $oldManifest
    $result = Invoke-Child $installer @('-TargetPath', $beta, '-Update', '-RemoveStale')
    Assert-Case ($result.Exit -eq 0 -and -not (Test-Path -LiteralPath (Split-Path -Parent $retired))) 'Remove a valid stale file and its empty target directory'
    Assert-Case (Test-Path -LiteralPath $sentinel) 'Valid stale cleanup preserves outside files'

    foreach ($maintenanceFile in @('clean-backups.ps1', 'update-zhanlu.ps1')) {
        Run-Git $beta @('add', '-f', '--', $maintenanceFile)
        $result = Invoke-Child $verifier @('-RootPath', $beta)
        Assert-Case ($result.Exit -ne 0 -and $result.Output -match 'tracked by this repository') "Detect tracked $maintenanceFile"
        Run-Git $beta @('rm', '--cached', '--', $maintenanceFile)
    }
    $excludeBackup = [System.IO.File]::ReadAllText($excludeFile)
    [System.IO.File]::WriteAllText($excludeFile, $excludeBackup.Replace("/beta/update-zhanlu.ps1`n", ''), $utf8)
    $result = Invoke-Child $verifier @('-RootPath', $beta)
    Assert-Case ($result.Exit -ne 0 -and $result.Output -match 'not ignored') 'Detect missing ignore protection'
    [System.IO.File]::WriteAllText($excludeFile, $excludeBackup, $utf8)
    $result = Invoke-Child $verifier @('-RootPath', $beta)
    Assert-Case ($result.Exit -eq 0) 'Restored ignore protection passes verification'

    # Exercise an incoming manifest without changing the real source tree.
    $fixture = Join-Path $scratch 'fixture-kit'
    foreach ($file in @($manifest.portableFiles) + @('.agents/project.md', '.agents/context-index.md', '.agents/TODO.md')) {
        $destination = Join-Path $fixture $file
        New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $sourceRoot $file) -Destination $destination
    }
    $emptyTarget = Join-Path $scratch 'empty-target'
    New-Item -ItemType Directory -Path $emptyTarget | Out-Null
    $fixtureManifest = Read-Manifest $fixture
    foreach ($badPath in @('../sentinel.txt', '.agents/project.md')) {
        $fixtureManifest.portableFiles += $badPath
        Write-Manifest $fixture $fixtureManifest
        $result = Invoke-Child (Join-Path $fixture 'setup-zhanlu.ps1') @('-TargetPath', $emptyTarget)
        Assert-Case ($result.Exit -ne 0 -and @(Get-ChildItem -LiteralPath $emptyTarget -Force).Count -eq 0) "Reject incoming $badPath before writing"
        $fixtureManifest.portableFiles = @($fixtureManifest.portableFiles | Where-Object { $_ -ne $badPath })
        Write-Manifest $fixture $fixtureManifest
    }
    $fixtureCorePath = Join-Path $fixture 'AGENTS.md'
    $fixtureCore = [System.IO.File]::ReadAllText($fixtureCorePath)
    [System.IO.File]::WriteAllText($fixtureCorePath, ("Local tool: C:/local/tool.py`n" + $fixtureCore), $utf8)
    $result = Invoke-Child $verifier @('-RootPath', $fixture, '-PackageSource')
    Assert-Case ($result.Exit -ne 0 -and $result.Output -match 'machine-specific') 'Reject local drive paths in portable core'
    [System.IO.File]::WriteAllText($fixtureCorePath, ($fixtureCore + "`n## Extra section`nUnexpected tail`n"), $utf8)
    $result = Invoke-Child $verifier @('-RootPath', $fixture, '-PackageSource')
    Assert-Case ($result.Exit -ne 0 -and $result.Output -match 'sentinel section') 'Reject content after core sentinel section'
    [System.IO.File]::WriteAllText($fixtureCorePath, $fixtureCore, $utf8)

    $special = Join-Path $repo 'space [board]'
    New-Item -ItemType Directory -Path $special | Out-Null
    $result = Invoke-Child $installer @('-TargetPath', $special)
    Assert-Case ($result.Exit -eq 0) 'Install target with Git pattern characters'
    Assert-Ignored $repo 'space [board]/AGENTS.md'
    Assert-Ignored $repo 'alpha/AGENTS.md'

    # Linked worktrees share info/exclude, but need independent installation markers.
    Run-Git $repo @('add', '--', '.gitignore')
    Run-Git $repo @('-c', 'user.name=ZhanluRegression', '-c', 'user.email=regression@example.invalid',
        '-c', 'commit.gpgsign=false', 'commit', '--quiet', '-m', 'Initialize disposable regression fixture')
    $linkedTree = Join-Path $scratch 'linked-tree'
    Run-Git $repo @('worktree', 'add', '--quiet', '--detach', $linkedTree)
    $result = Invoke-Child $installer @('-TargetPath', $repo)
    Assert-Case ($result.Exit -eq 0) 'Install at the main worktree root'
    $result = Invoke-Child $installer @('-TargetPath', $linkedTree)
    Assert-Case ($result.Exit -eq 0) 'Install at a linked worktree root'
    Assert-Ignored $repo 'repo.code-workspace'
    Assert-Ignored $linkedTree 'linked-tree.code-workspace'
    $result = Invoke-Child $installer @('-TargetPath', $linkedTree, '-Update')
    Assert-Case ($result.Exit -eq 0) 'Update linked worktree independently'
    Assert-Ignored $repo 'repo.code-workspace'
    Assert-Ignored $repo 'alpha/alpha.code-workspace'

    # If the local release tag exists, exercise the real prior installer and manifest.
    $releaseTag = @(& git -C $sourceRoot tag --list v4.8.1)
    if ($LASTEXITCODE -eq 0 -and $releaseTag -contains 'v4.8.1') {
        $oldZip = Join-Path $scratch 'legacy-source.zip'
        Run-Git $sourceRoot @('archive', '--format=zip', '--output', $oldZip, 'v4.8.1')
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $oldSource = Join-Path $scratch 'legacy-source'
        [System.IO.Compression.ZipFile]::ExtractToDirectory($oldZip, $oldSource)
        $oldTarget = Join-Path $scratch 'legacy-target'
        New-Item -ItemType Directory -Path $oldTarget | Out-Null
        Run-Git $oldTarget @('init', '--quiet')
        Run-Git $oldTarget @('config', 'core.excludesFile', $emptyExclude)
        $result = Invoke-Child (Join-Path $oldSource 'setup-zhanlu.ps1') @('-TargetPath', $oldTarget)
        Assert-Case ($result.Exit -eq 0 -and (Read-Manifest $oldTarget).version -eq '4.8.1') 'Install actual v4.8.1 release source'
        $oldActiveHashes = @($activeFiles | ForEach-Object { (Get-FileHash -LiteralPath (Join-Path $oldTarget $_)).Hash })
        $result = Invoke-Child $installer @('-TargetPath', $oldTarget, '-Update')
        Assert-Case ($result.Exit -eq 0 -and (Read-Manifest $oldTarget).version -eq $manifest.version) 'Upgrade actual v4.8.1 installation'
        $oldActiveAfter = @($activeFiles | ForEach-Object { (Get-FileHash -LiteralPath (Join-Path $oldTarget $_)).Hash })
        Assert-Case (-not (Compare-Object $oldActiveHashes $oldActiveAfter)) 'Actual release upgrade preserves active data'
        Assert-Ignored $oldTarget 'legacy-target.code-workspace'
    } else {
        Write-Output '  [SKIP] Actual release upgrade: local v4.8.1 tag is unavailable.'
    }

    $packageDir = Join-Path $scratch 'package'
    $result = Invoke-Child (Join-Path $sourceRoot 'pack.ps1') @('-OutDir', $packageDir)
    Assert-Case ($result.Exit -eq 0) 'Build isolated package'
    $sevenZip = @('C:\Program Files\7-Zip\7z.exe', 'C:\Program Files (x86)\7-Zip\7z.exe') |
        Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $sevenZip) { $sevenZip = (Get-Command 7z.exe).Source }
    $unpacked = Join-Path $scratch 'unpacked'
    & $sevenZip x (Join-Path $packageDir $manifest.archiveName) "-o$unpacked" -y | Out-Null
    Assert-Case ($LASTEXITCODE -eq 0) 'Extract package'
    $unpackedFiles = @(Get-ChildItem -LiteralPath $unpacked -Recurse -File -Force -Name | ForEach-Object { $_.Replace('\', '/') })
    Assert-Case (-not (Compare-Object @($manifest.portableFiles) $unpackedFiles)) 'Archive contains exactly the portable whitelist'
    Assert-Case (-not (Test-Path -LiteralPath (Join-Path $unpacked '.agents/project.md'))) 'Archive excludes active project data'
    $archiveCore = [System.IO.File]::ReadAllText((Join-Path $unpacked 'AGENTS.md'))
    Assert-Case ($archiveCore -notmatch '(?i)\b[A-Z]:[\\/]') 'Archive core contains no local drive paths'
    Assert-Case ($archiveCore -match 'sentinel[^\r\n]*\s*\z') 'Archive core ends with sentinel'
    $internalDoc = [System.IO.File]::ReadAllText((Join-Path $unpacked '.agents/README.md'))
    # Assemble the former Chinese sentence using code points to keep this script ASCII.
    $obsolete = -join @([char]0x5C08,[char]0x6848,[char]0x5C64,[char]0x8CC7,[char]0x6599,[char]0x53EF,[char]0x63D0,[char]0x4EA4)
    Assert-Case (-not $internalDoc.Contains($obsolete)) 'Remove contradictory project-data commit guidance'
    $packageTarget = Join-Path $repo 'package-target'
    New-Item -ItemType Directory -Path $packageTarget | Out-Null
    $result = Invoke-Child (Join-Path $unpacked 'setup-zhanlu.ps1') @('-TargetPath', $packageTarget)
    Assert-Case ($result.Exit -eq 0) 'Install from extracted package'
    Assert-Ignored $repo 'alpha/AGENTS.md'
    Assert-Ignored $repo 'beta/update-zhanlu.ps1'

    # Uninstall keeps the project layer and data protected, and leaves other installs alone.
    $uninstallRepo = Join-Path $scratch 'uninstall-repo'
    $gamma = Join-Path $uninstallRepo 'gamma'
    $delta = Join-Path $uninstallRepo 'delta'
    New-Item -ItemType Directory -Path $gamma, $delta -Force | Out-Null
    Run-Git $uninstallRepo @('init', '--quiet')
    Run-Git $uninstallRepo @('config', 'core.excludesFile', $emptyExclude)
    [System.IO.File]::WriteAllText((Join-Path $gamma 'main.c'), 'int main(void) { return 0; }', $utf8)
    foreach ($target in @($gamma, $delta)) {
        $result = Invoke-Child $installer @('-TargetPath', $target)
        Assert-Case ($result.Exit -eq 0) "Install $(Split-Path -Leaf $target) for uninstall"
    }
    $evidence = Join-Path $gamma '.agents/resources/evidence.txt'
    [System.IO.File]::WriteAllText($evidence, 'private evidence', $utf8)
    [System.IO.File]::WriteAllText((Join-Path $gamma '.vscode/settings.json'), '{"edited":true}', $utf8)
    $uninstallExclude = Join-Path $uninstallRepo '.git/info/exclude'
    $beforeUninstall = @(Snapshot-Files $gamma)
    $excludeBeforeUninstall = [System.IO.File]::ReadAllText($uninstallExclude)
    $result = Invoke-Child $installer @('-TargetPath', $gamma, '-Uninstall', '-WhatIf')
    Assert-Case ($result.Exit -eq 0) 'Uninstall preview succeeds'
    Assert-Case (-not (Compare-Object $beforeUninstall @(Snapshot-Files $gamma))) 'Uninstall preview writes no target files'
    Assert-Case ([System.IO.File]::ReadAllText($uninstallExclude) -eq $excludeBeforeUninstall) 'Uninstall preview leaves exclusion file unchanged'
    $activeBefore = @('project.md', 'context-index.md', 'TODO.md' | ForEach-Object { (Get-FileHash -LiteralPath (Join-Path $gamma ".agents/$_")).Hash })
    $result = Invoke-Child $installer @('-TargetPath', $gamma, '-Uninstall')
    Assert-Case ($result.Exit -eq 0) 'Uninstall keeps project layer by default'
    Assert-Case (-not (Test-Path -LiteralPath (Join-Path $gamma 'AGENTS.md'))) 'Uninstall removes module core'
    Assert-Case (-not (Test-Path -LiteralPath (Join-Path $gamma '.claude'))) 'Uninstall removes Claude skill mounts'
    Assert-Case (-not (Test-Path -LiteralPath (Join-Path $gamma '.agents/module.json'))) 'Uninstall removes installed manifest'
    $activeAfter = @('project.md', 'context-index.md', 'TODO.md' | ForEach-Object { (Get-FileHash -LiteralPath (Join-Path $gamma ".agents/$_")).Hash })
    Assert-Case (-not (Compare-Object $activeBefore $activeAfter)) 'Uninstall preserves active project hashes'
    Assert-Case (Test-Path -LiteralPath $evidence) 'Uninstall preserves resource data'
    Assert-Case (Test-Path -LiteralPath (Join-Path $gamma '.vscode/settings.json')) 'Uninstall keeps edited editor settings'
    Assert-Case (-not (Test-Path -LiteralPath (Join-Path $gamma 'gamma.code-workspace'))) 'Uninstall removes unmodified workspace file'
    Assert-Case (Test-Path -LiteralPath (Join-Path $gamma 'main.c')) 'Uninstall preserves product source'
    Assert-Ignored $uninstallRepo 'gamma/.agents/resources/evidence.txt'
    Assert-Ignored $uninstallRepo 'gamma/.vscode/settings.json'
    Assert-Ignored $uninstallRepo 'delta/AGENTS.md'
    $excludeAfter = [System.IO.File]::ReadAllText($uninstallExclude)
    Assert-Case (-not $excludeAfter.Contains('/gamma/AGENTS.md')) 'Uninstall drops patterns for removed files'
    $result = Invoke-Child $installer @('-TargetPath', $delta, '-Uninstall', '-RemoveProjectLayer')
    Assert-Case ($result.Exit -eq 0) 'Uninstall with project layer removal'
    Assert-Case (-not (Test-Path -LiteralPath (Join-Path $delta '.agents'))) 'Full uninstall leaves no empty .agents'
    Assert-Case (-not (Test-Path -LiteralPath (Join-Path $delta '.vscode'))) 'Full uninstall removes unmodified editor settings'
    Assert-Case (-not ([System.IO.File]::ReadAllText($uninstallExclude)).Contains('[delta]')) 'Full uninstall removes its exclusion block'
    Assert-Ignored $uninstallRepo 'gamma/.agents/resources/evidence.txt'
    $result = Invoke-Child $installer @('-TargetPath', $gamma, '-Uninstall')
    Assert-Case ($result.Exit -ne 0 -and $result.Output -match 'No installed module') 'Reject uninstall without installed manifest'
    $result = Invoke-Child $installer @('-TargetPath', $delta, '-Uninstall', '-Update')
    Assert-Case ($result.Exit -ne 0) 'Reject uninstall combined with update'
    Write-Output "Regression passed: $script:checks checks."
} finally {
    $resolvedScratch = [System.IO.Path]::GetFullPath($scratch)
    $tempPrefix = [System.IO.Path]::GetFullPath($env:TEMP).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    if (-not $resolvedScratch.StartsWith($tempPrefix, [System.StringComparison]::OrdinalIgnoreCase) -or
        (Split-Path -Leaf $resolvedScratch) -ne $scratchName) {
        throw 'Refusing cleanup outside the verified scratch directory.'
    }
    foreach ($link in $script:links) {
        if (-not [System.IO.Path]::GetFullPath($link).StartsWith($resolvedScratch + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
            throw 'Refusing junction cleanup outside the scratch directory.'
        }
        if (Test-Path -LiteralPath $link) { [System.IO.Directory]::Delete($link) }
    }
    $remainingLinks = @(Get-ChildItem -LiteralPath $resolvedScratch -Recurse -Force | Where-Object {
        $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint
    })
    if ($remainingLinks.Count -gt 0) { throw 'Refusing recursive cleanup while scratch contains reparse points.' }
    Remove-Item -LiteralPath $resolvedScratch -Recurse -Force
}
