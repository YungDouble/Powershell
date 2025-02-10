<# 
===============================================================
Script Name  : downloadFiles-withSubFolderBreakdown.ps1
Author       : Davos DeHoyos
Date Created : 2/10/2025
Last Modified: 2/10/2025
Version      : 1.0

Description  : 
This script reads a CSV file containing file paths and subfolder 
names, then copies the files to a specified destination directory. 
If the destination subfolders do not exist, they are created. 
The script also logs success and failure messages in a log file.

Prefix Used  : fileCopy_ (e.g., fileCopy_log, fileCopy_destPath)
Postfix Used : _log, _error, _destination (e.g., filePath_log)

Dependencies :
- The CSV file must contain "Path" and "SubFolder" columns.
- The source files must exist in the specified paths.
- The destination server must be accessible.

===============================================================
#>

# Specify the path to the CSV file
$csvPath = "./FileList.csv"

# Specify the destination folder on the destination server
$destinationServer = "\\DC1-IMG-CONV-02\E"
$destinationPath = Join-Path -Path $destinationServer -ChildPath "BMH_HR_Files-Holding2"

# Log file setup
$fileCopy_log = "./FileCopyLog.txt"

# Function to write log messages
function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -Append -FilePath $fileCopy_log
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
        $fileCopy_destPath = Join-Path -Path $destinationPath -ChildPath $subFolder
        if (-not (Test-Path -Path $fileCopy_destPath)) {
            New-Item -ItemType Directory -Path $fileCopy_destPath -Force | Out-Null
            Write-Log "Created subfolder: $fileCopy_destPath"
        }

        # Define the destination file path
        $destinationFile = Join-Path -Path $fileCopy_destPath -ChildPath $fileName

        # Copy the file
        Copy-Item -Path $sourcePath -Destination $destinationFile -Force -ErrorAction Stop
        Write-Host "Copied: $sourcePath → $destinationFile"
        Write-Log "SUCCESS: Copied $sourcePath → $destinationFile"

    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host ("Error copying {0}: {1}" -f $sourcePath, $errorMessage)
        Write-Log ("ERROR: Failed to copy {0} → {1} - {2}" -f $sourcePath, $destinationFile, $errorMessage)
    }
}  # End of foreach loop


# Specify the path to the CSV file
$csvPath = "./FileList.csv"

# Specify the destination folder on the destination server
$destinationServer = "\\DC1-IMG-CONV-02\E"
$destinationPath = Join-Path -Path $destinationServer -ChildPath "BMH_HR_Files-Holding2"

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
    Write-Host "Error: Failed to read CSV file. $($_)"
    Write-Log "ERROR: Failed to read CSV file. $($_)"
    exit
}

# Check if the destination folder exists, if not, create it
if (-not (Test-Path -Path $destinationPath)) {
    try {
        New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
        Write-Log "Created destination folder: $destinationPath"
    } catch {
        Write-Host "Error: Failed to create destination folder. $($_)"
        Write-Log "ERROR: Failed to create destination folder. $($_)"
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
        # Use correct syntax for error handling
        $errorMessage = $_.Exception.Message
        Write-Host ("Error copying {0}: {1}" -f $sourcePath, $errorMessage)
        Write-Log ("ERROR: Failed to copy {0} → {1} - {2}" -f $sourcePath, $destinationFile, $errorMessage)
    }
}  # End of foreach loop
