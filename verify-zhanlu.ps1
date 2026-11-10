<#
.SYNOPSIS
    Validates module structure, entry files, skills, and active project documents.
#>
[CmdletBinding()]
param(
    [string]$RootPath,
    [switch]$PackageSource
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = $PSScriptRoot
}
$root = (Resolve-Path -LiteralPath $RootPath).Path
$errors = New-Object System.Collections.Generic.List[string]
$safetyScript = Join-Path $PSScriptRoot '.agents/lib/module-safety.ps1'
if (-not (Test-Path -LiteralPath $safetyScript -PathType Leaf)) {
    Write-Output '  [FAIL] Missing shared checks: .agents/lib/module-safety.ps1'
    exit 1
}
. $safetyScript

function Add-ValidationError([string]$Message) {
    $script:errors.Add($Message)
}

function Require-File([string]$RelativePath) {
    try {
        $path = Resolve-ModulePath $root $RelativePath
    } catch {
        Add-ValidationError $_.Exception.Message
        return $false
    }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-ValidationError "Missing file: $RelativePath"
        return $false
    }
    return $true
}

function Find-TemplateToken([string]$Content, [string[]]$Tokens) {
    $alternation = ($Tokens | ForEach-Object { [regex]::Escape($_) }) -join '|'
    # Only a whole Markdown field value is an unfilled template placeholder.
    # A prose mention of the token or a firmware identifier is valid project data.
    $pattern = '(?m)^\s*-\s*[^:\r\n\uFF1A]+[:\uFF1A]\s*`?(?<token>' + $alternation + ')`?\s*$'
    $match = [regex]::Match($Content, $pattern)
    if ($match.Success) {
        return $match.Groups['token'].Value
    }
    return $null
}

function Test-PatternFieldValue($Field, [string]$Value) {
    if (-not $Field -or [string]::IsNullOrWhiteSpace([string]$Field.pattern)) {
        return $false
    }
    if (-not [regex]::IsMatch($Value, [string]$Field.pattern)) {
        return $false
    }
    if ($Field.multiple -eq $true) {
        $separator = [string]$Field.separator
        if ([string]::IsNullOrEmpty($separator)) {
            return $false
        }
        $items = @($Value -split [regex]::Escape($separator))
        if ($items.Count -eq 0 -or @($items | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -gt 0) {
            return $false
        }
        if ($Field.uniqueItems -eq $true -and @($items | Select-Object -Unique).Count -ne $items.Count) {
            return $false
        }
    }
    return $true
}

$manifestRelativePath = '.agents/module.json'
if (-not (Require-File $manifestRelativePath)) {
    $errors | ForEach-Object { Write-Output "  [FAIL] $_" }
    exit 1
}

try {
    $manifest = Get-Content -LiteralPath (Join-Path $root $manifestRelativePath) -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    Add-ValidationError "module.json parse error: $($_.Exception.Message)"
}

if ($manifest) {
    if ([string]$manifest.releaseRepository -notmatch '^[^/\s]+/[^/\s]+$') {
        Add-ValidationError 'module.json releaseRepository is missing or invalid (expected owner/repo).'
    }
    try {
        $portableFiles = @(Get-ModulePortableFiles $manifest)
        $installFiles = @(Get-ModuleInstallFiles $manifest)
        foreach ($relativePath in $portableFiles) {
            if ($relativePath -in @('.agents/project.md', '.agents/context-index.md', '.agents/TODO.md')) {
                throw "portableFiles must not contain an active project file: $relativePath"
            }
        }
    } catch {
        Add-ValidationError $_.Exception.Message
    }
    foreach ($relativePath in @($manifest.requiredSessionFiles)) {
        [void](Require-File $relativePath)
    }

    $uniquePortableFiles = @($manifest.portableFiles | Select-Object -Unique)
    if ($uniquePortableFiles.Count -ne @($manifest.portableFiles).Count) {
        Add-ValidationError 'module.json portableFiles contains duplicate entries.'
    }

    $packageOnlyFiles = @($manifest.packageOnlyFiles)
    $uniquePackageOnlyFiles = @($packageOnlyFiles | Select-Object -Unique)
    if ($uniquePackageOnlyFiles.Count -ne $packageOnlyFiles.Count) {
        Add-ValidationError 'module.json packageOnlyFiles contains duplicate entries.'
    }
    foreach ($relativePath in $packageOnlyFiles) {
        if (@($manifest.portableFiles) -notcontains $relativePath) {
            Add-ValidationError "packageOnlyFiles entry is not in portableFiles: $relativePath"
        }
    }

    # Keep this script ASCII-compatible because Windows PowerShell 5.1 reads UTF-8
    # source files without a BOM through the active ANSI code page.
    $targetChipFieldName = -join @([char]0x76EE, [char]0x6A19, [char]0x6676, [char]0x7247)
    $targetChipSeparator = [string][char]0xFF0C
    $targetChipField = $manifest.projectSchema.fields.PSObject.Properties[$targetChipFieldName].Value
    if (-not $targetChipField) {
        Add-ValidationError 'projectSchema is missing the target-chip field.'
    } else {
        if ($targetChipField.type -ne 'pattern' -or
            $targetChipField.multiple -ne $true -or
            ([string]$targetChipField.separator) -ne $targetChipSeparator -or
            $targetChipField.uniqueItems -ne $true) {
            Add-ValidationError 'projectSchema target-chip field must be a unique multi-value pattern with the declared separator.'
        }

        $targetChipCases = @(
            @{ Value = 'IT51526'; Expected = $true; Name = 'single chip' },
            @{ Value = ('IT51526' + $targetChipSeparator + 'IT8298'); Expected = $true; Name = 'multiple chips' },
            @{ Value = 'IT51526, IT8298'; Expected = $false; Name = 'ASCII comma separator' },
            @{ Value = ('IT51526' + [char]0x3001 + 'IT8298'); Expected = $false; Name = 'ideographic comma separator' },
            @{ Value = ('IT51526' + $targetChipSeparator + 'STM32H743ZI'); Expected = $false; Name = 'invalid model' },
            @{ Value = ('IT51526' + $targetChipSeparator + 'IT51526'); Expected = $false; Name = 'duplicate model' }
        )
        foreach ($case in $targetChipCases) {
            $actual = Test-PatternFieldValue $targetChipField $case.Value
            if ($actual -ne $case.Expected) {
                Add-ValidationError "projectSchema target-chip regression failed: $($case.Name) ($($case.Value))"
            }
        }
    }

    $filesToRequire = if ($PackageSource) {
        @($manifest.portableFiles)
    } else {
        @($manifest.portableFiles | Where-Object { $packageOnlyFiles -notcontains $_ })
    }
    foreach ($relativePath in $filesToRequire) {
        [void](Require-File $relativePath)
    }

    if (Require-File 'AGENTS.md') {
        $core = Get-Content -LiteralPath (Join-Path $root 'AGENTS.md') -Raw -Encoding UTF8
        if ($core -notmatch [regex]::Escape([string]$manifest.coreVersion)) {
            Add-ValidationError "AGENTS.md does not contain coreVersion: $($manifest.coreVersion)"
        }
        if ($core -match '(?i)\b[A-Z]:[\\/]') {
            Add-ValidationError 'AGENTS.md must not contain machine-specific drive paths.'
        }
        $coreSections = [regex]::Matches($core, '(?m)^##[ \t]+[^\r\n]+')
        if ($coreSections.Count -eq 0 -or
            $core.Substring($coreSections[$coreSections.Count - 1].Index) -notmatch [regex]::Escape([string]$manifest.coreVersion) -or
            $core -notmatch 'sentinel[^\r\n]*\s*\z') {
            Add-ValidationError 'AGENTS.md must end with the core-version sentinel section.'
        }
    }

    $expectedImports = @(
        '@AGENTS.md',
        '@.agents/module.json',
        '@.agents/project.md',
        '@.agents/context-index.md'
    )
    foreach ($entryFile in @('CLAUDE.md', 'GEMINI.md')) {
        if (Require-File $entryFile) {
            $entryContent = Get-Content -LiteralPath (Join-Path $root $entryFile) -Raw -Encoding UTF8
            foreach ($import in $expectedImports) {
                if ($entryContent -notmatch [regex]::Escape($import)) {
                    Add-ValidationError "$entryFile is missing shared-source reference: $import"
                }
            }
            if ($entryFile -eq 'CLAUDE.md' -and $entryContent -match '(?m)^\s*@\.agents/TODO\.md\s*$') {
                Add-ValidationError 'CLAUDE.md must not eagerly import the full TODO.md history.'
            }
            if ($entryFile -eq 'GEMINI.md' -and $entryContent -notmatch [regex]::Escape('@.agents/TODO.md')) {
                Add-ValidationError 'GEMINI.md is missing the TODO.md file reference.'
            }
        }
    }

    $antigravityRule = '.agents/rules/project-context.md'
    if (Require-File $antigravityRule) {
        $ruleContent = Get-Content -LiteralPath (Join-Path $root $antigravityRule) -Raw -Encoding UTF8
        if ($ruleContent -notmatch '(?s)\A---\r?\ntrigger:[ \t]*always_on[ \t]*\r?\n.*?\r?\n---(?:\r?\n|\z)') {
            Add-ValidationError "$antigravityRule must declare an always_on YAML frontmatter trigger."
        }
        $expectedRuleImports = @(
            '@../../AGENTS.md',
            '@../module.json',
            '@../project.md',
            '@../context-index.md',
            '@../TODO.md'
        )
        foreach ($import in $expectedRuleImports) {
            if ($ruleContent -notmatch [regex]::Escape($import)) {
                Add-ValidationError "$antigravityRule is missing shared-source reference: $import"
            }
        }
    }

    foreach ($skill in @($manifest.skills)) {
        $canonical = ".agents/skills/$skill/SKILL.md"
        $loader = ".claude/skills/$skill/SKILL.md"
        if (Require-File $canonical) {
            $skillContent = Get-Content -LiteralPath (Join-Path $root $canonical) -Raw -Encoding UTF8
            if ($skillContent -notmatch '(?s)^---\s*\r?\n.*?name:\s*[^\r\n]+\r?\n.*?description:\s*[^\r\n]+\r?\n.*?---') {
                Add-ValidationError "$canonical has invalid YAML frontmatter."
            }
        }
        if (Require-File $loader) {
            $loaderContent = Get-Content -LiteralPath (Join-Path $root $loader) -Raw -Encoding UTF8
            if ($loaderContent -notmatch [regex]::Escape($canonical)) {
                Add-ValidationError "$loader does not reference canonical skill: $canonical"
            }
        }
    }
}

# An installed module must stay out of the target repository's version control. The kit
# source is the opposite case: there the module is meant to be tracked, so it is skipped.
# setup-zhanlu.ps1 rewrites projectKind to 'firmware' in every installed copy.
if ($manifest -and $manifest.projectKind -ne 'kit-source') {
    $gitCommand = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCommand) {
        Push-Location -LiteralPath $root
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
            if ($LASTEXITCODE -eq 0 -and $insideWorkTree -eq 'true') {
                $moduleGitPaths = @(Get-ModuleGitPaths $manifest)
                $trackedFiles = @(& $gitCommand.Source --literal-pathspecs ls-files -- $moduleGitPaths)
                if ($LASTEXITCODE -ne 0) {
                    Add-ValidationError 'git ls-files failed; tracking status could not be verified.'
                } elseif ($trackedFiles.Count -gt 0) {
                    Add-ValidationError (
                        "module files are tracked by this repository ($($trackedFiles.Count) file(s)); " +
                        "untrack them with: git rm -r --cached $($moduleGitPaths -join ' ')"
                    )
                }
                $ignorePaths = @(@($moduleGitPaths) + @($installFiles) + @(
                    '.agents/project.md', '.agents/context-index.md', '.agents/TODO.md'
                ) | Select-Object -Unique)
                # Pass paths as arguments: PS 5.1 pipes CRLF, and Git's --stdin keeps
                # the CR as part of the filename, causing false missing-ignore errors.
                $ignoredPaths = @(& $gitCommand.Source -c core.quotepath=false check-ignore --no-index -- $ignorePaths)
                if ($LASTEXITCODE -notin @(0, 1)) {
                    Add-ValidationError 'git check-ignore failed; ignore protection could not be verified.'
                } else {
                    $unprotected = @($ignorePaths | Where-Object { $ignoredPaths -notcontains $_ })
                    if ($unprotected.Count -gt 0) {
                        Add-ValidationError ("Module paths are not ignored; re-run setup-zhanlu.ps1 -Update: " + ($unprotected -join ', '))
                    }
                }
            }
        } finally {
            Pop-Location
        }
    }
}

# Check only placeholders actually emitted by the project templates. Firmware documents
# may legitimately mention identifiers such as __ITE8297__.
$templateTokens = @(
    '__PROJECT_ID__',
    '__REPOSITORY_NAME__',
    '__VALIDATION_CODE__',
    '__CONTEXT_REVISION__',
    '__CONTEXT_CODE__'
)
if ((Find-TemplateToken -Content ('- Build' + [char]0xFF1A + '__PROJECT_ID__') -Tokens $templateTokens) -ne '__PROJECT_ID__' -or
    (Find-TemplateToken -Content '__ITE8297__' -Tokens $templateTokens) -or
    (Find-TemplateToken -Content ('- Note' + [char]0xFF1A + 'example `__PROJECT_ID__` was rejected') -Tokens $templateTokens)) {
    Add-ValidationError 'template-token regression failed: placeholder or legitimate macro was misclassified.'
}
foreach ($activeFile in @('.agents/project.md', '.agents/context-index.md', '.agents/TODO.md')) {
    if (Require-File $activeFile) {
        $content = Get-Content -LiteralPath (Join-Path $root $activeFile) -Raw -Encoding UTF8
        $token = Find-TemplateToken -Content $content -Tokens $templateTokens
        if ($token) {
            Add-ValidationError "$activeFile still contains template token: $token"
        }
    }
}

if ($errors.Count -gt 0) {
    Write-Output "Validation failed: $($errors.Count) error(s)"
    $errors | ForEach-Object { Write-Output "  [FAIL] $_" }
    exit 1
}

Write-Output "Validation passed: $($manifest.name) $($manifest.version)"
Write-Output "  coreVersion: $($manifest.coreVersion)"
Write-Output "  portableFiles: $(@($manifest.portableFiles).Count)"
Write-Output "  packageOnlyFiles: $(@($manifest.packageOnlyFiles).Count)"
Write-Output "  skills: $(@($manifest.skills).Count)"
exit 0
