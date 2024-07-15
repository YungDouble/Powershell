# path is the current working folder
$rootPath = "./"

# Get all CSV files in the root folder and its subfolders
Get-ChildItem -Path $rootPath -Recurse -Include *.csv | ForEach-Object {
    # Import the CSV file
    $csv = Import-Csv $_.FullName

    # Modify the CSV data as needed
    $csv | ForEach-Object {
 				#$_.DocSuperCategory = "Accounts Payable 23-24"
                #$_.DocCategory = "Accounts Payable 23-24"
                #$_.DocType = "Accounts Payable 23-24"
                #$_.DateofBirth = "1/1/1753"
                #$_.FirstName = "Admin"
                #$_.LastName = "STN"
                #$_.IdentificationNumber = "STN-AR-123"

# Clean up the Status column by removing leading/trailing spaces and quotes
        if ($_.Status) {
            $_.Status = $_.Status.Trim()
            $_.Status = $_.Status.Replace('"', '').Trim()
        }
                
    }

    # Export the modified CSV data to the same file
    $csv | Export-Csv $_.FullName -NoTypeInformation
}
