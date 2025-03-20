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

# Regular Expressions for Date Patterns (Updated)
$datePatterns = @(
    "(?<year>\d{4})[-_\. ]?(?<month>0?[1-9]|1[0-2])[-_\. ]?(?<day>0?[1-9]|[12]\d|3[01])",  # YYYY-MM-DD, YYYY_M_D
    "(?<month>0?[1-9]|1[0-2])[-_\. ]?(?<day>0?[1-9]|[12]\d|3[01])[-_\. ]?(?<year>\d{4})",  # MM-DD-YYYY, MM_DD_YYYY
    "(?<month>[1-9]|1[0-2])[-_\. ]?(?<day>[1-9]|[12]\d|3[01])[-_\. ]?(?<year>\d{2})",  # M-D-YY, M.D.YY (NEW)
    "(?<year>\d{4})",  # Standalone Year (YYYY)
    "(?<startYear>\d{2})[-_\. ]?(?<endYear>\d{2})",  # Academic Year (22-23)
    "(?<month>[1-9]|1[0-2])[-_\. ]?(?<day>[1-9]|[12]\d|3[01])[-_\. ]?(?<year>\d{2,4})"  # Handles `_6_1_23` (NEW)
)

# Function to convert two-digit year (YY) to four-digit (YYYY)
function Convert-YYToYYYY ($yy) {
    $yy = [int]$yy
    if ($yy -lt 25) {  
        return "20$yy"  # If it's 00-24, assume 2000-2024
    } else {  
        return "19$yy"  # If it's 25-99, assume 1925-1999
    }
}

# Function to validate and format a date correctly
function Convert-ToDate ($year, $month, $day) {
    $dateString = "{0:D4}-{1:D2}-{2:D2}" -f $year, $month, $day
    try {
        $validDate = [datetime]::ParseExact($dateString, "yyyy-MM-dd", $null)
        return $validDate.ToString("yyyy-MM-dd")  # Returns only if valid
    }
    catch {
        return "No Date Found"  # Rejects invalid dates
    }
}

# Function to validate extracted years
function IsValidYear ($year) {
    return ($year -ge 1900 -and $year -le 2099)
}

# Normalize filename by replacing multiple spaces, underscores, and dashes
function Normalize-Filename ($filename) {
    $filename = $filename -replace "[_ \.-]+", "-"  # Convert all separators to single dashes
    $filename = $filename -replace "\s+", ""  # Remove extra spaces
    return $filename
}

# Remove file extensions from filenames
function Remove-FileExtension ($filename) {
    return ($filename -replace "\.(docx|doc|pdf|txt|xls|xlsx|html|jpg)$", "")  # Remove common file extensions
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

    # Remove file extension before extraction
    $cleanFilename = Remove-FileExtension $filename

    # Normalize filename (removes extra spaces, converts separators to "-")
    $normalizedFilename = Normalize-Filename $cleanFilename
    $dateExtracted = "No Date Found"

    foreach ($pattern in $datePatterns) {
        $match = [regex]::Match($normalizedFilename, $pattern)
        if ($match.Success) {
            if ($match.Groups["year"].Success -and $match.Groups["month"].Success -and $match.Groups["day"].Success) {
                # YYYY-MM-DD or MM-DD-YYYY formats
                $year = [int]$match.Groups["year"].Value
                $month = [int]$match.Groups["month"].Value
                $day = [int]$match.Groups["day"].Value
                if (IsValidYear $year) {
                    $dateExtracted = Convert-ToDate $year $month $day
                }
            }
            elseif ($match.Groups["month"].Success -and $match.Groups["day"].Success -and $match.Groups["year"].Success -and $match.Groups["year"].Value.Length -eq 2) {
                # MM-DD-YY or M-D-YY Format (Convert to YYYY)
                $year = Convert-YYToYYYY $match.Groups["year"].Value
                $month = [int]$match.Groups["month"].Value
                $day = [int]$match.Groups["day"].Value
                if (IsValidYear $year) {
                    $dateExtracted = Convert-ToDate $year $month $day
                }
            }
            elseif ($match.Groups["startYear"].Success -and $match.Groups["endYear"].Success) {
                # Academic Year (e.g., 22-23 → 2022-08-01)
                $fullYear = "20{0}" -f $match.Groups["startYear"].Value
                if (IsValidYear $fullYear) {
                    $dateExtracted = Convert-ToDate $fullYear "08" "01"
                }
            }
            elseif ($match.Groups["year"].Success) {
                # Standalone Year (YYYY)
                $year = [int]$match.Groups["year"].Value
                if (IsValidYear $year) {
                    $dateExtracted = Convert-ToDate $year "01" "01"
                }
            }

            # Validate extracted date
            if ($dateExtracted -ne "No Date Found") {
                Write-Host "Valid Date Extracted: $dateExtracted"
                break
            }
        }
    }

    $results += [PSCustomObject]@{ Filename = $filename; ExtractedDate = $dateExtracted }
}

# Export results
$results | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
Write-Host "Processing complete. Output saved to $outputFile"
