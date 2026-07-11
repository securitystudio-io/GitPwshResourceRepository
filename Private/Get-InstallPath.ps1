function Get-InstallPath {
    # OS specific installation path
    $defaultPath = if ($IsLinux -or $IsMacOS) {
        Join-Path (Split-Path -Path ([System.Management.Automation.Platform]::SelectProductNameForDirectory('USER_MODULES')) -Parent) 'Modules'
    } else {
        try {
            if ($PSVersionTable.PSEdition -eq 'Core') {
                [Environment]::GetFolderPath("MyDocuments") + '\PowerShell\Modules'
            } else {
                [Environment]::GetFolderPath("MyDocuments") + '\WindowsPowerShell\Modules'
            }            
        } catch {
            "$home\Documents\PowerShell\Modules"
        }
    }
    $ModulePaths = $Env:PSModulePath -split (';:'[[int]($IsLinux -or $IsMacOS)])
    if ($defaultPath -in $ModulePaths) {
        $defaultPath
    } else {
        $writablePath = ''
        foreach ($P1 in $ModulePaths) {
            if (([string]::IsNullOrEmpty($writablePath)) -and (Test-PathWritable $P1)) {
                $writablePath = $P1
            }
        }
        if ([string]::IsNullOrEmpty($writablePath)) {
            $defaultPath
        } else {
            $writablePath
        }
    }
}