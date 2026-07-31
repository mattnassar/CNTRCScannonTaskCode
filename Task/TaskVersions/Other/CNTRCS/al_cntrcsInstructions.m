function al_cntrcsInstructions(taskParam)
%AL_CNTRCSINSTRUCTIONS This function runs the instructions for the
% CNTRCS pilot version of the cannon task
%
%   Input
%       taskParam: Task-parameter-object instance
%
%   Output
%       ~

% Extract test day and cBal variables
testDay = taskParam.subject.testDay;
cBal = taskParam.subject.cBal;

% Indicate that cannon will be displayed during instructions
taskParam.trialflow.cannon = 'show cannon';
taskParam.trialflow.currentTickmarks = 'hide';

% Turn off push manipulation
taskParam.trialflow.push = 'practiceNoPush';

% Set text size and font
Screen('TextSize', taskParam.display.window.onScreen, taskParam.strings.textSize);
Screen('TextFont', taskParam.display.window.onScreen, 'Arial');

% 1. Present welcome message
% --------------------------

al_indicateCondition(taskParam, 'Welcome to the Cannon Task!')


if testDay == 1

    % 2. Introduce the cannon
    % -----------------------

    % Load taskData-object instance
    nTrials = 4;
    taskData = al_taskDataMain(nTrials, taskParam.gParam.taskType);

    % Generate practice-phase data
    taskData.catchTrial(1:nTrials) = 0; % no catch trials
    taskData.initiationRTs(1:nTrials) = nan;  % set initiation RT to nan to indicate that this is the first response
    taskData.block(1:nTrials) = 1; % block number
    taskData.allShieldSize(1:nTrials) = rad2deg(2*sqrt(1/taskParam.gParam.concentration)); % shield size
    taskData.shieldType(1:nTrials) = 1; % shield color
    taskData.distMean = [300, 240, 300, 65]; % aim of the cannon
    taskData.outcome = taskData.distMean; % in practice phase, mean and outcome are the same

    taskParam.unitTest.pred = [300, 0, 300, 0];

    % Introduce cannon
    currTrial = 1;
    txt = ['A cannon is aimed at a point on the circle. Your task is to intercept the cannonball with a shield. With the purple '...
        'point, you can indicate where you want to place your shield to intercept the cannonball.\nYou can move the point using the '...
        'green and blue buttons. Use green for fast movements and blue for slow movements.'];
    taskParam = al_introduceCannon(taskParam, taskData, currTrial, txt);

    % 3. Introduce shot of the cannon
    % -------------------------------

    currTrial = 2; % update trial number
    txt = 'The cannon''s target is shown by the black line. Press the space bar for the cannon to fire.';
    [taskData, taskParam] = al_introduceShot(taskParam, taskData, currTrial, txt);

    % 4. Introduce prediction spot and ask participant to catch cannonball
    % --------------------------------------------------------------------

    % Add tickmarks to introduce them to participant
    taskParam.trialflow.currentTickmarks = 'show';
    currTrial = 3; % update trial number

    % Repeat as long as subject misses cannonball
    while 1

        txt=['The black line shows you the position of the last cannonball. The purple line shows you the '...
            'position of your last shield. Please steer the purple point to the cannon''s target and press SPACE.'];
        [taskData, taskParam] = al_introduceSpot(taskParam, taskData, currTrial, txt);

        % If it is a miss, repeat instruction
        if abs(taskData.predErr(currTrial)) >= taskParam.gParam.practiceTrialCriterionEstErr
            header = 'Unfortunately not caught!';
            txt = 'You missed the cannonball. Please try again!';
            feedback = false; % indicate that this is the instruction mode
            al_bigScreen(taskParam, header, txt, feedback);
        else
            break
        end
    end

    % 5. Introduce shield
    % -------------------

    win = true; % Color of shield when catch is rewarded
    txt = ['The shield appears during the shot. In this case, you have intercepted the cannonball. '...
        'If at least half of the cannonball is on the shield, it counts as a hit.'];
    taskData = al_introduceShield(taskParam, taskData, win, currTrial, txt);

    % 6. Ask participant to miss cannonball
    % -------------------------------------

    % Update trial number
    currTrial = 4;

    % Repeat as long as subject catches cannonball
    while 1

        % Introduce miss with shield
        txt = 'Please try to position your shield so that you miss the cannonball. Then press SPACE.';
        [taskData, taskParam] = al_introduceShieldMiss(taskParam, taskData, currTrial, txt);

        % If it is a hit, repeat instruction
        if abs(taskData.predErr(currTrial)) <= taskParam.gParam.practiceTrialCriterionEstErr

            WaitSecs(0.5)
            header = 'Unfortunately caught!';
            txt = 'You caught the cannonball. Please try not to catch it!';
            feedback = false; % indicate that this is the instruction mode
            al_bigScreen(taskParam, header, txt, feedback);
        else
            break
        end

    end

    % 7. Confirm that cannonball was missed
    % -------------------------------------
    win = true;
    txt = 'In this case, you missed the cannonball.';
    al_confirmMiss(taskParam, taskData, win, currTrial, txt);

    % Update unit test predictions
    taskParam.unitTest.pred = zeros(20,1);

    % 8. Introduce variability of the cannon
    % --------------------------------------

    % Display instructions
    header = 'First Practice Block';
    txt=['Because the cannon is quite old, the shots are fairly inaccurate. This means that even if '...
        'you aim exactly at the target, you may still miss the cannonball. The inaccuracy is random, '...
        'but you will still intercept most cannonballs if you place your shield exactly on the spot '...
        'where the cannon is aiming.\n\nIn the next practice block, you will first get used to the cannon''s '...
        'inaccuracy. Keep your shield on the aimed location. If you inaccurately place your shield too many times, '...
        'you must repeat the practice.'];
    feedback = false; % indicate that this is the instruction mode
    al_bigScreen(taskParam, header, txt, feedback);

    % Load outcomes for practice
    taskParam.trialflow.exp = 'practVis';
    if exist('visCannonPracticeCNTRCS.mat', 'file')
        taskData = load('visCannonPracticeCNTRCS.mat');
    else
        taskData = load('visCannonPracticeSleep.mat');
    end
    taskData = taskData.taskData;

    % Reset roation angle to starting location
    taskParam.circle.rotAngle = 0;

    % Run task
    while 1

        % Task loop
        al_cntrcsLoop(taskParam, taskData, taskParam.gParam.practTrials);

        % If estimation error is larger than a criterion on more than five
        % trials, we repeat the instructions
        repeatBlock = sum(abs(taskData.estErr) >= taskParam.gParam.practiceTrialCriterionEstErr);
        if sum(repeatBlock) > taskParam.gParam.practiceTrialCriterionNTrials
            WaitSecs(0.5)
            header = 'Please try again!';
            txt = ['You often placed your shield next to the cannon''s target. In the next round, please try to steer '...
                'the shield directly to the target. The target will be shown by the needle.'];
            al_bigScreen(taskParam, header, txt, feedback);
        else
            break
        end
    end

    % 9. Introduce hidden cannon
    % --------------------------

    % Display instructions
    header = 'Second Practice Block';
    txt = ['So far, you knew the cannon''s target and could intercept most cannonballs. In the next '...
        'practice block, the cannon will no longer be visible. Instead of the cannon, you will see a cross. '...
        'You will also see where the cannonballs land.\n\nTo continue intercepting many cannonballs, you will need to infer '...
        'the location the cannon is aiming at based on the landing positions and place your shield at that position. '...
        'If you think that the cannon is aiming at a new location, you should also move your shield there. Please note '...
        'that even with good predictions, you will still often fail to catch the cannonballs.'];
    feedback = false;
    al_bigScreen(taskParam, header, txt, feedback);

    % Load data set for practice phase
    if exist('hidCannonPracticeCNTRCS.mat', 'file')
        taskData = load('hidCannonPracticeCNTRCS.mat');
    else
        taskData = load('hidCannonPracticeSleep.mat');
    end
    taskData = taskData.taskData;

    % Run task
    taskParam.trialflow.exp = 'practHid';
    taskParam.trialflow.cannon = 'none'; % don't show cannon anymore
    al_cntrcsLoop(taskParam, taskData, taskParam.gParam.practTrials);

    % 10. Introduce bucket push
    % -------------------------

    % Present
    header = 'Final Practice Block: Random Starting Point';

    txtStartTask = ['We now come to the final practice block. On some trials, your prediction (the purple point) will be reset on each trial. '...
        'Try not to be distracted by this and continue steering the shield to the place on the '...
        'circle where you think the cannon''s target is.'];

    feedback = false;
    al_bigScreen(taskParam, header, txtStartTask, feedback);

    % Load data set for practice phase
    if exist('hidCannonPracticeCNTRCSPush.mat', 'file')
        taskData = load('hidCannonPracticeCNTRCSPush.mat');
    else
        taskData = load('hidCannonPracticeSleepPush.mat');
    end
    taskData = taskData.taskData;

    % Run task
    taskParam.trialflow.cannon = 'none'; % don't show cannon anymore
    taskParam.trialflow.push = 'push';
    taskParam.trialflow.exp = 'practHidPush';
    al_cntrcsLoop(taskParam, taskData, taskParam.gParam.practTrials);

else

    % practice = true;

    % Text settings
    Screen('TextFont', taskParam.display.window.onScreen, 'Arial');
    Screen('TextSize', taskParam.display.window.onScreen, 50);
    header = 'Day 2: Practice Block';

    txtStartTask = ['Welcome to the second part of the experiment. As before, you will begin with a practice block. '...
        'On each trial, a cannon will aim at a point on the circle. The cannon''s shots will land near the target. '...
        'Most of the time, the cannon will aim at the same point, but it will also sometimes reorient.\n\n'...
        'You will usually not see the cannon, and will have to infer the target as best you can in order to catch as many cannonballs '...
        'as possible with your shield. Please note that even with good predictions, you will still often fail to catch the cannonballs.\n\n'...
        'When the cannon is shown in rare cases, you should place your shield (purple point) directly on the target.\n\nAlso note '...
        'that in half of the trials, the starting point of your prediction will appear randomly to the left or right of your previous position. '...
        'Try not to be distracted by this and steer your shield to the place on the circle where you think the cannon''s target is.'];

    feedback = false;
    al_bigScreen(taskParam, header, txtStartTask, feedback);

    if cBal == 1 || cBal == 4

        taskParam.trialflow.cannon = 'none'; % don't show cannon anymore
        taskParam.trialflow.currentTickmarks = 'show'; % show tickmarks

        % No-push first...
        % ----------------

        % Load data set for practice phase
        if exist('hidCannonPracticeCNTRCS.mat', 'file')
            taskData = load('hidCannonPracticeCNTRCS.mat');
        else
            taskData = load('hidCannonPracticeSleep.mat');
        end
        taskData = taskData.taskData;

        % Run task
        taskParam.trialflow.push = 'noPush';
        al_cntrcsIndicatePush(taskParam)
        trial = taskParam.gParam.practTrials;
        taskParam.trialflow.exp = 'pract';
        al_cntrcsLoop(taskParam, taskData, trial);

        % ... push second
        % ----------------

        % Load data set for practice phase
        if exist('hidCannonPracticeCNTRCSPush.mat', 'file')
            taskData = load('hidCannonPracticeCNTRCSPush.mat');
        else
            taskData = load('hidCannonPracticeSleepPush.mat');
        end
        taskData = taskData.taskData;

        % Run task
        taskParam.trialflow.push = 'push';
        al_cntrcsIndicatePush(taskParam)
        trial = taskParam.gParam.practTrials;
        al_cntrcsLoop(taskParam, taskData, trial);

    else

        taskParam.trialflow.cannon = 'none'; % don't show cannon anymore
        taskParam.trialflow.currentTickmarks = 'show'; % show tickmarks

        % Push first...
        % -------------

        % Load data set for practice phase
        if exist('hidCannonPracticeCNTRCSPush.mat', 'file')
            taskData = load('hidCannonPracticeCNTRCSPush.mat');
        else
            taskData = load('hidCannonPracticeSleepPush.mat');
        end
        taskData = taskData.taskData;

        % Run task
        taskParam.trialflow.push = 'push';
        al_cntrcsIndicatePush(taskParam)
        trial = taskParam.gParam.practTrials;
        %condition = 'practice';
        al_cntrcsLoop(taskParam, taskData, trial);

        % ... no-push second
        % ------------------

        % Load data set for practice phase
        if exist('hidCannonPracticeCNTRCS.mat', 'file')
            taskData = load('hidCannonPracticeCNTRCS.mat');
        else
            taskData = load('hidCannonPracticeSleep.mat');
        end
        taskData = taskData.taskData;

        % Run task
        taskParam.trialflow.push = 'noPush';
        al_cntrcsIndicatePush(taskParam)
        trial = taskParam.gParam.practTrials;
        al_cntrcsLoop(taskParam, taskData, trial);

    end
end

% Instructions experimental blocks
header = 'We will now begin the experiment';
txtStartTask = ['You have completed the practice phase. In short, you will intercept most cannonballs when you move the purple point to the place where the cannon is aiming. Because you will usually no longer be able to see the cannon, you will have to infer this location based on the position of the recent cannonballs. Please note that even with good predictions, you will still often fail to catch the cannonballs.\n\nIn a few cases, you will see the cannon and can improve your performance by placing the purple point exactly on the target.\n\nIn some cases, the starting point of your prediction will randomly differ from your previous position to the left or right.'...
    '\n\nYou will play four main blocks, as in the practice. Before the first and third main blocks, there will be a short practice block with a visible cannon. There will be 3 short breaks in each block.\n\nGood luck!'];

feedback = false;
al_bigScreen(taskParam, header, txtStartTask, feedback);

end