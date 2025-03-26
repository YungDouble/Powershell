# Excel conversion setup
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

# Word conversion setup
$word = New-Object -ComObject Word.Application
$word.Visible = $false

$sourceFolder = "\\dc1-img-conv-02\E\Convert Any File to PDF\1008_Errors\SAG-Excel-Errors\03 - Copy"

# Excel files
$excelFiles = Get-ChildItem -Path $sourceFolder -Recurse -Include *.xls, *.xlsx, *.xlsm -File
foreach ($file in $excelFiles) {
    try {
        $workbook = $excel.Workbooks.Open($file.FullName)
        $pdfPath = [System.IO.Path]::ChangeExtension($file.FullName, ".pdf")
        $workbook.ExportAsFixedFormat(0, $pdfPath)
        $workbook.Close($false)

        Remove-Item $file.FullName -Force
        Write-Host "Converted Excel: $($file.Name)"
    } catch {
        Write-Warning "Failed to convert Excel: $($file.FullName)"
    }
}

# Word files
$wordFiles = Get-ChildItem -Path $sourceFolder -Recurse -Include *.doc, *.docx -File
foreach ($file in $wordFiles) {
    try {
        $document = $word.Documents.Open($file.FullName, $false, $true)
        $pdfPath = [System.IO.Path]::ChangeExtension($file.FullName, ".pdf")
        $document.SaveAs([ref]$pdfPath, [ref]17)  # 17 = wdFormatPDF
        $document.Close($false)

        Remove-Item $file.FullName -Force
        Write-Host "Converted Word: $($file.Name)"
    } catch {
        Write-Warning "Failed to convert Word: $($file.FullName)"
    }
}

# Cleanup COM objects
$excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null

$word.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
