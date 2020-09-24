function varargout = manualObjectTracker(varargin)
% MANUALOBJECTTRACKER MATLAB code for manualObjectTracker.fig
%      MANUALOBJECTTRACKER, by itself, creates a new MANUALOBJECTTRACKER or raises the existing
%      singleton*.
%
%      H = MANUALOBJECTTRACKER returns the handle to a new MANUALOBJECTTRACKER or the handle to
%      the existing singleton*.
%
%      MANUALOBJECTTRACKER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MANUALOBJECTTRACKER.M with the given input arguments.
%
%      MANUALOBJECTTRACKER('Property','Value',...) creates a new MANUALOBJECTTRACKER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to tRhe GUI before manualObjectTracker_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to manualObjectTracker_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help manualObjectTracker

% Last Modified by GUIDE v2.5 12-Jun-2020 16:00:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @manualObjectTracker_OpeningFcn, ...
    'gui_OutputFcn',  @manualObjectTracker_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before manualObjectTracker is made visible.
function manualObjectTracker_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to manualObjectTracker (see VARARGIN)
handles.version = '1.14.1';

ensureMOTIsOnPath()

switch nargin
    case 4
        loadVideoOrImage(hObject, varargin{1});
        handles = guidata(hObject);
end

videoDependentControlEnableState(handles, 'off')

% Default path to start when browsing for files
handles.defaultPath = '';
handles.currentROIFile = '';
handles.nullFile = '<none>';

set(handles.Title, 'String', 'Manual object tracking');
handles.maxPoints = NaN;

handles.numFrames = 0;
handles.k = 1;
handles.DEFAULT_USER = 'AnonymousUser';
handles.currUser = handles.DEFAULT_USER;
handles.numROIs = 2;  % Change this number to allow for a different # of ROIs per frame
handles.activeROINum = 1;

% Initialize x and y ROI data
handles.ROIData.(handles.currUser) = createNewUserROIData(handles.numFrames, handles.numROIs);
handles.showAllUserData = false;

% Initialize flag to monitor whether data needs to be saved
handles.storingChangedDataSinceLastSave = false;

% Create empty image to prepare image object
handles.hImage = imagesc([], 'Parent', handles.axes1, 'Clipping', 'off');
set(handles.hImage, 'ButtonDownFcn', @imageButtonDown);
axis(handles.axes1, 'image');
handles.axes1.Visible = 'off';
colormap(handles.axes1, 'gray');
caxis(handles.axes1, 'manual');
caxis(handles.axes1, [0, 255]);
%caxis(handles.axes1, [min(handles.videoData(:)), max(handles.videoData(:))]);

% Create dummy distance measurement handle:
handles.imageDistanceMeasurementHandle = gobjects();
delete(handles.imageDistanceMeasurementHandle);

handles.autoApplyScaleDataToNewImages = true;

[newUserROIHandleData, handles] = createNewUserROIHandleData(handles, handles.currUser);
handles.hROI.(handles.currUser) = newUserROIHandleData;

set(hObject, 'WindowKeyPressFcn', {@KeyPress, hObject});

%set(handles.jumpToFrameBox, 'keyPressFcn', @jumpToFrameBox_keyPressFcn);

% Set up sliderAxes grab bar
cla(handles.sliderAxes);
handles.sliderGrabBarWidth = 0.1;
xlim(handles.sliderAxes, [0,1 + handles.sliderGrabBarWidth]);
ylim(handles.sliderAxes, [0,1]);
handles.sliderGrabBar = rectangle(handles.sliderAxes, 'Position', [0, 0, handles.sliderGrabBarWidth, 1], 'Curvature', [0.3, 0.8], 'FaceColor', [0, 0.47, 0.84]);
set(handles.sliderAxes, 'xtick', [], 'ytick', [], 'box', 'on')
set(handles.sliderAxes, 'Units', 'pixels')
set(handles.figure1, 'Units', 'pixels')
handles.sliding = false;
handles.sliderGrabBar.set('ButtonDownFcn', @startSlide)
set(handles.figure1, 'WindowButtonMotionFcn', @mouseMotionHandler);

% Choose default command line output for manualObjectTracker
handles.output = [];

% Timer that controls video playback timing
handles.timer = timer('TimerFcn', {@changeFrame, hObject},'Period', 0.01, 'ExecutionMode', 'fixedRate');

% Flag that controls whether or not mouse motion invokes drawing function
handles.currentlyFreehandDrawing = false;

% Flag that indicates whether the user is in a zoom operation
handles.zooming = false;
handles.zoomStart = [];
handles.zoomBoxHandle = [];

% Handles when the "current directory" is modified
handles.currentDirectoryListener = addlistener(handles.currentDirectory, 'Value', 'PostSet', @(src, evnt)currentDirectory_Callback(hObject, evnt, NaN));

% Initialize repeated translate delays and counts
%    Order: [up down left right];
handles.translateTimes = [];
handles.translateTimes.up = 0;
handles.translateTimes.down = 0;
handles.translateTimes.left = 0;
handles.translateTimes.right = 0;
handles.translateCounts.up = 0;
handles.translateCounts.down = 0;
handles.translateCounts.left = 0;
handles.translateCounts.right = 0;

% Initialize prerandomized annotation mode variables
handles.prerandomizedAnnotationInfo = [];
handles.prerandomizedCurrentVideoFile = '';
handles.prerandomizedAnnotationFilepath = '';

% Previous prerandomizedAnnotationVideoListbox selection is stored in UserData
set(handles.prerandomizedAnnotationVideoListbox, 'UserData', 1);
set(handles.prerandomizedAnnotationVideoListbox, 'Value', 1);

% Previous fileList selection is stored in UserData.
set(handles.fileList, 'Value', 1);
set(handles.fileList, 'UserData', 1);

% Update handles structure
guidata(hObject, handles);

% Set stop freehand drawing callback
set(handles.figure1, 'WindowButtonUpFcn', @windowButtonUpHandler);

% Set active ROI
handles = setActiveROINum(handles, 1);

% Present initial video frame
updateDisplay(hObject);
% Start the video
%start(handles.timer);
% UIWAIT makes manualObjectTracker wait for user response (see UIRESUME)
%uiwait(handles.figure1);

function ensureMOTIsOnPath()
% Thanks to Jan on MATLAB Answers: https://www.mathworks.com/matlabcentral/answers/86740-how-can-i-determine-if-a-directory-is-on-the-matlab-path-programmatically#answer_96295
MOTPath = mfilename('fullpath');
[MOTDir, MOTName, MOTExt] = fileparts(MOTPath);
if ~isempty(MOTPath)
    pathCell = regexp(path, pathsep, 'split');
    if ispc  % Windows is not case-sensitive
      onPath = any(strcmpi(MOTDir, pathCell));
    else
      onPath = any(strcmp(MOTDir, pathCell));
    end
    if ~onPath
        choice = questdlg('manualObjectTracker does not appear to be in your MATLAB path - would you like to add it now?','Add to path?', 'Add to path','Continue without adding to path','Add to path');
        if strcmp(choice, 'Add to path')
            addpath(MOTDir);
        end
    end
end

function videoDependentControlEnableState(handles, enabledState)
set(handles.saveROIs, 'Enable', enabledState);
set(handles.loadROIs, 'Enable', enabledState);
set(handles.adjustContrast, 'Enable', enabledState);
set(handles.playPause, 'Enable', enabledState);
set(handles.backFrame, 'Enable', enabledState);
set(handles.forwardFrame, 'Enable', enabledState);
set(handles.jumpToFrameBox, 'Enable', enabledState);
set(handles.absentTongueButton, 'Enable', enabledState);
set(handles.clearButton, 'Enable', enabledState);
set(handles.undoButton, 'Enable', enabledState);
set(handles.clearROIs, 'Enable', enabledState);
set(handles.closeROI, 'Enable', enabledState);
set(handles.swapROIs, 'Enable', enabledState);
set(handles.rotateROIButton, 'Enable', enabledState);
set(handles.scaleROIButton, 'Enable', enabledState);

function startSlide(hObject, evt)
handles = guidata(hObject);
handles.sliding = true;
guidata(hObject, handles);

function defaultROIFolder = getCurrentROIFolder(handles)
% Get the current default ROI folder
defaultROIFolderName = 'ROIs';

% Check if we are in pre-randomized tracking mode or not
prerandomizedTrackingMode = isPrerandomizedTrackingModeOn(handles);
if ~prerandomizedTrackingMode
    % Get default ROI folder by appending '/ROIs' to the end of
    %   currentDirectory
    defaultROIFolder = fullfile(get(handles.currentDirectory, 'String'), defaultROIFolderName);
else
    % Get default ROI folder by appending '/ROIs' to the end of the folder
    %   containing the currently selected video specified in the 
    %   pre-randomized annotation file.
    [videoFilename, ~] = getPrerandomizedAnnotationNameAndFrameNumber(handles);
    [path, ~, ~] = fileparts(videoFilename);
    defaultROIFolder = fullfile(path, defaultROIFolderName);
end


function handles = setActiveROINum(handles, n)
% Switch which ROI is currently active
handles.activeROINum = n;
set(handles.activeROINumDisplay, 'String', num2str(n));

function handles = deleteUserROIHandleData(handles)
% Delete all graphics object handles related to USER ROIs
users = fieldnames(handles.hROI);
for k = 1:length(users)
    for n = 1:handles.numROIs
        user = users{k};
        delete(handles.hROI.(user).ROIPointHandles{n});
        delete(handles.hROI.(user).ROIFreehandHandles{n});
        delete(handles.hROI.(user).absentDataIndicatorHandles{n});
    end
    delete(handles.hROI.(user).projectedTongueHandle);
    handles.hROI = rmfield(handles.hROI, user);
end
handles = noteThatChangesNeedToBeSaved(handles);

function handles = deleteUserROIData(handles)
% Delete all ROI data
users = fieldnames(handles.hROI);
for k = 1:length(users)
    user = users{k};
    [blankUserROIHandleData, handles] = createNewUserROIHandleData(handles, user);
    handles.hROI.(user) = blankUserROIHandleData;
    handles.ROIData.(user) = createNewUserROIData(handles.numFrames, handles.numROIs);
end
handles = noteThatChangesNeedToBeSaved(handles);

function [userROIHandleData, handles] = createNewUserROIHandleData(handles, u)
% Create new empty graphics object handles for user ROI data
% Create empty plot to prepare plot object
hold(handles.axes1, 'on')
for n = 1:handles.numROIs
    userROIHandleData.ROIPointHandles{n} = line(handles.axes1, NaN,NaN);
    set(userROIHandleData.ROIPointHandles{n}, 'HitTest', 'off', 'DisplayName', [u, ' points'], 'Clipping', 'off');
    userROIHandleData.ROIFreehandHandles{n} = line(handles.axes1, NaN,NaN);
    set(userROIHandleData.ROIFreehandHandles{n}, 'HitTest', 'off', 'DisplayName', [u, ' freehand'], 'Clipping', 'off');
    userROIHandleData.absentDataIndicatorHandles{n} = text(handles.axes1, 'String', '', 'Position', [NaN,NaN], 'Units', 'characters');
    set(userROIHandleData.absentDataIndicatorHandles{n}, 'HitTest', 'off');
end
userROIHandleData.projectedTongueHandle = line(handles.axes1, NaN, NaN);
set(userROIHandleData.projectedTongueHandle, 'HitTest', 'off', 'Color', 'blue', 'Marker', 'o', 'DisplayName', [u, ' proj'], 'Clipping', 'off');
handles = noteThatChangesDoNotNeedToBeSaved(handles);

function userROIData = createNewUserROIData(numFrames, numROIs)
% Create blank data structures to hold user ROI data
[userROIData.xPoints, userROIData.yPoints] = createBlankROIs(numFrames, numROIs);
[userROIData.xFreehands, userROIData.yFreehands] = createBlankROIs(numFrames, numROIs);
[userROIData.xProj, userROIData.zProj] = createBlankROIs(numFrames, 1);
userROIData.absent = createBlankAbsentData(numFrames, numROIs);
userROIData.stats = createBlankStatsData(numFrames, numROIs);

function unloadVideoOrImage(hObject)
handles = guidata(hObject);
disp('unloadVideoOrImage');
% Reset all ROI data
if any(strcmp(handles.currUser, fieldnames(handles.ROIData)))
    [handles.ROIData.(handles.currUser).xPoints, handles.ROIData.(handles.currUser).yPoints] = createBlankROIs(handles.numFrames, handles.numROIs);
    [handles.ROIData.(handles.currUser).xFreehands, handles.ROIData.(handles.currUser).yFreehands] = createBlankROIs(handles.numFrames, handles.numROIs);
    [handles.ROIData.(handles.currUser).xProj, handles.ROIData.(handles.currUser).zProj] = createBlankROIs(handles.numFrames, handles.numROIs);
    handles.ROIData.(handles.currUser).absent = createBlankAbsentData(handles.numFrames, handles.numROIs);
end
handles.k = 1;
guidata(hObject, handles);
updateDisplay(hObject);
handles = guidata(hObject);
handles.videoData = [];
handles.numFrames = 0;
videoDependentControlEnableState(handles, 'off')
guidata(hObject, handles);
updateDisplay(hObject);

function loadVideoOrImage(hObject, file)
% Load a video or image from file, and reset all variables relating to the video and ROI data
handles = guidata(hObject);
disp('loadVideoOrImage');
if ischar(file)
    disp(file)
    [~, filename, ~] = fileparts(file);
    if strcmp(filename, handles.nullFile)
        % This is the placeholder file, not a real file
        return;
    end
    % It's a filename
    [proceed, handles] = warnIfLosingROIChanges(handles);
    if ~proceed
        return
    end
    try
        % Check if this is an image file rather than a video file.
        imfinfo(file);
        isImageFile = true;
    catch
        isImageFile = false;
    end
    if isImageFile
        try
            imageData = imread(file);
        catch
            disp(['Error loading file: ', file]);
            imageData = [];
        end
        if length(size(imageData)) > 2
            disp('Warning: Image data appears to be non-grayscale - currently only grayscale images are valid. Squashing colors...');
            imageData = rgb2gray(imageData);
        end
        handles.videoData = zeros([size(imageData), 1]);
        handles.videoData(:, :, 1) = imageData;
    else
        handles.videoData = squeeze(loadVideoData(file));
    end
else
    % It's video data
    [proceed, handles] = warnIfLosingROIChanges(handles);
    if ~proceed
        return
    end
    handles.videoData = file;
end
videoSize = size(handles.videoData);
try
    handles.numFrames = videoSize(3);
catch
    handles.numFrames = 1;
end

% Reset all ROI data
[handles.ROIData.(handles.currUser).xPoints, handles.ROIData.(handles.currUser).yPoints] = createBlankROIs(handles.numFrames, handles.numROIs);
[handles.ROIData.(handles.currUser).xFreehands, handles.ROIData.(handles.currUser).yFreehands] = createBlankROIs(handles.numFrames, handles.numROIs);
[handles.ROIData.(handles.currUser).xProj, handles.ROIData.(handles.currUser).zProj] = createBlankROIs(handles.numFrames, handles.numROIs);
handles.ROIData.(handles.currUser).absent = createBlankAbsentData(handles.numFrames, handles.numROIs);
handles.k = 1;
videoDependentControlEnableState(handles, 'on')
guidata(hObject, handles);
%updateDisplay(hObject);

if get(handles.autoLoadROIs, 'Value') && ischar(file)
    % Autoload corresponding ROI .mat file
    disp('Looking for existing ROI file to load...')
    foundROIFile = false;
    defaultROIFolder = getCurrentROIFolder(handles);
    if exist(defaultROIFolder, 'dir')
        matFiles = dir(fullfile(defaultROIFolder, '*.mat'));
        matFileNames = {matFiles.name};
        [~, vname, ~] = fileparts(file);
        % Strip cue and laser info just in case
%        vname = regexprep(vname, '(_C[0-9]+L?)', '');
%        indices = find(cellfun(@(x)contains(x, vname), matFileNames));
%        if ~isempty(indices)
%            [~, ii] = min(cellfun(@length, matFileNames(indices)));
%            index = indices(ii);
%        ROIfullfile = fullfile(defaultROIFolder, cell2mat(matFileNames(index)));
        ROIfullfile = fullfile(defaultROIFolder, makeROINameFromVideoName(vname));
            if exist(ROIfullfile, 'file')
                foundROIFile = true;
                loadROIs(hObject, ROIfullfile);
            end
%        end
    end
    if ~foundROIFile
        disp('...no corresponding ROI file found.');
    end
end

function [x, y] = createBlankROIs(numFrames, numROIs)
% Create blank datastructure for holding a set of ROIs
if numFrames > 0
    x{numROIs, numFrames} = [];
    y{numROIs, numFrames} = [];
else
    x = {};
    y = {};
end

function blankStatsData = createBlankStatsData(numFrames, numROIs)
if numFrames > 0
    blankStatsData.areaUnits(1:numROIs, 1:numFrames) = 0;
    blankStatsData.areaPixels(1:numROIs, 1:numFrames) = 0;
else
    blankStatsData.areaUnits = [];
    blankStatsData.areaPixels = [];
end
blankStatsData.pixelScaleMeasurement = [];
blankStatsData.unitScaleMeasurement = [];
blankStatsData.scaleUnit = [];

function blankAbsentData = createBlankAbsentData(numFrames, numROIs)
% Create blank datastructure for holding ROI absent data
if numFrames > 0
    blankAbsentData(1:numROIs, 1:numFrames) = false;
else
    blankAbsentData = [];
end

function handles = noteThatChangesNeedToBeSaved(handles)
%disp('Marking that there are changes that need saving')
% st = dbstack('-completenames');
% for k = 1:length(st)
%     sti = st(k);
%     disp(sti.line);    
% end
handles.storingChangedDataSinceLastSave = true;

function handles = noteThatChangesDoNotNeedToBeSaved(handles)
% disp('Marking that changes do not need to be saved')
handles.storingChangedDataSinceLastSave = false;

function [proceed, handles] = warnIfLosingROIChanges(handles)
% Display a warning dialog that user is taking an action that will result
%   in ROI data loss, and prompt to save & continue, continue without saving,
%   or abort.
if handles.storingChangedDataSinceLastSave
    if get(handles.autoSaveOnFrameChange, 'Value')
        % User has elected to automatically save - do not prompt for
        % choice.
        choice = 'Save and continue';
    else
        % There is new data to lose, check with user
        choice = questdlg('There is unsaved ROI data that will be lost. Do you want to continue?','ROI data loss warning','Save and continue', 'Continue without saving','Abort','Save and continue');
    end
    switch choice
        case 'Save and continue'
            % Get previous video name:
            [previousPathName, previousVideoName] = getCurrentVideoFileSelection(handles, true);
            handles = saveROIs_Callback(NaN, NaN, handles, fullfile(previousPathName, previousVideoName));
            proceed = true;
        case 'Continue without saving'
            proceed = true;
            handles.storingChangedDataSinceLastSave = false;
        case 'Abort'
            proceed = false;
    end
    guidata(handles.figure1, handles);
else
    % No new data, proceed
    proceed = true;
end

function toggleDrawMode(hObject)
% Switch between point mode and freehand mode for drawing ROIs
handles = guidata(hObject);
switch get(handles.modeButtonGroup.SelectedObject, 'String')
    case 'Freehand'
        set(handles.pointModeButton, 'Value', 1);
    case 'Point'
        set(handles.freehandModeButton, 'Value', 1);
end    
guidata(hObject, handles);

function KeyPress(~, EventData, hObject, ~)
% Handle various key press events
handles = guidata(hObject);
switch EventData.Key
    case cellfun(@(x) num2str(x), num2cell(1:handles.numROIs), 'UniformOutput', false)
        % Switch which ROI is active
        handles = setActiveROINum(handles, str2double(EventData.Key));
        guidata(hObject, handles);
    case 'm'
        if any(strcmp(EventData.Modifier, 'control'))
            % Ctl-m = switch between point and freehand ROI drawing modes
            toggleDrawMode(hObject);
        else
            % Toggle distance measurement on/off
            toggleDistanceMeasurement(hObject)
        end
    case 'a'
        if any(strcmp(EventData.Modifier, 'control')) && any(strcmp(EventData.Modifier, 'shift'))
            % ctl-shift-a = toggle between showing all user ROIs at the same time
            handles.showAllUserData = ~handles.showAllUserData;
            guidata(hObject, handles);
        else
            % a = Reset zoom to default
            axis(handles.axes1, 'image')
        end
    case 'z'
        if any(strcmp(EventData.Modifier, 'control'))
            % ctl-z = undo last ROI point
            undoButton_Callback(hObject, NaN, handles)
        end
    case 'delete'
        % del = clear all points
        choice = questdlg('Are you sure you want to delete the current ROI?', 'Delete ROI?', 'Delete', 'Cancel', 'Delete');
        switch choice
            case 'Delete'
                clearButton_Callback(hObject, NaN, handles)
            case 'Cancel'
                return
        end
    case 'c'
        % Close ROI
        if strcmp(get(handles.modeButtonGroup.SelectedObject, 'String'), 'Freehand')
            [handles.ROIData.(handles.currUser).xFreehands{handles.activeROINum, handles.k}, handles.ROIData.(handles.currUser).yFreehands{handles.activeROINum, handles.k}] = closeROI(handles.ROIData.(handles.currUser).xFreehands{handles.activeROINum, handles.k}, handles.ROIData.(handles.currUser).yFreehands{handles.activeROINum, handles.k});
        else
            [handles.ROIData.(handles.currUser).xPoints{handles.activeROINum, handles.k}, handles.ROIData.(handles.currUser).yPoints{handles.activeROINum, handles.k}] = closeROI(handles.ROIData.(handles.currUser).xPoints{handles.activeROINum, handles.k}, handles.ROIData.(handles.currUser).yPoints{handles.activeROINum, handles.k});
        end
        handles = noteThatChangesNeedToBeSaved(handles);
        guidata(hObject, handles);
        updateDisplay(hObject);
%        changeFrame(NaN, NaN, hObject, 'delta', 1);
    case 'n'
        k = handles.k;
        n = handles.activeROINum;
        u = handles.currUser;
        if ~any(strcmp(EventData.Modifier, 'shift'))
            % Mark all ROIs as "no tongue"
            handles = toggleTongueAbsent(handles, k, NaN, u);
        else
            % Mark current ROI as "no tongue"
            handles = toggleTongueAbsent(handles, k, n, u);
        end
        guidata(hObject, handles);
    case 'leftarrow'
        if strcmp(EventData.Modifier, 'control')
            % ctl-left = go back 10 frames in video
            changeFrame(NaN, NaN, hObject, 'delta', -10);
        elseif isempty(EventData.Modifier)
            % left = go back 1 frame in video
            changeFrame(NaN, NaN, hObject, 'delta', -1);
        elseif strcmp(EventData.Modifier, 'shift')
            % shift-left = shift last ROI point left 1 pixel
            shiftCurrentPoint(hObject, -1, 0)
        elseif strcmp(EventData.Modifier, 'alt')
            currentTime = now();
            dt = currentTime - handles.translateTimes.left;
            if dt < 2e-6
                handles.translateCounts.left = handles.translateCounts.left + 1;
            else
                handles.translateCounts.left = 1;
            end
            handles.translateTimes.left = currentTime;
            deltaX = -ceil(handles.translateCounts.left^2/100);
            deltaY = 0;
            if strcmp(get(handles.modeButtonGroup.SelectedObject, 'String'), 'Freehand')
                [handles.ROIData.(handles.currUser).xFreehands{handles.k}, handles.ROIData.(handles.currUser).yFreehands{handles.k}] = translateROI(deltaX, deltaY, handles.ROIData.(handles.currUser).xFreehands{handles.k}, handles.ROIData.(handles.currUser).yFreehands{handles.k});
            else
                [handles.ROIData.(handles.currUser).xPoints{handles.k}, handles.ROIData.(handles.currUser).yPoints{handles.k}] = translateROI(deltaX, deltaY, handles.ROIData.(handles.currUser).xPoints{handles.k}, handles.ROIData.(handles.currUser).yPoints{handles.k});
            end
            guidata(hObject, handles);
        end
    case 'rightarrow'
        if strcmp(EventData.Modifier, 'control')
            % ctl-right = go forward 10 frames in video
            changeFrame(NaN, NaN, hObject, 'delta', 10);
        elseif isempty(EventData.Modifier)
            % right = go forward 1 frame in video
            changeFrame(NaN, NaN, hObject, 'delta', 1);
        elseif strcmp(EventData.Modifier, 'shift')
            shiftCurrentPoint(hObject, 1, 0)
            % shift-right = shift last ROI point right 1 pixel
        elseif strcmp(EventData.Modifier, 'alt')
            currentTime = now();
            dt = currentTime - handles.translateTimes.right;
            if dt < 2e-6
                handles.translateCounts.right = handles.translateCounts.right + 1;
            else
                handles.translateCounts.right = 1;
            end
            handles.translateTimes.right= currentTime;
            deltaX = ceil(handles.translateCounts.right^2/100);
            deltaY = 0;
            if strcmp(get(handles.modeButtonGroup.SelectedObject, 'String'), 'Freehand')
                [handles.ROIData.(handles.currUser).xFreehands{handles.k}, handles.ROIData.(handles.currUser).yFreehands{handles.k}] = translateROI(deltaX, deltaY, handles.ROIData.(handles.currUser).xFreehands{handles.k}, handles.ROIData.(handles.currUser).yFreehands{handles.k});
            else
                [handles.ROIData.(handles.currUser).xPoints{handles.k}, handles.ROIData.(handles.currUser).yPoints{handles.k}] = translateROI(deltaX, deltaY, handles.ROIData.(handles.currUser).xPoints{handles.k}, handles.ROIData.(handles.currUser).yPoints{handles.k});
            end
            guidata(hObject, handles);
        end
    case 'uparrow'
        if strcmp(EventData.Modifier, 'shift')
            % shift-up = shift last ROI point up 1 pixel
            shiftCurrentPoint(hObject, 0, -1)
        elseif strcmp(EventData.Modifier, 'alt')
            currentTime = now();
            dt = currentTime - handles.translateTimes.up;
            if dt < 2e-6
                handles.translateCounts.up = handles.translateCounts.up + 1;
            else
                handles.translateCounts.up = 1;
            end
            handles.translateTimes.up = currentTime;
            deltaX = 0;
            deltaY = -ceil(handles.translateCounts.up^2/100);
            if strcmp(get(handles.modeButtonGroup.SelectedObject, 'String'), 'Freehand')
                [handles.ROIData.(handles.currUser).xFreehands{handles.k}, handles.ROIData.(handles.currUser).yFreehands{handles.k}] = translateROI(deltaX, deltaY, handles.ROIData.(handles.currUser).xFreehands{handles.k}, handles.ROIData.(handles.currUser).yFreehands{handles.k});
            else
                [handles.ROIData.(handles.currUser).xPoints{handles.k}, handles.ROIData.(handles.currUser).yPoints{handles.k}] = translateROI(deltaX, deltaY, handles.ROIData.(handles.currUser).xPoints{handles.k}, handles.ROIData.(handles.currUser).yPoints{handles.k});
            end
            guidata(hObject, handles);
        end
    case 'downarrow'
        if strcmp(EventData.Modifier, 'shift')
            % shift-down = shift last ROI point down 1 pixel
            shiftCurrentPoint(hObject, 0, 1)
        elseif strcmp(EventData.Modifier, 'alt')
            currentTime = now();
            dt = currentTime - handles.translateTimes.down;
            if dt < 2e-6
                handles.translateCounts.down = handles.translateCounts.down + 1;
            else
                handles.translateCounts.down = 1;
            end
            handles.translateTimes.down = currentTime;
            deltaX = 0;
            deltaY = ceil(handles.translateCounts.down^2/100);
            if strcmp(get(handles.modeButtonGroup.SelectedObject, 'String'), 'Freehand')
                [handles.ROIData.(handles.currUser).xFreehands{handles.k}, handles.ROIData.(handles.currUser).yFreehands{handles.k}] = translateROI(deltaX, deltaY, handles.ROIData.(handles.currUser).xFreehands{handles.k}, handles.ROIData.(handles.currUser).yFreehands{handles.k});
            else
                [handles.ROIData.(handles.currUser).xPoints{handles.k}, handles.ROIData.(handles.currUser).yPoints{handles.k}] = translateROI(deltaX, deltaY, handles.ROIData.(handles.currUser).xPoints{handles.k}, handles.ROIData.(handles.currUser).yPoints{handles.k});
            end
            guidata(hObject, handles);
        end
    case 'space'
        % space = toggle play/pause video
        playPause_Callback(hObject, EventData, handles);
    case 'q'
        % q = switch to previous video in video list
        if isPrerandomizedTrackingModeOn(handles)
            if strcmp(get(handles.prerandomizedAnnotationVideoListbox, 'Enable'), 'on')
                numVideos = length(get(handles.prerandomizedAnnotationVideoListbox, 'String'));
                currentVideoNumber = get(handles.prerandomizedAnnotationVideoListbox, 'Value');
                newVideoNumber = mod(currentVideoNumber - 2, numVideos)+1;
                set(handles.prerandomizedAnnotationVideoListbox, 'Value', newVideoNumber);
                prerandomizedAnnotationVideoListbox_Callback(hObject, NaN, handles);
            end
        else
            if strcmp(get(handles.fileList, 'Enable'), 'on')
                numVideos = length(get(handles.fileList, 'String'));
                currentVideoNumber = get(handles.fileList, 'Value');
                newVideoNumber = mod(currentVideoNumber - 2, numVideos)+1;
                set(handles.fileList, 'Value', newVideoNumber);
                fileList_Callback(hObject, NaN, handles);
            end
        end
    case 'w'
        % w = switch to next video in video list
        if isPrerandomizedTrackingModeOn(handles)
            if strcmp(get(handles.prerandomizedAnnotationVideoListbox, 'Enable'), 'on')
                disp('handling w');
                numVideos = length(get(handles.prerandomizedAnnotationVideoListbox, 'String'));
                currentVideoNumber = get(handles.prerandomizedAnnotationVideoListbox, 'Value');
                newVideoNumber = mod(currentVideoNumber, numVideos)+1;
                set(handles.prerandomizedAnnotationVideoListbox, 'Value', newVideoNumber);
                prerandomizedAnnotationVideoListbox_Callback(hObject, NaN, handles);
            end
        else
            if strcmp(get(handles.fileList, 'Enable'), 'on')
                numVideos = length(get(handles.fileList, 'String'));
                currentVideoNumber = get(handles.fileList, 'Value');
                newVideoNumber = mod(currentVideoNumber, numVideos)+1;
                set(handles.fileList, 'Value', newVideoNumber);
                fileList_Callback(hObject, NaN, handles);
            end
        end
end
updateDisplay(hObject);

function toggleDistanceMeasurement(hObject)
% Currently only creates them, doesn't delete them. Not sure why, but right
% click brings up a context menu that has a delete button that works.
handles = guidata(hObject);
if isvalid(handles.imageDistanceMeasurementHandle)
    delete(handles.imageDistanceMeasurementHandle)
else
    handles.imageDistanceMeasurementHandle = imdistline(handles.axes1);
    setLabelTextFormatter(handles.imageDistanceMeasurementHandle,'%02.0f px');
end
guidata(hObject);

function shiftCurrentPoint(hObject, deltaX, deltaY)
% shift last ROI point by delta in x and y directions
handles = guidata(hObject);
if strcmp(get(handles.modeButtonGroup.SelectedObject, 'String'), 'Freehand')
    [handles.ROIData.(handles.currUser).xFreehands{handles.k}, handles.ROIData.(handles.currUser).yFreehands{handles.k}] = shiftLastNonclosingPoint(deltaX, deltaY, handles.ROIData.(handles.currUser).xFreehands{handles.k}, handles.ROIData.(handles.currUser).yFreehands{handles.k});
else
    [handles.ROIData.(handles.currUser).xPoints{handles.k}, handles.ROIData.(handles.currUser).yPoints{handles.k}] = shiftLastNonclosingPoint(deltaX, deltaY, handles.ROIData.(handles.currUser).xPoints{handles.k}, handles.ROIData.(handles.currUser).yPoints{handles.k});
end
handles = noteThatChangesNeedToBeSaved(handles);
guidata(hObject, handles);

function [x, y] = shiftLastNonclosingPoint(deltaX, deltaY, x, y)
% shift last ROI point that is not a closing point (the same as the
%   starting point) by delta in the x and y directions
if x(end) == x(1) && y(end) == y(1)
    index = length(x)-1;
else
    index = length(x);
end
x(index) = x(index) + deltaX;
y(index) = y(index) + deltaY;

function closed = isROIClosed(x, y)
% Check if the ROI specified by a list of x and y coordinates is closed
%   or not (last point is the same as the first point)
if isempty(x)
    closed = true;
else
    closed = x(1)==x(end) && y(1)==y(end);
end

function [x, y] = closeROI(x, y)
% If the ROI specified by the list of x and y coordinates is not closed,
%   close it.
if ~isROIClosed(x, y)
    x(end+1) = x(1);
    y(end+1) = y(1);
end

function changeFrame(~, ~, hObject, mode, value, varargin)
% Switch the currently displayed video frame by either a given frame delta,
%   or to a given frame number, depending on if the mode argument is 'delta'
%   or 'absolute'
handles = guidata(hObject);
if handles.numFrames == 0
    return;
end
if nargin == 3
    dk = 1;
else
    switch mode
        case 'delta'
            dk = value;
        case 'absolute'
            dk = value - handles.k;
    end
end
%disp(['changing frame: ', num2str(dk)]);
handles.k = mod(handles.k-1+dk, handles.numFrames)+1;

% Update slider position
if handles.numFrames > 1
    val = (handles.k-1) / (handles.numFrames-1);
else
    val = 0;
end
set(handles.sliderGrabBar, 'Position', [val, 0, handles.sliderGrabBarWidth, 1]);

guidata(hObject, handles);
updateDisplay(hObject);

function updateDisplay(hObject)
% Master function that updates the entire GUI (mostly the stuff drawn on the axes) as is necessary
handles = guidata(hObject);
k = handles.k;
if handles.numFrames == 0
    % No video frames present, do not update GUI
    set(handles.hImage, 'CData', []);
    return;
end

% Display the current video frame
frame = handles.videoData(:, :, k);
frameSize = size(frame);
set(handles.hImage, 'CData', frame);

% Update ROI stats display
handles = updateROIStatDisplay(handles);

% Update file number display
prerandomizedTrackingMode = isPrerandomizedTrackingModeOn(handles);
if ~prerandomizedTrackingMode
    numFiles = length(cellstr(get(handles.fileList,'String')));
    fileIndex = get(handles.fileList, 'Value');
else
    numFiles = length(cellstr(get(handles.prerandomizedAnnotationVideoListbox,'String')));
    fileIndex = get(handles.prerandomizedAnnotationVideoListbox,'UserData');
end
set(handles.fileNumberDisplay, 'String', ['#', num2str(fileIndex), ' of ', num2str(numFiles)]);

% Display various ROI markings
colors = {'g', 'r', 'b', 'y', 'c', 'm'};
users = fieldnames(handles.hROI);
for userIndex = 1:length(users)
    % Loop over all users
    u = users{userIndex};
    for n = 1:handles.numROIs
        % Loop over all ROIs
        if handles.showAllUserData || strcmp(u, handles.currUser)
            % Update ROI
            set(handles.hROI.(u).ROIPointHandles{n}, ...
                'XData', handles.ROIData.(u).xPoints{n, k}, ...
                'YData', handles.ROIData.(u).yPoints{n, k});
            set(handles.hROI.(u).ROIFreehandHandles{n}, ...
                'XData', handles.ROIData.(u).xFreehands{n, k}, ...
                'YData', handles.ROIData.(u).yFreehands{n, k});
            color = colors{mod(n-1, 6)+1};
            set(handles.hROI.(u).ROIPointHandles{n}, 'LineStyle', 'none', 'Marker', '*', 'Color', color);
            set(handles.hROI.(u).ROIFreehandHandles{n}, 'Marker', 'none',  'Color', color);
            % Update projected tongue position, if available
            set(handles.hROI.(u).projectedTongueHandle, ...
                'XData', handles.ROIData.(u).xProj{k}, ...
                'YData', handles.ROIData.(u).zProj{k});
            % Update absent data indicator
            if handles.ROIData.(u).absent(n, k)
                absentString = ['ROI #', num2str(n),': NO TONGUE'];
                set(handles.hROI.(u).absentDataIndicatorHandles{n}, ... 
                    'Position', [0, 3-n], ... 
                    'Color', color, ...
                    'String', absentString, ...
                    'Visible', 'on');
            else
                set(handles.hROI.(u).absentDataIndicatorHandles{n}, 'Visible', 'off');
            end
        else
            % Clear ROIs that should not be visible
            set(handles.hROI.(u).ROIPointHandles{n}, 'XData', [], 'YData', []);
            set(handles.hROI.(u).ROIFreehandHandles{n}, 'XData', [], 'YData', []);
            set(handles.hROI.(u).projectedTongueHandle, 'XData', [], 'YData', []);
            set(handles.hROI.(u).absentDataIndicatorHandles{n}, 'Visible', 'off');
        end
    end
end
% If not currently zooming, remove zoom box
if ~handles.zooming
    set(handles.zoomBoxHandle, 'Position', [0, 0, 0, 0]);
end

% Update the current user box
set(handles.currentUserDisplay, 'String', handles.currUser);
% Update the current frame number box
set(handles.frameNumberLabel, 'String', [num2str(k), ' / ', num2str(handles.numFrames)]);
if handles.showAllUserData
    % If all users displays are being superimposed, show a legend
    legend(handles.axes1, users);
else
    legend(handles.axes1, 'off');
end
if isPrerandomizedTrackingModeOn(handles)
    updatePrerandomizedAnnotationListboxes(handles);
end

function imageButtonDown(hObject, ~)
% Handle mouse clicks on the video frame image
handles = guidata(hObject);
k = handles.k;

if handles.numFrames == 0
    return;
end
coordinates = get(handles.axes1, 'CurrentPoint');
x = round(coordinates(1, 1));
y = round(coordinates(1, 2));

switch get(handles.figure1, 'SelectionType')
    case 'normal'
        if ~warnDataAbsent(handles, k, handles.activeROINum, handles.currUser)
            if strcmp(get(handles.modeButtonGroup.SelectedObject, 'String'), 'Freehand')
                [handles.ROIData.(handles.currUser).xFreehands{handles.activeROINum, k}, handles.ROIData.(handles.currUser).yFreehands{handles.activeROINum, k}] ...
                    = getUpdatedCoords(x, y, handles.ROIData.(handles.currUser).xFreehands{handles.activeROINum, k}, handles.ROIData.(handles.currUser).yFreehands{handles.activeROINum, k}, get(handles.autocloseROI, 'Value'));
            else
                [handles.ROIData.(handles.currUser).xPoints{handles.activeROINum, k}, handles.ROIData.(handles.currUser).yPoints{handles.activeROINum, k}] ...
                    = getUpdatedCoords(x, y, handles.ROIData.(handles.currUser).xPoints{handles.activeROINum, k}, handles.ROIData.(handles.currUser).yPoints{handles.activeROINum, k}, get(handles.autocloseROI, 'Value'));
            end
            % Check if freehand mode is on and freehand drawing has not begun
            if strcmp(get(handles.modeButtonGroup.SelectedObject, 'String'), 'Freehand') && ~handles.currentlyFreehandDrawing
                % Start freehand drawing
                handles.currentlyFreehandDrawing = true;
            end
            handles = noteThatChangesNeedToBeSaved(handles);
        end
%    case {'extend', 'open'}
%        % Zoom out
%        zoom(handles.axes1, [x, y], 2)
    case 'alt'
%        zoom(handles.axes1, [x, y], 0.5)
        % initiate or end zoom
        if ~handles.zooming
            % Start zooming
            handles.zooming = true;
            handles.zoomStart = [x, y];
        else
            % Stop zooming, execute zoom
            handles.zooming = false;
            dx = x - handles.zoomStart(1);
            dy = y - handles.zoomStart(2);
            axis_dx = handles.axes1.XLim(2) - handles.axes1.XLim(1);
            axis_dy = handles.axes1.YLim(2) - handles.axes1.YLim(1);
            xRatio = abs(dx/axis_dx);
            yRatio = abs(dy/axis_dy);
            zoomRatio = min([xRatio, yRatio]);
            center = [mean([x, handles.zoomStart(1)]), mean([y, handles.zoomStart(2)])];
            if dy > 0
                % Zoom out
                zoom(handles.axes1, center, zoomRatio);
            else
                % Zoom in
                zoom(handles.axes1, center, 1/zoomRatio);
            end
        end
end
guidata(hObject, handles);
updateDisplay(hObject);

function [xCoords, yCoords] = getUpdatedCoords(xClick, yClick, xCoords, yCoords, autoClose)
% Based on current ROI coordinates xCoords and yCoords, new click
%   coordinates xClick and yClick, and autoClose, which determines whether
%   the ROI should be closed, return an updated list of ROI coordinates
if autoClose && isROIClosed(xCoords, yCoords) && length(xCoords) > 1
    % ROI is already closed - unclose it first
    xCoords = xCoords(1:end-1);
    yCoords = yCoords(1:end-1);
end
% Add newest point
xCoords = [xCoords, xClick];
yCoords = [yCoords, yClick];
if autoClose
    % Close ROI
    [xCoords, yCoords] = closeROI(xCoords, yCoords);
end

function windowButtonUpHandler(hObject, ~)
% Handle mouse button up events (either letting go of the slider or letting
%   go of the mouse while freehand drawing an ROI)
handles = guidata(hObject);
u = handles.currUser;
k = handles.k;
n = handles.activeROINum;
% Stop sliding if necessary
handles.sliding= false;
% Stop freehand drawing if necessary
if handles.currentlyFreehandDrawing
    if get(handles.autocloseROI, 'Value') && ~isROIClosed(handles.ROIData.(u).xFreehands{n, k}, handles.ROIData.(u).yFreehands{n, k})
        % If autoclose is on, and the ROI is not closed, close it.
        [handles.ROIData.(handlesu).xFreehands{n, k}, handles.ROIData.(u).yFreehands{n, k}] ...
            = closeROI(handles.ROIData.(u).xFreehands{n, k}, handles.ROIData.(u).yFreehands{n, k});
        handles = noteThatChangesNeedToBeSaved(handles);
    end
    handles.currentlyFreehandDrawing = false;
end
guidata(hObject, handles);

function mouseMotionHandler(hObject, ~)
% Handle mouse motion events
handles = guidata(hObject);
%mouseButton = get(handles.figure1, 'SelectionType');
%disp(['Mouse: ', mouseButton]);
handles.mouseCoords.String = ['(', num2str(round(handles.axes1.CurrentPoint(1, 1))), ', ', num2str(round(handles.axes1.CurrentPoint(1, 2))), ')'];

if handles.sliding
    % Slider is currenly being slid
    currentPoint = get(hObject, 'CurrentPoint');
    axesPosition = get(handles.sliderAxes, 'Position');
    delta = currentPoint(1) - axesPosition(1);
    val = delta / axesPosition(3);
    nextK = round(val*(handles.numFrames-1))+1;
    deltaK = round((nextK - handles.k));
    changeFrame(NaN, NaN, hObject, 'delta', deltaK);
elseif handles.currentlyFreehandDrawing
    % User is currently freehand drawing
    pt = get(handles.axes1, 'CurrentPoint');
    x = pt(1, 1);
    y = pt(1, 2);
    k = handles.k;
    n = handles.activeROINum;
    if ~warnDataAbsent(handles, k, n, handles.currUser)
        [handles.ROIData.(handles.currUser).xFreehands{n, k}, handles.ROIData.(handles.currUser).yFreehands{n, k}] ...
            = getUpdatedCoords(x, y, handles.ROIData.(handles.currUser).xFreehands{n, k}, handles.ROIData.(handles.currUser).yFreehands{n, k}, get(handles.autocloseROI, 'Value'));
        handles = noteThatChangesNeedToBeSaved(handles);
        guidata(hObject, handles);
        updateDisplay(hObject);
    end
elseif handles.zooming
    % If currently zooming, display zoom box
    handles = guidata(hObject);
     coordinates = get(handles.axes1, 'CurrentPoint');
    x = round(coordinates(1, 1));
    y = round(coordinates(1, 2));
    xs = handles.zoomStart(1);
    ys = handles.zoomStart(2);
    xMin = min([x, xs]);
    xMax = max([x, xs]);
    yMin = min([y, ys]);
    yMax = max([y, ys]);
    rectangleBounds = [xMin, yMin, xMax-xMin, yMax-yMin];
    if isempty(handles.zoomBoxHandle)
        handles.zoomBoxHandle = rectangle('Position', rectangleBounds, 'EdgeColor', 'r', 'HitTest', 'off', 'PickableParts', 'none');
    else
        handles.zoomBoxHandle.Position = rectangleBounds;
    end
    guidata(hObject, handles);
end

function absentFlag = warnDataAbsent(handles, k, n, u)
% Check if user is trying to draw an ROI that has already been marked
%   absent, and warn them.
% k = frame number
% n = ROI number
% u = User
if handles.ROIData.(u).absent(n, k)
    % ROI is marked as data absent, drawing ROI not allowed
    warndlg(['Frame ', num2str(k), ' ROI #', num2str(n), ' for user ', u, ' is marked as data absent. Toggle data absent marker to draw ROI.']);
    absentFlag = true;
else
    % ROI is not marked as data absent
    absentFlag = false;
end

function zoom(axesHandle, center, factor)
% Zoom in or out on axes based on center coordinates, and a zoom factor
% factor > 1 = zoom out
% factor < 1 = zoom in
%axesHandle.Clipping = 'off';
fxl = xlim(axesHandle);
fyl = ylim(axesHandle);
fw = fxl(2) - fxl(1);
fh = fyl(2) - fyl(1);
% zoom out
fxl = [center(1)-factor*fw/2, center(1)+factor*fw/2];
fyl = [center(2)-factor*fh/2, center(2)+factor*fh/2];
xlim(axesHandle, fxl);
ylim(axesHandle, fyl);

% --- Outputs from this function are returned to the command line.
function varargout = manualObjectTracker_OutputFcn(hObject, ~, ~)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

varargout{1} = hObject;

% --- Executes on button press in clearButton.
function clearButton_Callback(hObject, ~, handles)
% hObject    handle to clearButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.numFrames == 0
    return;
end
if strcmp(get(handles.modeButtonGroup.SelectedObject, 'String'), 'Freehand')
    handles.ROIData.(handles.currUser).xFreehands{handles.activeROINum, handles.k} = [];
    handles.ROIData.(handles.currUser).yFreehands{handles.activeROINum, handles.k} = [];
else
    handles.ROIData.(handles.currUser).xPoints{handles.activeROINum, handles.k} = [];
    handles.ROIData.(handles.currUser).yPoints{handles.activeROINum, handles.k} = [];
end
handles = noteThatChangesNeedToBeSaved(handles);
guidata(hObject, handles);
updateDisplay(hObject);

% --- Executes on button press in undoButton.
function undoButton_Callback(hObject, ~, handles)
% hObject    handle to undoButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.numFrames == 0
    return;
end
if strcmp(get(handles.modeButtonGroup.SelectedObject, 'String'), 'Freehand')
    handles.ROIData.(handles.currUser).xFreehands{handles.activeROINum, handles.k} = handles.ROIData.(handles.currUser).xFreehands{handles.activeROINum, handles.k}(1:end-1);
    handles.ROIData.(handles.currUser).yFreehands{handles.activeROINum, handles.k} = handles.ROIData.(handles.currUser).yFreehands{handles.activeROINum, handles.k}(1:end-1);
else
    handles.ROIData.(handles.currUser).xPoints{handles.activeROINum, handles.k} = handles.ROIData.(handles.currUser).xPoints{handles.activeROINum, handles.k}(1:end-1);
    handles.ROIData.(handles.currUser).yPoints{handles.activeROINum, handles.k} = handles.ROIData.(handles.currUser).yPoints{handles.activeROINum, handles.k}(1:end-1);
end
handles = noteThatChangesNeedToBeSaved(handles);
guidata(hObject, handles);
updateDisplay(hObject);

% --- Executes on button press in playPause.
function playPause_Callback(~, ~, handles)
% hObject    handle to playPause (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(handles.timer,'Running'), 'off')
    start(handles.timer);
else
    stop(handles.timer);
end
% Hint: get(hObject,'Value') returns toggle state of playPause

% function startTimer(hObject)
% handles = guidata(hObject);
% if strcmp(get(handles.timer,'Running'), 'off')
%     start(handles.timer);
% end

function stopTimer(hObject)
handles = guidata(hObject);
if strcmp(get(handles.timer,'Running'), 'on')
    stop(handles.timer);
end

% --- Executes on mouse press over axes background.
function axes1_ButtonDownFcn(~, ~, ~)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, ~, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
stop(handles.timer);
if isequal(get(hObject, 'waitstatus'), 'waiting')
    uiresume(hObject);
else
    delete(hObject);
end

% --- Executes on button press in backFrame.
function backFrame_Callback(hObject, ~, ~)
% hObject    handle to backFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stopTimer(hObject)
changeFrame(NaN, NaN, hObject, 'delta', -1);

% --- Executes on button press in forwardFrame.
function forwardFrame_Callback(hObject, ~, ~)
% hObject    handle to forwardFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stopTimer(hObject)
changeFrame(NaN, NaN, hObject, 'delta', 1);

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over backFrame.
function backFrame_ButtonDownFcn(hObject, ~, ~)
% hObject    handle to backFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stopTimer(hObject)
changeFrame(NaN, NaN, hObject, 'delta', -1);

function sliderKeyPress(hObject, eventdata)
switch eventdata.Key
    case 'rightarrow'
        changeFrame(NaN, NaN, hObject, 'delta', 1);
    case 'leftarrow'
        changeFrame(NaN, NaN, hObject, 'delta', -1);
end

function roiName = makeROINameFromVideoName(videoName)
roiName = [videoName, '_ROI.mat'];

% --- Executes on button press in saveROIs.
function handles = saveROIs_Callback(~, ~, handles, varargin)
% hObject    handle to saveROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% currentVideoName (optional): alternate current video name to use

if nargin == 4
    currentVName = varargin{1};
else
    [~, currentVName] = getCurrentVideoFileSelection(handles);
end

[~, currentVName, ~] = fileparts(currentVName);
suggestedROIFilename = makeROINameFromVideoName(currentVName);
if get(handles.useDefaultROIPath, 'Value')
    defaultROIPath = getCurrentROIFolder(handles);
    if ~exist(defaultROIPath, 'dir')
        disp(['Creating directory: ', defaultROIPath]);
        mkdir(defaultROIPath);
    end
    selectedFile = fullfile(defaultROIPath, suggestedROIFilename);
else
    [FileName,PathName,~] = uiputfile([handles.defaultPath, suggestedROIFilename],'Select or create a file');
    if FileName == 0
        disp('ROI save aborted')
        return;
    end
    selectedFile = fullfile(PathName, FileName);
end
disp(['Saving ROIs to file: ', selectedFile]);

outputStruct.videoFile = currentVName;
outputStruct.videoSize = size(handles.videoData);
outputStruct.ROIData = handles.ROIData;
outputStruct.manualObjectTrackerVersion = handles.version;
save(selectedFile, 'outputStruct');
handles = noteThatChangesDoNotNeedToBeSaved(handles);

% --- Executes on button press in autocloseROI.
function autocloseROI_Callback(~, ~, ~)
% hObject    handle to autocloseROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of autocloseROI


% --------------------------------------------------------------------
function modeButtonGroup_ButtonDownFcn(~, ~, ~)
% hObject    handle to modeButtonGroup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in fileList.
function fileList_Callback(hObject, ~, handles)
% hObject    handle to fileList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns fileList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from fileList
set(handles.fileList, 'Enable', 'off');
[proceed, handles] = warnIfLosingROIChanges(handles);
if proceed
    [PathName, FileName] = getCurrentVideoFileSelection(handles);
    disp('Loading video...')
    disp(['Loading file: ', fullfile(PathName, FileName)])
    loadVideoOrImage(hObject, fullfile(PathName, FileName));
    disp('...video load complete')
    set(handles.fileList, 'UserData', get(handles.fileList, 'Value'));
else
    set(handles.fileList, 'Value', get(handles.fileList, 'UserData'));
end
set(handles.fileList, 'Enable', 'on');
updateDisplay(hObject)

function [PathName, FileName] = getCurrentVideoFileSelection(handles, varargin)
if nargin == 2
    previous = varargin{1};
else
    previous = false;
end

prerandomizedTrackingMode = isPrerandomizedTrackingModeOn(handles);
if ~prerandomizedTrackingMode
    PathName = get(handles.currentDirectory, 'String');
    FileNames = get(handles.fileList, 'String');
    if previous
        FileName = cell2mat(FileNames(get(handles.fileList, 'UserData')));
    else
        FileName = cell2mat(FileNames(get(handles.fileList, 'Value')));
    end
else
    [videoFilename, ~] = getPrerandomizedAnnotationNameAndFrameNumber(handles, previous);
    if ~isempty(videoFilename)
        [PathName, FileNameMinusExtension, Extension] = fileparts(videoFilename);
        FileName = [FileNameMinusExtension, Extension];
    else
        PathName = '';
        FileName = '';
    end
end

% --- Executes during object creation, after setting all properties.
function fileList_CreateFcn(hObject, ~, ~)
% hObject    handle to fileList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function updateListBox(hObject, folder)
handles = guidata(hObject);
% Get video file list
if isempty(folder)
    videoFilenames = {};
else
    aviFiles = dir(fullfile(folder, '*.avi'));
    movFiles = dir(fullfile(folder, '*.mov'));
    mp4Files = dir(fullfile(folder, '*.mp4'));
    jpgFiles = dir(fullfile(folder, '*.jpg'));
    pngFiles = dir(fullfile(folder, '*.png'));
    gifFiles = dir(fullfile(folder, '*.gif'));
    videoFiles = cat(1, movFiles, mp4Files, aviFiles, gifFiles, jpgFiles, pngFiles);
    videoFilenames = {videoFiles.name};
end
handles = setFileList(handles, videoFilenames);
guidata(hObject, handles);

function handles = setFileList(handles, filenames)
if isempty(filenames)
    filenames = {handles.nullFile};
end
set(handles.fileList, 'String', filenames);
% Reset selection to the top
set(handles.fileList, 'Value', 1);
set(handles.fileList, 'UserData', 1);

function currentDirectory_Callback(hObject, ~, ~)
% hObject    handle to currentDirectory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of currentDirectory as text
%        str2double(get(hObject,'String')) returns contents of currentDirectory as a double
handles = guidata(hObject);
folder = get(handles.currentDirectory, 'String');
if isPrerandomizedTrackingModeOn(handles)
    % Clear normal mode file list box
    updateListBox(hObject, []);
    % Get a
    if ~isempty(folder)
        matFileList = findFilesByRegex(folder, '.*\.mat', false, false);
        if length(matFileList) == 0
            % No mat files found
            warndlg('No prerandomized file lists found. Please create one or choose a directory that contains one.');
        elseif length(matFileList) == 1
            prerandomizedAnnotationFile = matFileList{1};
        elseif length(matFileList) > 1
            prerandomizedAnnotationFile = itemSelectorDialog({'Select a prerandomized annotation file', matFileList});
            if strcmp(prerandomizedAnnotationFile, 'Cancel')
                prerandomizedAnnotationFile = '';
            else
                prerandomizedAnnotationFile = prerandomizedAnnotationFile{1};
            end
            
        end
        choosePrerandomizedAnnotationFile(hObject, [], handles, prerandomizedAnnotationFile);
    end
else
    updateListBox(hObject, folder);
end

% --- Executes during object creation, after setting all properties.
function currentDirectory_CreateFcn(hObject, ~, ~)
% hObject    handle to currentDirectory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in chooseDirectoryButton.
function chooseDirectoryButton_Callback(hObject, eventdata, handles)
% hObject    handle to chooseDirectoryButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
currentPath = get(handles.currentDirectory, 'String');
if isempty(currentPath)
    currentPath = handles.defaultPath;
end
PathName = uigetdir(currentPath,'Select a directory containing video or image files');
if PathName == 0
    return;
end
%fullfile(PathName, FileName)
handles.defaultPath = PathName;
set(handles.currentDirectory, 'String', PathName);
guidata(hObject, handles);
currentDirectory_Callback(hObject, eventdata, handles);

function handles = clearAllUserData(handles)
handles = deleteUserROIHandleData(handles);
handles = deleteUserROIData(handles);

function loadROIs(hObject, ROIfilename)
handles = guidata(hObject);
[proceed, handles] = warnIfLosingROIChanges(handles);
if proceed
    data = load(ROIfilename);
    [~, VideoFileName] = getCurrentVideoFileSelection(handles);
    [~, vname, ~] = fileparts(VideoFileName);
    if ~contains(data.outputStruct.videoFile, vname)
        warndlg('Warning, filename stored in ROI mat file does not match the currently loaded video filename.');
    end
    
    if ~isfield(data.outputStruct, 'manualObjectTrackerVersion')
        % Legacy file format support
        disp('Legacy file format detected');
        if isfield(data.outputStruct, 'xData')
            choice = questdlg('Legacy file format detected. Would you like to load points as freehand or points?', 'Legacy ROI mat file support', 'Freehand','Points','Cancel','Freehand');
            switch choice
                case 'Freehand'
                    handles = clearAllUserData(handles);
                    handles.ROIData.(handles.currUser).xFreehands(1,:) = data.outputStruct.xData;
                    handles.ROIData.(handles.currUser).yFreehands(1,:) = data.outputStruct.yData;
                    [handles.ROIData.(handles.currUser).xPoints, handles.ROIData.(handles.currUser).yPoints] = createBlankROIs(handles.numFrames, handles.numROIs);
                case 'Points'
                    handles = clearAllUserData(handles);
                    handles.ROIData.(handles.currUser).xPoints(1,:) = data.outputStruct.xData;
                    handles.ROIData.(handles.currUser).yPoints(1,:) = data.outputStruct.yData;
                    [handles.ROIData.(handles.currUser).xFreehands, handles.ROIData.(handles.currUser).yFreehands] = createBlankROIs(handles.numFrames, handles.numROIs);
                case 'Cancel'
                    warndlg('ROI load cancelled.');
                    return
            end
        elseif isfield(data.outputStruct, 'xFreehandData')
            choice = questdlg('Legacy file format detected. Would you like to load points as the current user?', ...
                'Current user', 'Choose another user','Cancel','Current user');
            switch choice
                case 'Current user'
                    handles = clearAllUserData(handles);
                case 'Choose another user'
                    handles = clearAllUserData(handles);
                    username = cell2mat(inputdlg({'Input username'}, 'Input username', 1, {handles.DEFAULT_USER}));
                    handles = createNewUser(handles, username);
                    handles.currUser = username;
                case 'Cancel'
                    warndlg('ROI load cancelled.');
                    return
            end
            handles.ROIData.(handles.currUser) = createNewUserROIData(handles.numFrames, handles.numROIs);
            handles.ROIData.(handles.currUser).xPoints(1,:) = data.outputStruct.xPointData;
            handles.ROIData.(handles.currUser).yPoints(1,:) = data.outputStruct.yPointData;
            handles.ROIData.(handles.currUser).xFreehands(1,:) = data.outputStruct.xFreehandData;
            handles.ROIData.(handles.currUser).yFreehands(1,:) = data.outputStruct.yFreehandData;
%            handles.ROIData.(handles.currUser).xProj = data.outputStruct.ROIData.xProj;
%            handles.ROIData.(handles.currUser).zProj = data.outputStruct.ROIData.zProj;
            [newUserROIHandleData, handles] = createNewUserROIHandleData(handles, handles.currUser);
            handles.hROI.(handles.currUser) = newUserROIHandleData;
        else
            disp('Unknown file format, load failed.');
            return
        end
    elseif isfield(data.outputStruct, 'ROIData')
        newUsers = fieldnames(data.outputStruct.ROIData);
        if isfield(data.outputStruct.ROIData.(newUsers{1}), 'xPoint')
            for k = 1:length(newUsers)
                newUser = newUsers{k};
                handles.ROIData.(newUser) = createNewUserROIData(handles.numFrames, handles.numROIs);
                handles.ROIData.(newUser).xPoints(1,:) = data.outputStruct.ROIData.(newUser).xPoint;
                handles.ROIData.(newUser).yPoints(1,:) = data.outputStruct.ROIData.(newUser).yPoint;
                handles.ROIData.(newUser).xFreehands(1,:) = data.outputStruct.ROIData.(newUser).xFreehand;
                handles.ROIData.(newUser).yFreehands(1,:) = data.outputStruct.ROIData.(newUser).yFreehand;
                handles.ROIData.(newUser).xProj = data.outputStruct.ROIData.(newUser).xProj;
                handles.ROIData.(newUser).zProj = data.outputStruct.ROIData.(newUser).zProj;
                [newUserROIHandleData, handles] = createNewUserROIHandleData(handles, newUser);
                handles.hROI.(newUser) = newUserROIHandleData;
            end
        else
            for k = 1:length(newUsers)
                u = newUsers{k};
                if ~isfield(data.outputStruct.ROIData.(u), 'stats')
                    % If legacy format doesn't have ROI stats, create blank
                    % ones
                    data.outputStruct.ROIData.(u).stats = createBlankStatsData(handles.numFrames, handles.numROIs);
                end
            end
            
            % .mat file format is compatible. Load ROIs
            handles = clearAllUserData(handles);
            handles.ROIData = data.outputStruct.ROIData;
            if ~any(strcmp(handles.currUser, newUsers))
                handles.ROIData.(handles.currUser) = createNewUserROIData(handles.numFrames, handles.numROIs);
            end
            for k = 1:length(newUsers)
                newUser = newUsers{k};
                [newUserROIHandleData, handles] = createNewUserROIHandleData(handles, newUser);
                handles.hROI.(newUser) = newUserROIHandleData;
            end
        end
    else
        disp('Error, ROI file structure not recognized.');
    end
    
    handles = noteThatChangesDoNotNeedToBeSaved(handles);
    disp(['Successfully loaded ROIs from file: ', ROIfilename])
end

guidata(hObject, handles);
updateDisplay(hObject)

% --- Executes on button press in loadROIs.
function loadROIs_Callback(hObject, ~, ~)
% hObject    handle to loadROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
[VideoFilePath, ~] = getCurrentVideoFileSelection(handles);
[FileName,PathName,~] = uigetfile(fullfile(VideoFilePath, '*.mat'),'Select ROI file to load');
if FileName ~= 0
    loadROIs(hObject, fullfile(PathName, FileName));
end

% --- Executes on button press in autoLoadROIs.
function autoLoadROIs_Callback(~, ~, ~)
% hObject    handle to autoLoadROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of autoLoadROIs

% --- Executes on button press in clearROIs.
function clearROIs_Callback(hObject, ~, handles)
% hObject    handle to clearROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
choice = questdlg('Are you sure you want to delete ALL ROIs for ALL FRAMES of this ENTIRE video?', 'Delete ROIs?', 'Delete', 'Cancel', 'Cancel');

if strcmp(choice, 'Cancel')
    return;
end

[proceed, handles] = warnIfLosingROIChanges(handles);
if proceed
    if strcmp(get(handles.modeButtonGroup.SelectedObject, 'String'), 'Freehand')
        [handles.ROIData.(handles.currUser).xFreehands, handles.ROIData.(handles.currUser).yFreehands] = createBlankROIs(handles.numFrames, handles.numROIs);
    else
        [handles.ROIData.(handles.currUser).xPoints, handles.ROIData.(handles.currUser).yPoints] = createBlankROIs(handles.numFrames, handles.numROIs);
    end
    handles = noteThatChangesDoNotNeedToBeSaved(handles);
    guidata(hObject, handles);
    updateDisplay(hObject);
end

% --- Executes on button press in useDefaultROIPath.
function useDefaultROIPath_Callback(~, ~, ~)
% hObject    handle to useDefaultROIPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of useDefaultROIPath


% --- Executes on button press in adjustContrast.
function adjustContrast_Callback(~, ~, handles)
% hObject    handle to adjustContrast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
imcontrast(handles.hImage);


% --- Executes on button press in pointModeButton.
function pointModeButton_Callback(~, ~, ~)
% hObject    handle to pointModeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of pointModeButton


% --- Executes on button press in closeROI.
function closeROI_Callback(hObject, ~, handles)
% hObject    handle to closeROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(handles.modeButtonGroup.SelectedObject, 'String'), 'Freehand')
    [handles.ROIData.(handles.currUser).xFreehands{handles.activeROINum, handles.k}, handles.ROIData.(handles.currUser).yFreehands{handles.activeROINum, handles.k}] ...
        = closeROI(handles.ROIData.(handles.currUser).xFreehands{handles.activeROINum, handles.k}, handles.ROIData.(handles.currUser).yFreehands{handles.activeROINum, handles.k});
else
    [handles.ROIData.(handles.currUser).xPoints{handles.activeROINum, handles.k}, handles.ROIData.(handles.currUser).yPoints{handles.activeROINum, handles.k}] ...
        = closeROI(handles.ROIData.(handles.currUser).xPoints{handles.activeROINum, handles.k}, handles.ROIData.(handles.currUser).yPoints{handles.activeROINum, handles.k});
end
handles = noteThatChangesNeedToBeSaved(handles);
guidata(hObject, handles);
updateDisplay(hObject);

% --- Executes on button press in switchCurrentUser.
function switchCurrentUser_Callback(hObject, ~, handles)
% hObject    handle to switchCurrentUser (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
username = cell2mat(inputdlg({'Input username'}, 'Input username', 1, {handles.DEFAULT_USER}));
if isfield(handles.ROIData, username)
    handles.currUser = username;
else
    response = questdlg('Username not found in this file. Create new user?', 'Create new user?', 'Create new user', 'Cancel', 'Cancel');
    if strcmp(response, 'Create new user')
        handles.currUser = username;
        handles = createNewUser(handles, handles.currUser);
    end
end
guidata(hObject, handles);
updateDisplay(hObject);

function handles = createNewUser(handles, user)
handles.ROIData.(user) = createNewUserROIData(handles.numFrames, handles.numROIs);
[newUserROIHandleData, handles] = createNewUserROIHandleData(handles, user);
handles.hROI.(user) = newUserROIHandleData;
handles = noteThatChangesNeedToBeSaved(handles);

function jumpToFrameBox_Callback(hObject, ~, handles)
% hObject    handle to jumpToFrameBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of jumpToFrameBox as text
%        str2double(get(hObject,'String')) returns contents of jumpToFrameBox as a double
changeFrame(NaN, NaN, hObject, 'absolute', str2double(get(handles.jumpToFrameBox,'String')));

% --- Executes during object creation, after setting all properties.
function jumpToFrameBox_CreateFcn(hObject, ~, ~)
% hObject    handle to jumpToFrameBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function jumpToFrameBox_keyPressFcn(hObject, ~)
% Tried to get this to remove keyboard focus from jumpToFrameBox so it
% would jump frame immediately on keypress, but it doesn't work so far.
handles = guidata(hObject);
uicontrol(handles.axes1)
%changeFrame(NaN, NaN, hObject, 'absolute', str2double(get(handles.jumpToFrameBox,'String')));

function handles = toggleTongueAbsent(handles, k, n, u)
% Toggle annotation of "tongue absent" for the given frame, roi num, and
% user
% k = frame number
% n = ROI num
% u = user
if isnan(n)
    % If n is NaN, loop over all ROIs
    s = size(handles.ROIData.(u).absent);
    nRange = 1:s(1);
else
    nRange = n;
end
for n = nRange
    handles.ROIData.(u).absent(n, k) = ~handles.ROIData.(u).absent(n, k);
    if handles.ROIData.(u).absent(n, k)
        % User just marked the current ROI in this frame as no data.
        % If there's any data here, delete it:
        handles.ROIData.(u).xPoints{n, k} = [];
        handles.ROIData.(u).yPoints{n, k} = [];
        handles.ROIData.(u).xFreehands{n, k} = [];
        handles.ROIData.(u).yFreehands{n, k} = [];
        handles.ROIData.(u).xProj{n, k} = [];
        handles.ROIData.(u).zProj{n, k} = [];
    end
end
handles = noteThatChangesNeedToBeSaved(handles);

% --- Executes on button press in absentTongueButton.
function absentTongueButton_Callback(hObject, ~, handles)
% hObject    handle to absentTongueButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
k = handles.k;
n = handles.activeROINum;
u = handles.currUser;
handles = toggleTongueAbsent(handles, k, n, u);
handles = noteThatChangesNeedToBeSaved(handles);
guidata(hObject, handles)
updateDisplay(hObject)

% --- Executes on button press in helpButton.
function helpButton_Callback(hObject, eventdata, handles)
% hObject    handle to helpButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
helpdialog(handles)

% --- Executes on button press in prerandomizedTrackingModeButton.
function prerandomizedTrackingModeButton_Callback(hObject, ~, handles)
% hObject    handle to prerandomizedTrackingModeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of prerandomizedTrackingModeButton
if isPrerandomizedTrackingModeOn(handles)
    set(handles.prerandomizedModePanel, 'Visible', 'on');
    set(handles.normalModePanel, 'Visible', 'off');
else
    set(handles.prerandomizedModePanel, 'Visible', 'off');
    set(handles.normalModePanel, 'Visible', 'on');
end

set(handles.currentDirectory, 'String', '');
guidata(hObject, handles);
currentDirectory_Callback(hObject, [], handles);
unloadVideoOrImage(hObject);

function mode = isPrerandomizedTrackingModeOn(handles)
mode = get(handles.prerandomizedTrackingModeButton, 'Value');

function isAnnotated = isFrameAnnotated(handles, frameNum)
isAnnotated = [false, false];
for roiNum = 1:2
    if ~isempty(handles.ROIData.(handles.currUser).xFreehands)
        if ~isempty(handles.ROIData.(handles.currUser).xFreehands{roiNum, frameNum})
            isAnnotated(roiNum) = true;
            continue;
        end
    end
    if ~isempty(handles.ROIData.(handles.currUser).absent)
        if handles.ROIData.(handles.currUser).absent(roiNum, frameNum)
            isAnnotated(roiNum) = true;
            continue;
        end
    end
    if ~isempty(handles.ROIData.(handles.currUser).xPoints)
        if ~isempty(handles.ROIData.(handles.currUser).xPoints{roiNum, frameNum})
            isAnnotated(roiNum) = true;
            continue;
        end
    end
end
isAnnotated = all(isAnnotated);

function handles = updatePrerandomizedAnnotationListboxes(handles)
listboxVideoNames = cell([1, length(handles.prerandomizedAnnotationInfo)]);
width = 53;
ellipsisStart = 3;
for k = 1:length(handles.prerandomizedAnnotationInfo)
    listboxVideoNames{k} = truncateWithEllipsis(handles.prerandomizedAnnotationInfo(k).videoFilename, width, ellipsisStart);
end
set(handles.prerandomizedAnnotationVideoListbox, 'String', listboxVideoNames);
currentVideoFilenameIndex = get(handles.prerandomizedAnnotationVideoListbox, 'Value');
frameNumDisplayList = {};

if ~isempty(handles.prerandomizedAnnotationInfo)
    for frameNum = handles.prerandomizedAnnotationInfo(currentVideoFilenameIndex).frameNumbers
        if isFrameAnnotated(handles, frameNum)
            annotationMark = [' ', char(10003)];
        else
            annotationMark = '';
        end
        frameNumDisplayList{end+1} = [' ', num2str(frameNum), annotationMark];
    end
end
set(handles.prerandomizedAnnotationFrameNumListbox, 'String', frameNumDisplayList);

% --- Executes on selection change in prerandomizedAnnotationVideoListbox.
function prerandomizedAnnotationVideoListbox_Callback(hObject, ~, ~)
% hObject    handle to prerandomizedAnnotationVideoListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns prerandomizedAnnotationVideoListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from prerandomizedAnnotationVideoListbox

handles = guidata(hObject);
set(handles.prerandomizedAnnotationVideoListbox, 'Enable', 'off');
set(handles.prerandomizedAnnotationFrameNumListbox, 'Enable', 'off');
[proceed, handles] = warnIfLosingROIChanges(handles);
if proceed
    [PathName, FileName] = getCurrentVideoFileSelection(handles);
    if ~isempty(FileName)
        disp('Loading video...')
        disp(['Loading file: ', fullfile(PathName, FileName)])
        loadVideoOrImage(hObject, fullfile(PathName, FileName));
        disp('...video load complete')
    else
        guidata(hObject, handles);
        unloadVideoOrImage(hObject);
        handles = guidata(hObject);
    end
    set(handles.prerandomizedAnnotationVideoListbox, 'UserData', get(handles.prerandomizedAnnotationVideoListbox, 'Value'));
else
    set(handles.prerandomizedAnnotationVideoListbox, 'Value', get(handles.prerandomizedAnnotationVideoListbox, 'UserData'));
end
set(handles.prerandomizedAnnotationVideoListbox, 'Enable', 'on');
set(handles.prerandomizedAnnotationFrameNumListbox, 'Value', 1);
updateDisplay(hObject)
% Call framenumber listbox change function
prerandomizedAnnotationFrameNumListbox_Callback(hObject, NaN, handles)
updateDisplay(hObject)
set(handles.prerandomizedAnnotationVideoListbox, 'Enable', 'on');
set(handles.prerandomizedAnnotationFrameNumListbox, 'Enable', 'on');

% --- Executes during object creation, after setting all properties.
function prerandomizedAnnotationVideoListbox_CreateFcn(hObject, ~, ~)
% hObject    handle to prerandomizedAnnotationVideoListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function [videoFilename, frameNumber] = getPrerandomizedAnnotationNameAndFrameNumber(handles, varargin)
if nargin == 2
    previous = varargin{1};
else
    previous = false;
end

if previous
    videoFilenameIndex = get(handles.prerandomizedAnnotationVideoListbox,'UserData');
else
    videoFilenameIndex = get(handles.prerandomizedAnnotationVideoListbox,'Value');
end

frameNumberIndex = get(handles.prerandomizedAnnotationFrameNumListbox,'Value');
if isnumeric(videoFilenameIndex) && ~isempty(handles.prerandomizedAnnotationInfo)
    videoFilename = handles.prerandomizedAnnotationInfo(videoFilenameIndex).videoFilename;
    if isnumeric(frameNumberIndex)
        frameNumber = handles.prerandomizedAnnotationInfo(videoFilenameIndex).frameNumbers(frameNumberIndex);
    else
        frameNumber = NaN;
    end
else
    frameNumber = NaN;
    videoFilename = '';
end

function choosePrerandomizedAnnotationFile(hObject, ~, handles, varargin)
% hObject    handle to choosePrerandomizedAnnotationFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isempty(get(handles.currentDirectory, 'String'))
   warndlg('Please choose a video (clip) dir to search for videos first.')
   return
end

if ~isempty(varargin) 
    prerandomizedAnnotationFilepath = varargin{1};
else
    prerandomizedAnnotationFilepath = '';
end

if ~isempty(prerandomizedAnnotationFilepath)
    handles.prerandomizedAnnotationFilepath = prerandomizedAnnotationFilepath;
    invalidFile = false;
    try
        disp('loading annotation file...')
        s = load(prerandomizedAnnotationFilepath, 'manualTrackingList');
        invalidFile = false;
        if ~isfield(s, 'manualTrackingList') || ~isfield(s.manualTrackingList, 'videoFilename') || ~isfield(s.manualTrackingList, 'frameNumbers')
            invalidFile = true;
            error('Invalid pre-randomized annotation list file')
        end
        disp('...done loading annotation file')
        drawnow
    catch
        disp(['Load pre-randomized annotation list file failed for file ', prerandomizedAnnotationFilepath]);
        if invalidFile
            disp('Invalid file format')
        end
    end
    handles.prerandomizedAnnotationInfo = [];
    set(handles.prerandomizedAnnotationFrameNumListbox, 'String', {'Loading...'});
    set(handles.prerandomizedAnnotationVideoListbox, 'String', {'Loading...'});

    % Get a list of possible extensions
    extensionList = cell(1, length(s.manualTrackingList));
    for k = 1:length(s.manualTrackingList)
        [~, ~, extension] = fileparts(s.manualTrackingList(k).videoFilename);
        extensionList{k} = regexptranslate('escape', extension);
    end
    extensionList = unique(extensionList);
    extensions = strjoin(extensionList, '|');
    
    % Find video files with the correct extension:
    possibleVideoFiles = findFilesByRegex(get(handles.currentDirectory, 'String'), ['.*(', extensions, ')']);
    
    for k = 1:length(s.manualTrackingList)
        % Loop through saved list of videos, and find corresponding videos 
        %   in the specified root directory structure
        disp(['(', num2str(k), ' of ', num2str(length(s.manualTrackingList)), ') Locating video corresponding to ', s.manualTrackingList(k).videoFilename])
        [~, vname, ~] = fileparts(s.manualTrackingList(k).videoFilename);
        % Strip cue and laser info just in case
%        vname = regexprep(vname, '(_C[0-9]+L?)', '');
%        vnameRegex = regexptranslate('escape', vname);
        [matchingVFiles, matchingVIndices] = filterWithPattern(possibleVideoFiles, vname);
        if isempty(matchingVFiles)
            warndlg(['Warning, could not find a video file that matched ', vname, ' in root directory ', get(handles.currentDirectory, 'String'), '. Skipping...'], 'manualObjectTracker warning', 'replace');
        else
            if length(matchingVFiles) > 1
                disp('Matching video files:')
                disp(matchingVFiles')
                warndlg(['Warning, found multiple video files matching that matched ', vname, ' in root directory ', get(handles.currentDirectory, 'String'), '. Picking the first one found.'], 'manualObjectTracker warning', 'replace');
            end
            handles.prerandomizedAnnotationInfo(end+1).videoFilename = matchingVFiles{1};
            handles.prerandomizedAnnotationInfo(end).frameNumbers = s.manualTrackingList(k).frameNumbers;
            possibleVideoFiles(matchingVIndices(1)) = [];
        end
    end
else
    % Clear prerandomized info
    handles.prerandomizedAnnotationInfo = [];
%     % Prompt user for a prerandomized annotation filepath
%     currentPath = get(handles.currentDirectory, 'String');
%     if isempty(currentPath)
%         currentPath = handles.defaultPath;
%     end
%     [PRAFile, PRAPath] = uigetfile(fullfile(currentPath, '*.mat'),'Select a prerandomized annotation file');
%     prerandomizedAnnotationFilepath = fullfile(PRAPath, PRAFile);
end

disp(['Prerandomized annotation file selected: ', prerandomizedAnnotationFilepath]);
% Update list boxes
handles = updatePrerandomizedAnnotationListboxes(handles);
% Select first video
set(handles.prerandomizedAnnotationVideoListbox, 'Value', 1);
set(handles.prerandomizedAnnotationVideoListbox, 'UserData', 1);
guidata(hObject, handles)
prerandomizedAnnotationVideoListbox_Callback(hObject, NaN, NaN);

% --- Executes on selection change in prerandomizedAnnotationFrameNumListbox.
function prerandomizedAnnotationFrameNumListbox_Callback(hObject, ~, handles)
% hObject    handle to prerandomizedAnnotationFrameNumListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns prerandomizedAnnotationFrameNumListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from prerandomizedAnnotationFrameNumListbox
set(handles.prerandomizedAnnotationVideoListbox, 'Enable', 'off');
set(handles.prerandomizedAnnotationFrameNumListbox, 'Enable', 'off');

[videoFilename, frameNumber] = getPrerandomizedAnnotationNameAndFrameNumber(handles);
if ~isnan(frameNumber)
    changeFrame(NaN, NaN, hObject, 'absolute', frameNumber);
end

set(handles.prerandomizedAnnotationVideoListbox, 'Enable', 'on');
set(handles.prerandomizedAnnotationFrameNumListbox, 'Enable', 'on');

% --- Executes during object creation, after setting all properties.
function prerandomizedAnnotationFrameNumListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to prerandomizedAnnotationFrameNumListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function truncatedString = truncateWithEllipsis(longString, maxLength, varargin)
    if nargin == 3
        ellipsisStart = varargin{1};
    else
        ellipsisStart = floor(maxLength/2) - 2;
    end
    divider = '...';
    if length(longString) > maxLength
        startLength = ellipsisStart;
        endLength = maxLength - (startLength + length(divider));
        truncatedString = [longString(1:startLength), divider, longString(end-endLength:end)];
    else
        truncatedString = longString;
    end

function [filteredListOfStrings, filteredIndices] = filterWithRegexp(listOfStrings, regex)
filterBoolean = cell2mat(cellfun(@(s)~isempty(regexp(s, regex, 'once')), listOfStrings, 'UniformOutput', false));
filteredIndices = 1:numel(listOfStrings);
filteredIndices = filteredIndices(filterBoolean);
filteredListOfStrings = listOfStrings(filteredIndices);

function [filteredListOfStrings, filteredIndices] = filterWithPattern(listOfStrings, pattern)
filterBoolean = cell2mat(cellfun(@(s)contains(s, pattern), listOfStrings, 'UniformOutput', false));
filteredIndices = 1:numel(listOfStrings);
filteredIndices = filteredIndices(filterBoolean);
filteredListOfStrings = listOfStrings(filteredIndices);

function helpdialog(handles)
    % Adapted from https://www.mathworks.com/help/matlab/ref/dialog.html
    d = dialog('Position',[10 100 650 500],'Name','Manual Object Tracker help');
    helpText = {
        ['manualObjectTracker version ', handles.version], ...
        '', ...
        'Manual Object Tracker is designed to allow manual tracing of regions of interest in the frames of a video or in an image.',     ...
        '', ...
        'Command reference:', ...
        '', ...
        'Keyboard & mouse controls/hotkeys:', ...
        '  Left click       - add point to ROI', ...
        '  Right click      - Start or end creating a zoom in/out box', ...
        '                     Draw box down+right to zoom in, up+left to zoom out.' ...
        '  a                - reset zoom to show whole frame', ...
        '  space            - play/pause video'  ...
        '  ctl-z            - undo last point of current ROI', ...
        '  delete           - clear all points for current ROI', ...
        '  c                - close the ROI', ...
        '  shift-n          - mark current ROI as "no tongue"', ...
        '  n                - mark all ROIs as "no tongue"', ...
        '  left arrow       - back 1 frame', ...
        '  ctl-left arrow   - back 10 frames', ...
        '  right arrow      - forward 1 frame', ...
        '  ctl-right arrow  - forward 10 frames', ...
        '  shift-arrow      - shift last ROI point in a direction', ...
        '  alt-arrow        - translate ROI (hold down to go faster)', ...
        '  q                - switch to the previous video in the list', ...
        '  w                - switch to the next video in the list', ...
        '  m                - add a measuring tool (right click to delete)', ...
        '', ...
        '  Written by Brian Kardon bmk27@cornell.edu 2018'...
        '', ...
        '', ...
        };
    txt = uicontrol('Parent',d,...
               'Style','text',...
               'Position',[20 -60 600 550],...
               'FontSize', 10,...
               'HorizontalAlignment', 'left',...
               'String',helpText,...
               'FontName','Courier');

    btn = uicontrol('Parent',d,...
               'Position',[90 0 470 25],...
               'String','Close',...
               'Callback','delete(gcf)');

% --- Executes on button press in autoSaveOnFrameChange.
function autoSaveOnFrameChange_Callback(hObject, eventdata, handles)
% hObject    handle to autoSaveOnFrameChange (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of autoSaveOnFrameChange


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function handles = updateROIStatDisplay(handles)
areaText = '';
%frameSize = size(handles.videoData(:, :, handles.k));
%widthPixels = frameSize(2);

% Get the current stored unit
unit = handles.ROIData.(handles.currUser).stats.scaleUnit;
% Set the display unit to match the stored unit
if ~isempty(unit)
    unitList = cellstr(get(handles.scaleUnitSelector,'String'));
    unitListIndex = find(cellfun(@(x) strcmp(x, unit), unitList, 'UniformOutput', 1));
    set(handles.scaleUnitSelector, 'Value', unitListIndex);
else
    if handles.autoApplyScaleDataToNewImages
        unitList = cellstr(get(handles.scaleUnitSelector,'String'));
        unitIndex = get(handles.scaleUnitSelector, 'Value');
        currentlyDisplayedScaleUnit = unitList{unitIndex};
        handles.ROIData.(handles.currUser).stats.scaleUnit = currentlyDisplayedScaleUnit;
        if ~isempty(currentlyDisplayedScaleUnit)
            handles = updateROIStatDisplay(handles);
        end
        handles = noteThatChangesNeedToBeSaved(handles);
    end
end

% Get the stored unit scale information
unitScaleMeasurement = handles.ROIData.(handles.currUser).stats.unitScaleMeasurement;
if ~isempty(unitScaleMeasurement)
    % Set the display width scale information to match the stored information
    set(handles.unitScaleMeasurement, 'String', num2str(unitScaleMeasurement));
else
    if handles.autoApplyScaleDataToNewImages
        currentlyDisplayedUnitScaleMeasurement = str2num(get(handles.unitScaleMeasurement, 'String'));
        handles.ROIData.(handles.currUser).stats.unitScaleMeasurement = currentlyDisplayedUnitScaleMeasurement;
        if ~isempty(currentlyDisplayedUnitScaleMeasurement)
            handles = updateROIStatDisplay(handles);
        end
        handles = noteThatChangesNeedToBeSaved(handles);
    end
end

% Get the stored pixel scale information
pixelScaleMeasurement = handles.ROIData.(handles.currUser).stats.pixelScaleMeasurement;
%disp(['Found stored pixel scale measurement: ', num2str(pixelScaleMeasurement)])
if ~isempty(pixelScaleMeasurement)
    % Set the display width scale information to match the stored information
%    disp('Stored pixel scale measurement is not empty - updating display!')
    set(handles.pixelScaleMeasurement, 'String', num2str(pixelScaleMeasurement));
else
    if handles.autoApplyScaleDataToNewImages
%        disp('Stored pixel scale measurement IS empty! Storing displayed value')
        currentlyDisplayedPixelScaleMeasurement = str2num(get(handles.pixelScaleMeasurement, 'String'));
        handles.ROIData.(handles.currUser).stats.pixelScaleMeasurement = currentlyDisplayedPixelScaleMeasurement;
        if ~isempty(currentlyDisplayedPixelScaleMeasurement)
            handles = updateROIStatDisplay(handles);
        end
        handles = noteThatChangesNeedToBeSaved(handles);
    end
end

for n = 1:handles.numROIs
    x = handles.ROIData.(handles.currUser).xFreehands{n, handles.k};
    y = handles.ROIData.(handles.currUser).yFreehands{n, handles.k};
    areaPixels = polyarea(x, y);
    if isempty(unitScaleMeasurement) || isempty(pixelScaleMeasurement)
        areaUnits = areaPixels;
    else
        areaUnits = areaPixels * (unitScaleMeasurement^2)/(pixelScaleMeasurement ^2);
    end
    handles.ROIData.(handles.currUser).stats.areaPixels(n, handles.k) = areaPixels;
    handles.ROIData.(handles.currUser).stats.areaUnits(n, handles.k) = areaUnits;
    
    areaText = [areaText, num2str(areaUnits), ' ', unit, '² '];
end
set(handles.ROIAreas, 'String', areaText);
handles = noteThatChangesNeedToBeSaved(handles);

% --- Executes on selection change in scaleUnitSelector.
function scaleUnitSelector_Callback(hObject, eventdata, handles)
% hObject    handle to scaleUnitSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns scaleUnitSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from scaleUnitSelector
handles = guidata(hObject);
scaleUnitList = cellstr(get(handles.scaleUnitSelector, 'String'));
scaleUnit = scaleUnitList{get(handles.scaleUnitSelector, 'Value')};
handles.ROIData.(handles.currUser).stats.scaleUnit = scaleUnit;
handles = noteThatChangesNeedToBeSaved(handles);
guidata(hObject, handles);
updateDisplay(hObject);

% --- Executes during object creation, after setting all properties.
function scaleUnitSelector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scaleUnitSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in startScaleMeasureButton.
function startScaleMeasureButton_Callback(hObject, eventdata, handles)
% hObject    handle to startScaleMeasureButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
toggleDistanceMeasurement(hObject);

function unitScaleMeasurement_Callback(hObject, eventdata, handles)
% hObject    handle to unitScaleMeasurement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of unitScaleMeasurement as text
%        str2double(get(hObject,'String')) returns contents of unitScaleMeasurement as a double
handles = guidata(hObject);
handles.ROIData.(handles.currUser).stats.unitScaleMeasurement = str2double(get(handles.unitScaleMeasurement, 'String'));
handles = noteThatChangesNeedToBeSaved(handles);
handles = updateROIStatDisplay(handles);
guidata(hObject, handles);
updateDisplay(hObject);


% --- Executes during object creation, after setting all properties.
function unitScaleMeasurement_CreateFcn(hObject, eventdata, handles)
% hObject    handle to unitScaleMeasurement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pixelScaleMeasurement_Callback(hObject, eventdata, handles)
% hObject    handle to pixelScaleMeasurement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pixelScaleMeasurement as text
%        str2double(get(hObject,'String')) returns contents of pixelScaleMeasurement as a double
handles = guidata(hObject);
handles.ROIData.(handles.currUser).stats.pixelScaleMeasurement = str2double(get(handles.pixelScaleMeasurement, 'String'));
handles = noteThatChangesNeedToBeSaved(handles);
handles = updateROIStatDisplay(handles);
guidata(hObject, handles);
updateDisplay(hObject);


% --- Executes during object creation, after setting all properties.
function pixelScaleMeasurement_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pixelScaleMeasurement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function [x, y] = translateROI(deltaX, deltaY, x, y)
% Translate x and y
x = x + deltaX;
y = y + deltaY;

function [x, y] = rotateROI(theta, x, y)
% Rotate x and y coordinates about the centroid
xc = mean(x);
yc = mean(y);
x = x - xc;
y = y - yc;
R = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
xy = [x; y]';
xy = xy*R;
x = xy(:, 1)' + xc;
y = xy(:, 2)' + yc;

function [x, y] = scaleROI(scale, x, y)
% Scale x and y coordinates from the centroid
xc = mean(x);
yc = mean(y);
x = x - xc;
y = y - yc;
x = x * scale + xc;
y = y * scale + yc;

% --- Executes on button press in rotateROIButton.
function rotateROIButton_Callback(hObject, eventdata, handles)
% hObject    handle to rotateROIButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
answer = inputdlg('Enter the angle to rotate in degrees (positive = cw, negative = ccw)','Rotate active ROI');
if ~isempty(answer)
    theta = str2double(answer);
    if strcmp(get(handles.modeButtonGroup.SelectedObject, 'String'), 'Freehand')
        [handles.ROIData.(handles.currUser).xFreehands{handles.k}, handles.ROIData.(handles.currUser).yFreehands{handles.k}] = rotateROI(theta, handles.ROIData.(handles.currUser).xFreehands{handles.k}, handles.ROIData.(handles.currUser).yFreehands{handles.k});
    else
        [handles.ROIData.(handles.currUser).xPoints{handles.k}, handles.ROIData.(handles.currUser).yPoints{handles.k}] = rotateROI(theta, handles.ROIData.(handles.currUser).xPoints{handles.k}, handles.ROIData.(handles.currUser).yPoints{handles.k});
    end
    handles = noteThatChangesNeedToBeSaved(handles);
    guidata(hObject, handles);
    updateDisplay(hObject);
end

% --- Executes on button press in scaleROIButton.
function scaleROIButton_Callback(hObject, eventdata, handles)
% hObject    handle to scaleROIButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
answer = inputdlg('Enter the factor by which to scale the active ROI (>1 ==> larger, <1 ==> smaller)','Scale active ROI');
if ~isempty(answer)
    scale = str2double(answer);
    if strcmp(get(handles.modeButtonGroup.SelectedObject, 'String'), 'Freehand')
        [handles.ROIData.(handles.currUser).xFreehands{handles.k}, handles.ROIData.(handles.currUser).yFreehands{handles.k}] = scaleROI(scale, handles.ROIData.(handles.currUser).xFreehands{handles.k}, handles.ROIData.(handles.currUser).yFreehands{handles.k});
    else
        [handles.ROIData.(handles.currUser).xPoints{handles.k}, handles.ROIData.(handles.currUser).yPoints{handles.k}] = scaleROI(scale, handles.ROIData.(handles.currUser).xPoints{handles.k}, handles.ROIData.(handles.currUser).yPoints{handles.k});
    end
    handles = noteThatChangesNeedToBeSaved(handles);
    guidata(hObject, handles);
    updateDisplay(hObject);
end


% --- Executes on button press in swapROIs.
function swapROIs_Callback(hObject, eventdata, handles)
% hObject    handle to swapROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = guidata(hObject);
handles.ROIData.(handles.currUser).xFreehands = permuteRows(handles.ROIData.(handles.currUser).xFreehands);
handles.ROIData.(handles.currUser).yFreehands = permuteRows(handles.ROIData.(handles.currUser).yFreehands);
handles.ROIData.(handles.currUser).xPoints = permuteRows(handles.ROIData.(handles.currUser).xPoints);
handles.ROIData.(handles.currUser).yPoints = permuteRows(handles.ROIData.(handles.currUser).yPoints);
handles = noteThatChangesNeedToBeSaved(handles);
guidata(hObject, handles);
updateDisplay(hObject);

function permutedArray = permuteRows(array)
shape = size(array);
rows = shape(1);
idx = [rows, 1:(rows-1)];
permutedArray = array(idx, :);


% --- Executes on button press in assemblePrerandomizedAnnotations.
function assemblePrerandomizedAnnotations_Callback(hObject, eventdata, handles)
% hObject    handle to assemblePrerandomizedAnnotations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[proceed, handles] = warnIfLosingROIChanges(handles);
p = assembleRandomManualTrackingAnnotationsGUI({get(handles.currentDirectory, 'String'), 'assembledRandomFrames'});
if p.complete
    msgbox(['Assembling random manual tracking annotations is complete. You can find your file at ', p.saveFilepath], 'Done assembling random manual tracking annotations.');
end

% --- Executes on button press in createPrerandomizationButton.
function createPrerandomizationButton_Callback(hObject, eventdata, handles)
% hObject    handle to createPrerandomizationButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

p = generateRandomManualTrackingListGUI();
if isempty(p)
    return;
end
if ~exist(p.clipDirectory, 'dir')
    try
        disp('Clip directory not found - attempting to create it')
        mkdir(p.clipDirectory)
    catch ME
        disp(ME)
        disp(['Failed to create clip directory ', p.clipDirectory])
        warndlg(['Failed to create clip directory ', p.clipDirectory], 'Failed to create directory')
        return
    end
end
generateRandomManualTrackingList(p.videoRootDirectories, ...
    p.videoRegex, ...
    p.videoExtensions, ...
    p.numAnnotations, ...
    p.saveFilepath, ...
    p.clipDirectory, ...
    p.clipRadius, ...
    p.recursiveSearch);
%set(handles.choosePrerandomizedAnnotationFile,'Enable','on')
set(handles.currentDirectory, 'String', p.clipDirectory);
choosePrerandomizedAnnotationFile(hObject, eventdata, handles, p.saveFilepath);
msgbox({'Generating random manual tracking list is complete!', ...
        'You may now annotate the randomly selected videos or clips. ', ...
        ['You can find the clips in: ', p.clipDirectory], ...
        ['You can find the random annotation list file at: ', p.saveFilepath]}, ...
        'Generation complete.');
