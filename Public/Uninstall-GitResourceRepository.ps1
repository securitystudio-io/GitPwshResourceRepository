function Uninstall-GitResourceRepository {

    <#
    .SYNOPSIS
        Uninstalls a PowerShell module and untracks its repository.
    .DESCRIPTION
        Locates the installed version(s) of the module, deletes their files/folders from disk,
        and removes the repository from the tracked JSON list.
    .PARAMETER Name
        One or more module names to uninstall.
    .PARAMETER ProjectUri
        One or more git repository URLs. The module name is derived from the last segment.
    .PARAMETER StorePath
        Path to the JSON file where the tracked list is stored.
    .EXAMPLE
        Uninstall-GitResourceRepository -Name 'example-module'
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName='ByName', Position=0)]
        [string[]]$Name,

        [Parameter(Mandatory, ParameterSetName='ByUri')]
        [string[]]$ProjectUri,

        [string]$StorePath = (Get-GitResourceRepositoryPath)
    )

    BEGIN {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose -Message "$(Get-Date -f G) $FunctionName starting"
    }

    PROCESS {
        $TargetNames = @()
        if ($Name) {
            $TargetNames = $Name
        } elseif ($ProjectUri) {
            foreach ($P1 in $ProjectUri) {
                $TargetNames += ($P1 -split '/')[-1] -replace '\.git$',''
            }
        }

        foreach ($ModuleName in $TargetNames) {
            Write-Verbose -Message "$(Get-Date -f T)   uninstalling module $ModuleName"

            # Locate installed instances
            $Modules = @(
                (Get-Module -Name $ModuleName -ListAvailable),
                (Get-InstalledModule -Name $ModuleName -ErrorAction SilentlyContinue)
            )

            $DeletedPaths = @()
            foreach ($Mod in $Modules) {
                $Base = $Mod.ModuleBase
                if ($Base -and (Test-Path $Base)) {
                    if ($DeletedPaths -contains $Base) {continue}
                    Write-Verbose -Message "$(Get-Date -f T)   deleting directory $Base"
                    Remove-Item $Base -Recurse -Force -ErrorAction SilentlyContinue
                    $DeletedPaths += $Base

                    # Check if the parent directory is now empty, and clean it up if it is.
                    $Parent = Split-Path $Base -Parent
                    if (Test-Path $Parent) {
                        $Remaining = Get-ChildItem $Parent
                        if (!$Remaining) {
                            Write-Verbose -Message "$(Get-Date -f T)   deleting empty parent directory $Parent"
                            Remove-Item $Parent -Force -ErrorAction SilentlyContinue
                        }
                    }
                }
            }

            # Remove from tracked repository list
            Remove-GitResourceRepository -Name $ModuleName -StorePath $StorePath -Verbose:$VerbosePreference | Out-Null
        }
    }

    END {
        Write-Verbose -Message "$(Get-Date -f G) $FunctionName completed"
    }
}
