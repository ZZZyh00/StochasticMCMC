% Default script to be run for test/debugging purposes
close all
tic;
% Running the Gaussian example
%path = 'GaussianMeanL1/';
%path = 'GaussianVariance/';
path = 'cpusmall/';
addpath(path);

% Runing the runScript from particular folder
runScript

% Removing the path
%rmpath(path);
