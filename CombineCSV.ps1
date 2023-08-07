# Set the import folder path
$sourceFolder = "C:\Users\ddehoyos\Desktop\BatchesWorkbench"

# Set the ouput file path
$outputFile = "C:\Users\ddehoyos\Desktop\BatchesWorkbench\Cobmined.csv"

# Get all CSV files in the source folder
$csvFiles = Get-ChildItem $sourceFolder -Filter "*.csv"

# Initialize an empty array to hold the data
$combineData = @()

# Loop through each CSV and append its data to the Combined CSV
foreach ($csvFile in $csvFiles) {
	$data = Import-Csv $csvFile.FullName
	$combinedData += $data
	
}

# Export the combined Csv
$combineData | Export-Csv -Path $outputFile -NoTypeInformation

# Getting permission eror
