<# 
    Script Name: File Copy Script from CSV  
    Author: Davos DeHoyos  
    Date: 2/6/2025  
    Version: 1.0  

    Description:  
    This script reads a CSV file containing file paths and copies the specified files  
    to a designated destination folder on a remote server. If the destination folder  
    or subfolders do not exist, the script creates them before copying the files.

    Preconditions:  
    - The CSV file must exist at the specified path (`$csvPath`).  
    - The CSV file must contain at least two columns:  
      - `Path`: Full path of the source file to be copied.  
      - `SubFolder` (if applicable): Name of the subfolder where the file should be placed.  
    - The source files must be accessible to the script.  
    - The script must have sufficient permissions to create folders and copy files to the destination.  
    - If the destination is a network location, the server must be reachable.  

    Postconditions:  
    - All valid source files are copied to the designated destination folder.  
    - Missing destination folders are created as needed.  
    - A log is maintained to track successful copies and errors.  
    - If any source files are missing, the script logs warnings but continues execution.  

    Notes:  
    - Running the script as an administrator may be required if permission errors occur.  
    - If copying files to a network location, ensure the script has proper network access.  

#>

# Specify the path to the CSV file
$csvPath = "./FileList.csv"

# Specify the destination folder on the destination server
$destinationServer = "\\DC1-IMG-CONV-02\E"
$destinationPath = Join-Path -Path $destinationServer -ChildPath "BMH_HR_Files-Holding"

# Log file setup
$logFile = "./FileCopyLog.txt"

# Function to write log messages
function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -Append -FilePath $logFile
}

# Validate that the CSV file exists
if (-not (Test-Path -Path $csvPath -PathType Leaf)) {
    Write-Host "Error: CSV file not found at $csvPath"
    Write-Log "ERROR: CSV file not found at $csvPath"
    exit
}

# Read the CSV file
try {
    $fileList = Import-Csv -Path $csvPath -ErrorAction Stop
} catch {
    Write-Host "Error: Failed to read CSV file. $_"
    Write-Log "ERROR: Failed to read CSV file. $_"
    exit
}

# Check if the destination folder exists, if not, create it
if (-not (Test-Path -Path $destinationPath)) {
    try {
        New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
        Write-Log "Created destination folder: $destinationPath"
    } catch {
        Write-Host "Error: Failed to create destination folder. $_"
        Write-Log "ERROR: Failed to create destination folder. $_"
        exit
    }
}

# Iterate through each row in the CSV and copy the files
foreach ($entry in $fileList) {
    try {
        $sourcePath = $entry.Path
        $subFolder = $entry.SubFolder
        $fileName = [System.IO.Path]::GetFileName($sourcePath)  # Extract filename

        # Validate the source file exists before processing
        if (-not (Test-Path -Path $sourcePath -PathType Leaf)) {
            Write-Host "Warning: Source file not found: $sourcePath"
            Write-Log "WARNING: Source file not found: $sourcePath"
            continue
        }

        # Create the subfolder in the destination if it doesn't exist
        $subFolderPath = Join-Path -Path $destinationPath -ChildPath $subFolder
        if (-not (Test-Path -Path $subFolderPath)) {
            New-Item -ItemType Directory -Path $subFolderPath -Force | Out-Null
            Write-Log "Created subfolder: $subFolderPath"
        }

        # Define the destination file path
        $destinationFile = Join-Path -Path $subFolderPath -ChildPath $fileName

        # Copy the file
        Copy-Item -Path $sourcePath -Destination $destinationFile -Force -ErrorAction Stop
        Write-Host "Copied: $sourcePath → $destinationFile"
        Write-Log "SUCCESS: Copied $sourcePath → $destinationFile"

    } catch {
        Write-Host "Error copying ${sourcePath}: $_"
        Write-Log "ERROR: Failed to copy ${sourcePath} to ${destinationFile}. $_"
    }
}

Write-Host "File copy process completed."
Write-Log "File copy process completed."
