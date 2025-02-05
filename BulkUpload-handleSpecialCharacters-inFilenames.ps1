# Define the base directory where files are stored
$basePath = "./FileHolding"

# Output the base path for reference
Write-Output $basePath

# Get all files in the base directory (excluding directories)
$files = Get-ChildItem $basePath | Where-Object { $_.PSIsContainer -eq $false }

# Loop through each file found in the base directory
foreach ($file in $files) {
    # Output the base name of the file (filename without extension)
    Write-Output $file.BaseName

    # Split the filename using ">" as the delimiter
    $split = $file.BaseName -split ">"

    # Check if the filename follows the expected format (at least two parts after splitting)
    if ($split.Count -lt 2) {
        Write-Host "Skipping file (Invalid Format): $($file.Name)"
        continue  # Skip processing this file if the format is incorrect
    }

    # Construct directory paths based on the split filename
    $root = "$basePath\$($split[1])"            # Root directory
    $sub = "$root\$($split[0])\images"          # Subdirectory for images
    $CSV = "$root\$($split[0])\CSV"             # Subdirectory for CSV files
    $CSVfile = "Done.csv"                       # CSV filename

    # Output paths for debugging purposes
    Write-Output $root
    Write-Output $sub

    # Check if directories exist; if not, create them
    if (!(Test-Path $root -ErrorAction SilentlyContinue)) {
        New-Item $root -ItemType Directory | Out-Null
    }

    if (!(Test-Path $sub -ErrorAction SilentlyContinue)) {
        New-Item $sub -ItemType Directory | Out-Null
    }

    if (!(Test-Path $CSV -ErrorAction SilentlyContinue)) {
        New-Item $CSV -ItemType Directory | Out-Null
    }

    # Create an empty CSV file in the CSV directory
    New-Item "$CSV\$CSVfile" -ItemType file | Out-Null 

    # Check if the file already exists in the destination before moving
    if (Test-Path "$sub\$($file.Name)") {
        Write-Host "File already exists: $($file.Name), skipping..."
        continue  # Skip moving the file if it already exists
    }

    # Move the file to the images subdirectory, using -LiteralPath to handle special characters in filenames
    Move-Item -LiteralPath $file.FullName -Destination $sub -Verbose
}
