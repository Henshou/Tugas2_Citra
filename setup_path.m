function root = setup_path()
%SETUP_PATH Summary of this function goes here
%   Detailed explanation goes here
    root = fileparts(mfilename('fullpath'));    
    addpath(genpath(fullfile(root, 'src')));
end