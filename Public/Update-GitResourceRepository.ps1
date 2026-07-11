function Update-GitResourceRepository {

    <#
    .SYNOPSIS
        Updates locally installed modules if their git repository has a newer version.
    .DESCRIPTION
        For each repository (explicit -ProjectUri/-Name, pipeline input, or, if none of those are
        given, every repository tracked via Add-GitResourceRepository) this compares the locally
        installed module version against the version in the repository and installs the newer one
        if the repository is ahead.
    .PARAMETER ProjectUri
        One or more git repository URLs to check. If omitted (and nothing arrives via the pipeline),
        the repositories tracked in the Add-GitResourceRepository store are used instead.
    .PARAMETER Name
        One or more names of already-installed modules; their ProjectUri is looked up and used instead.
    .PARAMETER Branch
        The branch to check. Defaults to "master" for explicit -ProjectUri/-Name input; repositories
        loaded from the tracked store use the branch recorded for each of them.
    .PARAMETER DestinationPath
        Where to install an updated module. Defaults to a writable path already on $env:PSModulePath.
    .PARAMETER Force
        Overwrites an existing, non-empty install directory for the same module/version.
    .PARAMETER InstallMissing
        Installs the module if it isn't found locally at all, instead of writing a non-terminating
        error. Without this switch, repositories with no matching local module are reported via
        Write-Error and skipped.
    .EXAMPLE
        Update-GitResourceRepository
        Checks every repository tracked via Add-GitResourceRepository.
    .EXAMPLE
        Update-GitResourceRepository -ProjectUri 'https://github.com/example-org/example-module'
    .EXAMPLE
        Update-GitResourceRepository -InstallMissing
        Checks every tracked repository, installing any whose module isn't installed locally yet.
    #>

    [CmdletBinding()]

    param (


        [Parameter(ValueFromPipelineByPropertyName,Position=0,ParameterSetName='ByUri')]
        [string[]]$ProjectUri,
        [Parameter(Mandatory,ParameterSetName='ByName')]
        [string[]]$Name,
        [string]$Branch = "master",
        [string]$DestinationPath = (Get-InstallPath),
        [switch]$Force,
        [switch]$InstallMissing

    )

    BEGIN {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose -Message "$(Get-Date -f G) $FunctionName starting"

        if (!(Get-Command git -ErrorAction SilentlyContinue)) {
            throw "$FunctionName requires the git command, but it was not found on `$env:PATH"
        }

        if ($Name) {
            # explicit -Name list, resolve to URIs and use the -Branch parameter for all of them
            $Items = @(ConvertTo-Uri -Name $Name | ForEach-Object { [PSCustomObject]@{ProjectUri = $_; Branch = $Branch} })
        } elseif ($ProjectUri) {
            # explicit -ProjectUri list, use the -Branch parameter for all of them
            $Items = @($ProjectUri | ForEach-Object { [PSCustomObject]@{ProjectUri = $_; Branch = $Branch} })
        } elseif ($MyInvocation.ExpectingInput) {
            # values will arrive per pipeline object in PROCESS
            $Items = $null
        } else {
            # no repository specified at all, fall back to the tracked repository list
            Write-Verbose -Message "$(Get-Date -f T)   no repository specified, loading tracked repositories from $(Get-GitResourceRepositoryPath)"
            $Items = @(Get-GitResourceRepositoryList)
            if (!$Items) {
                Write-Warning -Message "$FunctionName found no tracked repositories; use Add-GitResourceRepository to add some"
            }
        }

    }

    PROCESS {

        $CurrentItems = if ($null -eq $Items) {
            @([PSCustomObject]@{ProjectUri = $ProjectUri; Branch = $Branch})
        } else {
            $Items
        }

        foreach ($Item in $CurrentItems) {

            $P1 = $Item.ProjectUri
            if (!$P1) {continue}
            $B1 = if ($Item.Branch) {$Item.Branch} else {$Branch}

            Write-Verbose -Message "$(Get-Date -f T)   processing $P1"

            $RemoteModuleInfo = Get-GitResourceRepository -ProjectUri $P1 -Branch $B1 -KeepTempCopy
            if (!$RemoteModuleInfo -or ($RemoteModuleInfo.Count -gt 1)) {continue} # we have the error in get-gitresourcerepository
            $ModuleName = $RemoteModuleInfo.Name

            # TODO: continue only after cleanup!

            # Check version, and if higher install it
            $AllModules = @(
                (Get-Module -Name $ModuleName -ListAvailable),
                (Get-InstalledModule -Name $ModuleName -ErrorAction SilentlyContinue)
            ) | Select Name, Version
            $LocalModuleInfo = $AllModules | Sort-Object Version -Descending | Select -First 1
            if (!$LocalModuleInfo) {
                if ($InstallMissing) {
                    Write-Verbose "$(Get-Date -f T)   module '$ModuleName' not installed locally, installing it"
                    Install-ModuleInfo -ModuleInfo $RemoteModuleInfo -DestinationPath $DestinationPath -Force:$Force
                } else {
                    Write-Error "$FunctionName cannot find local module '$ModuleName'"
                }
                continue
            }
            if ($LocalModuleInfo.Version -ge $RemoteModuleInfo.Version) {
                Write-Verbose "$(Get-Date -f T)   not updating module '$ModuleName', local version $($LocalModuleInfo.Version), remote version $($RemoteModuleInfo.Version)"
            } else {
                Install-ModuleInfo -ModuleInfo $RemoteModuleInfo -DestinationPath $DestinationPath -Force:$Force
            }
        }
    }

    END {
        Write-Verbose -Message "$(Get-Date -f G) $FunctionName completed"
    }

}
