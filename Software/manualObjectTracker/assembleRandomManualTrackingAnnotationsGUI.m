function varargout = assembleRandomManualTrackingAnnotationsGUI(varargin)
% ASSEMBLERANDOMMANUALTRACKINGANNOTATIONSGUI MATLAB code for assembleRandomManualTrackingAnnotationsGUI.fig
%      ASSEMBLERANDOMMANUALTRACKINGANNOTATIONSGUI, by itself, creates a new ASSEMBLERANDOMMANUALTRACKINGANNOTATIONSGUI or raises the existing
%      singleton*.
%
%      H = ASSEMBLERANDOMMANUALTRACKINGANNOTATIONSGUI returns the handle to a new ASSEMBLERANDOMMANUALTRACKINGANNOTATIONSGUI or the handle to
%      the existing singleton*.
%
%      ASSEMBLERANDOMMANUALTRACKINGANNOTATIONSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ASSEMBLERANDOMMANUALTRACKINGANNOTATIONSGUI.M with the given input arguments.
%
%      ASSEMBLERANDOMMANUALTRACKINGANNOTATIONSGUI('Property','Value',...) creates a new ASSEMBLERANDOMMANUALTRACKINGANNOTATIONSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before assembleRandomManualTrackingAnnotationsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to assembleRandomManualTrackingAnnotationsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help assembleRandomManualTrackingAnnotationsGUI

% Last Modified by GUIDE v2.5 09-Jun-2020 20:25:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @assembleRandomManualTrackingAnnotationsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @assembleRandomManualTrackingAnnotationsGUI_OutputFcn, ...
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


% --- Executes just before assembleRandomManualTrackingAnnotationsGUI is made visible.
function assembleRandomManualTrackingAnnotationsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to assembleRandomManualTrackingAnnotationsGUI (see VARARGIN)

if length(varargin) == 1 && iscell(varargin{1})
    % Defaults have been passsed in
    varargin = varargin{1};

    if length(varargin) >= 1
        baseDirectory = varargin{1};
    else
        baseDirectory = '';
    end
    if length(varargin) >= 2
        saveFilepath = varargin{2};
    else
        saveFilepath = '';
    end
    if length(varargin) >= 3
        prerandomizedAnnotationFilepath = varargin{3};
    else
        prerandomizedAnnotationFilepath = '';
    end
    % Choose default command line output for assembleRandomManualTrackingAnnotationsGUI
    handles.output.prerandomizedAnnotationFilepath = prerandomizedAnnotationFilepath;
    handles.output.baseDirectory = baseDirectory;
    handles.output.saveFilepath = saveFilepath;

    % Set up default field values
    set(handles.baseDirectory, 'String', baseDirectory);
    set(handles.saveFilepath, 'String', saveFilepath);
end

handles.output.complete = false;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes assembleRandomManualTrackingAnnotationsGUI wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = assembleRandomManualTrackingAnnotationsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(handles.figure1);

% --- Executes on button press in videoRootDirectoryBrowseButton.
function videoRootDirectoryBrowseButton_Callback(hObject, eventdata, handles)
% hObject    handle to videoRootDirectoryBrowseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
newDir = uigetdir('.', 'Choose directory in which to search for videos to select frames from.');
if newDir == 0
    return
end
currentDirs = get(handles.videoRootDirectories, 'String');
if isempty(currentDirs)
    currentDirs = {};
end
if ischar(currentDirs)
    currentDirs = {currentDirs};
end
if ~any(strcmp(currentDirs, newDir))
    currentDirs = [currentDirs; newDir];
    set(handles.videoRootDirectories, 'String', currentDirs);
    guidata(hObject, handles);
end


function videoRootDirectories_Callback(hObject, eventdata, handles)
% hObject    handle to videoRootDirectories (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of videoRootDirectories as text
%        str2double(get(hObject,'String')) returns contents of videoRootDirectories as a double


% --- Executes during object creation, after setting all properties.
function videoRootDirectories_CreateFcn(hObject, eventdata, handles)
% hObject    handle to videoRootDirectories (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function videoRegex_Callback(hObject, eventdata, handles)
% hObject    handle to videoRegex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of videoRegex as text
%        str2double(get(hObject,'String')) returns contents of videoRegex as a double


% --- Executes during object creation, after setting all properties.
function videoRegex_CreateFcn(hObject, eventdata, handles)
% hObject    handle to videoRegex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function videoExtensions_Callback(hObject, eventdata, handles)
% hObject    handle to videoExtensions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of videoExtensions as text
%        str2double(get(hObject,'String')) returns contents of videoExtensions as a double


% --- Executes during object creation, after setting all properties.
function videoExtensions_CreateFcn(hObject, eventdata, handles)
% hObject    handle to videoExtensions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function numAnnotations_Callback(hObject, eventdata, handles)
% hObject    handle to numAnnotations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numAnnotations as text
%        str2double(get(hObject,'String')) returns contents of numAnnotations as a double


% --- Executes during object creation, after setting all properties.
function numAnnotations_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numAnnotations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function baseDirectory_Callback(hObject, eventdata, handles)
% hObject    handle to baseDirectory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of baseDirectory as text
%        str2double(get(hObject,'String')) returns contents of baseDirectory as a double


% --- Executes during object creation, after setting all properties.
function baseDirectory_CreateFcn(hObject, eventdata, handles)
% hObject    handle to baseDirectory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in baseDirectoryBrowseButton.
function baseDirectoryBrowseButton_Callback(hObject, eventdata, handles)
% hObject    handle to baseDirectoryBrowseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

newDir = uigetdir('.', 'Choose directory in which to save clip videos.');
if newDir == 0
    return
end
handles.baseDirectory.String = newDir;
guidata(hObject, handles);

function clipRadius_Callback(hObject, eventdata, handles)
% hObject    handle to clipRadius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of clipRadius as text
%        str2double(get(hObject,'String')) returns contents of clipRadius as a double

% --- Executes during object creation, after setting all properties.
function clipRadius_CreateFcn(hObject, eventdata, handles)
% hObject    handle to clipRadius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in runButton.
function runButton_Callback(hObject, eventdata, handles)
% hObject    handle to runButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output.baseDirectory = get(handles.baseDirectory, 'String');
handles.output.saveFilepath = get(handles.saveFilepath, 'String');
if isempty(handles.output.prerandomizedAnnotationFilepath)
    % Use default filepath for prerandomized annotation list
    defaultPrerandomizedAnnotationFilename = 'randomizedAnnotationList.mat';
    handles.output.prerandomizedAnnotationFilepath = fullfile(handles.output.baseDirectory, defaultPrerandomizedAnnotationFilename);
end
assembleRandomManualTrackingAnnotations( ...
    handles.output.prerandomizedAnnotationFilepath, ...
    handles.output.baseDirectory, ...
    handles.output.saveFilepath);
handles.output.complete = true;
guidata(hObject, handles);
figure1_CloseRequestFcn(handles.figure1, eventdata, handles)

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
if isequal(get(hObject, 'waitstatus'), 'waiting')
    uiresume(hObject);
else
    delete(hObject);
end



function saveFilepath_Callback(hObject, eventdata, handles)
% hObject    handle to saveFilepath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of saveFilepath as text
%        str2double(get(hObject,'String')) returns contents of saveFilepath as a double


% --- Executes during object creation, after setting all properties.
function saveFilepath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to saveFilepath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in saveFilepathBrowseButton.
function saveFilepathBrowseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveFilepathBrowseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[file, path] = uiputfile('*.mat', 'Choose a filename to save ROI annotation file');
if all(file == 0) || all(path == 0)
    return;
end
filepath = fullfile(path, file);
handles.saveFilename.String = filepath;
guidata(hObject, handles);
