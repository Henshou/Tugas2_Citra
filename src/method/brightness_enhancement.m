function [g, H] = brightness_enhancement(img, D0, gammaL, gammaH)
%BRIGHTNESS_ENHANCEMENT Menggunakan homomorphic filtering untuk
%meningkatkan kecerahan
    kelas = class(img);  f = im2double(img);
    isRGB = size(f,3) == 3;
    if isRGB
        hsv = rgb2hsv(f);  I = hsv(:,:,3);
    else
        I = f;
    end
    [M, N] = size(I);
    
    [~, ~, D] = freq_grid(2*M, 2*N);
    H0 = (gammaH - gammaL) * (1 - exp(-(D.^2) / (2*D0^2))) + gammaL;
    
    z   = log1p(I);               
    s   = freq_filter(z, H0);
    out = expm1(s);
    out = (out - min(out(:))) / (max(out(:)) - min(out(:)) + eps);
    
    if isRGB
        hsv(:,:,3) = out;  g = hsv2rgb(hsv);
    else
        g = out;
    end
    g = freq_convert(g, kelas);
    H = fftshift(H0);
end