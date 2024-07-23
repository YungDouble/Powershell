# Define the start and end strings to search for
$searchStringStart = "mark currentfile"
$searchStringEnd = "cleartomark"
# Define the replacement string
$replacementString = ""

# Get all .ps files in the directory recursively
$files = Get-ChildItem -Path "./" -Recurse -Filter "*.ps"

# Loop through each file
foreach ($file in $files) {
    # Read the content of the file as a single string
    $content = Get-Content $file.FullName -Raw
    
    # Initialize a variable to track changes
    $contentModified = $false

    # Loop until no more start and end markers are found
    do {
        # Find the start and end indices of the search strings
        $startIndex = $content.IndexOf($searchStringStart)
        $endIndex = $content.IndexOf($searchStringEnd, $startIndex + $searchStringStart.Length)
        
        # If both the start and end strings are found
        if ($startIndex -ge 0 -and $endIndex -ge 0) {
            # Get the content before the start string
            $before = $content.Substring(0, $startIndex)
            # Get the content after the end string
            $after = $content.Substring($endIndex + $searchStringEnd.Length)
            # Concatenate the content before the start string, the replacement string, and the content after the end string
            $content = $before + $replacementString + $after
            # Mark content as modified
            $contentModified = $true
        }
        else {
            # Exit the loop if no more markers are found
            break
        }
    } while ($true)

    # If the content was modified, write the updated content back to the file
    if ($contentModified) {
        Set-Content $file.FullName -Value $content
    }
}
