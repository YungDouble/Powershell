
$rootPath = "./"

# Get all CSV files in the root folder and its subfolders
Get-ChildItem -Path $rootPath -Recurse -Include *.csv | ForEach-Object {
    # Import the CSV file
    $csv = Import-Csv $_.FullName

    # Modify the CSV data as needed
    $csv | ForEach-Object {
 				$_.DocSuperCategory = "Miscellaneous"
                $_.DocCategory = "Miscellaneous"
                $_.DocType = "Miscellaneous"
                $_.DateofBirth = "1/1/1753"
                $_.FirstName = "Admin"
                $_.LastName = "SBD"
                $_.IdentificationNumber = "GSB-AR-123"
                
    }

    # Export the modified CSV data to the same file
    $csv | Export-Csv $_.FullName -NoTypeInformation
}
