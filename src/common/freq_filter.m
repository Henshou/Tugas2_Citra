function g = freq_filter(f,H)
%FREQ_FILTER Inti penapisan ranah frekuensi: FFT -> kali H -> IFFT -> crop.
    [M, N, C] = size(f);
    [P, Q] = size(H);
    if ~((P == 2*M && Q == 2*N) || (P == M && Q == N))
        error('Ukuran H harus MxN atau 2Mx2N (citra %dx%d, H %dx%d).', M, N, P, Q);
    end
    
    g = zeros(M, N, C);
    for c = 1:C
        F  = fft2(f(:,:,c), P, Q);     
        gp = real(ifft2(H .* F));
        g(:,:,c) = gp(1:M, 1:N);
    end
end