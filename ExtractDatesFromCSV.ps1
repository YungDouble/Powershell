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
    "\b\d{4}-\d{2}-\d{2}\b",                        # YYYY-MM-DD
    "\b\d{4}\.\d{2}\.\d{2}\b",                      # YYYY.MM.DD
    "\b\d{8}\b",                                    # YYYYMMDD
    "\b\d{4}-\d{1,2}-\d{1,2}\b",                    # YYYY-M-D (handles missing leading zeros)
    "\b\d{4}_\d{1,2}_\d{1,2}\b",                    # YYYY_M_D (underscore format)
    "\b\d{4}\s(?:January|February|March|April|May|June|July|August|September|October|November|December)\b", # YYYY Month
    "\b(?:January|February|March|April|May|June|July|August|September|October|November|December)\s\d{4}\b", # Month YYYY
    "\b\d{2}-\d{2}-\d{4}\b",                        # MM-DD-YYYY
    "\b\d{2}_\d{2}_\d{4}\b",                        # MM_DD_YYYY (underscore format)
    "\b\d{4}-\d{4}\b",                              # YYYY-YYYY (academic years)
    "\b\d{4}-\d{1,2}\b",                            # YYYY-M (year and month)
    "\b\d{4}\b"                                     # Standalone Year (YYYY)
    "\b\d{1,2}\.\d{1,2}\.\d{2,4}\b",                # M.D.YY or M.D.YYYY (e.g., 4.18.23)
    "\b\d{1,2}-\d{1,2}-\d{2,4}\b",                  # M-D-YY or M-D-YYYY (e.g., 9-26-22)
    "\b\d{2}-\d{2}-\d{2}\b",                        # MM-DD-YY (e.g., 06-21-21)
    "\b\d{2}\.\d{2}\.\d{2,4}\b",                    # MM.DD.YY or MM.DD.YYYY (e.g., 3.16.18)
    "\b\d{2}-\d{2}[A-Za-z]{2}\b"                    # Academic Year (e.g., 19-20SY)
)

# Process each row and extract date
$results = $data | ForEach-Object {
    $filename = $_.$columnName  # Correct column reference

    if (-not $filename -or $filename -match "^\s*$") {
        Write-Host "Warning: Empty or malformed filename entry detected. Skipping."
        return
    }

    Write-Host "Processing: $filename"

    # Replace underscores with dashes for consistency
    $normalizedFilename = $filename -replace "_", "-"

    # Try matching multiple date formats
    $dateExtracted = "No Date Found"
    foreach ($pattern in $datePatterns) {
        $match = [regex]::Match($normalizedFilename, $pattern)
        if ($match.Success) {
            $dateExtracted = $match.Groups[0].Value

            # Convert YYYY_M_D format to YYYY-MM-DD
            if ($dateExtracted -match "^\d{4}_\d{1,2}_\d{1,2}$") {
                $dateExtracted = $dateExtracted -replace "_", "-"
            }

            # Convert MM_DD_YYYY format to YYYY-MM-DD
            if ($dateExtracted -match "^\d{2}_\d{2}_\d{4}$") {
                $parts = $dateExtracted -split "_"
                $dateExtracted = "$($parts[2])-$($parts[0])-$($parts[1])"
            }

            # Handle academic years (e.g., 2023-2024 → default to first day of the academic year)
            if ($dateExtracted -match "^\d{4}-\d{4}$") {
                $dateExtracted = "$($dateExtracted.Substring(0,4))-08-01"
            }
            # Handle year-month (YYYY-M)
            elseif ($dateExtracted -match "^\d{4}-\d{1,2}$") {
                $dateExtracted += "-01"
            }
            # Handle standalone year (YYYY)
            elseif ($dateExtracted -match "^\d{4}$") {
                $dateExtracted += "-01-01"
            }
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
