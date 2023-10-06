$source = Get-Location
$destination = Join-Path -Path $source -ChildPath "NewLocation"

if (-not (Test-Path -Path $destination -PathType Container)) {
    New-Item -Path $destination -ItemType Directory
}

$csvFilePath = "files.csv"

$csvData = Import-Csv -Path $csvFilePath

foreach ($row in $csvData) {
    # Get the folder name from the CSV
    $folderName = $row.FolderName

    $sourcePath = Join-Path -Path $source -ChildPath $folderName
    $destinationPath = Join-Path -Path $destination -ChildPath $folderName

    if (Test-Path -Path $sourcePath -PathType Container) {
        # Move the entire folder to the destination
        Move-Item -Path $sourcePath -Destination $destinationPath -Force
        Write-Host "Moved folder '$folderName' to '$destinationPath'"
    }
    elseif (Test-Path -Path $sourcePath -PathType Leaf) {
        # Move a single file to the destination
        Move-Item -Path $sourcePath -Destination $destinationPath -Force
        Write-Host "Moved file '$folderName' to '$destinationPath'"
    }
    else {
        Write-Host "Folder or file '$folderName' does not exist"
    }
}

# Output a message when the script is finished
Write-Host "Script completed."
