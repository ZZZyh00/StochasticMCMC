% Default script to be run for test/debugging purposes
close all
tic;
% Running the Gaussian example
%addpath('GaussianExample/');

noDims = 2; % Number of dimensions
noSamples = 1000; % Number of samples

% Create the dataset
[data, truePDF] = generateDataset(noDims, noSamples); 


% Initializing the options (manually done checking the code in hmc)
options = -1 * ones(18, 1);
options(9) = 0; % false
options(14) = 100000; % Run for 50000 iterations
options(15) = 1000; % burn in
options(7) = 10; % Number of leap steps
options(1) = 0; % Display 
options(18) = 0.0001;
stochastic = true;

% Running HMC, select with gradient or stochastic gradient
prob = @likelihood;
if(stochastic)
    gradProb = @stocGradLikelihood;
else
    gradProb = @gradLikelihood;
end

meanPrior = struct('mean', 0.5 * ones(1, noDims), ...
                'variance', eye(noDims), ...
                'precision', eye(noDims));

% Generating multiple samples
noMCMC = 1;
mcmcSamples = zeros(noMCMC, noDims);

% Infomation for selecting the batches
batchSize = 5;
batchSelect = 1;  % 1 for random and 2 for linear
batchInfo = struct('size', batchSize, 'select', batchSelect);

%%%%%%%%%%%%%%%%%%%%%%%%%% HMC without stochastic %%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(~stochastic)
    for i = 1:noMCMC
        initGuess = [rand(1, noDims), 1];
        [samples, energies, diagn] = hmc(prob, initGuess, options, gradProb, ...
                                          data, meanPrior, batchInfo);
        % Selecting the batches at 'random' or in a 'linear' way

        mcmcSamples = samples(1:100:size(samples, 1), :);
    end
else
    % Generating the fisher matrix
    % Use mle mean and mle variance
    mleMean = mean(data);
    shifted = bsxfun(@minus, data, mleMean);
    mleVar = 1/size(data, 1) * sum(sum(shifted .* shifted));
    
    gaussian = struct('type', 'mGaussMeanSigma', 'variance', mleVar, ...
                    'dimensions', noDims + 1);
    fisher = getFisherMatrix(gaussian);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%% HMC with stochastic %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for i = 1:noMCMC
        initGuess = [rand(1, noDims), 1];
        [samples, energies, diagn] = sghmc(prob, initGuess, options, gradProb,...
                                            fisher, ...
                                           data, meanPrior, batchInfo);
        % Selecting the batches at 'random' or in a 'linear' way
        
        mcmcSamples = samples;
        %mcmcSamples = samples(1:100:size(samples, 1), :);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Verify samples
generatePlots(data, mcmcSamples, truePDF, meanPrior, initGuess);
%generateTrajectory(data, samples, truePDF);                                                
toc