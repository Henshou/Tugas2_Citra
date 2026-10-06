function out = freq_convert(g,kelas)
%FREQ_CONVERT Clipping ke [0,1] lalu kembalikan ke kelas citra asal.
    g = min(max(g, 0), 1);
    switch kelas
        case 'uint8',  out = im2uint8(g);
        case 'uint16', out = im2uint16(g);
        otherwise,     out = g;
    end
end