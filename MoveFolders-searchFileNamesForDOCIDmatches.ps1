# Load DocIDs
$docIdCsvPath = ".\DocIDs.csv"
$csvData = Import-Csv -Path $docIdCsvPath
$firstColumn = ($csvData | Get-Member -MemberType NoteProperty | Select-Object -First 1).Name
$docIDs = $csvData | Select-Object -ExpandProperty $firstColumn | ForEach-Object { $_.Trim() }

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

# Get all PDF files recursively
$pdfFiles = Get-ChildItem -Path $baseDirectory -Filter "*.pdf" -Recurse

# HashSet for moved folders
$matchedFolders = @{}

# Check PDF filenames against DocIDs
foreach ($file in $pdfFiles) {
    $fileName = $file.Name
    $folderPath = $file.Directory.FullName  # Get the folder containing the file

    foreach ($docID in $docIDs) {
        if ($fileName -match [regex]::Escape($docID)) {
            Write-Output "✅ MATCH FOUND: [$fileName] contains [$docID]"

            # Move the **entire parent folder** (up to 2 levels)
            $parentFolder = (Get-Item $folderPath).Parent.FullName
            if ($parentFolder -and $parentFolder -ne $baseDirectory) {
                if (-not $matchedFolders.ContainsKey($parentFolder)) {
                    Write-Output "🚀 Moving Folder: $parentFolder to $newLocation"
                    Move-Item -Path $parentFolder -Destination $newLocation -Force
                    $matchedFolders[$parentFolder] = $parentFolder
                }
            }
            break
        }
    }
}

# Log moved folders
$matchedFolders.GetEnumerator() | Select-Object @{Name="FolderPath";Expression={$_.Value}} |
    Export-Csv -Path "$baseDirectory\matched_folders.csv" -NoTypeInformation

Write-Output "✅ Process Complete! Matched folders have been moved to $newLocation."
Write-Output "📄 A record of matched folders has been saved in matched_folders.csv."
