function [g, Hrest, Hpsf] = motionblur_restoration(img, metode, L, theta, option)
%MOTIONBLUR_RESTORATION Degradasi motion blur + restorasi inverse / Wiener.
    if nargin < 5, option = struct(); end
    option = setDefault(option, 'sigma', 0);
    option = setDefault(option, 'K',     0.01);
    option = setDefault(option, 'epsH',  0.01);
    option = setDefault(option, 'Dlim',  Inf);
    
    kelas = class(img);
    f = im2double(img);
    [M, N, ~] = size(f);
    [U, V, D] = freq_grid(M, N);
    
    % --- model degradasi H(u,v) ---
    a = L * sind(theta);   b = L * cosd(theta);
    x = (U/M) * a + (V/N) * b;
    s = ones(size(x));  nz = (x ~= 0);
    s(nz) = sin(pi*x(nz)) ./ (pi*x(nz));
    Hp = s;
    
    switch lower(metode)
        case 'degrade'
            g = freq_filter(f, Hp);
            if option.sigma > 0
                g = g + option.sigma * randn(size(g));
            end
            Hr = [];
    
        case 'inverse'
            Hr = zeros(M, N);
            ok = (abs(Hp) >= option.epsH) & (D <= option.Dlim);
            Hr(ok) = 1 ./ Hp(ok);
            g = freq_filter(f, Hr);
    
        case 'wiener'
            Hr = conj(Hp) ./ (abs(Hp).^2 + option.K);
            g = freq_filter(f, Hr);
    
        otherwise
            error('Metode "%s" tidak dikenal.', metode);
end

g = freq_convert(g, kelas);
Hpsf = fftshift(Hp);
if isempty(Hr), Hrest = []; else, Hrest = fftshift(Hr); end
end

function s = setDefault(s, nama, nilai)
    if ~isfield(s, nama) || isempty(s.(nama)), s.(nama) = nilai; end
end