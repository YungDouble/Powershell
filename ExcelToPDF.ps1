$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

$sourceFolder = "C:\Path\To\Your\Files"
$files = Get-ChildItem -Path $sourceFolder -Recurse -Include *.xls, *.xlsx, *.xlsm

foreach ($file in $files) {
    try {
        $workbook = $excel.Workbooks.Open($file.FullName)
        $pdfPath = [System.IO.Path]::ChangeExtension($file.FullName, ".pdf")

        $workbook.ExportAsFixedFormat(0, $pdfPath)
        $workbook.Close($false)
        Write-Host "Converted: $($file.Name)"
    } catch {
        Write-Warning "Failed to convert: $($file.FullName)"
    }
}

$excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
