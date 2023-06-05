// This script is used to remove lines in .ps files so that they can be converted to PDF 
// This is not to be shared outside YF
// Diese script

$searchStringStart = "mark currentfile"
$searchStringEnd = "cleartomark"
$replacementString = ""

# Get all .ps files in the directory
$files = Get-ChildItem -Path "./" -Recurse -Filter "*.ps"

foreach ($file in $files) {
$content = Get-Content $file.FullName -Raw
$startIndex = $content.IndexOf($searchStringStart)
$endIndex = $content.IndexOf($searchStringEnd, $startIndex + $searchStringStart.Length)

if ($startIndex -ge 0 -and $endIndex -ge 0){
$before = $content.Substring(0, $startIndex)
$after = $content.Substring($endIndex + $searchStringEnd.Length)
$content = $before + $replacementString + $after
Set-Content $file.FullName -Value $content
}
}
