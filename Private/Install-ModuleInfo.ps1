function Install-ModuleInfo {

    param(
        [PSObject]$ModuleInfo,
        [string]$DestinationPath,
        [switch]$Force
    )

    $FunctionName = $MyInvocation.MyCommand.Name

    # verify properties
    if (!$ModuleInfo.Root) {
        Write-Warning -Message "$FunctionName installing a module whose manifest is not located in the module root directory"
    }
    if (!$ModuleInfo.SameName) {
        Write-Warning -Message "$FunctionName installing a module whose name does not match its directory name"
    }

    # check target directory
    $TargetDir = Join-Path (Join-Path $DestinationPath $ModuleInfo.Name) $ModuleInfo.Version
    if (!(Test-Path $TargetDir)) {
        New-Item $TargetDir -ItemType Directory -Force | Out-Null
    } elseif ((Get-ChildItem $TargetDir) -and (!$Force)) {
        Write-Error "$FunctionName cannot install into non-empty directory $TargetDir; use a different -DestinationPath or -Force to override it"
        return
    }
    
    # copy module
    Write-Verbose -Message "$(Get-Date -f T)   installing module to $TargetDir"
    Copy-Item "$($ModuleInfo.LocalPath)/*" $TargetDir -Force -Recurse | Out-Null
    
    # clean up
    $gitDir = Join-Path $TargetDir '.git'
    if (Test-Path $gitDir) {Remove-Item $gitDir -Recurse -Force}
    Remove-Item $ModuleInfo.LocalPath -Recurse -Force | Out-Null
    Write-Verbose -Message "$(Get-Date -f T)   module $($ModuleInfo.Name) installation completed"

    # return value
    $ModuleInfo.LocalPath = $TargetDir
    $ModuleInfo
}