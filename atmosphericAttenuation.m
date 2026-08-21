function H_atm = atmosphericAttenuation(alpha, L)

%% Convert distance from metres to kilometres

L_km = L / 1e3;


%% Atmospheric attenuation

H_atm = 10^(-alpha * L_km / 10);

end