function tip_track_futures = getTongueTipSessionTrack(varargin)
% getTongueTipSessionTrack(dataRoot, 'params', params, 'verboseFlag', verboseFlag, 'makeMovieFlag', makeMovieFlag, 'saveDataFlag', saveDataFlag, 'savePlotsFlag', savePlotsFlag, 'plotFlag', plotFlag)

defaultParams = setTrackParams();

p = inputParser;
addRequired(p, 'dataRoot');
addOptional(p, 'queue', []);
addParameter(p, 'params', defaultParams, @isstruct)
addParameter(p, 'verboseFlag', false, @islogical)
parse(p, varargin{:});
dataRoot = p.Results.dataRoot;
params = p.Results.params;
verboseFlag = p.Results.verboseFlag;
queue = p.Results.queue;

topFilePaths = dir(fullfile(dataRoot, 'Top*.mat'));
botFilePaths = dir(fullfile(dataRoot, 'Bot*.mat'));

% If parallel pool hasn't been initialized, initialize it.
gcp();

% Initialize array of future promised tip_track outputs
tip_track_futures(1:numel(topFilePaths)) = parallel.FevalFuture;

% Create a queue to allow stdout from functions executing in parallel.
if isempty(queue)
    queue = parallel.pool.DataQueue();
    afterEach(queue, @disp);
end

for i = 1:numel(topFilePaths)  %, max_workers)
    topFilePath = fullfile(topFilePaths(i).folder, topFilePaths(i).name);
    botFilePath = fullfile(botFilePaths(i).folder, botFilePaths(i).name);
    send(queue, ['    Scheduling mask processing of ', topFilePath, ' and ', botFilePath]);
    tip_track_futures(i) = parfeval(@getTongueTipVideoTrack, 1, topFilePath, botFilePath, ...
        queue, 'params', params, 'verboseFlag', verboseFlag);
end