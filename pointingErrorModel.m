function H_point = pointingErrorModel(wRx, sigmaPoint, Nbits)

%% =========================================================
% Pointing Error Model
% One pointing realization per transmitted bit
% ==========================================================

% Random horizontal and vertical pointing displacement
x_error = sigmaPoint * randn(1, Nbits);
y_error = sigmaPoint * randn(1, Nbits);

% Radial pointing displacement
r_error = sqrt(x_error.^2 + y_error.^2);

% Gaussian beam pointing loss
H_point_bits = exp(-2 * r_error.^2 / wRx^2);

% Return one pointing gain per bit
H_point = H_point_bits;

end