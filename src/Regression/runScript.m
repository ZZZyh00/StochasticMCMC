% Default script to be run for test/debugging purposes
%close all
display('Running Bayesian Lasso');
tic;
stochastic = 0;

% noDims = 300; % Number of dimensions
% noSamples = 10000; % Number of samples
% 
% % Create the dataset
% [X, y, trueBeta, trueSigmaSq] = generateDataset(noDims, noSamples); 
% 
% % Splitting between training, validation and testing
% train = 1:noSamples * 0.6;
% XTrain = X(train, :);
% yTrain = y(train);
% 
% XTest = X(train(end)+1:end, :);
% yTest = y(train(end)+1:end);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reading the lib linear dataset
addpath('/Users/skottur/CMU/Sem2/graphicalModels/liblinear-1.96/matlab/');
dataPath = '/Users/skottur/CMU/Sem2/graphicalModels/Datasets/cpusmall/train.txt';
[yTrain, XTrain] = libsvmread(dataPath);

noDims = size(XTrain, 2);
noSamples = size(XTrain, 1);

dataPath = '/Users/skottur/CMU/Sem2/graphicalModels/Datasets/cpusmall/test.txt';
[yTest, XTest] = libsvmread(dataPath);

% Splitting for validation data
fraction = 0.1;
validData = rand(noSamples, 1) < fraction;
XVal = XTrain(validData, :);
yVal = yTrain(validData);

XTrain = XTrain(~validData, :);
yTrain = yTrain(~validData);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%lambda = 6;
% EM for lambda
% Splitting for validation
%XVal = XTest(1:2:end, :);
%yVal = yTest(1:2:end);
%XTest = XTest(2:2:end, :);
%yTest = yTest(2:2:end);

initLambda = 0.6;
%lambda = 0.6;
%lambda = runLambdaEM(initLambda, XVal, yVal);

%fprintf('Lambda changed from %f to %f \n\n\n', initLambda, lambda);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Running HMC, select with gradient or stochastic gradient
prob = @likelihood;
if (stochastic)
    gradProb = @stocGradLikelihoodSmooth;
else
    gradProb = @gradLikelihood;
end

% Initializing the options (manually done checking the code in hmc)
options = -1 * ones(18, 1);
options(9) = 0; % false
options(14) = 200000; % Run for 50000 iterations
options(15) = 20000; % burn in
options(7) = 2; % Number of leap steps
options(1) = 0; % Display 
options(18) = 1e-4; %step size

% Infomation for selecting the batches
batchSize = 30;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generating the fisher matrix
% Use mle mean and mle variance
% mleMean = mean(data);
% shifted = bsxfun(@minus, data, mleMean);
% mleVar = 1/size(data, 1) * sum(sum(shifted .* shifted));
% 
% gaussian = struct('type', 'mGaussMean', 'variance', mleVar, ...
%                 'dimensions', noDims);

%gaussian = struct('type', 'mGaussMeanSigma', 'variance', mleVar, ...
%    'dimensions', noDims+1);
%fisher = getFisherMatrix(gaussian);
fisher = zeros(1, noDims+1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

initGuess = rand(1, noDims + 1);
%lambda = 10;

% Stochastic
if (stochastic)
    [samples, energies] = shmc(prob, initGuess, options, gradProb, ...
                                XTrain, yTrain, lambda, batchSize, fisher, []);
else
    [samples, energies] = hmc(prob, initGuess, options, gradProb, ...
                                 XTrain, yTrain, lambda, []);    
end
    
% Verify samples
sparsityCutoff = 1e-3;
generatePlots(XTest, yTest, samples,1, sparsityCutoff);
generatePlots(XTest, yTest, samples, 0, sparsityCutoff);
rejectionAnalysis
Lasso
%generateTrajectory(data, samples, truePDF);                                                
toc
save('samples.mat')
