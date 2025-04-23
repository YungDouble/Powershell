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

    # Copy the file
    try {
        Copy-Item -Path $sourcePath -Destination $destinationFile -Force -ErrorAction Stop
        Write-Host "Copied: $sourcePath → $destinationFile"
        Write-Log "SUCCESS: Copied $sourcePath → $destinationFile"
    } catch {
        Write-Host "Failed to copy $sourcePath - $($_.Exception.Message)"
        Write-Log "ERROR: Failed to copy $sourcePath → $destinationFile - $($_.Exception.Message)"
    }
}

Write-Host "✅ Copy process complete."
Write-Log "INFO: Copy process complete."
