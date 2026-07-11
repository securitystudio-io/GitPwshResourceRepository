function Get-GitResourceRepositoryList {
    # reads the tracked repository list from the store, returns an empty array if none exists

    param (
        [string]$StorePath = (Get-GitResourceRepositoryPath)
    )

    if (Test-Path $StorePath) {
        @(Get-Content -Raw -Path $StorePath | ConvertFrom-Json)
    } else {
        @()
    }
}
