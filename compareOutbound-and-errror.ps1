# Define the path to the directory where the subfolders are located
$sourceDirectory1 = "./Outbound2"
$sourceDirectory2 = "./1008_Errors"

# Define the path to the directory where you want to move the subfolders
$destinationDirectory = "./ErrorFreestalledBatches"

# Get the list of subfolders in each source directory
$subfolders1 = Get-ChildItem -Path $sourceDirectory1 -Directory
$subfolders2 = Get-ChildItem -Path $sourceDirectory2 -Directory

# Loop through each subfolder in the first source directory
foreach ($subfolder in $subfolders1) {
    $subfolderName = $subfolder.Name

    # Check if the subfolder exists in the second source directory
    $subfolderExistsInBoth = $subfolders2 | Where-Object { $_.Name -eq $subfolderName }

    if ($subfolderExistsInBoth) {
        Write-Host "Subfolder '$subfolderName' exists in both source directories."
    } else {
        # Move the subfolder to the destination directory
        Move-Item -Path (Join-Path -Path $sourceDirectory1 -ChildPath $subfolderName) -Destination $destinationDirectory -Force
        Write-Host "Moved subfolder '$subfolderName' from source directory 1 to '$destinationDirectory'"
    }
}

# Loop through each subfolder in the second source directory
foreach ($subfolder in $subfolders2) {
    $subfolderName = $subfolder.Name

    # Check if the subfolder exists in the first source directory
    $subfolderExistsInBoth = $subfolders1 | Where-Object { $_.Name -eq $subfolderName }

    if (-not $subfolderExistsInBoth) {
        # Move the subfolder to the destination directory
        Move-Item -Path (Join-Path -Path $sourceDirectory2 -ChildPath $subfolderName) -Destination $destinationDirectory -Force
        Write-Host "Moved subfolder '$subfolderName' from source directory 2 to '$destinationDirectory'"
    }
}
