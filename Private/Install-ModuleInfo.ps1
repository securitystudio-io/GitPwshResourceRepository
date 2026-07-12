function Install-ModuleInfo {

    param(
        [PSObject]$ModuleInfo,
        [string]$DestinationPath,
        [switch]$Force
    )

    $FunctionName = $MyInvocation.MyCommand.Name

    # verify properties
    if (!$ModuleInfo.SameName) {
        Write-Warning -Message "$FunctionName installing a module whose name does not match its directory name"
    }
    if (!$ModuleInfo.Root) {
        Write-Verbose -Message "$FunctionName using the directory containing the manifest as the module root"
    }

    # check target directory
    $TargetDir = Join-Path (Join-Path $DestinationPath $ModuleInfo.Name) $ModuleInfo.Version
    if (Test-Path $TargetDir) {
        if ((Get-ChildItem $TargetDir) -and (!$Force)) {
            Write-Error "$FunctionName cannot install into non-empty directory $TargetDir; use a different -DestinationPath or -Force to override it"
            return
        }
        if ($Force) {
            Write-Verbose -Message "$(Get-Date -f T)   removing existing directory $TargetDir due to -Force"
            Remove-Item $TargetDir -Recurse -Force | Out-Null
        }
    }
    if (!(Test-Path $TargetDir)) {
        New-Item $TargetDir -ItemType Directory -Force | Out-Null
    }
    
    # copy module - excluding repository artifacts
    Write-Verbose -Message "$(Get-Date -f T)   installing module to $TargetDir"
    Copy-Item "$($ModuleInfo.LocalPath)/*" $TargetDir -Force -Recurse | Out-Null

    # clean up non-PowerShell artifacts
    $ExcludeDirs = @('.git', '.github', '.gitignore', 'node_modules', '.vscode', '.idea', 'build', 'dist', '.env*', '*.log', '*.tmp')
    $ExcludeDirs | ForEach-Object {
        $path = Join-Path $TargetDir $_
        if (Test-Path $path) {
            Write-Verbose -Message "$(Get-Date -f T)   removing $_ from installation"
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # clean up source temp directory
    Remove-Item $ModuleInfo.LocalPath -Recurse -Force | Out-Null
    Write-Verbose -Message "$(Get-Date -f T)   module $($ModuleInfo.Name) installation completed"

    # return value
    $ModuleInfo.LocalPath = $TargetDir
    $ModuleInfo
}