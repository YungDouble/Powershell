<#
    ExtractDatesFromCSV.ps1
    DESCRIPTION:
        Extracts and standardizes dates from a column in a CSV file.
        Adds a new column 'ExtractedDate' while preserving all original data.
#>

# Define input and output file paths
$inputFile = "./input.csv"
$outputFile = "./output.csv"

# The column that contains the filenames/text to extract from
$columnName = "CustomDocumentName"

# Ensure input file exists
if (!(Test-Path $inputFile)) {
    Write-Host "Error: Input file not found at $inputFile"
    exit
}

# Read CSV
$data = Import-Csv -Path $inputFile -Encoding UTF8

# Ensure column exists
if (-not ($data | Get-Member -Name $columnName)) {
    Write-Host "Error: Column '$columnName' not found in CSV."
    exit
}

# Regex patterns to match various date formats
$datePatterns = @(
    "(?<year>\d{4})[-_](?<month>\d{1,2})[-_](?<day>\d{1,2})(?=\b|[^0-9])",  # 2023-05-12 or 2023_05_12
    "(?<month>\d{1,2})[-](?<day>\d{1,2})[-](?<year>\d{2,4})(?=\b|[^0-9])",   # 05-12-2023 or 05-12-23
    "(?<month>\d{1,2})/(?<day>\d{1,2})/(?<year>\d{2,4})(?=\b|[^0-9])",       # 5/12/2023 or 5/12/23
    "(?<month>\d{1,2})\.(?<day>\d{1,2})\.(?<year>\d{2,4})(?=\b|[^0-9])",     # 5.12.2023
    "(?<month>\d{1,2})(?<day>\d{1,2})(?<year>\d{4})(?=\b|[^0-9])",           # 05122023 (no separators)

    # Month names
    "(?<monthName>(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*)\s*(?<day>\d{1,2})(?:[/-](?<year>\d{2,4}))?",

    # Year-only LAST
    "(?<year>\d{4})(?=\b|[^0-9])"
)

# Month name to number map
$monthMap = @{
    jan = 1; feb = 2; mar = 3; apr = 4; may = 5; jun = 6;
    jul = 7; aug = 8; sep = 9; oct = 10; nov = 11; dec = 12
}

# Function to convert YY to YYYY
function Convert-YYToYYYY ($yy) {
    $yy = [int]$yy
    if ($yy -lt 25) { return "20$yy" } else { return "19$yy" }
}

# Function to format a date as YYYY-MM-DD
function Convert-ToDate ($year, $month, $day) {
    if ($year -match "^\d{4}$" -and $month -match "^\d{2}$" -and $day -match "^\d{2}$") {
        $month = [int]$month
        $day = [int]$day
        if (($month -ge 1 -and $month -le 12) -and ($day -ge 1 -and $day -le 31)) {
            return "{0:D4}-{1:D2}-{2:D2}" -f $year, $month, $day
        }
    }
    return "No Date Found"
}

# Process each row and add ExtractedDate
$updated = foreach ($row in $data) {
    $filename = $row.$columnName
    $dateExtracted = "No Date Found"

    if ($filename -and $filename -notmatch "^\s*$") {
        $normalized = $filename -replace "_", "-"

        # 🧹 Clean junk words like "DOB", "PERM", "TEMP", etc.
        $normalized = $normalized -replace "(?i)\b(DOB|PERM|PERMANENT|TEMPORARY|TEMP|STUDENT CARD|PERMANENT FILE|PERM STUDENT CARD)\b", ""
        $normalized = $normalized.Trim()

        foreach ($pattern in $datePatterns) {
            $match = [regex]::Match($normalized, $pattern)
            if ($match.Success) {
                if ($match.Groups["year"].Success -and $match.Groups["month"].Success -and $match.Groups["day"].Success) {
                    $year = $match.Groups["year"].Value
                    $month = $match.Groups["month"].Value
                    $day = $match.Groups["day"].Value

                    # Normalize
                    if ($year.Length -eq 2) { $year = Convert-YYToYYYY $year }
                    if ($month.Length -eq 1) { $month = "0$month" }
                    if ($day.Length -eq 1) { $day = "0$day" }

                    $dateExtracted = Convert-ToDate $year $month $day
                }
                elseif ($match.Groups["monthName"].Success -and $match.Groups["day"].Success) {
                    $monthText = $match.Groups["monthName"].Value.ToLower()
                    $month = $monthMap[$monthText.Substring(0,3)]
                    $day = $match.Groups["day"].Value
                    $year = if ($match.Groups["year"].Success) {
                        $val = $match.Groups["year"].Value
                        if ($val.Length -eq 2) { Convert-YYToYYYY $val } else { $val }
                    } else { "2000" } # Default year if none

                    # Pad day if needed
                    if ($day.Length -eq 1) { $day = "0$day" }
                    $dateExtracted = Convert-ToDate $year $month $day
                }
                elseif ($match.Groups["year"].Success) {
                    # Only year found
                    $dateExtracted = Convert-ToDate $match.Groups["year"].Value "01" "01"
                }

                if ($dateExtracted -ne "No Date Found") { break }
            }
        }
    }

    # Add the ExtractedDate while preserving all original fields
    $newRow = $row.PSObject.Copy()
    $newRow | Add-Member -NotePropertyName "ExtractedDate" -NotePropertyValue $dateExtracted
    $newRow
}

# Export
$updated | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
Write-Host "✅ Done! Output saved to $outputFile"
