function Install-GitResourceRepository {

    <#
    .SYNOPSIS
        Installs a PowerShell module directly from a git repository.
    .DESCRIPTION
        Clones the given repository via Get-GitResourceRepository and copies its module into
        DestinationPath\<ModuleName>\<Version>, matching the layout PowerShell expects for
        auto-discoverable modules.
    .PARAMETER ProjectUri
        One or more git repository URLs to install from.
    .PARAMETER Branch
        The branch to clone. Defaults to "master".
    .PARAMETER DestinationPath
        Where to install the module. Defaults to a writable path already on $env:PSModulePath.
    .PARAMETER Force
        Overwrites an existing, non-empty install directory for the same module/version.
    .EXAMPLE
        (Install-GitResourceRepository 'https://github.com/example-org/example-module').Name | Import-Module
    #>

    [CmdletBinding()]

    param (


        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string[]]$ProjectUri,
        [string]$Branch = "master",
        [string]$DestinationPath = (Get-InstallPath),
        [switch]$Force
    )

    BEGIN {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose -Message "$(Get-Date -f G) $FunctionName starting"

        if (!(Get-Command git -ErrorAction SilentlyContinue)) {
            throw "$FunctionName requires the git command, but it was not found on `$env:PATH"
        }

        $PSModulePaths = $env:PSModulePath -split (';:'[[int]($IsLinux -or $IsMacOS)])
        if ($DestinationPath -notin $PSModulePaths) {
            Write-Warning -Message "$FunctionName using a path that is not in `$Env:PSModulePath ($DestinationPath)"
        }


    }

    PROCESS {

        foreach ($P1 in $ProjectUri) {

            Write-Verbose -Message "$(Get-Date -f T)   processing $P1"

            $ModuleInfo = Get-GitResourceRepository -ProjectUri $P1 -Branch $Branch -KeepTempCopy
            if (!$ModuleInfo -or ($ModuleInfo.Count -gt 1)) {continue} # we have the error in get-gitresourcerepository

            Install-ModuleInfo -ModuleInfo $ModuleInfo -DestinationPath $DestinationPath -Force:$Force
        }
    }

    END {
        Write-Verbose -Message "$(Get-Date -f G) $FunctionName completed"
    }

}
