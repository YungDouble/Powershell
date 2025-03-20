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

# Regular Expressions for Date Patterns (Using Word Boundaries)
$datePatterns = @(
    "\b\d{4}-\d{2}-\d{2}\b",                        # YYYY-MM-DD
    "\b\d{4}\.\d{2}\.\d{2}\b",                      # YYYY.MM.DD
    "\b\d{8}\b",                                    # YYYYMMDD
    "\b\d{4}-\d{1,2}-\d{1,2}\b",                    # YYYY-M-D
    "\b\d{4}_\d{1,2}_\d{1,2}\b",                    # YYYY_M_D
    "\b\d{1,2}\.\d{1,2}\.\d{2,4}\b",                # M.D.YY or M.D.YYYY (e.g., 4.18.23)
    "\b\d{1,2}-\d{1,2}-\d{2,4}\b",                  # M-D-YY or M-D-YYYY
    "\b\d{2}-\d{2}-\d{2}\b",                        # MM-DD-YY
    "\b\d{2}\.\d{2}\.\d{2,4}\b",                    # MM.DD.YY or MM.DD.YYYY
    "\b\d{4}-\d{4}\b",                              # YYYY-YYYY (academic years)
    "(?<year>\d{4})[-_.](?<month>\d{1,2})[-_.](?<day>\d{1,2})",  # YYYY-MM-DD, YYYY_M_D (Fixes Underscore)
    "(?<month>\d{1,2})[-_.](?<day>\d{1,2})[-_.](?<year>\d{4})",  # MM-DD-YYYY, MM_DD_YYYY
    "(?<month>\d{1,2})[-_.](?<day>\d{1,2})[-_.](?<year>\d{2})",  # MM-DD-YY
    "\b\d{4}\b"                                     # Standalone Year YYYY
)

# Function to Convert Date to M/D/YYYY Format
function Convert-ToShortDate ($year, $month, $day) {
    try {
        if ($year -lt 1900 -or $year -gt 2099) { return "No Date Found" }
        if ($month -lt 1 -or $month -gt 12) { return "No Date Found" }
        if ($day -lt 1 -or $day -gt 31) { return "No Date Found" }
        return "$month/$day/$year"  # Short date format
    }
    catch {
        return "No Date Found"
    }
}

# Process Each Row
$results = @()
foreach ($row in $data) {
    $filename = $row.$columnName
    if (-not $filename) { continue }

    Write-Host "`nProcessing: $filename"
    
    $dateExtracted = "No Date Found"

    foreach ($pattern in $datePatterns) {
        $match = [regex]::Match($filename, $pattern)
        if ($match.Success) {
            $year = [int]$match.Groups["year"].Value
            $month = [int]$match.Groups["month"].Value
            $day = [int]$match.Groups["day"].Value

            $dateExtracted = Convert-ToShortDate $year $month $day
            if ($dateExtracted -ne "No Date Found") { break }
        }
    }

    $results += [PSCustomObject]@{ Filename = $filename; ExtractedDate = $dateExtracted }
}

# Export Results
$results | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
Write-Host "Processing complete. Output saved to $outputFile"
