function [g, H, notches] = periodic_restoration(img, metode, option)
%PERIODIC_RESTORATION Restorasi derau periodik di ranah frekuensi.
    if nargin < 3, option = struct(); end
    option = setDefault(option, 'D0', 30);
    option = setDefault(option, 'W', 10);
    option = setDefault(option, 'n', 2);
    option = setDefault(option, 'notches', []);
    option = setDefault(option, 'jenis', 'butterworth');
    option = setDefault(option, 'kStd', 5);
    option = setDefault(option, 'maxNotch', 4);
    option = setDefault(option, 'excl', 0.05);

    kelas = class(img);  
    f = im2double(img);
    [M, N, ~] = size(f);
    [U, V, D] = freq_grid(M, N);
    notches = zeros(0, 2);
    
    switch upper(metode)
        case 'IBR', H0 = bandreject(D, option.D0, option.W, 'ideal',       option.n);
        case 'GBR', H0 = bandreject(D, option.D0, option.W, 'gaussian',    option.n);
        case 'BBR', H0 = bandreject(D, option.D0, option.W, 'butterworth', option.n);
        case 'NR'
            notches = option.notches;
            if isempty(notches), notches = detectNotches(f, option); end
            H0 = notchReject(U, V, M, N, notches, option.D0, option.jenis, option.n);
        otherwise
            error('Metode "%s" tidak dikenal (IBR, GBR, BBR, NR).', metode);
    end
    
    g = freq_convert(freq_filter(f, H0), kelas);
    H = fftshift(H0);
end


%% ---------- Bandreject ----------
function H = bandreject(D, D0, W, jenis, n)
if D0 <= 0 || W <= 0, error('D0 dan W harus positif.'); end
switch jenis
    case 'ideal'
        H = double(~(D >= D0 - W/2 & D <= D0 + W/2));
    case 'gaussian'
        Dd = max(D, eps);                     
        H = 1 - exp(-((D.^2 - D0^2) ./ (Dd * W)).^2);
    case 'butterworth'
        Dd = max(D, eps);
        H = 1 ./ (1 + abs((Dd * W) ./ (D.^2 - D0^2)).^(2*n));
end
end

%% ---------- Notch reject ----------
function H = notchReject(U, V, M, N, notches, D0, jenis, n)
cr = floor(M/2) + 1;  cc = floor(N/2) + 1;    
offs = notches - [cr cc];                     
H = ones(M, N);
for k = 1:size(offs, 1)
    uk = offs(k,1);  vk = offs(k,2);
    Dk  = sqrt((U - uk).^2 + (V - vk).^2);
    Dmk = sqrt((U + uk).^2 + (V + vk).^2);
    H = H .* (1 - low_pass(Dk,  D0, jenis, n)).* (1 - low_pass(Dmk, D0, jenis, n));
end
end

%% ---------- Deteksi puncak derau ----------
function notches = detectNotches(f, opts)
    S = freq_spectrum(f);
    [M, N] = size(S);
    cr = floor(M/2) + 1;  cc = floor(N/2) + 1;
    [C, R] = meshgrid(1:N, 1:M);
    
    jauh = hypot(R - cr, C - cc) > opts.excl * min(M, N);  
    half = (R > cr) | (R == cr & C > cc);                
    thr  = mean(S(:)) + opts.kStd * std(S(:));
    cand = imregionalmax(S) & (S > thr) & jauh & half;
    
    idx = find(cand);
    [~, ord] = sort(S(idx), 'descend');
    idx = idx(ord(1:min(numel(ord), opts.maxNotch)));
    [r, c] = ind2sub([M N], idx);
    notches = [r c];
    if isempty(notches)
        warning('Tidak ada puncak derau terdeteksi.');
        notches = zeros(0, 2);
    end
end

function s = setDefault(s, nama, nilai)
if ~isfield(s, nama) || isempty(s.(nama)), s.(nama) = nilai; end
end