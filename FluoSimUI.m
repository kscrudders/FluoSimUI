function FluoSimUI()
    spectra_filePath = 'Q:\01_Matlab\99_Github\FluoSimUI\01_Ex_Em_Spectra.csv';
    filter_filePath = 'Q:\01_Matlab\99_Github\FluoSimUI\02_Filter_Transmission_Spectra.csv';
    camera_filePath = "Q:\01_Matlab\99_Github\FluoSimUI\Camera_Quantum_Yield\EMCCD_Andor.csv";

    % Get default figure position
    Pos = get(0, 'defaultfigureposition');
    screenSize = get(0, 'ScreenSize'); % [left, bottom, width, height]
    
    % Define enlarged figure size
    figureWidth = Pos(3) * 2.5; 
    figureHeight = Pos(4) * 2.5;  
    figPosition = [5, screenSize(4) - figureHeight - 85, figureWidth, figureHeight];

    % Create UI figure
    fig = uifigure('Name', 'FluoSimUI', 'Position', figPosition);

    %---------------------------------------------------------%
    % Load data
    %---------------------------------------------------------%
    % spectra
    data = readtable(spectra_filePath,'VariableNamingRule','preserve');

    % Extract wavelengths and fluorophore names
    wavelengths = data.wavelength;
    fluorophoreNamesRaw = data.Properties.VariableNames(2:end);  % Skip 'wavelength'

    % Clean fluorophore names (remove EX and EM suffixes)
    cleanedNames = unique(regexprep(fluorophoreNamesRaw, '_?(EX|EM)$', '', 'ignorecase'));    

    % Load filter data
    filter_data = readtable(filter_filePath,'VariableNamingRule','preserve');
    % Clean fluorophore names (remove EX and EM suffixes)
    cleanedFilterNames = unique(regexprep(filter_data.Properties.VariableNames(2:end), '_?(Ex|Dichroic|Em)$', '', 'ignorecase')); 

    % Load camera data
    camera_data = readtable(camera_filePath,'VariableNamingRule','preserve');
    % Clean fluorophore names (remove EX and EM suffixes)
    cameraNames = unique(camera_data.Properties.VariableNames(2:end)); 

    %---------------------------------------------------------%
    % UI elements
    %---------------------------------------------------------%
    % UI dimensions
    left_off_set = 20;
    list_width = 250;
    list_height = 200;
    button_width = 100;
    button_height = 30;
    button_height_offset = button_height+10;
    width_from_list = 10;

    first_button_height = 100;

    %----------------%
    % Fluorophore selection Items
    %----------------%
    % Search bar
    searchBox = uieditfield(fig, 'text', 'Placeholder', 'Search fluorophore...', ...
        'Position', [left_off_set, figureHeight - 50, list_width, 25], ...
        'ValueChangedFcn', @(src, event) filterList());

    % Listbox for fluorophore selection
    lb = uilistbox(fig, 'Position', [left_off_set, figureHeight - 270, list_width, list_height], 'Items', cleanedNames);
    lb.Multiselect = 'on';

    % Selected fluorophore list
    selectionList = uilistbox(fig, 'Position', [left_off_set + list_width + width_from_list*2 + button_width, figureHeight - 270, 200, list_height], 'Items', {});
    selectionList.Multiselect = 'on';

    % Fluorophore list buttons
    addBtn = uibutton(fig, 'push', 'Text', 'Add ->', ...
        'Position', [left_off_set + list_width + width_from_list, figureHeight - first_button_height, button_width, button_height], 'ButtonPushedFcn', @(src, event) addSelection());

    removeBtn = uibutton(fig, 'push', 'Text', '<- Remove', ...
        'Position', [left_off_set + list_width + width_from_list, figureHeight - (first_button_height + button_height_offset), button_width, button_height], 'ButtonPushedFcn', @(src, event) removeSelection());

    clearAllBtn = uibutton(fig, 'push', 'Text', 'Clear All', ...
        'Position', [left_off_set + list_width + width_from_list, figureHeight - (first_button_height + button_height_offset*2), button_width, button_height], 'ButtonPushedFcn', @(src, event) clearAllSelection());

    % Toggle checkbox for plotting ExSpectra
    plot_ExSpectra_flag = 1;
    plotExCheckbox = uicheckbox(fig, 'Text', 'Plot Ex', 'Value', true, ...
        'Position', [left_off_set + list_width + width_from_list*2 + button_width+20, figureHeight - (list_height + button_height_offset*2.5), list_width, 25], ...
        'ValueChangedFcn', @(src, event) togglePlot_ExSpectra(src));

    % Toggle checkbox for plotting EmSpectra
    plot_EmSpectra_flag = 1;
    plotEmCheckbox = uicheckbox(fig, 'Text', 'Plot Em', 'Value', true, ...
        'Position', [left_off_set + list_width + width_from_list*2 + button_width + 120, figureHeight - (list_height + button_height_offset*2.5), list_width, 25], ...
        'ValueChangedFcn', @(src, event) togglePlot_EmSpectra(src));

    %----------------%
    % Laser Selection Items
    %----------------%
    % Laser line input list
    laserInput = uieditfield(fig, 'numeric', 'Limits', [200, 1000], ...
        'Position', [left_off_set + list_width*2 + width_from_list*2 + button_width, figureHeight - 95, list_width/3, 25], 'Placeholder', 'Laser line (nm)');
    
    laserList = uilistbox(fig, 'Position', [left_off_set + list_width*2 + width_from_list*2 + button_width, figureHeight - 195 - width_from_list, list_width/3, 100], 'Items', {'405', '488', '561', '640'});

    % Laser line list buttons
    addLaserBtn = uibutton(fig, 'push', 'Text', 'Add Laser', ...
        'Position', [left_off_set + list_width*3 + width_from_list*3 + button_width - list_width*(2/3), figureHeight - first_button_height, button_width, button_height], 'ButtonPushedFcn', @(src, event) addLaser());
    
    removeLaserBtn = uibutton(fig, 'push', 'Text', 'Remove Laser', ...
        'Position', [left_off_set + list_width*3 + width_from_list*3 + button_width - list_width*(2/3), figureHeight - (first_button_height + button_height_offset), button_width, button_height], 'ButtonPushedFcn', @(src, event) removeLaser());
    
    clearAllLaserBtn = uibutton(fig, 'push', 'Text', 'Clear All', ...
        'Position', [left_off_set + list_width*3 + width_from_list*3 + button_width - list_width*(2/3), figureHeight - (first_button_height + button_height_offset*2), button_width, button_height], 'ButtonPushedFcn', @(src, event) clearAllLaserSelection());

    %----------------%
    % Plot Button
    %----------------%
    % plot button
    plotBtn = uibutton(fig, 'push', 'Text', 'Plot Spectra', ...
        'Position', [left_off_set + list_width + width_from_list, figureHeight - (first_button_height + button_height_offset*4), button_width, button_height], 'ButtonPushedFcn', @(src, event) plotSpectra());

    %----------------%
    % Filter Selection
    %----------------%
    % Excitation Filters
    exfilterLabel = uilabel(fig, 'Text', 'Excitation Filter', ...
        'Position', [left_off_set + list_width*3 + width_from_list*3 + button_width, figureHeight - 270 + list_height, list_width, 25]);
    
    exfilter_List = uilistbox(fig, 'Position', [left_off_set + list_width*3 + width_from_list*3 + button_width, figureHeight - 270+100, list_width/2, list_height-100], 'Items', cleanedFilterNames);
    exfilter_List.Multiselect = 'off';
    exfilter_List.Value = exfilter_List.Items{1};
    exfilter_List.UserData = exfilter_List.Value;
    exfilter_List.ValueChangedFcn = @(src, event) enforceSelection(src);

    % Excitation Filters
    emfilterLabel = uilabel(fig, 'Text', 'Emission Filter', ...
        'Position', [left_off_set + list_width*3.5 + width_from_list*4 + button_width, figureHeight - 270 + list_height, list_width, 25]);
    
    emfilter_List = uilistbox(fig, 'Position', [left_off_set + list_width*3.5 + width_from_list*4 + button_width, figureHeight - 270+100, list_width/2, list_height-100], 'Items', cleanedFilterNames);
    emfilter_List.Multiselect = 'off';
    emfilter_List.Value = emfilter_List.Items{1};
    emfilter_List.UserData = emfilter_List.Value;
    emfilter_List.ValueChangedFcn = @(src, event) enforceSelection(src);

    % Toggle checkbox for using filters
    use_filters_flag = 0;
    useFiltersCheckbox = uicheckbox(fig, 'Text', 'Use Filters', 'Value', false, ...
        'Position', [left_off_set + list_width*3.5 + width_from_list*4 + button_width, figureHeight - 270 + list_height - 125, list_width, 25], ...
        'ValueChangedFcn', @(src, event) toggleFilters(src));

    % Toggle checkbox for plotting filters
    plot_filters_flag = 0;
    plotFiltersCheckbox = uicheckbox(fig, 'Text', 'Plot Filters', 'Value', false, ...
        'Position', [left_off_set + list_width*3.5 + width_from_list*4 + button_width, figureHeight - 270 + list_height - 125 - 35, list_width, 25], ...
        'ValueChangedFcn', @(src, event) togglePlotFilters(src));

    %----------------%
    % Camera Quantum Yeild
    %----------------%
    % Camera Quantum Yields
    cameraLabel = uilabel(fig, 'Text', 'Camera', ...
        'Position', [left_off_set + list_width*4.2 + width_from_list*4 + button_width, figureHeight - 270 + list_height, list_width, 25]);
    
    camera_List = uilistbox(fig, 'Position', [left_off_set + list_width*4.2 + width_from_list*4 + button_width, figureHeight - 270+100, list_width/2, list_height-100], 'Items', cameraNames);
    camera_List.Multiselect = 'off';

    % Toggle checkbox for using camera Quantum Yield
    use_Cameras_flag = 0;
    useCamerasCheckbox = uicheckbox(fig, 'Text', 'Use Camera Quantum Yield', 'Value', false, ...
        'Position', [left_off_set + list_width*4.2 + width_from_list*4 + button_width, figureHeight - 270 + list_height - 125, list_width, 25], ...
        'ValueChangedFcn', @(src, event) toggleCameras(src));

    % Toggle checkbox for plotting camera Quantum Yield
    plot_Cameras_flag = 0;
    plotCamerasCheckbox = uicheckbox(fig, 'Text', 'Plot Camera Quantum Yield', 'Value', false, ...
        'Position', [left_off_set + list_width*4.2 + width_from_list*4 + button_width, figureHeight - 270 + list_height - 125 - 35, list_width, 25], ...
        'ValueChangedFcn', @(src, event) togglePlotCameras(src));
    % Axes for plotting
    ax = uiaxes(fig, 'Position', [50, 30, figureWidth - 100, figureHeight - 350]);

    % Local functions
    function filterList()
        searchText = lower(searchBox.Value);
        filteredItems = cleanedNames(contains(lower(cleanedNames), searchText));
        lb.Items = filteredItems;
    end

    function addSelection()
        selected = lb.Value;
        currentItems = selectionList.Items;
        newItems = unique([currentItems, selected]);  % Prevent duplicates
        selectionList.Items = newItems;
    end

    function removeSelection()
        selectedToRemove = selectionList.Value;
        selectionList.Items = setdiff(selectionList.Items, selectedToRemove, 'stable');
    end

    function clearAllSelection()
        selectionList.Items = {};
    end

    function clearAllLaserSelection
        laserList.Items = {};
    end

    function plotSpectra()
        fill_opacity = 0.7;

        % Clear the plot
        cla(ax);
        hold(ax, 'on');

        % Clear existing laser lines and spectra
        delete(findall(ax, 'Type', 'ConstantLine'));
        delete(findall(ax, 'Type', 'Line'));
        delete(findall(ax, 'Type', 'Text'));

        selectedFluorophores = selectionList.Items;
        if isempty(selectedFluorophores)
            title(ax, 'No fluorophores selected');
            return;
        end
        
        % Plot filters
        if plot_filters_flag == 1
            expectedColumnName = [exfilter_List.Value '_Ex'];
            colIdx = find(strcmp(filter_data.Properties.VariableNames, expectedColumnName), 1);
            Excitation = filter_data{:,colIdx};
            wavelength_ex = filter_data{:,1};

            plot(ax, wavelength_ex, Excitation, ':', 'Color', 'k', 'LineWidth', 1, 'HandleVisibility', 'off');

            expectedColumnName = [emfilter_List.Value '_Em'];
            colIdx = find(strcmp(filter_data.Properties.VariableNames, expectedColumnName), 1);
            Emission = filter_data{:,colIdx};
            wavelength_em = filter_data{:,1};

            plot(ax, wavelength_em, Emission, '--', 'Color', 'k', 'LineWidth', 1, 'HandleVisibility', 'off');
        end

        % Plot camera Quantum Yield
        if plot_Cameras_flag == 1
            expectedColumnName = camera_List.Value;
            colIdx = find(strcmp(camera_data.Properties.VariableNames, expectedColumnName), 1);
            Quantum_Yield = camera_data{:,colIdx};
            wavelength_ex = camera_data{:,1};

            plot(ax, wavelength_ex, Quantum_Yield, ':', 'Color', 'k', 'LineWidth', 1, 'HandleVisibility', 'off');
        end

        % Plot excitation & emission spectra for each fluorophore
        for i = 1:length(selectedFluorophores)
            fluorophore = selectedFluorophores{i};

            % Extract core fluorophore name (remove EX/EM suffix)
            coreName = regexprep(fluorophore, '_?(EX|EM)$', '', 'ignorecase');

            % Find excitation and emission column indices correctly
            ex_idx = find(contains(fluorophoreNamesRaw, 'EX', 'IgnoreCase', false) & ...
                          contains(fluorophoreNamesRaw, coreName, 'IgnoreCase', false));
            em_idx = find(contains(fluorophoreNamesRaw, 'EM', 'IgnoreCase', false) & ...
                          contains(fluorophoreNamesRaw, coreName, 'IgnoreCase', false));

            % Ensure correct match if multiple indices exist
            if length(ex_idx) > 1
                ex_idx = find(strcmp(regexprep(fluorophoreNamesRaw(ex_idx), '_?(EX|EM)$', '', 'ignorecase'), coreName), 1);
            end
            if length(em_idx) > 1
                specific_idx = find(strcmp(regexprep(fluorophoreNamesRaw(em_idx), '_?(EX|EM)$', '', 'ignorecase'), coreName), 1);
                em_idx = em_idx(specific_idx);
                clear specific_idx
            end

            % Skip if no match found
            if isempty(ex_idx) || isempty(em_idx)
                warning('No excitation or emission spectra found for %s.', fluorophore);
                continue;
            end

            % Extract excitation and emission data
            exData = data{:, ex_idx+1};
            emData = data{:, em_idx+1};
            raw_emData = data{:, em_idx+1};

            % Find max wavelength for color determination
            [~, maxIdxEx] = max(exData);
            [~, maxIdxEm] = max(emData);
            colorEx = nmToRGB(wavelengths(maxIdxEx)) / 255;
            colorEm = nmToRGB(wavelengths(maxIdxEm)) / 255;

            if plot_ExSpectra_flag == 1
                % Plot excitation spectrum
                valid_idx_ex = ~isnan(exData);
                fill(ax, [wavelengths(valid_idx_ex); flip(wavelengths(valid_idx_ex))], [zeros(size(exData(valid_idx_ex))); flip(exData(valid_idx_ex))], colorEx, ...
                    'FaceAlpha', fill_opacity, 'EdgeColor', 'none','DisplayName', [fluorophore ' EX']);
                %plot(ax, wavelengths, exData, '-', 'Color', colorEx, 'LineWidth', 0.5, 'HandleVisibility', 'off');
                plot(ax, wavelengths, exData, '-', 'Color', 'k', 'LineWidth', 0.5, 'HandleVisibility', 'off');
            end
            % Adjust Emission based on laser excitation
            laserValues = str2double(laserList.Items);
            if ~isempty(laserValues)
                Abs_efficiency = 0;
                current_wavelength = wavelengths(valid_idx_ex);
                current_abs = exData(valid_idx_ex);

                for ii = 1:length(laserValues)
                    idx_of_abs = current_wavelength == laserValues(ii);
                    if ~isempty(find(idx_of_abs,1))
                        curr_efficiency = current_abs(idx_of_abs);
                        if curr_efficiency > Abs_efficiency
                            Abs_efficiency = curr_efficiency;
                            laser_selection = ii;
                        end
                    else
                        laser_selection = 1; % default to the first laser
                    end
                end
                
                % Attenutate laser power in a linear fashion based on Ex
                % filter, transmission %
                if use_filters_flag == 1
                    % If filters are selected, apply filter effects.
                    nm_to_filter = laserValues(laser_selection);

                    expectedColumnName = [exfilter_List.Value '_Ex'];

                    % Find the column index in filter_data
                    colIdx = find(strcmp(filter_data.Properties.VariableNames, expectedColumnName), 1);

                    laser_attenuation = filter_data{filter_data{:,1} == nm_to_filter,colIdx};
                    emData = emData .* Abs_efficiency .* laser_attenuation;
                else
                    emData = emData .* Abs_efficiency;
                end
            end

            % Adjust Emission based on Collection Effeciency
            valid_idx_em = ~isnan(emData);
            em_wavelength = wavelengths(valid_idx_em);
            if use_filters_flag == 1
                % If filters are selected, apply filter effects.
                expectedColumnName = [emfilter_List.Value '_Dichroic'];
                colIdx = find(strcmp(filter_data.Properties.VariableNames, expectedColumnName), 1);
                Dichroic = filter_data{:,colIdx};

                if strcmp(exfilter_List.Value, 'Quad') && ~strcmp(emfilter_List.Value, 'Quad')
                    expectedColumnName = [exfilter_List.Value '_Em'];
                    colIdx = find(strcmp(filter_data.Properties.VariableNames, expectedColumnName), 1);
                    Emission = filter_data{:,colIdx};

                    expectedColumnName = [emfilter_List.Value '_Em'];
                    colIdx = find(strcmp(filter_data.Properties.VariableNames, expectedColumnName), 1);
                    Emission = Emission .* filter_data{:,colIdx};
                else
                    expectedColumnName = [emfilter_List.Value '_Em'];
                    colIdx = find(strcmp(filter_data.Properties.VariableNames, expectedColumnName), 1);
                    Emission = filter_data{:,colIdx};
                end

                Light_Transmission_to_camera = Dichroic .* Emission;

                filter_wavelength = filter_data{:,1};

                overlapping_wavelength = find(ismember(filter_wavelength, em_wavelength));

                current_emission_efficiency = emData(valid_idx_em);
                filtered_emission_efficiency = current_emission_efficiency .* Light_Transmission_to_camera(overlapping_wavelength); %#ok<FNDSB>

                filter_attenuation = sum(filtered_emission_efficiency,'omitnan') / sum(current_emission_efficiency,'omitnan');
                emData = emData .* filter_attenuation;
            end

            if use_Cameras_flag == 1
                % If camera quantum yield is selected, apply quantum yield effects.
                expectedColumnName = camera_List.Value;
                colIdx = find(strcmp(camera_data.Properties.VariableNames, expectedColumnName), 1);
                Quantum_Yield = camera_data{:,colIdx};

                camera_wavelength = camera_data{:,1};

                overlapping_wavelength = find(ismember(camera_wavelength, em_wavelength));

                current_emission_efficiency = emData(valid_idx_em);
                camera_collection_efficiency = current_emission_efficiency .* Quantum_Yield(overlapping_wavelength); %#ok<FNDSB>

                camera_quantum_yield = sum(camera_collection_efficiency,'omitnan') / sum(current_emission_efficiency,'omitnan');
                emData = emData .* camera_quantum_yield;
            end

            if plot_EmSpectra_flag == 1
                % Plot emission spectrum
                valid_idx_ex = ~isnan(emData);
                fill(ax, [wavelengths(valid_idx_ex); flip(wavelengths(valid_idx_ex))], [zeros(size(emData(valid_idx_ex))); flip(emData(valid_idx_ex))], colorEm, ...
                    'FaceAlpha', fill_opacity, 'EdgeColor', 'none', 'DisplayName', [fluorophore ' EM']);
                %plot(ax, wavelengths, emData, '--', 'Color', colorEm, 'LineWidth', 0.5, 'HandleVisibility', 'off');
                plot(ax, wavelengths, emData, '--', 'Color', 'k', 'LineWidth', 0.5, 'HandleVisibility', 'off');
            end

            % Find peak emission intensity and corresponding wavelength
            [peakIntensity, peakIndex] = max(emData);
            peakWavelength = wavelengths(peakIndex);

            Collected_light_relative_to_full_emSpectra = sum(emData,'omitnan') / sum(raw_emData,'omitnan');

            if use_filters_flag == 1 | ~isempty(laserValues) | use_Cameras_flag %#ok<OR2>
                % Add text above the peak with a small vertical offset (0.02 is an example)
                text(ax, peakWavelength, peakIntensity + 0.02, sprintf('%.2f', peakIntensity), ...
                    'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontSize', 12, ...
                    'Color', 'k', 'BackgroundColor','w');
                % KLS 20250304
                % I thought there might be a difference between the max abs
                % peak and the integrated emission relative to the raw
                % emission. After testing with a few fluorophores and
                % filter/laser settings. There doesn't appear to be a
                % difference. I think it might be a calculation mismatach.
                % Like I think I'm calculating the first thing, but it's
                % really the second thing the whole time.
                %text(ax, peakWavelength, peakIntensity + 0.02, sprintf('%.2f (%.2f)', peakIntensity, Collected_light_relative_to_full_emSpectra), ...
                %    'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontSize', 12, ...
                %    'Color', 'k', 'BackgroundColor','w');
            end
        end
        
        title(ax, 'Excitation and Emission Spectra');
        xlabel(ax, 'Wavelength (nm)');
        xlim(ax, [325 800])

        ylabel(ax, 'Relative intensity (a.u.)');
        ylim(ax,[0 1.1])
        legend(ax, 'show');
        hold(ax, 'off');

        % Plot laser lines
        laserValues = str2double(laserList.Items);
        for i = 1:length(laserValues)
            xline(ax, laserValues(i), 'Color', nmToRGB(laserValues(i)) / 255, 'LineWidth', 3, 'HandleVisibility', 'off');
            %xline(ax, laserValues(i), '--', 'Color', 'k', 'LineWidth', 0.5, 'HandleVisibility', 'off');
        end
    end

    function addLaser()
        laserValue = num2str(laserInput.Value);
        currentLasers = laserList.Items;
        if ~ismember(laserValue, currentLasers)
            laserList.Items = [currentLasers, laserValue];
        end
    end
    
    function removeLaser()
        selectedToRemove = laserList.Value;
        laserList.Items = setdiff(laserList.Items, selectedToRemove, 'stable');
    end

    function rgb = nmToRGB(wavelength)
        % Convert wavelength (380-780 nm) to approximate RGB color
        gamma = 0.80;
        intensityMax = 255;
        factor = 0.0;
        R = 0; G = 0; B = 0;

        if (wavelength >= 380) && (wavelength < 440)
            R = -(wavelength - 440) / (440 - 380);
            B = 1.0;
        elseif (wavelength >= 440) && (wavelength < 490)
            G = (wavelength - 440) / (490 - 440);
            B = 1.0;
        elseif (wavelength >= 490) && (wavelength < 510)
            G = 1.0;
            B = -(wavelength - 510) / (510 - 490);
        elseif (wavelength >= 510) && (wavelength < 580)
            R = (wavelength - 510) / (580 - 510);
            G = 1.0;
        elseif (wavelength >= 580) && (wavelength < 645)
            R = 1.0;
            G = -(wavelength - 645) / (645 - 580);
        elseif (wavelength >= 645) && (wavelength < 781)
            R = 1.0;
        end

        if (wavelength >= 380) && (wavelength < 420)
            factor = 0.3 + 0.7 * (wavelength - 380) / (420 - 380);
        elseif (wavelength >= 420) && (wavelength < 701)
            factor = 1.0;
        elseif (wavelength >= 701) && (wavelength < 781)
            factor = 0.3 + 0.7 * (780 - wavelength) / (780 - 700);
        end

        R = round(intensityMax * (R * factor) ^ gamma);
        G = round(intensityMax * (G * factor) ^ gamma);
        B = round(intensityMax * (B * factor) ^ gamma);

        rgb = [R, G, B];
    end

    function toggleFilters(src)
        if src.Value
            use_filters_flag = 1;
        else
            use_filters_flag = 0;
        end
    end

    function togglePlotFilters(src)
        if src.Value
            plot_filters_flag = 1;
        else
            plot_filters_flag = 0;
        end
    end

    function toggleCameras(src)
        if src.Value
            use_Cameras_flag = 1;
        else
            use_Cameras_flag = 0;
        end
    end

    function togglePlotCameras(src)
        if src.Value
            plot_Cameras_flag = 1;
        else
            plot_Cameras_flag = 0;
        end
    end

    function togglePlot_ExSpectra(src)
        if src.Value
            plot_ExSpectra_flag = 1;
        else
            plot_ExSpectra_flag = 0;
        end
    end

    function togglePlot_EmSpectra(src)
        if src.Value
            plot_EmSpectra_flag = 1;
        else
            plot_EmSpectra_flag = 0;
        end
    end

    function enforceSelection(src)
        % If no value is selected, revert to the previous selection stored in UserData.
        if isempty(src.Value)
            src.Value = src.UserData;
        else
            % Update UserData with the current valid selection.
            src.UserData = src.Value;
        end
    end
end
