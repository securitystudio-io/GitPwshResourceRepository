function Register-GitResourceRepositoryPath {

    <#
    .SYNOPSIS
        Adds or removes the module installation directory from the PSModulePath environment variable.
    .DESCRIPTION
        Modifies the User-scoped PSModulePath environment variable to include or exclude the
        specified installation directory. The change is persisted to the registry (User scope)
        so that new PowerShell sessions automatically inherit the updated path.

        After applying the change the function prompts the user to reload the current session
        so that the updated PSModulePath takes effect immediately.
    .PARAMETER Path
        The directory to add or remove. Defaults to the writable install path returned by
        Get-InstallPath (i.e. the same default used by Install-GitResourceRepository).
    .PARAMETER Action
        'Add'    – appends Path to PSModulePath if it is not already present (default).
        'Remove' – removes Path from PSModulePath if it is present.
    .EXAMPLE
        Register-GitResourceRepositoryPath
        # Adds the default install directory to $env:PSModulePath.

    .EXAMPLE
        Register-GitResourceRepositoryPath -Action Remove
        # Removes the default install directory from $env:PSModulePath.

    .EXAMPLE
        Register-GitResourceRepositoryPath -Path 'C:\MyModules' -Action Add
        # Adds a custom path to $env:PSModulePath.
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param (
        [string]$Path = (Get-InstallPath),

        [ValidateSet('Add', 'Remove')]
        [string]$Action = 'Add'
    )

    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose -Message "$(Get-Date -f G) $FunctionName starting"

    # Determine the path separator for this OS
    $Separator = if ($IsLinux -or $IsMacOS) { ':' } else { ';' }

    # ── Resolve the current User-scoped PSModulePath ──────────────────────────
    $scope = [System.EnvironmentVariableTarget]::User
    $currentPersisted = [System.Environment]::GetEnvironmentVariable('PSModulePath', $scope)

    # Fall back to the session value if the User key is empty (first-run edge case)
    if ([string]::IsNullOrWhiteSpace($currentPersisted)) {
        $currentPersisted = $env:PSModulePath
    }

    $persistedParts = $currentPersisted -split [regex]::Escape($Separator) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    # ── Compute the new path list ─────────────────────────────────────────────
    $changed = $false

    if ($Action -eq 'Add') {
        if ($Path -notin $persistedParts) {
            if ($PSCmdlet.ShouldProcess($Path, "Add to PSModulePath (User scope)")) {
                $newParts = $persistedParts + $Path
                $changed  = $true
            }
        } else {
            Write-Host "'$Path' is already present in PSModulePath." -ForegroundColor Cyan
        }
    } else {
        # Remove
        if ($Path -in $persistedParts) {
            if ($PSCmdlet.ShouldProcess($Path, "Remove from PSModulePath (User scope)")) {
                $newParts = $persistedParts | Where-Object { $_ -ne $Path }
                $changed  = $true
            }
        } else {
            Write-Host "'$Path' was not found in PSModulePath." -ForegroundColor Cyan
        }
    }

    if (-not $changed) {
        Write-Verbose -Message "$(Get-Date -f G) $FunctionName – no change required"
        return
    }

    # ── Persist to User environment ───────────────────────────────────────────
    $newValue = $newParts -join $Separator
    [System.Environment]::SetEnvironmentVariable('PSModulePath', $newValue, $scope)
    Write-Verbose -Message "User-scoped PSModulePath updated."

    # ── Update the current session immediately ────────────────────────────────
    $sessionParts = $env:PSModulePath -split [regex]::Escape($Separator) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    if ($Action -eq 'Add' -and $Path -notin $sessionParts) {
        $env:PSModulePath = ($sessionParts + $Path) -join $Separator
    } elseif ($Action -eq 'Remove') {
        $env:PSModulePath = ($sessionParts | Where-Object { $_ -ne $Path }) -join $Separator
    }

    $verb = if ($Action -eq 'Add') { 'added to' } else { 'removed from' }
    Write-Host "'$Path' has been $verb PSModulePath." -ForegroundColor Green

    # ── Prompt the user to reload the session ─────────────────────────────────
    Write-Host ''
    Write-Host 'PSModulePath has been updated for new sessions.' -ForegroundColor Yellow
    Write-Host 'To apply the change to this session, reload it now.' -ForegroundColor Yellow
    Write-Host ''
    $answer = Read-Host "Reload the current PowerShell session now? [Y/N]"

    if ($answer -match '^[Yy]') {
        Write-Host 'Reloading session...' -ForegroundColor Cyan
        # Re-exec the current process: launches a new pwsh/powershell in the same window
        $exe = (Get-Process -Id $PID).Path
        if ([string]::IsNullOrEmpty($exe)) {
            # Fallback: just warn the user
            Write-Warning 'Could not determine the current PowerShell executable path. Please close and reopen your terminal manually.'
        } else {
            & $exe -NoLogo -NoExit -Command "Write-Host 'Session reloaded. PSModulePath is now: ' -ForegroundColor Green; `$env:PSModulePath -split [System.IO.Path]::PathSeparator | ForEach-Object { Write-Host `"  `$_`" }"
        }
    } else {
        Write-Host 'Skipped. Open a new PowerShell session to pick up the updated PSModulePath.' -ForegroundColor DarkYellow
    }

    Write-Verbose -Message "$(Get-Date -f G) $FunctionName completed"
}
