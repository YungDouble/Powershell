# Define the path to the directory where the subfolders are located
# Worked 1031
$sourceDirectory1 = "./Outbound2"
$sourceDirectory2 = "./1008_Errors"

# Define the path to the directory where you want to move the subfolders
$destinationDirectory = "./ErrorFreestalledBatches"

# Get the list of subfolders in each source directory
$subfolders1 = Get-ChildItem -Path $sourceDirectory1 -Directory
$subfolders2 = Get-ChildItem -Path $sourceDirectory2 -Directory

# Function to check if a folder contains only .pdf files
function ContainsOnlyPdfFiles {
    param (
        [string]$folderPath
    )
    $files = Get-ChildItem -Path $folderPath -File
    foreach ($file in $files) {
        if ($file.Extension -ne ".pdf") {
            return $false
        }
    }
    return $true
}

# Loop through each subfolder in the first source directory
foreach ($subfolder in $subfolders1) {
    $subfolderName = $subfolder.Name
    $subfolderPath = Join-Path -Path $sourceDirectory1 -ChildPath $subfolderName

    # Check if the subfolder exists in the second source directory
    $subfolderExistsInBoth = $subfolders2 | Where-Object { $_.Name -eq $subfolderName }

    if ($subfolderExistsInBoth) {
        # If the subfolder exists in both source directories, log the information
        Write-Host "Subfolder '$subfolderName' exists in both source directories."
    } else {
        # If the subfolder does not exist in the second source directory, check for non-PDF files
        if (ContainsOnlyPdfFiles -folderPath $subfolderPath) {
            # Move the subfolder to the destination directory
            Move-Item -Path $subfolderPath -Destination $destinationDirectory -Force
            Write-Host "Moved subfolder '$subfolderName' from source directory 1 to '$destinationDirectory'"
        } else {
            Write-Host "Subfolder '$subfolderName' contains non-PDF files and was not moved."
        }
    }
}

# Loop through each subfolder in the second source directory
foreach ($subfolder in $subfolders2) {
    $subfolderName = $subfolder.Name
    $subfolderPath = Join-Path -Path $sourceDirectory2 -ChildPath $subfolderName

    # Check if the subfolder exists in the first source directory
    $subfolderExistsInBoth = $subfolders1 | Where-Object { $_.Name -eq $subfolderName }

    if (-not $subfolderExistsInBoth) {
        # If the subfolder does not exist in the first source directory, check for non-PDF files
        if (ContainsOnlyPdfFiles -folderPath $subfolderPath) {
            # Move the subfolder to the destination directory
            Move-Item -Path $subfolderPath -Destination $destinationDirectory -Force
            Write-Host "Moved subfolder '$subfolderName' from source directory 2 to '$destinationDirectory'"
        } else {
            Write-Host "Subfolder '$subfolderName' contains non-PDF files and was not moved."
        }
    }
}
