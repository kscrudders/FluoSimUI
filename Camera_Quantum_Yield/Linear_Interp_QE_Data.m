% sCMOS_ZYLA_QE_Interp.m
% Read Zyla QE CSV, interp to 1 nm grid 300–1100 nm, zero-pad outside data range

csvPath = "E:\01_Matlab\99_Github\FluoSimUI\Camera_Quantum_Yield\sCMOS_Sona-2BV11_Andor.csv";

raw = readmatrix(csvPath);
wl_data = raw(:,1);   % nm
qe_data = raw(:,2);   % percent

% Output grid
wl_out = (300:1:1100)';

% Interp within data range, 0 outside
qe_out = zeros(size(wl_out));
mask = wl_out >= min(wl_data) & wl_out <= max(wl_data);
qe_out(mask) = interp1(wl_data, qe_data, wl_out(mask), 'linear');

qe_out = qe_out ./100;

% Optional: plot
figure;
plot(wl_out, qe_out, 'b-', 'LineWidth', 1.5);
xlabel('Wavelength (nm)');
ylabel('QE (fraction)');
title('Zyla 4.2P QE');
grid on;