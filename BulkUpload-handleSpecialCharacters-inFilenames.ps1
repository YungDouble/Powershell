<#
.SYNOPSIS
    Renames files to remove square brackets `[ ]` and moves them into an "images" folder.

.DESCRIPTION
    - Scans the `FileHolding` directory for files.
    - If a file contains `[ ]` in its name, it is renamed to remove those characters.
    - Moves all files into `FileHolding/images/`.
    - Skips moving a file if it already exists in the destination.
    - Uses `-LiteralPath` to handle special characters.

.NOTES
    - If brackets `[ ]` exist in filenames, they are removed automatically.
    - If a file with the same name already exists in `images/`, it is skipped.
    - Run this script in PowerShell with the `FileHolding` directory present.
#>

$basePath = "./FileHolding"
$destFolder = Join-Path -Path $basePath -ChildPath "images"

# Ensure the destination folder exists
if (!(Test-Path -LiteralPath $destFolder -ErrorAction SilentlyContinue)) {
    New-Item -LiteralPath $destFolder -ItemType Directory | Out-Null
}

Write-Output "Base Path: $basePath"
$files = Get-ChildItem -Path $basePath -File

foreach ($file in $files) {
    Write-Output "Processing File: $($file.Name)"

    # Check if the filename contains square brackets and sanitize
    if ($file.Name -match '[\[\]]') {
        $newFileName = $file.Name -replace '[\[\]]', ''  # Remove brackets
        $newFilePath = Join-Path -Path $file.DirectoryName -ChildPath $newFileName

        # Rename the file safely
        Rename-Item -LiteralPath $file.FullName -NewName $newFileName -Force
        Write-Host "Renamed: $($file.Name) -> $newFileName"

        # Update file reference after renaming
        $file = Get-Item -LiteralPath $newFilePath
    }

    # Define the destination file path
    $destFilePath = Join-Path -Path $destFolder -ChildPath $file.Name

    # Check if file already exists in the destination
    if (Test-Path -LiteralPath $destFilePath) {
        Write-Host "File already exists: $($file.Name), skipping..."
        continue
    }

    # Move file safely with -LiteralPath
    Move-Item -LiteralPath $file.FullName -Destination $destFolder -Verbose
}
