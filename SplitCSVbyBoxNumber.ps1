<# 
.SYNOPSIS
    This script reads a CSV file, groups its rows based on the 'BoxNumber' column, 
    and exports each group to a separate CSV file.

.DESCRIPTION
    - The script assumes the input CSV file is named 'input.csv' and located in the current directory.
    - It checks for the existence of the file before proceeding.
    - The CSV data is imported and grouped by the 'BoxNumber' column.
    - Each group is then exported as a separate CSV file, named after the respective 'BoxNumber'.
    - The resulting CSV files are saved in the same directory as the script.

.PARAMETER inputCsvPath
    The file path of the input CSV. Defaults to './input.csv'.

.PARAMETER outputDirectory
    The directory where the split CSV files will be saved. Defaults to the current directory.

.OUTPUTS
    Separate CSV files for each unique 'BoxNumber', named as '<BoxNumber>.csv'.

.NOTES
    Author: Davos DeHoyos
    Date: 2025-03-16
    Version: 1.0
    PowerShell Version: 5.1+ (compatible with later versions)

.EXAMPLE
    PS> .\SplitCsvByBoxNumber.ps1
    This runs the script and creates multiple CSV files based on the 'BoxNumber' column in 'input.csv'.

#>

# Define the input CSV file path (assumes it's in the current directory)
$inputCsvPath = "./input.csv"

# Define the output directory (same as current directory)
$outputDirectory = "./"

# Check if the input file exists
if (-not (Test-Path -Path $inputCsvPath)) {
    Write-Host "Input file 'input.csv' not found in the current directory."
    exit
}

# Import the CSV
$data = Import-Csv -Path $inputCsvPath

# Group the rows by the 'BoxNumber' column
$groupedData = $data | Group-Object -Property BoxNumber

# Iterate through each group and export to separate CSV files
foreach ($group in $groupedData) {
    # Create a filename based on the BoxNumber value
    $boxNumber = $group.Name
    $outputFile = Join-Path -Path $outputDirectory -ChildPath "$boxNumber.csv"

    # Export the rows in the group to the file
    $group.Group | Export-Csv -Path $outputFile -NoTypeInformation -Force
    Write-Host "Exported BoxNumber '$boxNumber' to $outputFile"
}

Write-Host "Splitting completed. CSVs saved in the current directory."
