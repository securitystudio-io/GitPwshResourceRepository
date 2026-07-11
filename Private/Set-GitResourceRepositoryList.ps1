function Set-GitResourceRepositoryList {
    # writes the tracked repository list to the store, creating the parent directory if needed

    param (
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [array]$RepoList,

        [string]$StorePath = (Get-GitResourceRepositoryPath)
    )

    $StoreDir = Split-Path -Path $StorePath -Parent
    if (!(Test-Path $StoreDir)) {
        New-Item -Path $StoreDir -ItemType Directory -Force | Out-Null
    }

    # -InputObject (not the pipeline) is required so an empty array still serializes to '[]' instead of nothing
    ConvertTo-Json -InputObject $RepoList | Set-Content -Path $StorePath
}
