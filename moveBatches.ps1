# This script is to move a list of batches from one location to a new 

# Set the source and destination folder paths
$sourceFolder = "./"
$destinationFolder = "./DestinationFolder"

# Ensure the destination folder exists
if (-not (Test-Path -Path $destinationFolder -PathType Container)) {
    New-Item -Path $destinationFolder -ItemType Directory -Force
}

# Specify the path to the CSV file
$csvFilePath = ".\files.csv"

# Read the CSV file
$folderList = Import-Csv -Path $csvFilePath

# Iterate through each folder in the CSV and move it
foreach ($folder in $folderList) {
    $folderName = $folder.FolderName

    $sourcePath = Join-Path -Path $sourceFolder -ChildPath $folderName
    $destinationPath = Join-Path -Path $destinationFolder -ChildPath $folderName

    # Check if the source folder exists
    if (Test-Path -Path $sourcePath -PathType Container) {
        # Move the folder to the destination
        Move-Item -Path $sourcePath -Destination $destinationPath -Force
        Write-Host "Moved folder '$folderName' to '$destinationPath'"
    } else {
        Write-Host "Source folder '$folderName' does not exist"
    }
}

Write-Host "Script completed."
