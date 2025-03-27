# Specify the path to the CSV file
$csvPath = "./FileList.csv"

# Specify the destination folder on the destination server
$destinationServer = "\\DC1-IMG-CONV-02\E"
$destinationPath = Join-Path -Path $destinationServer -ChildPath "SAG_SPED_Files-Holding-03262025-PartC1-BracketTest"

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
    Write-Host ("Error: Failed to read CSV file. " + $_.Exception.Message)
    Write-Log ("ERROR: Failed to read CSV file. " + $_.Exception.Message)
    exit
}

# Ensure the destination folder exists
if (-not (Test-Path -Path $destinationPath)) {
    try {
        New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
        Write-Log ("Created destination folder: " + $destinationPath)
    } catch {
        Write-Host ("Error: Failed to create destination folder. " + $_.Exception.Message)
        Write-Log ("ERROR: Failed to create destination folder. " + $_.Exception.Message)
        exit
    }
}

# Iterate through each row in the CSV and copy the files
foreach ($entry in $fileList) {
    try {
        # Sanitize the source path
        $sourcePath = $entry.Path -replace "`r|`n", "" -replace "\u00A0", " "  # Remove line breaks & non-breaking spaces
        $sourcePath = $sourcePath.Trim()

        $subFolder = $entry.SubFolder.Trim()
        $fileName = [System.IO.Path]::GetFileName($sourcePath)

        # Use Get-Item with -LiteralPath to safely handle special characters
        try {
            $sourceItem = Get-Item -LiteralPath $sourcePath -ErrorAction Stop
        } catch {
            Write-Host ("Warning: Source file not found: " + $sourcePath)
            Write-Log ("WARNING: Source file not found: " + $sourcePath)
            continue
        }

        # Create the subfolder in the destination if it doesn't exist
        $subFolderPath = Join-Path -Path $destinationPath -ChildPath $subFolder
        if (-not (Test-Path -Path $subFolderPath)) {
            New-Item -ItemType Directory -Path $subFolderPath -Force | Out-Null
            Write-Log ("Created subfolder: " + $subFolderPath)
        }

        # Define the destination file path
        $destinationFile = Join-Path -Path $subFolderPath -ChildPath $fileName

        # Use Copy-Item with -LiteralPath
        Copy-Item -LiteralPath $sourceItem.FullName -Destination $destinationFile -Force -ErrorAction Stop
        Write-Host ("Copied: " + $sourcePath + " → " + $destinationFile)
        Write-Log ("SUCCESS: Copied " + $sourcePath + " → " + $destinationFile)

    } catch {
        Write-Host ("Error copying " + $sourcePath + ": " + $_.Exception.Message)
        Write-Log ("ERROR: Failed to copy " + $sourcePath + " → " + $destinationFile + " - " + $_.Exception.Message)
    }
}

Write-Host "File copy process completed."
Write-Log "INFO: File copy process completed."
