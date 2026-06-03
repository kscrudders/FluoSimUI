function FluoSimUI_v3()
    % FluoSimUI_v3
    % ------------------------------------------------------------------
    % Updated for MATLAB R2025a/b.
    %
    %   * Resolution-independent layout: window is 3/4 of the monitor
    %     (or a fixed 1920x1080 via USE_FIXED_SIZE). Every element is laid
    %     out in a fixed 1400x1050 "design space" and scaled by scalePos().
    %
    %   * Bug fix: valid_idx_ex is now always defined (was only created
    %     inside the Plot-Ex block, but used by the laser code).
    %
    %   * FRET analysis (toggle): highlight exactly two fluorophores in the
    %     selected list. Donor = lower emission-peak wavelength. Reports the
    %     raw donor-EM / acceptor-EX overlap and the full-setup collected
    %     acceptor intensity (donor reduced by laser + Ex filter, acceptor
    %     reduced by the Em filter only).
    %
    %   * Self-quench overlap (toggle): own-EM / own-EX overlap, per FP.
    %
    %   * Emission filter list is now multi-select; selected filters are
    %     combined by multiplication (series stacking). Dichroic is taken
    %     from the first selected filter.
    % ------------------------------------------------------------------

    spectra_filePath = 'E:\01_Matlab\99_Github\FluoSimUI\01_Ex_Em_Spectra.csv';
    filter_filePath = 'E:\01_Matlab\99_Github\FluoSimUI\02_Filter_Transmission_Spectra.csv';
    camera_filePath = "E:\01_Matlab\99_Github\FluoSimUI\Camera_Quantum_Yield\Camera_list.csv";

    %---------------------------------------------------------%
    % Figure sizing (resolution-independent)
    %---------------------------------------------------------%
    USE_FIXED_SIZE = false;   % true -> fixed 1920x1080 window

    screenSize = get(0, 'ScreenSize');   % [left, bottom, width, height]
    screenW = screenSize(3);
    screenH = screenSize(4);

    if USE_FIXED_SIZE
        figureWidth  = 1920;
        figureHeight = 1080;
    else
        figureWidth  = round(0.75 * screenW);
        figureHeight = round(0.75 * screenH);
    end

    % Design space the layout was authored for (2.5x the 560x420 default).
    designW = 1400;
    designH = 1050;

    sx = figureWidth  / designW;
    sy = figureHeight / designH;

    figX = max(1, round((screenW - figureWidth)  / 2));
    figY = max(1, round((screenH - figureHeight) / 2));
    figPosition = [figX, figY, figureWidth, figureHeight];

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
    cleanedFilterNames = unique(regexprep(filter_data.Properties.VariableNames(2:end), '_?(Ex|Dichroic|Em)$', '', 'ignorecase'));

    % Load camera data
    camera_data = readtable(camera_filePath,'VariableNamingRule','preserve');
    cameraNames = unique(camera_data.Properties.VariableNames(2:end));

    %---------------------------------------------------------%
    % UI elements (design-space coords; scalePos() -> window pixels)
    %---------------------------------------------------------%
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
    searchBox = uieditfield(fig, 'text', 'Placeholder', 'Search fluorophore...', ...
        'Position', scalePos(left_off_set, designH - 50, list_width, 25), ...
        'ValueChangedFcn', @(src, event) filterList());

    lb = uilistbox(fig, 'Position', scalePos(left_off_set, designH - 270, list_width, list_height), 'Items', cleanedNames);
    lb.Multiselect = 'on';

    selectionList = uilistbox(fig, 'Position', scalePos(left_off_set + list_width + width_from_list*2 + button_width, designH - 270, 200, list_height), 'Items', {});
    selectionList.Multiselect = 'on';

    addBtn = uibutton(fig, 'push', 'Text', 'Add ->', ...
        'Position', scalePos(left_off_set + list_width + width_from_list, designH - first_button_height, button_width, button_height), 'ButtonPushedFcn', @(src, event) addSelection());

    removeBtn = uibutton(fig, 'push', 'Text', '<- Remove', ...
        'Position', scalePos(left_off_set + list_width + width_from_list, designH - (first_button_height + button_height_offset), button_width, button_height), 'ButtonPushedFcn', @(src, event) removeSelection());

    clearAllBtn = uibutton(fig, 'push', 'Text', 'Clear All', ...
        'Position', scalePos(left_off_set + list_width + width_from_list, designH - (first_button_height + button_height_offset*2), button_width, button_height), 'ButtonPushedFcn', @(src, event) clearAllSelection());

    plot_ExSpectra_flag = 1;
    plotExCheckbox = uicheckbox(fig, 'Text', 'Plot Ex', 'Value', true, ...
        'Position', scalePos(left_off_set + list_width + width_from_list*2 + button_width+20, designH - (list_height + button_height_offset*2.5), list_width, 25), ...
        'ValueChangedFcn', @(src, event) togglePlot_ExSpectra(src));

    plot_EmSpectra_flag = 1;
    plotEmCheckbox = uicheckbox(fig, 'Text', 'Plot Em', 'Value', true, ...
        'Position', scalePos(left_off_set + list_width + width_from_list*2 + button_width + 120, designH - (list_height + button_height_offset*2.5), list_width, 25), ...
        'ValueChangedFcn', @(src, event) togglePlot_EmSpectra(src));

    %----------------%
    % Laser Selection Items
    %----------------%
    laserInput = uieditfield(fig, 'numeric', 'Limits', [200, 1000], ...
        'Position', scalePos(left_off_set + list_width*2 + width_from_list*2 + button_width, designH - 95, list_width/3, 25), 'Placeholder', 'Laser line (nm)');

    laserList = uilistbox(fig, 'Position', scalePos(left_off_set + list_width*2 + width_from_list*2 + button_width, designH - 195 - width_from_list, list_width/3, 100), 'Items', {'405', '488', '561', '640'});

    addLaserBtn = uibutton(fig, 'push', 'Text', 'Add Laser', ...
        'Position', scalePos(left_off_set + list_width*3 + width_from_list*3 + button_width - list_width*(2/3), designH - first_button_height, button_width, button_height), 'ButtonPushedFcn', @(src, event) addLaser());

    removeLaserBtn = uibutton(fig, 'push', 'Text', 'Remove Laser', ...
        'Position', scalePos(left_off_set + list_width*3 + width_from_list*3 + button_width - list_width*(2/3), designH - (first_button_height + button_height_offset), button_width, button_height), 'ButtonPushedFcn', @(src, event) removeLaser());

    clearAllLaserBtn = uibutton(fig, 'push', 'Text', 'Clear All', ...
        'Position', scalePos(left_off_set + list_width*3 + width_from_list*3 + button_width - list_width*(2/3), designH - (first_button_height + button_height_offset*2), button_width, button_height), 'ButtonPushedFcn', @(src, event) clearAllLaserSelection());

    %----------------%
    % Plot Button
    %----------------%
    plotBtn = uibutton(fig, 'push', 'Text', 'Plot Spectra', ...
        'Position', scalePos(left_off_set + list_width + width_from_list, designH - (first_button_height + button_height_offset*4), button_width, button_height), 'ButtonPushedFcn', @(src, event) plotSpectra());

    %----------------%
    % Filter Selection
    %----------------%
    % Excitation Filter (single select)
    exfilterLabel = uilabel(fig, 'Text', 'Excitation Filter', ...
        'Position', scalePos(left_off_set + list_width*3 + width_from_list*3 + button_width, designH - 270 + list_height, list_width, 25)); %#ok<NASGU>

    exfilter_List = uilistbox(fig, 'Position', scalePos(left_off_set + list_width*3 + width_from_list*3 + button_width, designH - 270+100, list_width/2, list_height-100), 'Items', cleanedFilterNames);
    exfilter_List.Multiselect = 'off';
    exfilter_List.Value = exfilter_List.Items{1};
    exfilter_List.UserData = exfilter_List.Value;
    exfilter_List.ValueChangedFcn = @(src, event) enforceSelection(src);

    % Emission Filter (multi-select; combined by multiplication)
    emfilterLabel = uilabel(fig, 'Text', 'Emission Filter (multi-select)', ...
        'Position', scalePos(left_off_set + list_width*3.5 + width_from_list*4 + button_width, designH - 270 + list_height, list_width, 25)); %#ok<NASGU>

    emfilter_List = uilistbox(fig, 'Position', scalePos(left_off_set + list_width*3.5 + width_from_list*4 + button_width, designH - 270+100, list_width/2, list_height-100), 'Items', cleanedFilterNames);
    emfilter_List.Multiselect = 'on';
    emfilter_List.Value = emfilter_List.Items(1);   % start with one selection
    emfilter_List.UserData = emfilter_List.Value;
    emfilter_List.ValueChangedFcn = @(src, event) enforceSelection(src);

    use_filters_flag = 0;
    useFiltersCheckbox = uicheckbox(fig, 'Text', 'Use Filters', 'Value', false, ...
        'Position', scalePos(left_off_set + list_width*3.5 + width_from_list*4 + button_width, designH - 270 + list_height - 125, list_width, 25), ...
        'ValueChangedFcn', @(src, event) toggleFilters(src));

    plot_filters_flag = 0;
    plotFiltersCheckbox = uicheckbox(fig, 'Text', 'Plot Filters', 'Value', false, ...
        'Position', scalePos(left_off_set + list_width*3.5 + width_from_list*4 + button_width, designH - 270 + list_height - 125 - 35, list_width, 25), ...
        'ValueChangedFcn', @(src, event) togglePlotFilters(src));

    %----------------%
    % Camera Quantum Yield
    %----------------%
    cameraLabel = uilabel(fig, 'Text', 'Camera', ...
        'Position', scalePos(left_off_set + list_width*4.2 + width_from_list*4 + button_width, designH - 270 + list_height, list_width, 25)); %#ok<NASGU>

    camera_List = uilistbox(fig, 'Position', scalePos(left_off_set + list_width*4.2 + width_from_list*4 + button_width, designH - 270+100, list_width/2, list_height-100), 'Items', cameraNames);
    camera_List.Multiselect = 'off';

    use_Cameras_flag = 0;
    useCamerasCheckbox = uicheckbox(fig, 'Text', 'Use Camera Quantum Yield', 'Value', false, ...
        'Position', scalePos(left_off_set + list_width*4.2 + width_from_list*4 + button_width, designH - 270 + list_height - 125, list_width, 25), ...
        'ValueChangedFcn', @(src, event) toggleCameras(src));

    plot_Cameras_flag = 0;
    plotCamerasCheckbox = uicheckbox(fig, 'Text', 'Plot Camera Quantum Yield', 'Value', false, ...
        'Position', scalePos(left_off_set + list_width*4.2 + width_from_list*4 + button_width, designH - 270 + list_height - 125 - 35, list_width, 25), ...
        'ValueChangedFcn', @(src, event) togglePlotCameras(src));

    %----------------%
    % Analysis controls (FRET / self-quench) + results panel
    %----------------%
    fret_flag = 0;
    selfquench_flag = 0;

    analysisLabel = uilabel(fig, 'Text', 'Analysis  (FRET: highlight 2 FPs in the selected list)', ...
        'Position', scalePos(60, 700, 240, 30)); %#ok<NASGU>

    fretCheckbox = uicheckbox(fig, 'Text', 'FRET transfer', 'Value', false, ...
        'Position', scalePos(60, 668, 240, 25), ...
        'ValueChangedFcn', @(src, event) toggleFRET(src)); %#ok<NASGU>

    selfquenchCheckbox = uicheckbox(fig, 'Text', 'Self-quench overlap', 'Value', false, ...
        'Position', scalePos(60, 640, 240, 25), ...
        'ValueChangedFcn', @(src, event) toggleSelfQuench(src)); %#ok<NASGU>

    resultsArea = uitextarea(fig, ...
        'Position', scalePos(300, 585, 1040, 142), ...
        'Editable', 'off', 'FontName', 'monospaced', ...
        'Value', {'(enable FRET or Self-quench, then Plot Spectra)'});

    % Axes for plotting (height reduced to make room for the analysis panel)
    ax = uiaxes(fig, 'Position', scalePos(50, 30, designW - 100, designH - 500));

    % ==================================================================
    % Local (nested) functions
    % ==================================================================

    function p = scalePos(x, y, w, h)
        % Convert a design-space rectangle into actual-window pixels.
        p = [x*sx, y*sy, w*sx, h*sy];
    end

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

    % ---- spectra / overlap helpers -----------------------------------

    function [exData, emData, exPeakWL, emPeakWL, ok] = getFPSpectra(fluorophore)
        % Look up a fluorophore's excitation and emission spectra by name.
        coreName = regexprep(fluorophore, '_?(EX|EM)$', '', 'ignorecase');

        ex_idx = find(contains(fluorophoreNamesRaw, 'EX', 'IgnoreCase', false) & ...
                      contains(fluorophoreNamesRaw, coreName, 'IgnoreCase', false));
        em_idx = find(contains(fluorophoreNamesRaw, 'EM', 'IgnoreCase', false) & ...
                      contains(fluorophoreNamesRaw, coreName, 'IgnoreCase', false));

        if numel(ex_idx) > 1
            ex_idx = ex_idx(find(strcmp(regexprep(fluorophoreNamesRaw(ex_idx), '_?(EX|EM)$', '', 'ignorecase'), coreName), 1));
        end
        if numel(em_idx) > 1
            em_idx = em_idx(find(strcmp(regexprep(fluorophoreNamesRaw(em_idx), '_?(EX|EM)$', '', 'ignorecase'), coreName), 1));
        end

        ok = ~(isempty(ex_idx) || isempty(em_idx));
        if ~ok
            exData = []; emData = []; exPeakWL = NaN; emPeakWL = NaN; return;
        end

        exData = data{:, ex_idx+1};
        emData = data{:, em_idx+1};
        [~, mi_ex] = max(exData); exPeakWL = wavelengths(mi_ex);
        [~, mi_em] = max(emData); emPeakWL = wavelengths(mi_em);
    end

    function ov = spectralOverlap(emData_src, exData_dst)
        % Area-normalized source emission weighted by destination excitation.
        % Returns a 0-1 fraction (no optics applied). Used for FRET and
        % self-quench (where src == dst).
        v = ~isnan(emData_src) & ~isnan(exData_dst);
        if ~any(v), ov = 0; return; end
        e = emData_src(v);
        a = exData_dst(v);
        s = sum(e, 'omitnan');
        if s <= 0, ov = 0; return; end
        ov = sum((e ./ s) .* a, 'omitnan');
    end

    function sel = emSelection()
        % Selected emission filter names as a cellstr (handles char or cell).
        sel = emfilter_List.Value;
        if ~iscell(sel), sel = cellstr(sel); end
    end

    function Em = combinedEmFilter()
        % Product of the selected emission filters' transmission (series).
        sel = emSelection();
        Em = ones(height(filter_data), 1);
        for k = 1:numel(sel)
            ci = find(strcmp(filter_data.Properties.VariableNames, [sel{k} '_Em']), 1);
            if ~isempty(ci)
                Em = Em .* filter_data{:, ci};
            end
        end
    end

    function frac = emFilterFraction(emData_full)
        % Fraction of an emission spectrum transmitted by the emission
        % optics (dichroic x combined emission filter, + Quad special case).
        % Scale-independent, so the input spectrum need not be normalized.
        sel = emSelection();
        Em = combinedEmFilter();

        % Preserve original Quad behavior: if the Ex filter is the Quad and
        % Quad is not among the chosen Em filters, fold in the Quad's Em band.
        if strcmp(exfilter_List.Value, 'Quad') && ~any(strcmp(sel, 'Quad'))
            ci = find(strcmp(filter_data.Properties.VariableNames, 'Quad_Em'), 1);
            if ~isempty(ci), Em = Em .* filter_data{:, ci}; end
        end

        % Dichroic from the first selected emission filter
        ci = find(strcmp(filter_data.Properties.VariableNames, [sel{1} '_Dichroic']), 1);
        if ~isempty(ci)
            Dichroic = filter_data{:, ci};
        else
            Dichroic = ones(height(filter_data), 1);
        end

        Tcombined = Dichroic .* Em;

        v = ~isnan(emData_full);
        em_wl  = wavelengths(v);
        em_eff = emData_full(v);
        fwl = filter_data{:, 1};
        ov_idx = ismember(fwl, em_wl);

        transmitted = em_eff .* Tcombined(ov_idx);
        denom = sum(em_eff, 'omitnan');
        if denom <= 0, frac = 0; else, frac = sum(transmitted, 'omitnan') / denom; end
    end

    function frac = cameraFraction(emData_full)
        % Fraction collected after the camera quantum yield.
        ci = find(strcmp(camera_data.Properties.VariableNames, camera_List.Value), 1);
        QY = camera_data{:, ci};
        cwl = camera_data{:, 1};

        v = ~isnan(emData_full);
        em_wl  = wavelengths(v);
        em_eff = emData_full(v);
        ov_idx = ismember(cwl, em_wl);

        transmitted = em_eff .* QY(ov_idx);
        denom = sum(em_eff, 'omitnan');
        if denom <= 0, frac = 0; else, frac = sum(transmitted, 'omitnan') / denom; end
    end

    function [de, bestLaser, hasLaser] = donorExcitation(exData_src)
        % Effective excitation of a fluorophore: its excitation at the best
        % laser line, attenuated by the Ex filter (if Use Filters is on).
        lv = str2double(laserList.Items);
        lv = lv(~isnan(lv));
        hasLaser = ~isempty(lv);

        if ~hasLaser
            de = max(exData_src);     % no laser -> assume peak excitation
            bestLaser = NaN;
            return;
        end

        best = 0; bestLaser = lv(1);
        for q = 1:numel(lv)
            idx = wavelengths == lv(q);
            if any(idx)
                val = exData_src(idx);
                if val > best, best = val; bestLaser = lv(q); end
            end
        end
        de = best;

        if use_filters_flag == 1
            ci = find(strcmp(filter_data.Properties.VariableNames, [exfilter_List.Value '_Ex']), 1);
            if ~isempty(ci)
                att = filter_data{filter_data{:,1} == bestLaser, ci};
                if ~isempty(att), de = de * att; end
            end
        end
    end

    % ---- analysis (FRET / self-quench) -------------------------------

    function lines = computeFRET()
        lines = {};
        sel = selectionList.Value;
        if ~iscell(sel), sel = cellstr(sel); end

        if numel(sel) ~= 2
            lines = {'FRET: highlight exactly 2 fluorophores in the selected list.'};
            return;
        end

        [ex1, em1, ~, emp1, ok1] = getFPSpectra(sel{1});
        [ex2, em2, ~, emp2, ok2] = getFPSpectra(sel{2});
        if ~ok1 || ~ok2
            lines = {'FRET: spectra not found for one of the selected fluorophores.'};
            return;
        end

        % Donor = lower emission-peak wavelength
        if emp1 <= emp2
            donName = sel{1}; accName = sel{2};
            donEm = em1; donEx = ex1; accEx = ex2; accEm = em2;
        else
            donName = sel{2}; accName = sel{1};
            donEm = em2; donEx = ex2; accEx = ex1; accEm = em1;
        end

        overlap = spectralOverlap(donEm, accEx);          % (a) raw, no optics
        [de, bestLaser, hasLaser] = donorExcitation(donEx);

        if use_filters_flag == 1
            emFrac = emFilterFraction(accEm);             % Em filter on acceptor
        else
            emFrac = 1;
        end

        acceptor_excited = de * overlap;
        collected = acceptor_excited * emFrac;            % (b) full setup

        lines{end+1} = sprintf('FRET   %s (donor)  ->  %s (acceptor)', donName, accName); %#ok<AGROW>
        lines{end+1} = sprintf('  Raw overlap (donor EM x acceptor EX) : %.3f', overlap); %#ok<AGROW>
        if hasLaser
            if use_filters_flag == 1
                lines{end+1} = sprintf('  Donor excitation (%g nm + Ex filter) : %.3f', bestLaser, de); %#ok<AGROW>
            else
                lines{end+1} = sprintf('  Donor excitation (%g nm laser)       : %.3f', bestLaser, de); %#ok<AGROW>
            end
        else
            lines{end+1} = sprintf('  Donor excitation (no laser; peak)    : %.3f', de); %#ok<AGROW>
        end
        if use_filters_flag == 1
            lines{end+1} = sprintf('  Acceptor collected (Em filter)       : %.3f', collected); %#ok<AGROW>
        else
            lines{end+1} = sprintf('  Acceptor collected (no Em filter)    : %.3f', collected); %#ok<AGROW>
        end
    end

    function lines = computeSelfQuench()
        lines = {'Self-quench overlap (own EM x own EX):'};
        items = selectionList.Items;
        if isempty(items)
            lines{end+1} = '  (no fluorophores in the selected list)'; %#ok<AGROW>
            return;
        end
        for k = 1:numel(items)
            [exk, emk, ~, ~, okk] = getFPSpectra(items{k});
            if ~okk
                lines{end+1} = sprintf('  %-18s : n/a', items{k}); %#ok<AGROW>
                continue;
            end
            sq = spectralOverlap(emk, exk);   % own emission weighted by own excitation
            lines{end+1} = sprintf('  %-18s : %.3f', items{k}, sq); %#ok<AGROW>
        end
    end

    function updateResults()
        resLines = {};
        if fret_flag == 1
            resLines = [resLines, computeFRET()];
        end
        if selfquench_flag == 1
            if ~isempty(resLines), resLines{end+1} = ''; end
            resLines = [resLines, computeSelfQuench()];
        end
        if isempty(resLines)
            resultsArea.Value = {'(enable FRET or Self-quench, then Plot Spectra)'};
        else
            resultsArea.Value = resLines;
        end
    end

    % ---- main plot ----------------------------------------------------

    function plotSpectra()
        fill_opacity = 0.7;

        cla(ax);
        hold(ax, 'on');

        delete(findall(ax, 'Type', 'ConstantLine'));
        delete(findall(ax, 'Type', 'Line'));
        delete(findall(ax, 'Type', 'Text'));

        selectedFluorophores = selectionList.Items;
        if isempty(selectedFluorophores)
            title(ax, 'No fluorophores selected');
            updateResults();
            return;
        end

        % Plot filters
        if plot_filters_flag == 1
            ci = find(strcmp(filter_data.Properties.VariableNames, [exfilter_List.Value '_Ex']), 1);
            plot(ax, filter_data{:,1}, filter_data{:,ci}, ':', 'Color', 'k', 'LineWidth', 1, 'HandleVisibility', 'off');

            plot(ax, filter_data{:,1}, combinedEmFilter(), '--', 'Color', 'k', 'LineWidth', 1, 'HandleVisibility', 'off');
        end

        % Plot camera Quantum Yield
        if plot_Cameras_flag == 1
            ci = find(strcmp(camera_data.Properties.VariableNames, camera_List.Value), 1);
            plot(ax, camera_data{:,1}, camera_data{:,ci}, ':', 'Color', 'k', 'LineWidth', 1, 'HandleVisibility', 'off');
        end

        % Plot excitation & emission spectra for each fluorophore
        for i = 1:length(selectedFluorophores)
            fluorophore = selectedFluorophores{i};

            [exData, emData, exPeakWL, emPeakWL, ok] = getFPSpectra(fluorophore);
            if ~ok
                warning('No excitation or emission spectra found for %s.', fluorophore);
                continue;
            end
            raw_emData = emData;

            % Valid (non-NaN) excitation mask -- always defined now (BUG FIX)
            valid_idx_ex = ~isnan(exData);

            % Colors from spectral peaks
            colorEx = nmToRGB(exPeakWL) / 255;
            colorEm = nmToRGB(emPeakWL) / 255;

            if plot_ExSpectra_flag == 1
                fill(ax, [wavelengths(valid_idx_ex); flip(wavelengths(valid_idx_ex))], ...
                     [zeros(size(exData(valid_idx_ex))); flip(exData(valid_idx_ex))], colorEx, ...
                     'FaceAlpha', fill_opacity, 'EdgeColor', 'none', 'DisplayName', [fluorophore ' EX']);
                plot(ax, wavelengths, exData, '-', 'Color', 'k', 'LineWidth', 0.5, 'HandleVisibility', 'off');
            end

            % Adjust Emission based on laser excitation
            laserValues = str2double(laserList.Items);
            if ~isempty(laserValues)
                Abs_efficiency = 0;
                current_wavelength = wavelengths(valid_idx_ex);
                current_abs = exData(valid_idx_ex);
                laser_selection = 1; % default to the first laser

                for ii = 1:length(laserValues)
                    idx_of_abs = current_wavelength == laserValues(ii);
                    if any(idx_of_abs)
                        curr_efficiency = current_abs(idx_of_abs);
                        if curr_efficiency > Abs_efficiency
                            Abs_efficiency = curr_efficiency;
                            laser_selection = ii;
                        end
                    end
                end

                % Attenuate laser power based on Ex filter transmission %
                if use_filters_flag == 1
                    nm_to_filter = laserValues(laser_selection);
                    ci = find(strcmp(filter_data.Properties.VariableNames, [exfilter_List.Value '_Ex']), 1);
                    laser_attenuation = filter_data{filter_data{:,1} == nm_to_filter, ci};
                    emData = emData .* Abs_efficiency .* laser_attenuation;
                else
                    emData = emData .* Abs_efficiency;
                end
            end

            % Adjust Emission based on collection efficiency (emission optics)
            if use_filters_flag == 1
                emData = emData .* emFilterFraction(emData);
            end

            if use_Cameras_flag == 1
                emData = emData .* cameraFraction(emData);
            end

            if plot_EmSpectra_flag == 1
                valid_em = ~isnan(emData);
                fill(ax, [wavelengths(valid_em); flip(wavelengths(valid_em))], ...
                     [zeros(size(emData(valid_em))); flip(emData(valid_em))], colorEm, ...
                     'FaceAlpha', fill_opacity, 'EdgeColor', 'none', 'DisplayName', [fluorophore ' EM']);
                plot(ax, wavelengths, emData, '--', 'Color', 'k', 'LineWidth', 0.5, 'HandleVisibility', 'off');
            end

            % Peak emission intensity / wavelength label
            [peakIntensity, peakIndex] = max(emData);
            peakWavelength = wavelengths(peakIndex);

            if use_filters_flag == 1 || ~isempty(laserValues) || use_Cameras_flag == 1
                text(ax, peakWavelength, peakIntensity + 0.02, sprintf('%.2f', peakIntensity), ...
                    'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontSize', 12, ...
                    'Color', 'k', 'BackgroundColor', 'w');
            end
        end

        title(ax, 'Excitation and Emission Spectra');
        xlabel(ax, 'Wavelength (nm)');
        xlim(ax, [325 800])

        ylabel(ax, 'Relative intensity (a.u.)');
        ylim(ax, [0 1.1])
        legend(ax, 'show');
        hold(ax, 'off');

        % Plot laser lines
        laserValues = str2double(laserList.Items);
        for i = 1:length(laserValues)
            xline(ax, laserValues(i), 'Color', nmToRGB(laserValues(i)) / 255, 'LineWidth', 3, 'HandleVisibility', 'off');
        end

        % Refresh the analysis panel
        updateResults();
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
        use_filters_flag = double(src.Value);
    end

    function togglePlotFilters(src)
        plot_filters_flag = double(src.Value);
    end

    function toggleCameras(src)
        use_Cameras_flag = double(src.Value);
    end

    function togglePlotCameras(src)
        plot_Cameras_flag = double(src.Value);
    end

    function togglePlot_ExSpectra(src)
        plot_ExSpectra_flag = double(src.Value);
    end

    function togglePlot_EmSpectra(src)
        plot_EmSpectra_flag = double(src.Value);
    end

    function toggleFRET(src)
        fret_flag = double(src.Value);
        updateResults();   % immediate feedback (no full replot needed)
    end

    function toggleSelfQuench(src)
        selfquench_flag = double(src.Value);
        updateResults();
    end

    function enforceSelection(src)
        % Revert to the previous selection if the user deselects everything.
        if isempty(src.Value)
            src.Value = src.UserData;
        else
            src.UserData = src.Value;
        end
    end
end