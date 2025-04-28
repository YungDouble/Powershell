<#
    Script Name: MoveFilesByCSV.ps1
    Description: 
        This script reads a CSV file containing file paths and target subfolder names, 
        and moves each file into its designated subfolder under a root directory ("SubParts"). 
        It logs all actions (successes, warnings, errors) to a text log file.

    CSV Format:
        The CSV must have at least two columns:
        - Path: relative or absolute path to the source file
        - Subpart: name of the destination subfolder under ./SubParts/

    Key Features:
        - Validates input file and folder paths
        - Creates missing subfolders automatically
        - Logs moved files, missing files, and any errors encountered
        - Designed to run from the same directory as the source files

    Author: YellowFolder Support
    Date: April 2025
#>

# CSV file path
$csvPath = "./FileList.csv"

# Root destination folder
$destinationRoot = Join-Path -Path (Get-Location) -ChildPath "SubParts"

# Log file
$logFile = "./FileCopyLog.txt"

# Function to write log messages
function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -Append -FilePath $logFile
}

# Check for CSV
if (-not (Test-Path -Path $csvPath -PathType Leaf)) {
    Write-Host "ERROR: CSV not found at $csvPath"
    Write-Log "ERROR: CSV not found at $csvPath"
    exit
}

# Read the CSV
try {
    $fileList = Import-Csv -Path $csvPath -ErrorAction Stop
} catch {
    Write-Host "ERROR: Failed to read CSV - $($_.Exception.Message)"
    Write-Log "ERROR: Failed to read CSV - $($_.Exception.Message)"
    exit
}

# Ensure root exists
if (-not (Test-Path -Path $destinationRoot)) {
    New-Item -ItemType Directory -Path $destinationRoot -Force | Out-Null
    Write-Log "Created root destination: $destinationRoot"
}

# Process each file
foreach ($entry in $fileList) {
    $sourcePath = $entry.Path
    $subpartFolderName = $entry.Subpart
    $fileName = [System.IO.Path]::GetFileName($sourcePath)

    # Build the full subfolder path under ./SubParts/
    $destinationSubfolder = Join-Path -Path $destinationRoot -ChildPath $subpartFolderName
    $destinationFile = Join-Path -Path $destinationSubfolder -ChildPath $fileName

    # Make sure the subfolder exists
    if (-not (Test-Path -Path $destinationSubfolder)) {
        New-Item -ItemType Directory -Path $destinationSubfolder -Force | Out-Null
        Write-Log "Created subfolder: $destinationSubfolder"
    }

    # Check source file exists
    if (-not (Test-Path -Path $sourcePath -PathType Leaf)) {
        Write-Host "Missing file: $sourcePath"
        Write-Log "WARNING: File not found - $sourcePath"
        continue
    }

    # Move the file, may need to have option to have this move versus copy
    try {
        Move-Item -Path $sourcePath -Destination $destinationFile -Force -ErrorAction Stop
        Write-Host "Moved: $sourcePath → $destinationFile"
        Write-Log "SUCCESS: Moved $sourcePath → $destinationFile"
    } catch {
        Write-Host "Failed to move $sourcePath - $($_.Exception.Message)"
        Write-Log "ERROR: Failed to move $sourcePath → $destinationFile - $($_.Exception.Message)"
    }

}

Write-Host "✅ Copy process complete."
Write-Log "INFO: Copy process complete."
