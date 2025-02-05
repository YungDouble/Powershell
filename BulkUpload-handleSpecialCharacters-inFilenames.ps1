$basePath = "./FileHolding"

Write-Output $basePath
$files = Get-ChildItem $basePath | Where-Object {$_.PSIsContainer -eq $false}

foreach ($file in $files) {
    Write-Output $file.BaseName
    
    $split = $file.BaseName -split ">"
    
    if ($split.Count -lt 2) {
        Write-Host "Skipping file (Invalid Format): $($file.Name)"
        continue
    }

    $root = "$basePath\$($split[1])"
    $sub = "$root\$($split[0])\images"
    $CSV = "$root\$($split[0])\CSV"
    $CSVfile = "Done.csv"
    
    Write-Output $root
    Write-Output $sub

    if (!(Test-Path $root -ErrorAction SilentlyContinue)) {
        New-Item $root -ItemType Directory | Out-Null
    }

    if (!(Test-Path $sub -ErrorAction SilentlyContinue)) {
        New-Item $sub -ItemType Directory | Out-Null
    }

    if (!(Test-Path $CSV -ErrorAction SilentlyContinue)) {
        New-Item $CSV -ItemType Directory | Out-Null
    }
    
    New-Item "$CSV\$CSVfile" -ItemType file | Out-Null 

    if (Test-Path "$sub\$($file.Name)") {
        Write-Host "File already exists: $($file.Name), skipping..."
        continue
    }

    # **Fixed Move-Item with -LiteralPath to handle special characters**
    Move-Item -LiteralPath $file.FullName -Destination $sub -Verbose
}
