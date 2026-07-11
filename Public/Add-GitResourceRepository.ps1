function Add-GitResourceRepository {

    <#
    .SYNOPSIS
        Tracks a git repository so Update-GitResourceRepository checks it automatically.
    .DESCRIPTION
        Appends the given repository (and branch) to the JSON store used by
        Update-GitResourceRepository when it's called with no -ProjectUri/-Name. Repositories
        already present (same ProjectUri and Branch) are skipped rather than duplicated.
    .PARAMETER ProjectUri
        One or more git repository URLs to track.
    .PARAMETER Branch
        The branch to track for each repository. Defaults to "master".
    .PARAMETER StorePath
        Path to the JSON file the tracked list is stored in. Defaults to the module's standard
        store location (see Get-GitResourceRepositoryPath).
    .EXAMPLE
        Add-GitResourceRepository 'https://github.com/example-org/example-module' -Branch master
    #>

    [CmdletBinding()]

    param (

        [Parameter(Mandatory,ValueFromPipelineByPropertyName,Position=0)]
        [string[]]$ProjectUri,

        [string]$Branch = "master",

        [string]$StorePath = (Get-GitResourceRepositoryPath)

    )

    BEGIN {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose -Message "$(Get-Date -f G) $FunctionName starting"

        $RepoList = @(Get-GitResourceRepositoryList -StorePath $StorePath)
    }

    PROCESS {

        foreach ($P1 in $ProjectUri) {

            if ($RepoList | Where-Object {($_.ProjectUri -eq $P1) -and ($_.Branch -eq $Branch)}) {
                Write-Verbose -Message "$(Get-Date -f T)   repository $P1 ($Branch) is already tracked"
                continue
            }

            Write-Verbose -Message "$(Get-Date -f T)   adding repository $P1 ($Branch)"
            $RepoList += [PSCustomObject]@{
                ProjectUri = $P1
                Branch = $Branch
            }
        }
    }

    END {
        Set-GitResourceRepositoryList -RepoList $RepoList -StorePath $StorePath
        Write-Verbose -Message "$(Get-Date -f G) $FunctionName completed"

        $RepoList
    }

}
