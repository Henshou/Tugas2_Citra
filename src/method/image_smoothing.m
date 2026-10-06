function [g, H] = image_smoothing(img ,metode, D0, n)
%IMAGE_SMOOTHING Metode blurring/low pass filtering pada ranah frekuensi
    kelas = class(img);  
    f = im2double(img);
    [M, N, ~] = size(f);
    
    [~, ~, D] = freq_grid(2*M, 2*N);
    switch upper(metode)
        case 'ILPF', jenis = 'ideal';
        case 'GLPF', jenis = 'gaussian';
        case 'BLPF', jenis = 'butterworth';
        otherwise, error('Metode "%s" tidak dikenal.', metode);
    end
    
    H0 = low_pass(D, D0, jenis, n);
    g  = freq_convert(freq_filter(f, H0), kelas);
    H  = fftshift(H0);
end