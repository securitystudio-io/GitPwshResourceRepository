function Remove-GitResourceRepository {

    <#
    .SYNOPSIS
        Removes a git repository from the tracked list.
    .DESCRIPTION
        Removes the given repository from the tracked JSON list used by Update-GitResourceRepository.
    .PARAMETER ProjectUri
        One or more git repository URLs to untrack.
    .PARAMETER Name
        One or more names of modules to untrack. Matches the last segment of the ProjectUri.
    .PARAMETER Branch
        If specified, only removes the entry if it tracks this specific branch. If not specified, removes all branches for the matching repository/name.
    .PARAMETER StorePath
        Path to the JSON file where the tracked list is stored.
    .EXAMPLE
        Remove-GitResourceRepository -Name 'example-module'
    #>

    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName='ByUri', ValueFromPipelineByPropertyName)]
        [string[]]$ProjectUri,

        [Parameter(ParameterSetName='ByName')]
        [string[]]$Name,

        [string]$Branch,

        [string]$StorePath = (Get-GitResourceRepositoryPath)
    )

    BEGIN {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose -Message "$(Get-Date -f G) $FunctionName starting"

        $RepoList = @(Get-GitResourceRepositoryList -StorePath $StorePath)
    }

    PROCESS {
        if ($ProjectUri) {
            foreach ($P1 in $ProjectUri) {
                Write-Verbose -Message "$(Get-Date -f T)   removing repository $P1"
                $RepoList = @($RepoList | Where-Object {
                    if ($Branch) {
                        !($_.ProjectUri -eq $P1 -and $_.Branch -eq $Branch)
                    } else {
                        $_.ProjectUri -ne $P1
                    }
                })
            }
        } elseif ($Name) {
            foreach ($N1 in $Name) {
                Write-Verbose -Message "$(Get-Date -f T)   removing module by name $N1"
                $RepoList = @($RepoList | Where-Object {
                    $UriName = ($_.ProjectUri -split '[/\\]')[-1] -replace '\.git$',''
                    if ($Branch) {
                        !($UriName -eq $N1 -and $_.Branch -eq $Branch)
                    } else {
                        $UriName -ne $N1
                    }
                })
            }
        }
    }

    END {
        Set-GitResourceRepositoryList -RepoList $RepoList -StorePath $StorePath
        Write-Verbose -Message "$(Get-Date -f G) $FunctionName completed"
        $RepoList
    }
}
