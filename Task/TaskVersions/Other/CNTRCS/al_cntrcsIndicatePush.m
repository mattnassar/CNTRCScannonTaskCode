function al_cntrcsIndicatePush(taskParam)
% AL_CNTRCSINDICATEPUSH This function indicates the push
% condition
%
%   Input:
%       taskParam: Task-parameter-object instance
%
%   Output:
%       ~

if strcmp(taskParam.trialflow.push, 'noPush')
    header = 'Same prediction starting point';
    txt = 'In the next block, the starting point of your prediction will not change.';

elseif strcmp(taskParam.trialflow.push, 'push')
    header = 'Random prediction starting point';
    txt = 'In the next block, the starting point of your prediction will appear randomly to the left or right of your previous position.';
end

feedback = true;
al_bigScreen(taskParam, header, txt, feedback);

end