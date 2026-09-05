function severity = estimateJammerSeverity( ...
    features, ...
    jammerClass)

%% =========================================================
% JAMMER SEVERITY ESTIMATOR
%
% Determines how severe a detected jamming attack is.
%
% Input:
%
%   features    -> Receiver feature structure
%
%   jammerClass -> Predicted class from ML detector
%
% Output:
%
%   severity ->
%
%       'Normal'
%       'Mild'
%       'Moderate'
%       'Severe'
%
%% =========================================================


%% =========================================================
% NORMAL COMMUNICATION
%% =========================================================

if strcmp(jammerClass, 'Normal')

    severity = 'Normal';

    return;

end


%% =========================================================
% EXTRACT SATURATION FRACTION
%% =========================================================

satFraction = ...
    features.saturationFraction;


%% =========================================================
% SEVERITY CLASSIFICATION
%
% Mild:
%
%     Low saturation
%
% Moderate:
%
%     Significant receiver influence
%
% Severe:
%
%     Heavy saturation
%
%% =========================================================


%% =========================================================
% MILD ATTACK
%% =========================================================

if satFraction < 0.25

    severity = 'Mild';


    %% =========================================================
    % MODERATE ATTACK
    %% =========================================================

elseif satFraction < 0.60

    severity = 'Moderate';


    %% =========================================================
    % SEVERE ATTACK
    %% =========================================================

else

    severity = 'Severe';

end


end