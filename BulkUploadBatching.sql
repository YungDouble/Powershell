# This is the parent directory for the files and sorted folders
$basePath = "E:\Bulk Uploads\Bulk_Upload_Batching_Tool\SET1"

# This sets that folder as your CWD (Current working directory)
Set-Location $basePath

# This grabs the *files* underneath the parent directory, ignoring sub directories
$files = Get-ChildItem $basePath | Where-Object {$_.PSIsContainer -eq $false}

# Starts iterating through each file
foreach ($file in $files) {
    # Split the base file name by underscore (creates an array with each part of the name seperated)
    $split = $file.BaseName -split ">"
    # Store the second item [1] in the array $split as the root folder name
    $root = "$basePath\$($split[1])"
    # Store the first item [0] in the array $split as the sub folder name
    $sub = "$root\$($split[0])\images"
    # Creates Sub Folders CSV
    $CSV = "$root\$($split[0])\CSV"
    # Creates CSV file
    $CSVfile = "Done.csv"

    # Check if the root folder exists, create it if not
    if (!(Test-Path $root -ErrorAction SilentlyContinue)) {
        New-Item $root -ItemType Directory | Out-Null
    }

    # Check if the sub folder exists, create it if not
    if (!(Test-Path $sub -ErrorAction SilentlyContinue)) {
        New-Item $sub -ItemType Directory | Out-Null
    }

    # Check if the CSV folder exists, create it if not
    if (!(Test-Path $CSV -ErrorAction SilentlyContinue)) {
        New-Item $CSV -ItemType Directory | Out-Null
    }
    
    # Check if the CSV File exists, create it if not   
    New-Item "$CSV\$CSVfile" -ItemType file | Out-Null 
    
    # Move the file to the sub folder
    Move-Item $file.FullName -Destination $sub -Verbose
    
}

