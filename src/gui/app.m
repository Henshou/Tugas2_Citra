function app()
%APP Summary of this function goes here
%   Detailed explanation goes here
    root = setup_path();
 
    f = [];  g = [];  Sorig = [];  ref = [];
    notches = zeros(0, 2);
    selRow  = [];
 
    cats  = {'Image Smoothing', 'Image Sharpening', 'Brightness Enhancement', ...
             'Periodic Noise Restoration', 'Motion Blur Restoration'};
    mItems = {{'Ideal LPF (ILPF)', 'Gaussian LPF (GLPF)', 'Butterworth LPF (BLPF)'}, ...
              {'Ideal HPF (IHPF)', 'Gaussian HPF (GHPF)', 'Butterworth HPF (BHPF)'}, ...
              {'Homomorphic filter'}, ...
              {'Bandreject Ideal (IBR)', 'Bandreject Gaussian (GBR)', ...
               'Bandreject Butterworth (BBR)', 'Notch reject (NR)'}, ...
              {'Inverse filter', 'Wiener filter', 'Degrade (simulate blur)'}};
    mData  = {{'ILPF','GLPF','BLPF'}, {'IHPF','GHPF','BHPF'}, {'homomorphic'}, ...
              {'IBR','GBR','BBR','NR'}, {'inverse','wiener','degrade'}};
 
    fig  = uifigure('Name', 'Frequency-Domain Image Processing', ...
                    'Position', [40 40 1300 760]);
    main = uigridlayout(fig, [1 2]);
    main.ColumnWidth = {350, '1x'};
 
    left = uigridlayout(main, [7 1]);
    left.RowHeight = {32, 28, 28, '1x', 24, 36, 48};
    left.Padding = [8 8 8 8];  left.RowSpacing = 6;
 
    bGrid = uigridlayout(left, [1 2]);  bGrid.Padding = [0 0 0 0];
    uibutton(bGrid, 'Text', 'Load Image',  'ButtonPushedFcn', @onLoad);
    uibutton(bGrid, 'Text', 'Add Reference', 'ButtonPushedFcn', @onAddRef);
 
    ddCat    = uidropdown(left, 'Items', cats, 'ValueChangedFcn', @onCategory);
    ddMethod = uidropdown(left, 'Items', {'-'}, 'ValueChangedFcn', @onParamChanged);
 
    host = uigridlayout(left, [1 1]);  host.Padding = [0 0 0 0];
    pnl = cell(1, 5);
    for ii = 1:5
        pp = uipanel(host, 'BorderType', 'none', 'Visible', 'off');
        pp.Layout.Row = 1;  pp.Layout.Column = 1;
        pnl{ii} = pp;
    end
 
    chkAuto = uicheckbox(left, 'Text', 'Auto-update saat parameter berubah', 'Value', true);
    uibutton(left, 'Text', 'Apply', 'FontWeight', 'bold', 'ButtonPushedFcn', @runPipeline);
    lblStatus = uilabel(left, 'Text', 'Load an image to start.', 'WordWrap', 'on');
 
    % 1. Smoothing
    g1 = mkGrid(1, {26, 26});
    eSmD0 = addNum(g1, 1, 'D0 (cutoff, px)', 30, [1 Inf]);
    eSmN  = addNum(g1, 2, 'n (Butterworth order)', 2, [1 20]);
 
    % 2. Sharpening
    g2 = mkGrid(2, {26, 26, 26, 26});
    eShD0 = addNum(g2, 1, 'D0 (cutoff, px)', 30, [1 Inf]);
    eShN  = addNum(g2, 2, 'n (Butterworth order)', 2, [1 20]);
    eShK  = addNum(g2, 3, 'k (high-boost)', 1.5, [0 20]);
    ddShOut = addDD(g2, 4, 'Output', {'Highpass only', 'Sharpened (f + k*HP)'}, {'hp','sharp'}, 'sharp');
 
    % 3. Brightness
    g3 = mkGrid(3, {26, 26, 26});
    eBrD0 = addNum(g3, 1, 'D0 (cutoff, px)', 30, [1 Inf]);
    eBrGL = addNum(g3, 2, 'gamma L (< 1)', 0.5, [0 1]);
    eBrGH = addNum(g3, 3, 'gamma H (> 1)', 2, [1 10]);
 
    % 4. Periodic noise
    g4 = mkGrid(4, {26, 26, 26, 26, 26, 26, 26, 110, 30});
    ePnD0   = addNum(g4, 1, 'D0 (band radius / notch radius)', 10, [1 Inf]);
    ePnW    = addNum(g4, 2, 'W (band width)', 10, [1 Inf]);
    ePnN    = addNum(g4, 3, 'n (Butterworth order)', 2, [1 20]);
    ePnJenis = addDD(g4, 4, 'Notch shape', {'ideal','gaussian','butterworth'}, ...
                     {'ideal','gaussian','butterworth'}, 'butterworth');
    eKStd   = addNum(g4, 5, 'Detect: threshold (k*std)', 5, [0.5 50]);
    eMax    = addNum(g4, 6, 'Detect: max notches', 4, [1 50]);
    eExcl   = addNum(g4, 7, 'Detect: DC exclusion (frac)', 0.05, [0 0.5]);
    tblNotch = uitable(g4, 'ColumnName', {'Row', 'Col'}, 'ColumnEditable', [true true], ...
                       'ColumnFormat', {'numeric', 'numeric'}, 'Data', notches, ...
                       'CellEditCallback', @onCellEdit, 'CellSelectionCallback', @onCellSelect);
    tblNotch.Layout.Row = 8;  tblNotch.Layout.Column = [1 2];
    nbGrid = uigridlayout(g4, [1 3]);  nbGrid.Padding = [0 0 0 0];
    nbGrid.Layout.Row = 9;  nbGrid.Layout.Column = [1 2];
    btnDetect = uibutton(nbGrid, 'Text', 'Auto-detect', 'ButtonPushedFcn', @onDetect);
    btnRemove = uibutton(nbGrid, 'Text', 'Remove sel.', 'ButtonPushedFcn', @onRemove);
    btnClear  = uibutton(nbGrid, 'Text', 'Clear all',   'ButtonPushedFcn', @onClear);
 
    % 5. Motion blur
    g5 = mkGrid(5, {26, 26, 26, 26, 26, 26});
    eMbL     = addNum(g5, 1, 'Length L (px)', 15, [1 500]);
    eMbTheta = addNum(g5, 2, 'Angle theta (deg)', 0, [-180 180]);
    eMbK     = addNum(g5, 3, 'K (Wiener NSR)', 0.01, [1e-8 Inf]);
    eMbEps   = addNum(g5, 4, 'epsH (inverse threshold)', 0.05, [0 1]);
    eMbDlim  = addNum(g5, 5, 'Dlim (inverse, 0 = none)', 0, [0 Inf]);
    eMbSigma = addNum(g5, 6, 'Noise sigma (degrade)', 0, [0 1]);
 
    right = uigridlayout(main, [2 3]);
    axOrig    = mkAxes(1, 1, 'Original');
    axSpec    = mkAxes(1, 2, 'Magnitude spectrum (log, fftshift)');
    axH       = mkAxes(1, 3, 'Filter |H(u,v)|');
    axRes     = mkAxes(2, 1, 'Result');
    axSpecRes = mkAxes(2, 2, 'Result spectrum');
    axDiff    = mkAxes(2, 3, 'Difference |reference - result|');
 
    onCategory();     
 
    function onLoad(~, ~)
        startDir = fullfile(root, 'dataset');
        if ~isfolder(startDir), startDir = root; end
        [fn, fp] = uigetfile({'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp', 'Images'}, ...
                             'Select image', startDir);
        figure(fig);
        if isequal(fn, 0), return; end
        [A, cmap] = imread(fullfile(fp, fn));
        if ~isempty(cmap), A = ind2rgb(A, cmap); end
        if size(A, 3) == 4, A = A(:, :, 1:3); end     
        f = A;  g = [];
        notches = zeros(0, 2);  tblNotch.Data = notches;  selRow = [];
        Sorig = freq_spectrum(f);
        showImg(axOrig, f, sprintf('Original (%dx%d, %s)', size(f,1), size(f,2), class(f)));
        clearResultAxes();
        refreshSpectra();
        setStatus(sprintf('Loaded %s', fn));
        autoRun();
    end
 
    function onAddRef(~, ~)
        startDir = fullfile(root, 'dataset');
        if ~isfolder(startDir), startDir = root; end
        [fn, fp] = uigetfile({'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp', 'Images'}, ...
                             'Select reference image', startDir);
        figure(fig);
        if isequal(fn, 0), return; end
        [A, cmap] = imread(fullfile(fp, fn));
        if ~isempty(cmap), A = ind2rgb(A, cmap); end
        if size(A, 3) == 4, A = A(:, :, 1:3); end
        ref = A;
        setStatus(sprintf('Reference: %s', fn));
        autoRun();
    end
 
    function onCategory(~, ~)
        kk = find(strcmp(ddCat.Value, cats));
        for jj = 1:5, pnl{jj}.Visible = onoff(jj == kk); end
        ddMethod.ItemsData = {};
        ddMethod.Items     = mItems{kk};
        ddMethod.ItemsData = mData{kk};
        ddMethod.Value     = mData{kk}{1};
        updateEnable();
        refreshSpectra();
        autoRun();
    end
 
    function onParamChanged(~, ~)
        updateEnable();
        autoRun();
    end
 
    function autoRun()
        if chkAuto.Value && ~isempty(f), runPipeline(); end
    end
 
    function runPipeline(~, ~)
        if isempty(f), setStatus('Load an image first.'); return; end
        kk = find(strcmp(ddCat.Value, cats));
        mm = ddMethod.Value;
        setStatus('Processing...');  drawnow;
        t0 = tic;
        try
            switch kk
                case 1
                    [g, H] = image_smoothing(f, mm, eSmD0.Value, eSmN.Value);
                case 2
                    [gHP, H, gSh] = image_sharpening(f, mm, eShD0.Value, eShN.Value, eShK.Value);
                    if strcmp(ddShOut.Value, 'hp'), g = gHP; else, g = gSh; end
                case 3
                    [g, H] = brightness_enhancement(f, eBrD0.Value, eBrGL.Value, eBrGH.Value);
                case 4
                    [g, H, nt] = periodic_restoration(f, mm, pnOpts());
                    if strcmp(mm, 'NR')
                        notches = nt;  tblNotch.Data = notches;
                        refreshSpectra();
                    end
                case 5
                    dl = eMbDlim.Value;  if dl <= 0, dl = Inf; end
                    o = struct('K', eMbK.Value, 'epsH', eMbEps.Value, 'Dlim', dl, ...
                               'sigma', eMbSigma.Value);
                    [g, Hr, Hp] = motionblur_restoration(f, mm, eMbL.Value, eMbTheta.Value, o);
                    if isempty(Hr), H = Hp; else, H = Hr; end
            end
        catch ME
            uialert(fig, ME.message, 'Processing error');
            setStatus(['Error: ' ME.message]);
            return;
        end
        showImg(axRes, g, sprintf('Result (%s)', mm));
        showImg(axSpecRes, freq_spectrum(g), 'Result spectrum');
        showImg(axH, mat2gray(abs(H)), 'Filter |H(u,v)|');
        if isempty(ref)
            cla(axDiff);
            title(axDiff, 'Difference |reference - result| (add a reference)');
        elseif ~isequal(size(ref), size(g))
            cla(axDiff);
            title(axDiff, 'Reference size differs from result');
        else
            d = mean(abs(im2double(ref) - im2double(g)), 3);
            imshow(d, [0 0.25], 'Parent', axDiff);
         
            title(axDiff, {'|reference - result|', ...
                  sprintf('PSNR %.2f dB   SSIM %.3f', psnr(im2double(g), im2double(ref)), ssim(im2double(g), im2double(ref)))});
        end
        setStatus(sprintf('%s done in %.2f s', mm, toc(t0)));
    end
 
    %% ---- Periodic noise: notch handling ----
    function o = pnOpts()
        o = struct('D0', ePnD0.Value, 'W', ePnW.Value, 'n', ePnN.Value, ...
                   'jenis', ePnJenis.Value, 'kStd', eKStd.Value, ...
                   'maxNotch', round(eMax.Value), 'excl', eExcl.Value, ...
                   'notches', notches);
    end
 
    function onDetect(~, ~)
        if isempty(f), return; end
        o = pnOpts();  o.notches = [];
        [~, ~, nt] = periodic_restoration(f, 'NR', o);
        notches = nt;  tblNotch.Data = notches;
        refreshSpectra();
        setStatus(sprintf('%d notch(es) detected.', size(nt, 1)));
        autoRun();
    end
 
    function onRemove(~, ~)
        if ~isempty(selRow) && selRow <= size(notches, 1)
            notches(selRow, :) = [];  selRow = [];
            tblNotch.Data = notches;  refreshSpectra();  autoRun();
        end
    end
 
    function onClear(~, ~)
        notches = zeros(0, 2);  selRow = [];
        tblNotch.Data = notches;  refreshSpectra();
    end
 
    function onCellEdit(~, ~)
        nt = round(tblNotch.Data);
        nt(any(isnan(nt), 2), :) = [];
        notches = nt;  refreshSpectra();  autoRun();
    end
 
    function onCellSelect(~, evt)
        if isempty(evt.Indices), selRow = []; else, selRow = evt.Indices(1, 1); end
    end
 
    function onSpecClick(~, ~)
        if isempty(f) || ~strcmp(ddCat.Value, cats{4}) || ~strcmp(ddMethod.Value, 'NR')
            return;
        end
        cp = axSpec.CurrentPoint;
        [Mi, Ni, ~] = size(f);
        col = min(max(round(cp(1, 1)), 1), Ni);
        row = min(max(round(cp(1, 2)), 1), Mi);
        notches(end+1, :) = [row col];
        tblNotch.Data = notches;
        refreshSpectra();  autoRun();
    end
 
    function refreshSpectra()
        if isempty(Sorig), return; end
        showMarkers = strcmp(ddCat.Value, cats{4});
        hImg = showImg(axSpec, Sorig, 'Magnitude spectrum (log, fftshift)');
        disableDefaultInteractivity(axSpec);
        if showMarkers && ~isempty(notches)
            [Mi, Ni] = size(Sorig);
            cr = floor(Mi/2) + 1;  cc = floor(Ni/2) + 1;
            hold(axSpec, 'on');
            plot(axSpec, notches(:,2), notches(:,1), 'r+', 'MarkerSize', 12, ...
                 'LineWidth', 1.5, 'PickableParts', 'none');
            plot(axSpec, 2*cc - notches(:,2), 2*cr - notches(:,1), 'c+', ...
                 'MarkerSize', 12, 'LineWidth', 1.5, 'PickableParts', 'none');
            hold(axSpec, 'off');
        end
        hImg.ButtonDownFcn = @onSpecClick;
    end
 
    function clearResultAxes()
        for ax = {axRes, axSpecRes, axH, axDiff}
            cla(ax{1});
        end
    end
 
    function setStatus(msg)
        lblStatus.Text = msg;
    end
 
    function updateEnable()
        kk = find(strcmp(ddCat.Value, cats));
        mm = ddMethod.Value;
        switch kk
            case 1, eSmN.Enable = onoff(strcmp(mm, 'BLPF'));
            case 2, eShN.Enable = onoff(strcmp(mm, 'BHPF'));
            case 4
                isNR = strcmp(mm, 'NR');
                ePnW.Enable = onoff(~isNR);
                ePnN.Enable = onoff(strcmp(mm, 'BBR') || ...
                                    (isNR && strcmp(ePnJenis.Value, 'butterworth')));
                for hh = {ePnJenis, eKStd, eMax, eExcl, tblNotch, btnDetect, btnRemove, btnClear}
                    hh{1}.Enable = onoff(isNR);
                end
            case 5
                eMbK.Enable     = onoff(strcmp(mm, 'wiener'));
                eMbEps.Enable   = onoff(strcmp(mm, 'inverse'));
                eMbDlim.Enable  = onoff(strcmp(mm, 'inverse'));
                eMbSigma.Enable = onoff(strcmp(mm, 'degrade'));
        end
    end

    function gr = mkGrid(idx, heights)
        gr = uigridlayout(pnl{idx}, [numel(heights) 2]);
        gr.RowHeight = heights;  gr.ColumnWidth = {'1x', 110};
        gr.Padding = [0 0 0 0];  gr.Scrollable = 'on';
    end
 
    function e = addNum(gr, row, lbl, val, lim)
        l = uilabel(gr, 'Text', lbl);
        l.Layout.Row = row;  l.Layout.Column = 1;
        e = uieditfield(gr, 'numeric', 'Value', val, 'Limits', lim, ...
                        'ValueChangedFcn', @onParamChanged);
        e.Layout.Row = row;  e.Layout.Column = 2;
    end
 
    function d = addDD(gr, row, lbl, items, data, val)
        l = uilabel(gr, 'Text', lbl);
        l.Layout.Row = row;  l.Layout.Column = 1;
        d = uidropdown(gr, 'Items', items, 'ItemsData', data, 'Value', val, ...
                       'ValueChangedFcn', @onParamChanged);
        d.Layout.Row = row;  d.Layout.Column = 2;
    end
 
    function ax = mkAxes(row, col, ttl)
        ax = uiaxes(right);
        ax.Layout.Row = row;  ax.Layout.Column = col;
        ax.XTick = [];  ax.YTick = [];
        title(ax, ttl);
    end
 
    function hImg = showImg(ax, img, ttl)
        hImg = imshow(img, 'Parent', ax);
        title(ax, ttl);
    end
end
 
function s = onoff(tf)
    if tf, s = 'on'; else, s = 'off'; end
end