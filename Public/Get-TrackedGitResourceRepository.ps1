function Get-TrackedGitResourceRepository {

    <#
    .SYNOPSIS
        Lists the tracked Git resource repositories.
    .DESCRIPTION
        Returns the list of repositories (and branches) tracked in the JSON store.
    .PARAMETER StorePath
        Path to the JSON file where the tracked list is stored. Defaults to the module's standard
        store location (see Get-GitResourceRepositoryPath).
    .EXAMPLE
        Get-TrackedGitResourceRepository
    #>

    [CmdletBinding()]
    param (
        [string]$StorePath = (Get-GitResourceRepositoryPath)
    )

    BEGIN {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose -Message "$(Get-Date -f G) $FunctionName starting"
    }

    PROCESS {
        Get-GitResourceRepositoryList -StorePath $StorePath
    }

    END {
        Write-Verbose -Message "$(Get-Date -f G) $FunctionName completed"
    }

}
