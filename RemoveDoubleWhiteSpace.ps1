#Powershell script to remove instances of two spaces within a filename instead of one

Get-ChildItem -Recurse -File | Where-Object { $_.Name -match "  " } | ForEach-Object {

    $newName = ($_.Name -replace '\s{2,}', ' ')
    $newPath = Join-Path -Path $_.DirectoryName -ChildPath $newName

    if (-not (Test-Path $newPath)) {
        Rename-Item -Path $_.FullName -NewName $newName
        Write-Host "Renamed:`n$($_.FullName)`n-> $newName`n"
    } else {
        Write-Warning "Skipped (file already exists): $newName"
    }
}


Get-ChildItem -Recurse -Filter *.pdf | Where-Object { $_.Name -match "\s{2,}" } | ForEach-Object {
    $newName = ($_.Name -replace '\s{2,}', ' ')  # Replace double or more spaces with a single space
    $newPath = Join-Path -Path $_.DirectoryName -ChildPath $newName

    if (-not (Test-Path $newPath)) {
        Rename-Item -Path $_.FullName -NewName $newName
        Write-Host "Renamed:`n$($_.FullName)`n→ $newName`n"
    } else {
        Write-Warning "Skipped (target file already exists): $newName"
    }
}
