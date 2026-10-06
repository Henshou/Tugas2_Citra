function [U, V, D] = freq_grid(P, Q)
%FREQ_GRID Summary of this function goes here
%   Detailed explanation goes here
    u = 0:(P-1);  v = 0:(Q-1);
    u(u >= P/2) = u(u >= P/2) - P;
    v(v >= Q/2) = v(v >= Q/2) - Q;
    [V, U] = meshgrid(v, u);
    D = sqrt(U.^2 + V.^2);
end