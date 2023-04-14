$filePath = "./*.ps"
$searchStringStart = "mark currentfile"
$searchStringEnd = "cleartomark"
$replacementString = ""

$content = Get-Content $filePath -Raw
$startIndex = $content.IndexOf($searchStringStart)
$endIndex = $content.IndexOf($searchStringEnd, $startIndex + $searchStringStart.Length)

if ($startIndex -ge 0 -and $endIndex -ge 0) {
	$before = $content.Substring(0, $startIndex)
	$after = $content.Substring($endIndex + $searchStringEnd.length)
	$content = $before + $replacementString + $after
	Set-Content $filePath -Value $content
}
