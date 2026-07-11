# GitPwshResourceRepository

A PowerShell module for installing and updating PowerShell modules directly from git repositories
(GitHub, Azure DevOps, or any other git remote), and for tracking a list of repositories to check
for updates in one shot.

## Prerequisites

- PowerShell 7.0 or later
- **Git** client installed and available on `PATH` — check with `Get-Command git`

```PowerShell
winget install --id Git.Git -e --source winget
winget install --id Microsoft.PowerShell -e --source winget
```

## Installation

```PowerShell
git clone <this repository's clone URL>
Import-Module ./GitPwshResourceRepository/GitPwshResourceRepository.psd1
```

## Commands

| Command | Purpose |
|---|---|
| [`Get-GitResourceRepository`](#get-gitresourcerepository) | Inspect a repository's module (name/version) without installing it |
| [`Install-GitResourceRepository`](#install-gitresourcerepository) | Install a module straight from a git repository (and automatically track it) |
| [`Uninstall-GitResourceRepository`](#uninstall-gitresourcerepository) | Uninstall a module from disk and remove it from the tracked list |
| [`Add-GitResourceRepository`](#add-gitresourcerepository) | Track a repository for automatic update checks |
| [`Remove-GitResourceRepository`](#remove-gitresourcerepository) | Untrack a repository to stop automatic update checks |
| [`Update-GitResourceRepository`](#update-gitresourcerepository) | Update installed modules whose repository has moved ahead (and auto-remove if uninstalled) |

### Get-GitResourceRepository

Clones a repository to a temp directory, locates (or synthesizes) its module manifest, and returns
the module's name and version — without installing anything.

```PowerShell
Get-GitResourceRepository 'https://github.com/example-org/example-module' -Verbose
```

Accepts `-Name` instead of `-ProjectUri` to resolve an already-installed module's `ProjectUri`
automatically. Supports `-Branch` (default `main`).

### Install-GitResourceRepository

Installs a module directly from a git repository into a writable folder on `$env:PSModulePath`.
Successful installations are automatically added to the tracked repositories list.

```PowerShell
(Install-GitResourceRepository 'https://github.com/example-org/example-module').Name | Import-Module
```

Use `-DestinationPath` to control where it installs, and `-Force` to overwrite an existing,
non-empty install of the same module/version.

### Uninstall-GitResourceRepository

Uninstalls an installed module by deleting its files/directories from disk and automatically removing it from the tracked list.

```PowerShell
Uninstall-GitResourceRepository -Name 'example-module'
```

### Add-GitResourceRepository

Adds a repository (and branch) to the tracked list used by `Update-GitResourceRepository`.
Repositories already tracked (same URI and branch) are skipped rather than duplicated. The list is
stored as JSON at `D:\profile\GitResourceRepositoryRepos.json`.

```PowerShell
Add-GitResourceRepository 'https://github.com/example-org/example-module' -Branch main
Add-GitResourceRepository 'https://github.com/example-org/another-module' -Branch dev
```

### Remove-GitResourceRepository

Removes a repository from the tracked JSON list. Supports removing by `ProjectUri` or module `Name`.

```PowerShell
Remove-GitResourceRepository -Name 'example-module'
```

### Update-GitResourceRepository

Compares each repository's module version against what's installed locally, and installs the
newer version when the repository is ahead. Called with no arguments, it checks every repository
tracked via `Add-GitResourceRepository`, using the branch recorded for each one.

```PowerShell
# check everything tracked with Add-GitResourceRepository
Update-GitResourceRepository

# check a single repository explicitly
Update-GitResourceRepository -ProjectUri 'https://github.com/example-org/example-module'

# also install a tracked repository's module if it isn't installed locally yet
Update-GitResourceRepository -InstallMissing
```

By default, a tracked repository whose module isn't installed anywhere locally is reported via
`Write-Error` and skipped; pass `-InstallMissing` to install it instead. Additionally, if a tracked module has been uninstalled manually, `Update-GitResourceRepository` will automatically remove it from the tracked list.

## Typical workflow

```PowerShell
# Installs a module and automatically tracks it for updates
Install-GitResourceRepository 'https://github.com/example-org/example-module'

# ... later, e.g. from a scheduled task ...
# Checks all tracked modules and updates any that are out of date
Update-GitResourceRepository
```

## Getting help

Every command ships with comment-based help:

```PowerShell
Get-Help Update-GitResourceRepository -Full
```
