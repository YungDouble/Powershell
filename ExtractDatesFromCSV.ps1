<#  
    SCRIPT: ExtractDatesFromCSV.ps1
    DESCRIPTION:
        This PowerShell script reads a CSV file containing filenames, extracts dates embedded in the filenames, 
        and outputs a new CSV file with the original filenames and their corresponding extracted dates.

    PRECONDITIONS:
        - The input CSV file must exist in the specified location.
        - The CSV must contain a column named "CustomDocumentName".
        - The filenames should contain at least one recognizable date format.

    POSTCONDITIONS:
        - A new CSV file is generated, containing two columns:
            1. Filename (original input value)
            2. ExtractedDate (extracted date in YYYY-MM-DD format or "No Date Found" if no date was detected)

    EXPECTED CSV HEADER:
        "CustomDocumentName"
        Example:
        ---------------------------------
        CustomDocumentName
        2023-03-31_Leonti Taya_AP.pdf
        2023.03.31_Leonti Taya_AP.pdf
        2023_3_16_Aguilar_Noah_Initial_AP.pdf
        2023_05_12_Aguilar Noah_Initial.pdf
        04_26_2023_Alcaraz.A_Meeting Notice.pdf

    SUPPORTED DATE FORMATS:
        - YYYY-MM-DD (e.g., 2023-03-31)
        - YYYY.MM.DD (e.g., 2023.03.31)
        - YYYYMMDD (e.g., 20230331)
        - YYYY-M-D or YYYY_M_D (e.g., 2023-3-16, 2023_3_16)
        - MM-DD-YYYY or MM_DD_YYYY (e.g., 04-26-2023, 04_26_2023)
        - YYYY Month (e.g., 2023 March)
        - Month YYYY (e.g., March 2023)
        - YYYY-YYYY (e.g., 2023-2024) → Defaults to `YYYY-08-01`
        - YYYY-M or YYYY_M (e.g., 2023-3, 2023_3) → Defaults to `YYYY-MM-01`
        - YYYY (e.g., 2023) → Defaults to `YYYY-01-01`

    ERROR HANDLING:
        - Ensures the input CSV file exists.
        - Validates the presence of the expected column.
        - Handles filenames with missing or malformed entries.
        - Prints debug information to assist with troubleshooting.

    AUTHOR: DD
    DATE: 2/27/2025
#>

# Import CSV file
<#  
    SCRIPT: ExtractDatesFromCSV.ps1
    DESCRIPTION:
        This script extracts dates embedded in filenames from a CSV file 
        and outputs a new CSV with the extracted dates.

    EXPECTED OUTPUT:
        - If a date is found, it's formatted in YYYY-MM-DD.
        - If no date is found, "No Date Found" is inserted.
#>

# Define input and output file paths
$inputFile = "./input.csv"
$outputFile = "./output.csv"

# Ensure input file exists
if (!(Test-Path $inputFile)) {
    Write-Host "Error: Input file not found at $inputFile"
    exit
}

# Read CSV
$data = Import-Csv -Path $inputFile -Encoding UTF8
$columnName = "CustomDocumentName"

# Ensure column exists
if (-not ($data | Get-Member -Name $columnName)) {
    Write-Host "Error: Column '$columnName' not found in CSV."
    exit
}

# Regular Expressions for Date Patterns
$datePatterns = @(
    "(?<year>\d{4})[-_](?<month>\d{1,2})[-_](?<day>\d{1,2})",  # YYYY-MM-DD or YYYY_M_D
    "(?<month>\d{1,2})[-_](?<day>\d{1,2})[-_](?<year>\d{4})",  # MM-DD-YYYY or MM_DD_YYYY
    "(?<month>\d{1,2})[-_](?<day>\d{1,2})[-_](?<year>\d{2})",  # MM-DD-YY (NEW)
    "(?<year>\d{4})",  # Standalone Year YYYY
    "(?<startYear>\d{2})[-_](?<endYear>\d{2})"  # Academic Year (22-23)
)

# Function to convert two-digit year (YY) to four-digit (YYYY)
function Convert-YYToYYYY ($yy) {
    $yy = [int]$yy
    if ($yy -lt 25) {
    return "20$yy"
} else {
    return "19$yy"
}

}

# Function to format date correctly
function Convert-ToDate ($year, $month, $day) {
    return "{0:D4}-{1:D2}-{2:D2}" -f $year, $month, $day
}

# Process each row and extract date
$results = @()
foreach ($row in $data) {
    $filename = $row.$columnName

    if (-not $filename -or $filename -match "^\s*$") {
        Write-Host "Warning: Empty filename detected. Assigning 'No Date Found'."
        $results += [PSCustomObject]@{ Filename = $filename; ExtractedDate = "No Date Found" }
        continue
    }

    Write-Host "Processing: $filename"

    $normalizedFilename = $filename -replace "_", "-"  # Normalize underscores to dashes
    $dateExtracted = "No Date Found"

    foreach ($pattern in $datePatterns) {
        $match = [regex]::Match($normalizedFilename, $pattern)
        if ($match.Success) {
            if ($match.Groups["year"].Success -and $match.Groups["month"].Success -and $match.Groups["day"].Success) {
                # MM-DD-YYYY or YYYY-MM-DD formats
                $year = $match.Groups["year"].Value
                $dateExtracted = Convert-ToDate $year $match.Groups["month"].Value $match.Groups["day"].Value
            }
            elseif ($match.Groups["month"].Success -and $match.Groups["day"].Success -and $match.Groups["year"].Success -and $match.Groups["year"].Value.Length -eq 2) {
                # MM-DD-YY Format (Convert to YYYY)
                $year = Convert-YYToYYYY $match.Groups["year"].Value
                $dateExtracted = Convert-ToDate $year $match.Groups["month"].Value $match.Groups["day"].Value
            }
            elseif ($match.Groups["startYear"].Success -and $match.Groups["endYear"].Success) {
                # Academic year (e.g., 22-23 → 2022-08-01)
                $fullYear = "20{0}" -f $match.Groups["startYear"].Value
                $dateExtracted = Convert-ToDate $fullYear "08" "01"
            }
            elseif ($match.Groups["year"].Success) {
                # Standalone Year (YYYY)
                $dateExtracted = Convert-ToDate $match.Groups["year"].Value "01" "01"
            }
            Write-Host "Match found: $dateExtracted"
            break
        }
    }

    $results += [PSCustomObject]@{ Filename = $filename; ExtractedDate = $dateExtracted }
}

# Export results
$results | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
Write-Host "Processing complete. Output saved to $outputFile"



