# List of target filenames to search for (add your filenames here)
$targetFilenames = @(
    "resume_john_doe.pdf",
    "contract_jane_smith.docx",
    "id_michael_brown.jpg"
)

# Define destination folder path
$destinationFolder = Join-Path -Path (Get-Location) -ChildPath "PersonnelFiles"

# Create destination folder if it doesn't exist
if (-not (Test-Path $destinationFolder)) {
    New-Item -Path $destinationFolder -ItemType Directory | Out-Null
}

# Search and copy matching files
Get-ChildItem -Recurse -File | ForEach-Object {
    if ($targetFilenames -contains $_.Name) {
        $destinationPath = Join-Path -Path $destinationFolder -ChildPath $_.Name

        # If a file with the same name already exists, append a number
        $counter = 1
        while (Test-Path $destinationPath) {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
            $ext = [System.IO.Path]::GetExtension($_.Name)
            $destinationPath = Join-Path $destinationFolder "$baseName`_$counter$ext"
            $counter++
        }

        Copy-Item -Path $_.FullName -Destination $destinationPath
        Write-Host "Copied $($_.FullName) to $destinationPath"
    }
}
