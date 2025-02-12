<#
.SYNOPSIS
    Renames files to remove square brackets `[ ]` and organizes them into structured subdirectories.

.DESCRIPTION
    - The script scans `BulkUpload` for files.
    - If a file contains `[ ]` in its name, it is renamed to remove those characters.
    - It splits filenames by `_` to determine sorting folders.
    - The directory structure follows:
        BulkUpload/
        ├── postfix/
            ├── prefix/
                ├── images/   (Holds moved files)
                ├── CSV/      (Contains "Done.csv")
    - Moves each file into the correct `images/` folder.
    - A `Done.csv` file is created in the `CSV` folder for tracking.
    - Uses `-LiteralPath` to handle special characters.

.NOTES
    - If brackets `[ ]` exist in filenames, they are removed automatically.
    - If a file does not follow the expected format, it is skipped.
    - If a file with the same name already exists in `images/`, it is skipped.
    - Run this script in PowerShell with the `BulkUpload` directory present.
#>

# Define the base directory
$basePath = "./BulkUpload"

Write-Output "Base Path: $basePath"
$files = Get-ChildItem -Path $basePath -File

foreach ($file in $files) {
    Write-Output "Processing File: $($file.Name)"

    # Check if the filename contains square brackets and sanitize it
    if ($file.Name -match '[\[\]]') {
        $newFileName = $file.Name -replace '[\[\]]', ''  # Remove brackets
        $newFilePath = Join-Path -Path $file.DirectoryName -ChildPath $newFileName

        # Rename the file safely
        Rename-Item -LiteralPath $file.FullName -NewName $newFileName -Force
        Write-Host "Renamed: $($file.Name) -> $newFileName"

        # Update file reference after renaming
        $file = Get-Item -LiteralPath $newFilePath
    }

    # Split filename by `_` to extract batch folder names
    $split = $file.BaseName -split '>'

    if ($split.Count -lt 2) {
        Write-Host "Skipping file (Invalid Format): $($file.Name)"
        continue
    }

    # Define folder paths
    $root = Join-Path -Path $basePath -ChildPath $split[1]
    $sub = Join-Path -Path $root -ChildPath "$($split[0])\images"
    $CSV = Join-Path -Path $root -ChildPath "$($split[0])\CSV"
    $CSVfile = "Done.csv"

    Write-Output "Root Path: $root"
    Write-Output "Subdirectory Path: $sub"

    # Ensure the necessary directories exist
    foreach ($dir in @($root, $sub, $CSV)) {
        if (!(Test-Path -LiteralPath $dir -ErrorAction SilentlyContinue)) {
            New-Item -LiteralPath $dir -ItemType Directory | Out-Null
        }
    }

    # Create CSV file safely
    $csvFilePath = Join-Path -Path $CSV -ChildPath $CSVfile
    if (!(Test-Path -LiteralPath $csvFilePath -ErrorAction SilentlyContinue)) {
        New-Item -LiteralPath $csvFilePath -ItemType File | Out-Null
    }

    # Determine the destination file path
    $destFilePath = Join-Path -Path $sub -ChildPath $file.Name

    # Check if file already exists in the destination
    if (Test-Path -LiteralPath $destFilePath) {
        Write-Host "File already exists: $($file.Name), skipping..."
        continue
    }

    # Move file safely with -LiteralPath
    Move-Item -LiteralPath $file.FullName -Destination $sub -Verbose
}
