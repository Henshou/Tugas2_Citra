function S = freq_spectrum(f)
%FREQ_SPECTRUM Summary of this function goes here
%   Detailed explanation goes here
    f = im2double(f);
    if size(f,3) == 3, f = rgb2gray(f); end
    S = mat2gray(log(1 + abs(fftshift(fft2(f)))));
end