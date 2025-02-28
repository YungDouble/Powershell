<#
    SCRIPT: ExtractDatesFromCSV.ps1
    DESCRIPTION:
        This PowerShell script reads a CSV file containing filenames, extracts dates embedded in the filenames,
        and outputs a new CSV file with the original filenames and their corresponding extracted dates.

    PRECONDITIONS:
        - The input CSV file must exist in the specified location.
        - The CSV must contain a column named "CustomDocumentName".
        - The filenames must contain at least one recognizable date format.

    POSTCONDITIONS:
        - A new CSV file is generated, containing two columns:
            1. Filename (original input value)
            2. ExtractedDate (extracted date or "No Date Found" if no date was detected)

    EXPECTED CSV HEADER:
        "CustomDocumentName"
        Example:
        ---------------------------------
        CustomDocumentName
        2023-03-31_Leonti Taya_AP.pdf
        2023.03.31_Leonti Taya_AP.pdf
        March 2023_Leonti Taya_AP.pdf
        2023-2024_Leonti Taya_AP.pdf

    SUPPORTED DATE FORMATS:
        - YYYY-MM-DD (e.g., 2023-03-31)
        - YYYY.MM.DD (e.g., 2023.03.31)
        - YYYYMMDD (e.g., 20230331)
        - YYYY Month (e.g., 2023 March)
        - Month YYYY (e.g., March 2023)
        - MM-DD-YYYY (e.g., 03-31-2023)
        - YYYY-YYYY (e.g., 2023-2024)
        - YYYY-MM (e.g., 2023-03)

    ERROR HANDLING:
        - Checks if the input file exists.
        - Ensures the CSV contains the expected column.
        - Skips empty or malformed filename entries.
        - Prints debug information to assist with troubleshooting.

    AUTHOR: DD
    DATE: 2/27/2025
#>


# Import CSV file
$inputFile = "./input.csv"
$outputFile = "./output.csv"

# Ensure input file exists
if (!(Test-Path $inputFile)) {
    Write-Host "Error: Input file not found at $inputFile"
    exit
}

# Read CSV with correct encoding
$data = Import-Csv -Path $inputFile -Encoding UTF8

# Debug: Print CSV structure
Write-Host "Checking CSV Structure..."
$data | Format-Table -AutoSize | Out-String | Write-Host

# Ensure correct column header
$columnName = "CustomDocumentName"

# Check if column exists in CSV
if (-not ($data | Get-Member -Name $columnName)) {
    Write-Host "Error: Column '$columnName' not found in CSV file. Check your headers."
    exit
}

# Debug: Print raw input values
Write-Host "Debug: Printing first 5 filenames from CSV..."
$data | Select-Object -First 5 | ForEach-Object { Write-Host "Row: '$($_.$columnName)'" }

# Enhanced Regular Expressions to match additional date formats
$datePatterns = @(
    "\b\d{4}-\d{2}-\d{2}\b",                      # YYYY-MM-DD
    "\b\d{4}\.\d{2}\.\d{2}\b",                    # YYYY.MM.DD
    "\b\d{8}\b",                                  # YYYYMMDD
    "\b\d{4}\s(?:January|February|March|April|May|June|July|August|September|October|November|December)\b", # YYYY Month
    "\b(?:January|February|March|April|May|June|July|August|September|October|November|December)\s\d{4}\b", # Month YYYY
    "\b\d{2}-\d{2}-\d{4}\b",                      # MM-DD-YYYY
    "\b\d{4}-\d{4}\b",                            # YYYY-YYYY
    "\b\d{4}-\d{2}\b"                             # YYYY-MM
)

# Process each row and extract date
$results = $data | ForEach-Object {
    $filename = $_.$columnName  # Correct column reference

    if (-not $filename -or $filename -match "^\s*$") {
        Write-Host "Warning: Empty or malformed filename entry detected. Skipping."
        return
    }

    Write-Host "Processing: $filename"

    # Try matching multiple date formats
    $dateExtracted = "No Date Found"
    foreach ($pattern in $datePatterns) {
        $match = [regex]::Match($filename, $pattern)
        if ($match.Success) {
            $dateExtracted = $match.Groups[0].Value
            Write-Host "Match found: $dateExtracted"
            break  # Stop at first successful match
        }
    }

    if ($dateExtracted -eq "No Date Found") {
        Write-Host "No date found in: $filename"
    }

    [PSCustomObject]@{
        Filename = $filename
        ExtractedDate = $dateExtracted
    }
}

# Export results to CSV
$results | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
Write-Host "Date extraction complete. Output saved to $outputFile"
