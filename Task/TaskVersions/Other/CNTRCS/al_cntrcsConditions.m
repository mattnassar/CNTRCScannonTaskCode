function [dataNoPushChangepoint, dataPushChangepoint, dataNoPushOddball, dataPushOddball] = al_cntrcsConditions(taskParam)
%AL_CNTRCSCONDITIONS This function runs the four factorial conditions of the
%   CNTRCS pilot cannon task: push/no-push crossed with changepoint/oddball
%   generative processes.
%
%   Input
%       taskParam: Task-parameter-object instance
%
%   Output
%       dataNoPushChangepoint: Task-data-object for no-push + changepoint
%       dataPushChangepoint: Task-data-object for push + changepoint
%       dataNoPushOddball: Task-data-object for no-push + oddball
%       dataPushOddball: Task-data-object for push + oddball

% -----------------------------------------------------
% 1. Extract some variables from task-parameters object
% -----------------------------------------------------

runIntro = taskParam.gParam.runIntro;
concentration = taskParam.gParam.concentration;
haz = taskParam.gParam.haz;

% --------------------------------
% 2. Show instructions, if desired
% --------------------------------

if runIntro %&& ~taskParam.unitTest.run
    al_cntrcsInstructions(taskParam)
end

taskParam.trialflow.currentTickmarks = 'show';

% ------------
% 3. Main task
% ------------

% Extract number of trials
trial = taskParam.gParam.trials;

% Explicit 2x2 factorial block order
% ---------------------------------
% Participants see one of two block orders:
%   Order A: noPush + changepoint, push + changepoint, noPush + oddball, push + oddball
%   Order B: noPush + oddball, push + oddball, noPush + changepoint, push + changepoint

cBal = taskParam.subject.cBal;
if isempty(cBal) || isnan(cBal)
    cBal = 1;
end

if ismember(cBal, [1, 2])
    blockSpecs = {
        'noPush', 'changepoint';
        'push', 'changepoint';
        'noPush', 'oddball';
        'push', 'oddball'
    };
else
    blockSpecs = {
        'noPush', 'oddball';
        'push', 'oddball';
        'noPush', 'changepoint';
        'push', 'changepoint'
    };
end

for blockIdx = 1:size(blockSpecs, 1)

    pushMode = blockSpecs{blockIdx, 1};
    generationMode = blockSpecs{blockIdx, 2};

    % Run a visible-cannon practice block before the first and third main blocks
    if ismember(blockIdx, [1, 3])
        taskParam.trialflow.cannon = 'show cannon';
        taskParam.trialflow.currentTickmarks = 'show';
        taskParam.trialflow.push = 'practiceNoPush';
        taskParam.trialflow.generationMode = generationMode;
        if strcmpi(generationMode, 'oddball')
            taskParam.trialflow.distMean = 'drift';
        else
            taskParam.trialflow.distMean = 'fixed';
        end

        if ~taskParam.unitTest.run
            practiceTaskData = al_taskDataMain(taskParam.gParam.practTrials, taskParam.gParam.taskType);
            practiceTaskData = practiceTaskData.al_cannonData(taskParam, haz, concentration, taskParam.gParam.safe);
        else
            load('integrationTest_sleep.mat','taskData')
            practiceTaskData = taskData;
        end

        if strcmpi(generationMode, 'changepoint')
            practiceLabel = 'changing target locations';
        else
            practiceLabel = 'unexpected outliers';
        end

        header = 'Practice block';
        txt = sprintf('You will now see a short practice block with %s.', practiceLabel);
        feedback = false;
        al_bigScreen(taskParam, header, txt, feedback);
        al_cntrcsLoop(taskParam, practiceTaskData, taskParam.gParam.practTrials);
    end

    % Generate task data for the current block
    if ~taskParam.unitTest.run

        % TaskData-object instance
        taskData = al_taskDataMain(trial, taskParam.gParam.taskType);

        % Set generation mode before generating outcomes
        taskParam.trialflow.generationMode = generationMode;
        if strcmpi(generationMode, 'oddball')
            taskParam.trialflow.distMean = 'drift';
        else
            taskParam.trialflow.distMean = 'fixed';
        end

        % Generate outcomes using cannonData function
        taskData = taskData.al_cannonData(taskParam, haz, concentration, taskParam.gParam.safe);

    else
        load('integrationTest_sleep.mat','taskData')
    end

    % Run task for the current block
    taskParam.trialflow.cannon = 'none';
    taskParam.trialflow.push = pushMode;
    taskParam.trialflow.generationMode = generationMode;
    if strcmpi(generationMode, 'oddball')
        taskParam.trialflow.distMean = 'drift';
    else
        taskParam.trialflow.distMean = 'fixed';
    end
    al_cntrcsIndicatePush(taskParam)

    switch lower(pushMode)
        case 'nopush'
            if strcmpi(generationMode, 'changepoint')
                dataNoPushChangepoint = al_cntrcsLoop(taskParam, taskData, trial);
            else
                dataNoPushOddball = al_cntrcsLoop(taskParam, taskData, trial);
            end

        case 'push'
            if strcmpi(generationMode, 'changepoint')
                dataPushChangepoint = al_cntrcsLoop(taskParam, taskData, trial);
            else
                dataPushOddball = al_cntrcsLoop(taskParam, taskData, trial);
            end
    end
end

end
