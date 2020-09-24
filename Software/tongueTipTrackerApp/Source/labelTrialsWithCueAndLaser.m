function labelTrialsWithCueAndLaser(varargin)
% Rename files that correspond to xml files with frame number of cue onset
% and laser on. This command also recursively searches subdirectories.
%   Naming convention: originalfilename.avi ==> originalfilename_CXL.avi where
%   "X" is the first frame number with cue on, and the L is present if
%   laser was on.
% xmlDirectory = path to directory that contains xml video info files in
%   phantom camera format (includes subdirectories)
% trialDirectory = path to directory that contains the trial files
%   (typically video files) to be renamed (includes subdirectories)
% trialExtensions = a file extension or cell array of file extensions for
%   files that should be considered for renaming.
% dryRun (optional, default=1) if true, this command doesn't actually
%   rename anything, just outputs a record of what it would do. Set to 0 to
%   actually rename files.
% queue (optional, dummy queue that displays using disp) a message queue 
%   for sending stdout messages to parent process, for parallelization 
%   purposes.

p = inputParser;
addRequired(p, 'xmlDirectory');
addRequired(p, 'trialDirectory');
addRequired(p, 'trialExtensions');
addOptional(p, 'dryRun', false);
addOptional(p, 'queue', []);
addParameter(p, 'verbose', false);
parse(p, varargin{:});
xmlDirectory = p.Results.xmlDirectory;
trialDirectory = p.Results.trialDirectory;
trialExtensions = p.Results.trialExtensions;
dryRun = p.Results.dryRun;
queue = p.Results.queue;
verbose = p.Results.verbose;
disp(p.Results)
% If no queue given, create a dummy queue
if isempty(queue)
    queue = parallel.pool.DataQueue();
    afterEach(queue, @disp);
end

if isempty(trialDirectory)
    % trialDirectory not given, assume the same as xmlDirectory
    trialDirectory = xmlDirectory;
end

% Recursively get a list of all xml files within xmlDirectory and subdirectories
xmlFilepaths = findFilesByExtension(xmlDirectory, '.xml');
[~, xmlFilenames, ~] = cellfun(@fileparts, xmlFilepaths, 'UniformOutput', false);

% Recursively get a list of all trial files within xmlDirectory and subdirectories
trialFilepaths = findFilesByExtension(trialDirectory, trialExtensions);
[~, trialFilenames, ~] = cellfun(@fileparts, trialFilepaths, 'UniformOutput', false);

% Only check xml files that have corresponding trial files
xmlFilepaths = xmlFilepaths(cellfun(@(x)any(contains(trialFilenames, x)), xmlFilenames));

for k = 1:length(xmlFilepaths)
    xmlFilepathCell = xmlFilepaths(k);
    xmlFilepath = cell2mat(xmlFilepathCell);
    if verbose
        send(queue, ['Checking ', xmlFilepath]);
    end
    %    [isLaser, laserOnsetFrame] = isLaserTrial(xmlFilepath);
    [cueFrame, isLaser] = findTriggerFrameAndLaser(xmlFilepath);
    
    %     if isLaser
    %         send(queue, ['  ...LASER! First laser on frame: ', num2str(laserOnsetFrame)]);
    %     else
    %         send(queue, '  ...no laser');
    %     end
    [~, xmlName, ~] = fileparts(xmlFilepath);
    currentTrialPaths = trialFilepaths(contains(trialFilenames, xmlName));
    for filepathCell = currentTrialPaths
        filepath = cell2mat(filepathCell);
        [path, name, ext] = fileparts(filepath);
        
        alreadyDidItStartIndex = regexp(name, '_C[0-9]+L?');
        if alreadyDidItStartIndex
            name = name(1:alreadyDidItStartIndex-1);
        end
        if isLaser
            laserTag = 'L';
        else
            laserTag = '';
        end
        newfilepath = fullfile(path, [name, '_C',num2str(cueFrame), laserTag, ext]);
        if ~strcmp(filepath, newfilepath)
            if dryRun
                send(queue, 'This command would move:');
            else
                movefile(filepath, newfilepath);
                send(queue, 'Moved:')
            end
            send(queue, [filepath, ' to ', newfilepath]);
        end
    end
end

function [cueFrame, isLaser] = findTriggerFrameAndLaser(xmlFilepath)
text = fileread(xmlFilepath);
tokens = regexp(text, '<FirstImageNo>-([0-9]+)</FirstImageNo>', 'tokens');
cueFrame = str2num(tokens{1}{1}) + 1;
if regexp(text, ' E</Time>')
    isLaser = true;
else
    isLaser = false;
end