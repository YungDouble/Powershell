# Load DocIDs
$docIdCsvPath = ".\DocIDs.csv"
$csvData = Import-Csv -Path $docIdCsvPath

# Detect first column name dynamically
$firstColumn = ($csvData | Get-Member -MemberType NoteProperty | Select-Object -First 1).Name

# Clean and format DocIDs
$docIDs = $csvData | Select-Object -ExpandProperty $firstColumn | ForEach-Object { $_ -replace '[^\x20-\x7E]', '' -replace '\s', '' }

Write-Output "📄 Loaded DocIDs from CSV:"
$docIDs | ForEach-Object { Write-Output "🔹 [$($_)]" }

# Set base directories
$baseDirectory = Get-Location
$newLocation = "$baseDirectory\NewLocation"

# Ensure NewLocation exists
if (!(Test-Path $newLocation)) {
    New-Item -ItemType Directory -Path $newLocation | Out-Null
}

# Define base level to preserve in the directory structure
$baseLevel = "Active"

# Get all PDF files recursively
$pdfFiles = Get-ChildItem -Path $baseDirectory -Filter "*.pdf" -Recurse

Write-Output "📂 Scanning PDF files..."
$matchedFolders = @{}

# Process each file
foreach ($file in $pdfFiles) {
    $fileName = $file.Name
    $filePath = $file.FullName
    $folderPath = $file.Directory.FullName

    Write-Output "🔍 Checking: $fileName"

    foreach ($docID in $docIDs) {
        if ($fileName -match [regex]::Escape($docID)) {
            Write-Output "✅ MATCH FOUND: [$fileName] contains [$docID]"

            # Extract the relative path from the base level onward
            $relativePath = $filePath.Replace($baseDirectory, "").Trim("\")
            $baseStartIndex = $relativePath.IndexOf($baseLevel)

            if ($baseStartIndex -ge 0) {
                $finalRelativePath = $relativePath.Substring($baseStartIndex)
                $destinationFolder = "$newLocation\$($finalRelativePath | Split-Path -Parent)"

                # Ensure parent directories are created
                if (!(Test-Path $destinationFolder)) {
                    New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
                }

                # Copy the matched file only
                $destinationFile = "$destinationFolder\$fileName"
                Copy-Item -Path $filePath -Destination $destinationFile -Force

                Write-Output "📂 Copied File: $filePath -> $destinationFile"

                # Log copied structure
                $matchedFolders[$filePath] = $destinationFile
            }

            break  # Stop checking once a match is found
        }
    }
}

# Log copied files
$matchedFolders.GetEnumerator() | Select-Object @{Name="OriginalPath";Expression={$_.Key}}, @{Name="CopiedTo";Expression={$_.Value}} |
    Export-Csv -Path "$baseDirectory\matched_files.csv" -NoTypeInformation

Write-Output "✅ Process Complete! Matched files have been copied to $newLocation."
Write-Output "📄 A record of copied files has been saved in matched_files.csv."
