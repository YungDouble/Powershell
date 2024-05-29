# This script is to convert .ps files to .pdf using gs
# Set the path to the Ghostscript executable
$ghostscriptPath = "C:\Program Files\gs\gs10.02.1\bin\gswin64c.exe"

# Set the root folder where you want to start the conversion
# this is set to be in the current folder, command: powershell__ise.exe to bring up the powershell console
$rootFolder = "./"

# Recursively find all .ps files in subfolders
$psFiles = Get-ChildItem -Path $rootFolder -Recurse -Filter *.ps

# Loop through each .ps file and convert to .pdf in the same folder
foreach ($psFile in $psFiles) {
    # Build the output PDF file path in the same folder
    $pdfFile = Join-Path -Path $psFile.Directory.FullName -ChildPath ($psFile.BaseName + '.pdf')

    # Execute the Ghostscript command
    & $ghostscriptPath -sDEVICE=pdfwrite -o $pdfFile $psFile.FullName

    # Output status
    Write-Host "Converted $($psFile.FullName) to $($pdfFile)"
}
