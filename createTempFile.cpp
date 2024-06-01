void CSVProcessor::createTempFile(const std::string& inputFileName, std::string& tempFileName, int fullNameColumnIndex) {
    std::ifstream inputFile(inputFileName);
    std::ofstream tempFile(tempFileName);
    std::vector<std::string> tempFileHeaders; // Temporarily store headers from input file

    // Check if any of the files are already open
    if (!inputFile.is_open() || !tempFile.is_open()) {
        std::cerr << "Error opening files." << std::endl;
        return;
    }

    std::string line;   // variable for holding the data in a line
    std::string header; // Variable for holding the header data

    // Read the header from the input.csv
    if (!std::getline(inputFile, header)) {
        std::cerr << "Error reading header from input file." << std::endl;
        inputFile.close();
        tempFile.close();
        return;
    }

    // Populate tempFileHeaders with the headers from the temporary file
    std::istringstream tempFileHeaderStream(header);
    std::string tempFileColumnName;
    while (std::getline(tempFileHeaderStream, tempFileColumnName, ',')) {
        tempFileHeaders.push_back(tempFileColumnName);
    }

    // Add any missing required columns to tempFileHeaders
    for (const std::string& requiredColumn : {"Account", "RecordSeries", "BoxNumber", "Scanning", "ScannedBy"}) {
        if (std::find(tempFileHeaders.begin(), tempFileHeaders.end(), requiredColumn) == tempFileHeaders.end()) {
            tempFileHeaders.push_back(requiredColumn);
        }
    }

    // Write the header for the new columns to the tempfile
    tempFile << header;
    for (const std::string& columnName : {"LastName", "FirstName", "MiddleName", "Suffix"}) {
        tempFile << "," << columnName;
    }
    tempFile << std::endl;

    // Process each line in the CSV
    while (std::getline(inputFile, line)) {
        std::istringstream iss(line);
        std::string dirtyFullName;

        // Extract the specified Fullname column
        for (int i = 0; i < fullNameColumnIndex; ++i) {
            if (!std::getline(iss, dirtyFullName, ',')) {
                std::cerr << "Error: Specified column index is out of bounds." << std::endl;
                inputFile.close();
                tempFile.close();
                return;
            }
        }

        // Clean up the full name by removing errant characters
        std::string cleanedFullName = cleanFullName(dirtyFullName);

        // Parse the cleaned name using NameParser
        NameParser nameParser(cleanedFullName);

        // Capitalize first letter of each component
        std::string lastName = capitalizeFirstLetter(nameParser.getLastName());
        std::string firstName = capitalizeFirstLetter(nameParser.getFirstName());
        std::string middleName = capitalizeFirstLetter(nameParser.getMiddleName());
        std::string suffix = capitalizeFirstLetter(nameParser.getSuffix());

        // Write the parsed name components to the tempfile
        tempFile << line << "," << lastName << ","
                 << firstName << "," << middleName << ","
                 << suffix;

        // Append empty values for any missing required columns
        for (const std::string& columnName : tempFileHeaders) {
            if (columnName != "LastName" && columnName != "FirstName" && columnName != "MiddleName" && columnName != "Suffix") {
                tempFile << ",";
            }
        }
        tempFile << std::endl;
    }

    inputFile.close();
    tempFile.close();
}
