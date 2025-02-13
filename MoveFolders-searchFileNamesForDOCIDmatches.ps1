<#
.SYNOPSIS
    This script scans a directory and all its subdirectories for PDF files.
    If a file's name contains a DocID from "DocIDs.csv", it **copies the full folder path** 
    (starting from "Active/Campus/...") to a "NewLocation" folder, preserving the original structure.

.DESCRIPTION
    - Reads a list of DocIDs from "DocIDs.csv".
    - Recursively scans all subdirectories for PDF files.
    - If a filename matches a DocID, it determines the **full path starting from a base level**.
    - Recreates the folder structure in "NewLocation" and copies the entire folder contents.

.REQUIREMENTS
    - PowerShell 5.0+ recommended.
    - "DocIDs.csv" should be formatted with a single column named "DocID".
    - Script must be run from the root directory where the folders/files are located.

.OUTPUTS
    - Matched folders are copied to "NewLocation" with their full structure preserved.
    - "matched_folders.csv" logs all copied directories.

.VERSION
    2.2

.AUTHOR
    Davos DeHoyos

.NOTES
    - The script **copies** (does not move) files to maintain the original directory.
    - If a DocID is not found in any file, no folders will be copied.
#>

# Load DocIDs
$docIdCsvPath = ".\DocIDs.csv"
$csvData = Import-Csv -Path $docIdCsvPath

# Detect first column name dynamically
$firstColumn = ($csvData | Get-Member -MemberType NoteProperty | Select-Object -First 1).Name

# Clean and format DocIDs to remove hidden characters
$docIDs = $csvData | Select-Object -ExpandProperty $firstColumn | ForEach-Object { $_ -replace '[^\x20-\x7E]', '' -replace '\s', '' }

# Log loaded DocIDs
Write-Output "📄 Loaded DocIDs from CSV:"
$docIDs | ForEach-Object { Write-Output "🔹 [$($_)]" }

# Set directories
$baseDirectory = Get-Location
$newLocation = "$baseDirectory\NewLocation"

# Ensure destination folder exists
if (!(Test-Path $newLocation)) {
    New-Item -ItemType Directory -Path $newLocation | Out-Null
}

# Define the base path level to preserve (modify as needed)
$baseLevel = "Active"  # Change this if needed

# Get all PDF files recursively
$pdfFiles = Get-ChildItem -Path $baseDirectory -Filter "*.pdf" -Recurse

Write-Output "📂 Listing all detected PDF files:"
$pdfFiles | ForEach-Object { Write-Output "📄 Found: $_.FullName" }

# HashSet for copied folders
$matchedFolders = @{}

# Check PDF filenames against DocIDs
foreach ($file in $pdfFiles) {
    $fileName = $file.Name
    $filePath = $file.FullName
    $folderPath = $file.Directory.FullName  # Get the folder containing the file

    Write-Output "🔍 Checking File: $fileName"

    foreach ($docID in $docIDs) {
        Write-Output "   🔹 Checking against DocID: $docID"

        if ($fileName -match [regex]::Escape($docID)) {
            Write-Output "✅ MATCH FOUND: [$fileName] contains [$docID]"

            # Find the starting point for the path structure (Active/Campus/Letter/Student)
            $relativePath = $folderPath.Replace($baseDirectory, "").Trim("\")  # Get relative path
            $baseStartIndex = $relativePath.IndexOf($baseLevel)
            
            if ($baseStartIndex -ge 0) {
                $finalRelativePath = $relativePath.Substring($baseStartIndex)
                $destinationPath = "$newLocation\$finalRelativePath"

                Write-Output "🚀 Copying Full Path Structure: $folderPath -> $destinationPath"

                # Create directory structure in NewLocation
                if (!(Test-Path $destinationPath)) {
                    New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
                }

                # Copy the entire directory (including subdirectories)
                Copy-Item -Path $folderPath -Destination $destinationPath -Recurse -Force

                # Track copied folders
                $matchedFolders[$folderPath] = $destinationPath
            }

            break
        }
    }
}

# Log copied folders
$matchedFolders.GetEnumerator() | Select-Object @{Name="OriginalPath";Expression={$_.Key}}, @{Name="CopiedTo";Expression={$_.Value}} |
    Export-Csv -Path "$baseDirectory\matched_folders.csv" -NoTypeInformation

Write-Output "✅ Process Complete! Matched folders have been copied to $newLocation."
Write-Output "📄 A record of copied folders has been saved in matched_folders.csv."
