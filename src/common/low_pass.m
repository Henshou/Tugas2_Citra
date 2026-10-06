function H = low_pass(D, D0, jenis, n)
%LOW_PASS fungsi lowpass dari matriks jarak D
    if D0 <= 0, error('D0 harus positif.'); end
    
    switch lower(jenis)
        case 'ideal'
            H = double(D <= D0);
        case 'gaussian'
            H = exp(-(D.^2) ./ (2*D0^2));
        case 'butterworth'
            H = 1 ./ (1 + (D ./ D0).^(2*n));
        otherwise
            error('Jenis "%s" tidak dikenal.', jenis);
    end
end