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
