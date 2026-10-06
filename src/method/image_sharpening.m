function [g, H, gSharp] = image_sharpening(img, metode, D0, n, k)
%IMAGE_SHARPENING Metode penajaman/ high pass filtering pada ranah
%frekuensi. Melakukan perhitungan highpass = 1 - lowpass
    kelas = class(img);  f = im2double(img);
    [M, N, ~] = size(f);
    
    [~, ~, D] = freqGrid(2*M, 2*N);
    switch upper(metode)
        case 'IHPF', jenis = 'ideal';
        case 'GHPF', jenis = 'gaussian';
        case 'BHPF', jenis = 'butterworth';
        otherwise, error('Metode "%s" tidak dikenal.', metode);
    end
    
    Hhp = 1 - low_pass(D, D0, jenis, n);      
    
    g      = freq_convert(freq_filter(f, Hhp), kelas);
    gSharp = freq_convert(freq_filter(f, 1 + k*Hhp), kelas);
    H      = fftshift(Hhp);
end