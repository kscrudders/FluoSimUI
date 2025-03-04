% Define the folder containing CSV files
folderPath = 'H:\01_Matlab\05_FPbase\Database_pulls';
savePath = 'H:\01_Matlab\05_FPbase';
outputFile = fullfile(savePath, '00_All_Spectra_20250302.csv');

% Get a list of all CSV files in the folder
csvFiles = dir(fullfile(folderPath, '*.csv'));

% Initialize an empty table for merging
combinedTable = table();

for i = 1:length(csvFiles)
    % Get full file path
    filePath = fullfile(folderPath, csvFiles(i).name);
    
    % Read the CSV file into a table
    T = readtable(filePath, 'VariableNamingRule', 'preserve');
    
    % Ensure 'wavelength' is the first column
    if ~strcmp(T.Properties.VariableNames{1}, 'wavelength')
        error('First column in %s is not "wavelength". Check file format.', csvFiles(i).name);
    end

    % Filter out wavelengths outside 100-2000 range
    T = T(T.wavelength >= 100 & T.wavelength <= 2000, :);
    
    % Merge based on 'wavelength'
    if isempty(combinedTable)
        combinedTable = T;  % First file sets the structure
    else
        combinedTable = outerjoin(combinedTable, T, 'Keys', 'wavelength', ...
                                  'MergeKeys', true, 'Type', 'full');
    end
end

temp = regexprep(combinedTable.Properties.VariableNames, '_combinedTable$', '');
temp = regexprep(temp, '_T$', '');

% Remove duplicate columns while keeping the first occurrence
[uniqueNames, uniqueIdx] = unique(temp, 'stable');
combinedTable = combinedTable(:, uniqueIdx);

combinedTable.Properties.VariableNames = regexprep(combinedTable.Properties.VariableNames, '_combinedTable$', '');
combinedTable.Properties.VariableNames = regexprep(combinedTable.Properties.VariableNames, '_T$', '');

% Save the merged dataset as a new CSV file
writetable(combinedTable, outputFile);
