function varargout = itemSelectorDialog(varargin)
% ITEMSELECTORDIALOG MATLAB code for itemSelectorDialog.fig
%      ITEMSELECTORDIALOG, by itself, creates a new ITEMSELECTORDIALOG or raises the existing
%      singleton*.
%
%      H = ITEMSELECTORDIALOG returns the handle to a new ITEMSELECTORDIALOG or the handle to
%      the existing singleton*.
%
%      ITEMSELECTORDIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ITEMSELECTORDIALOG.M with the given input arguments.
%
%      ITEMSELECTORDIALOG('Property','Value',...) creates a new ITEMSELECTORDIALOG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before itemSelectorDialog_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to itemSelectorDialog_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help itemSelectorDialog

% Last Modified by GUIDE v2.5 10-Jun-2020 16:45:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @itemSelectorDialog_OpeningFcn, ...
                   'gui_OutputFcn',  @itemSelectorDialog_OutputFcn, ...
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


% --- Executes just before itemSelectorDialog is made visible.
function itemSelectorDialog_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to itemSelectorDialog (see VARARGIN)

% Choose default command line output for itemSelectorDialog
handles.output = {};

if ~isempty(varargin) && iscell(varargin{1})
    varargin = varargin{1};
    if length(varargin) >= 1
        title = varargin{1};
    else
        title = 'Select one of these options';
    end
    if length(varargin) >= 2
        items = varargin{2};
        if ischar(items)
            items = {items};
        end
    else
        items = {};
    end
    if length(varargin) >= 3
        multiselect = varargin{3};
    else
        multiselect = false;
    end
    set(handles.figure1, 'Name', title);
    set(handles.items, 'String', items);
    if multiselect
        set(handles.items, 'Max', 1000);
    else
        set(handles.items, 'Max', 1);
    end
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes itemSelectorDialog wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = itemSelectorDialog_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(handles.figure1);

% --- Executes on selection change in items.
function items_Callback(hObject, eventdata, handles)
% hObject    handle to items (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns items contents as cell array
%        contents{get(hObject,'Value')} returns selected item from items


% --- Executes during object creation, after setting all properties.
function items_CreateFcn(hObject, eventdata, handles)
% hObject    handle to items (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in selectButton.
function selectButton_Callback(hObject, eventdata, handles)
% hObject    handle to selectButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
items = get(handles.items, 'String');
value = get(handles.items, 'Value');
items = items(value);
handles.output = items;
guidata(hObject, handles);
figure1_CloseRequestFcn(handles.figure1, eventdata, handles)


% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = 'Cancel';
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
