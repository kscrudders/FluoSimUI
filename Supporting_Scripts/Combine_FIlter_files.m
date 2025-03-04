clc; clear; close all;

% Define base directory
baseDir = 'H:\01_Matlab\05_FPbase';

% Define subdirectories
exDir = fullfile(baseDir, 'Excitation_Filters');
dichroicDir = fullfile(baseDir, 'Dichroic');
emDir = fullfile(baseDir, 'Emission_Filters');

% Get list of files in each directory
exFiles = dir(fullfile(exDir, '*_Ex.txt'));
dichroicFiles = dir(fullfile(dichroicDir, '*_Dichroic.txt'));
emFiles = dir(fullfile(emDir, '*_Em.txt'));

% Extract unique file prefixes
exNames = extractBefore({exFiles.name}, '_Ex.txt');
dichroicNames = extractBefore({dichroicFiles.name}, '_Dichroic.txt');
emNames = extractBefore({emFiles.name}, '_Em.txt');

% Find common file prefixes (only complete sets)
commonNames = intersect(intersect(exNames, dichroicNames), emNames);

% Define wavelength range
wavelengthRange = (200:1700)';

% Initialize results table
resultsTable = table(wavelengthRange, 'VariableNames', {'Wavelength'});

for i = 1:length(commonNames)
    prefix = commonNames{i};

    % Read and process each file
    exData = filter_whole_numbers(readmatrix(fullfile(exDir, [prefix '_Ex.txt'])));
    dichroicData = filter_whole_numbers(readmatrix(fullfile(dichroicDir, [prefix '_Dichroic.txt'])));
    emData = filter_whole_numbers(readmatrix(fullfile(emDir, [prefix '_Em.txt'])));

    % Interpolate data to match wavelength range
    exInterp = interp1(exData(:,1), exData(:,2), wavelengthRange, 'linear', NaN);
    dichroicInterp = interp1(dichroicData(:,1), dichroicData(:,2), wavelengthRange, 'linear', NaN);
    emInterp = interp1(emData(:,1), emData(:,2), wavelengthRange, 'linear', NaN);

    % Append to table
    resultsTable.([prefix '_Ex']) = exInterp;
    resultsTable.([prefix '_Dichroic']) = dichroicInterp;
    resultsTable.([prefix '_Em']) = emInterp;
end

% Display the final table
disp(resultsTable);

% Save table to CSV
writetable(resultsTable, fullfile(baseDir, 'Combined_Filter_Data.csv'));

function filtered_data = filter_whole_numbers(data)
    % Extract rows where the first column contains whole numbers
    whole_number_idx = mod(data(:,1), 1) == 0;
    filtered_data = data(whole_number_idx, :);
end