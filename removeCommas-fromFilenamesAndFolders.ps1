<#
.SYNOPSIS
    This script recursively removes commas from folder and file names within a specified root directory.

.DESCRIPTION
    The script scans the given root directory (default: current directory "./") and processes all subdirectories and files.
    It renames any items containing commas by removing them while preserving the original structure.

.PARAMETER rootDirectory
    Defines the starting directory for processing. Defaults to "./" (current directory).

.FUNCTIONS
    Remove-Commas
        - Accepts a file or folder path as input.
        - Checks if the name contains commas.
        - If commas are found, removes them and renames the item.
        - Provides logging for renamed items and skipped paths.

.NOTES
    - This script ensures that nested folders are renamed first to prevent conflicts.
    - Uses error handling to prevent failures due to invalid paths or permission issues.
    - Output messages indicate whether items were renamed or required no changes.

.OUTPUTS
    - Console messages indicating the status of processed files and folders.

.EXAMPLE
    # Run the script in the current directory
    .\Remove-Commas.ps1

    # Specify a different root directory
    $rootDirectory = "C:\Users\Documents"
    .\Remove-Commas.ps1

.AUTHOR
    Davos DeHoyos

.VERSION
    1.0
#>

# Define the root directory to start processing
$rootDirectory = "./"

# Function to remove commas from folder and file names
function Remove-Commas {
    param (
        [string]$path
    )

    # Ensure the path is valid and not empty
    if ([string]::IsNullOrWhiteSpace($path)) {
        Write-Warning "Invalid or empty path encountered. Skipping."
        return $null
    }

    # Get the parent directory and the current item name
    try {
        $parent = Split-Path -Parent $path
        $name = Split-Path -Leaf $path
    } catch {
        Write-Warning "Failed to process path: $path. Error: $_"
        return $null
    }

    # Check if the name contains a comma
    if ($name -like "*,*") {
        # Replace commas in the name
        $newName = $name -replace ",", ""

        # Build the new path
        $newPath = Join-Path -Path $parent -ChildPath $newName

        # Rename the item
        try {
            Rename-Item -Path $path -NewName $newPath -ErrorAction Stop
            Write-Host "Renamed: '$path' -> '$newPath'" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to rename '$path': $_"
        }

        # Return the new path
        return $newPath
    } else {
        # Log no change needed
        Write-Host "No change needed: '$path'" -ForegroundColor Yellow
        return $path
    }
}

Write-Host "Starting processing for directory: $rootDirectory" -ForegroundColor Cyan

# Process folders first, then files
Write-Host "Processing folders..." -ForegroundColor Cyan
Get-ChildItem -Path $rootDirectory -Recurse -Directory -ErrorAction SilentlyContinue |
    Sort-Object -Property FullName -Descending | # Sort in reverse order to rename nested folders first
    ForEach-Object {
        Remove-Commas -path $_.FullName
    }

Write-Host "Processing files..." -ForegroundColor Cyan
Get-ChildItem -Path $rootDirectory -Recurse -File -ErrorAction SilentlyContinue |
    ForEach-Object {
        Remove-Commas -path $_.FullName
    }

Write-Host "Processing completed for directory: $rootDirectory" -ForegroundColor Cyan
