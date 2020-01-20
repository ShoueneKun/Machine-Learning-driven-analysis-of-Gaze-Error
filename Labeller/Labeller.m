function varargout = Labeller(varargin)
% LABELLER MATLAB code for Labeller.fig
%      LABELLER, by itself, creates a new LABELLER or raises the existing
%      singleton*.
%
%      H = LABELLER returns the handle to a new LABELLER or the handle to
%      the existing singleton*.
%
%      LABELLER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LABELLER.M with the given input arguments.
%
%      LABELLER('Property','Value',...) creates a new LABELLER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Labeller_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Labeller_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".

% The State variable attached to handles keeps track of how to end the
% labelling procedure. Values:
% 0: Labelling done. Exit the code.
% 1: Labelling done. Next Trial.
% 2: Labelling unfinished. Repeat trial and DONOT store labelled info.

% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Labeller

% Last Modified by GUIDE v2.5 09-Jan-2019 00:50:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Labeller_OpeningFcn, ...
                   'gui_OutputFcn',  @Labeller_OutputFcn, ...
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


% --- Executes just before Labeller is made visible.
function Labeller_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Labeller (see VARARGIN)

global LabelData HeadRotFix
ProcessData = varargin{1};
LabelData = varargin{2};

handles.PrIdx = ProcessData.PrIdx;

handles.T = ProcessData.T(:);
handles.EIH_vel = ProcessData.ETG.EIH_vel(:);
handles.EIHvector = ProcessData.ETG.EIHvector;
handles.GIWvector = ProcessData.GIW.GIWvector;
handles.Headvector = ProcessData.IMU.HeadVector;

if isempty(LabelData.Labels)
    handles.Labels = zeros(length(handles.T), 1);
else
    handles.Labels = LabelData.Labels;
end

handles.GIW_vel = findGazeVelocity(handles.T(:), handles.GIWvector, 0, 0);
handles.Head_vel = ProcessData.IMU.Head_Vel(:);
handles.POR = ProcessData.ETG.POR.*repmat([1920, 1080], [numel(handles.T), 1]);

[handles.EIH_Az, handles.EIH_El, ~] = cart2sph(-ProcessData.ETG.EIHvector(:, 1),...
    ProcessData.ETG.EIHvector(:, 3), ProcessData.ETG.EIHvector(:, 2)); 
[handles.Head_Az, handles.Head_El, ~] = cart2sph(-ProcessData.IMU.HeadVector(:, 1),...
    ProcessData.IMU.HeadVector(:, 3), ProcessData.IMU.HeadVector(:, 2));
handles.EIH_El_vel = ProcessData.ETG.El_Vel;
handles.EIH_Az_vel = ProcessData.ETG.Az_Vel;

handles.OrigHeadPose = ProcessData.IMU.HeadVector;
HeadRotFix = [0, 0, 0, 0];

handles.Head_El_vel = ProcessData.IMU.El_Vel;
handles.Head_Az_vel = ProcessData.IMU.Az_Vel;

handles.SceneFrameNo = ProcessData.ETG.SceneFrameNo;
handles.EyeFrameNo = ProcessData.ETG.LeftEyeFrameNo;
handles.DepthFrameNo = ProcessData.ZED.FrameNo;

handles.SceneFrameList = unique(handles.SceneFrameNo);
handles.EyeFrameList = unique(handles.EyeFrameNo);

handles.DepthPresent = ProcessData.DepthPresent;
handles.Confidence = ProcessData.ETG.Confidence;
% Using the thresholded mean of the difference images as an indicator to
% look down on the user's eye images. 

set(handles.RadioButtonGroup, 'SelectedObject', handles.GazeFollowing);

global I_scene
global I_eye
global L1
global L2
global HeadVec_obj Head_Az_obj Head_El_obj Head_vel_obj
global G_Pt
global Path2Data
global DepthMode
DepthMode = 0;

% yyaxis(handles.EyeInHead, 'right'); hold(handles.EyeInHead, 'on');
% % plot(handles.EyeInHead, handles.T, handles.EIHvector, 'LineWidth', 1.0)
% plot(handles.EyeInHead, handles.T, rad2deg(handles.EIH_Az), 'LineWidth', 1.5, 'LineStyle', '--', 'Color', [1 0 0])
% plot(handles.EyeInHead, handles.T, rad2deg(handles.EIH_El), 'LineWidth', 1.5, 'LineStyle', '--', 'Color', [0 1 0])
yyaxis(handles.EyeInHead, 'left')
plot(handles.EyeInHead, handles.T, handles.EIH_vel, 'LineWidth', 2.5); hold(handles.EyeInHead, 'on');
L1 = plot(handles.EyeInHead, [0 0], [0 max(handles.EIH_vel)], 'Color', [0 0 0], 'LineWidth', 3);
plot(handles.EyeInHead, handles.T, handles.EIH_Az_vel, 'LineWidth', 1.5, 'LineStyle', '--', 'Color', [1 0 0])
plot(handles.EyeInHead, handles.T, handles.EIH_El_vel, 'LineWidth', 1.5, 'LineStyle', '--', 'Color', [0 1 0])
plot(handles.EyeInHead, handles.T, handles.GIW_vel, 'LineWidth', 1.5, 'LineStyle', '-', 'Color', [1 0 1], 'Marker', 'none')
xlim(handles.EyeInHead, [-0.25 +0.25])
title(handles.EyeInHead, 'Eye In Head Velocity'); hold(handles.EyeInHead, 'off');
legend(handles.EyeInHead, '|EIH| Vel', 'Timeline', 'Az Vel',...
    'El Vel', 'Location','northeast','AutoUpdate','off')

% yyaxis(handles.HeadVelocity, 'right'); hold(handles.HeadVelocity, 'on');
% HeadVec_obj = plot(handles.HeadVelocity, handles.T, handles.Headvector, 'LineWidth', 1.0);
% Head_Az_obj = plot(handles.HeadVelocity, handles.T, rad2deg(handles.Head_Az), 'LineWidth', 1.5, 'LineStyle', '--', 'Color', [1 0 0]);
% Head_El_obj = plot(handles.HeadVelocity, handles.T, rad2deg(handles.Head_El), 'LineWidth', 1.5, 'LineStyle', '--', 'Color', [0 1 0]);
yyaxis(handles.HeadVelocity, 'left')
Head_vel_obj = plot(handles.HeadVelocity, handles.T, handles.Head_vel, 'LineWidth', 2.5); hold(handles.HeadVelocity, 'on');
L2 = plot(handles.HeadVelocity, [0 0], [0 max(handles.Head_vel)], 'Color', [0 0 0], 'LineWidth', 3);
Head_Az_obj = plot(handles.HeadVelocity, handles.T, handles.Head_Az_vel, 'LineWidth', 1.5, 'LineStyle', '--', 'Color', [1 0 0]);
Head_El_obj = plot(handles.HeadVelocity, handles.T, handles.Head_El_vel, 'LineWidth', 1.5, 'LineStyle', '--', 'Color', [0 1 0]);
plot(handles.HeadVelocity, handles.T, handles.GIW_vel, 'LineWidth', 1.5, 'LineStyle', '-', 'Color', [1 0 1], 'Marker', 'none')
xlim(handles.HeadVelocity, [-0.25 +0.25])
title(handles.HeadVelocity, 'Head Velocity'); hold(handles.HeadVelocity, 'off');
legend(handles.HeadVelocity, '|Head| Vel', 'Timeline', 'Az Vel',...
    'El Vel', 'Location','northeast','AutoUpdate','off')

grid(handles.EyeInHead, 'on'); grid(handles.HeadVelocity, 'on');

str = fullfile(Path2Data, 'Gaze', 'Scene', [num2str(handles.SceneFrameNo(1)), '.jpg']);
I_scene = imshow(imread(str), 'parent', handles.SceneVideo); hold(handles.SceneVideo, 'on');

G_Pt = plot(0, 0, 'Color', [1 0 0], 'MarkerSize', 20, 'Marker', '+', 'LineWidth', 2.5, 'parent', handles.SceneVideo);
title(handles.SceneVideo, 'Scene Video'); hold(handles.SceneVideo, 'off');

str = fullfile(Path2Data, 'Gaze', 'Eye0', [num2str(handles.EyeFrameNo(1)), '.jpg']);
I_eye = imshow(imread(str), 'parent', handles.EyeVideo);
title(handles.EyeVideo, 'Eye Video')

SR = ProcessData.SR;

% Set scaling slider values
handles.ScaleSlider.Min = 1;
handles.ScaleSlider.Max = 8;
handles.ScaleSlider.SliderStep = [0.01*3 0.1*3];
handles.ScaleSlider.Value = 1;
handles.CurrentScale.String = num2str(handles.ScaleSlider.Min);

% Set Yaxis scaling slider values
handles.YSlider.Min = 1;
handles.YSlider.Max = 4;

% Set temporal slider values
handles.TemporalSlider.Min = handles.T(1);
handles.TemporalSlider.Max = handles.T(end);
handles.TemporalSlider.SliderStep = [200/(SR*numel(handles.T)), 5000/(SR*numel(handles.T))];

% Set label shifting slider
handles.ShiftLabels.Min = -100;
handles.ShiftLabels.Max = 100;
handles.ShiftLabels.SliderStep = [0.01, 0.05];

handles.LabeledSections.String = getHistoryStr(LabelData.LabelStruct);
DrawPatches(handles.EyeInHead, LabelData.LabelStruct, max(handles.EIH_vel))
DrawPatches(handles.HeadVelocity, LabelData.LabelStruct, max(handles.Head_vel))

% Timing and Label information
if ~isempty(LabelData.LabelStruct)
    handles.TimeVals = cell2mat({LabelData.LabelStruct.LabelTime}');
    handles.LabelSequence = [LabelData.LabelStruct.Label].';
else
    handles.TimeVals = NaN;
    handles.LabelSequence = NaN;
end

% Choose default command line output for Labeller
handles.output = LabelData.Labels;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Labeller wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Labeller_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure

% Pre-process LabelData.LabelStruct to get handles.output
global LabelData HeadRotFix
handles.Labels = zeros(length(handles.T), 1);
LabelStruct = LabelData.LabelStruct;

for i = 1:length(LabelStruct)
    handles.Labels(LabelStruct(i).LabelLoc(1):LabelStruct(i).LabelLoc(2), 1) = LabelStruct(i).Label; 
end
varargout{1} = handles.Labels;
varargout{2} = LabelStruct;
varargout{3} = {handles.Headvector, handles.Head_vel, handles.Head_Az_vel, handles.Head_El_vel};
varargout{4} = HeadRotFix;

% --- Executes on slider movement.
function ScaleSlider_Callback(hObject, eventdata, handles)
% hObject    handle to ScaleSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

t = handles.TemporalSlider.Value;
handles.CurrentScale.String = num2str(handles.ScaleSlider.Value);

% Find closest sample equal to t
[~, n] = min(abs(t - handles.T));

xlim(handles.EyeInHead, [handles.T(n) - 0.25*handles.ScaleSlider.Value, handles.T(n) + 0.25*handles.ScaleSlider.Value])
xlim(handles.HeadVelocity, [handles.T(n) - 0.25*handles.ScaleSlider.Value, handles.T(n) + 0.25*handles.ScaleSlider.Value])


% --- Executes on slider movement.
function TemporalSlider_Callback(hObject, eventdata, handles)
% hObject    handle to TemporalSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

t = get(hObject, 'Value');
UpdateTime(handles,t);


% --- Executes during object creation, after setting all properties.
function ScaleSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ScaleSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes during object creation, after setting all properties.
function TemporalSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TemporalSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

disp('Slider generated.')

% --- Executes on button press in NextTrialButton.
function NextTrialButton_Callback(hObject, eventdata, handles)
% hObject    handle to NextTrialButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
button = questdlg('Submit current trial and start labelling the next trial?');
if strcmp(button,'Yes')
    handles.State = 1;
    %uiresume(handles.figure1)
    set(handles.figure1, 'waitstatus', 'inactive');
    guidata(hObject, handles);
end

% --- Executes on button press in ExitButton.
function ExitButton_Callback(hObject, eventdata, handles)
% hObject    handle to ExitButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
button = questdlg('Stop labelling and submit current trial?');
if strcmp(button,'Yes')
    handles.State = 3;
    %uiresume(handles.figure1)
    set(handles.figure1, 'waitstatus', 'inactive');
    guidata(hObject, handles);
end

% --- Executes on button press in FixationButton.
function FixationButton_Callback(hObject, eventdata, handles)
% hObject    handle to FixationButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global LabelData
L = length(LabelData.LabelStruct);
% buttons off
handles.FixationButton.Enable = 'off';
handles.GazePursuitButton.Enable = 'off';
handles.SaccadeButton.Enable = 'off';
handles.GazeFollowing.Enable = 'off';
handles.BlinkButton.Enable = 'off';

h = imrect(handles.EyeInHead);
setColor(h, [0 1 0])
RectPos = wait(h); delete(h);
set(handles.figure1, 'waitstatus', 'waiting');

t1 = RectPos(1); t2 = RectPos(1) + RectPos(3);
n1 = findClosest(handles.T, t1); n2 = findClosest(handles.T, t2);

LabelData.LabelStruct(L+1).LabelTime = [t1, t2];
LabelData.LabelStruct(L+1).LabelLoc = [n1, n2];
LabelData.LabelStruct(L+1).Label = 1;
LabelData.Labels = GenerateLabelsfromStruct(LabelData);

DrawPatch(handles.HeadVelocity, [t1, t2, 0, max(handles.Head_vel)], [0 1 0]);
DrawPatch(handles.EyeInHead, [t1, t2, 0, max(handles.EIH_vel)], [0 1 0]);

handles.LabeledSections.String = getHistoryStr(LabelData.LabelStruct);
% buttons on
handles.FixationButton.Enable = 'on';
handles.GazePursuitButton.Enable = 'on';
handles.SaccadeButton.Enable = 'on';
handles.GazeFollowing.Enable = 'on';
handles.BlinkButton.Enable = 'on';

% --- Executes on button press in GazePursuitButton.
function GazePursuitButton_Callback(hObject, eventdata, handles)
% hObject    handle to GazePursuitButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global LabelData
L = length(LabelData.LabelStruct);
% buttons off
handles.FixationButton.Enable = 'off';
handles.GazePursuitButton.Enable = 'off';
handles.SaccadeButton.Enable = 'off';
handles.GazeFollowing.Enable = 'off';
handles.BlinkButton.Enable = 'off';

h = imrect(handles.EyeInHead);
setColor(h, [0 0 1])
RectPos = wait(h); delete(h);
set(handles.figure1, 'waitstatus', 'waiting');

t1 = RectPos(1); t2 = RectPos(1) + RectPos(3);
n1 = findClosest(handles.T, t1); n2 = findClosest(handles.T, t2);

LabelData.LabelStruct(L+1).LabelTime = [t1 t2];
LabelData.LabelStruct(L+1).LabelLoc = [n1 n2];
LabelData.LabelStruct(L+1).Label = 2;
LabelData.Labels = GenerateLabelsfromStruct(LabelData);

DrawPatch(handles.HeadVelocity, [t1 t2 0 max(handles.Head_vel)], [0 0 1]);
DrawPatch(handles.EyeInHead, [t1 t2 0 max(handles.EIH_vel)], [0 0 1]);

handles.LabeledSections.String = getHistoryStr(LabelData.LabelStruct);
% buttons on
handles.FixationButton.Enable = 'on';
handles.GazePursuitButton.Enable = 'on';
handles.SaccadeButton.Enable = 'on';
handles.GazeFollowing.Enable = 'on';
handles.BlinkButton.Enable = 'on';


% --- Executes on button press in SaccadeButton.
function SaccadeButton_Callback(hObject, eventdata, handles)
% hObject    handle to SaccadeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global LabelData
L = length(LabelData.LabelStruct);
% buttons off
handles.FixationButton.Enable = 'off';
handles.GazePursuitButton.Enable = 'off';
handles.SaccadeButton.Enable = 'off';
handles.GazeFollowing.Enable = 'off';
handles.BlinkButton.Enable = 'off';

h = imrect(handles.EyeInHead);
setColor(h, [1 0 0])
RectPos = wait(h); delete(h);
set(handles.figure1, 'waitstatus', 'waiting');

t1 = RectPos(1); t2 = RectPos(1) + RectPos(3);
n1 = findClosest(handles.T, t1); n2 = findClosest(handles.T, t2);

LabelData.LabelStruct(L+1).LabelTime = [t1 t2];
LabelData.LabelStruct(L+1).LabelLoc = [n1 n2];
LabelData.LabelStruct(L+1).Label = 3;
LabelData.Labels = GenerateLabelsfromStruct(LabelData);

DrawPatch(handles.HeadVelocity, [t1 t2 0 max(handles.Head_vel)], [1 0 0]);
DrawPatch(handles.EyeInHead, [t1 t2 0 max(handles.EIH_vel)], [1 0 0]);

handles.LabeledSections.String = getHistoryStr(LabelData.LabelStruct);
% buttons on
handles.FixationButton.Enable = 'on';
handles.GazePursuitButton.Enable = 'on';
handles.SaccadeButton.Enable = 'on';
handles.GazeFollowing.Enable = 'on';
handles.BlinkButton.Enable = 'on';


% --- Executes on button press in GazeFollowing.
function GazeFollowing_Callback(hObject, eventdata, handles)
% hObject    handle to GazeFollowing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global LabelData
L = length(LabelData.LabelStruct);

% buttons off
handles.FixationButton.Enable = 'off';
handles.GazePursuitButton.Enable = 'off';
handles.SaccadeButton.Enable = 'off';
handles.GazeFollowing.Enable = 'off';
handles.BlinkButton.Enable = 'off';

h = imrect(handles.EyeInHead);
setColor(h, [0 1 1])
RectPos = wait(h); delete(h);
set(handles.figure1, 'waitstatus', 'waiting');

t1 = RectPos(1); t2 = RectPos(1) + RectPos(3);
n1 = findClosest(handles.T, t1); n2 = findClosest(handles.T, t2);

LabelData.LabelStruct(L+1).LabelTime = [t1 t2];
LabelData.LabelStruct(L+1).LabelLoc = [n1 n2];
LabelData.LabelStruct(L+1).Label = 5;
LabelData.Labels = GenerateLabelsfromStruct(LabelData);

DrawPatch(handles.HeadVelocity, [t1 t2 0 max(handles.Head_vel)], [0 1 1]);
DrawPatch(handles.EyeInHead, [t1 t2 0 max(handles.EIH_vel)], [0 1 1]);

handles.LabeledSections.String = getHistoryStr(LabelData.LabelStruct);
% buttons on
handles.FixationButton.Enable = 'on';
handles.GazePursuitButton.Enable = 'on';
handles.SaccadeButton.Enable = 'on';
handles.GazeFollowing.Enable = 'on';
handles.BlinkButton.Enable = 'on';


% --- Executes on button press in BlinkButton.
function BlinkButton_Callback(hObject, eventdata, handles)
% hObject    handle to BlinkButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global LabelData
L = length(LabelData.LabelStruct);
% buttons off
handles.FixationButton.Enable = 'off';
handles.GazePursuitButton.Enable = 'off';
handles.SaccadeButton.Enable = 'off';
handles.GazeFollowing.Enable = 'off';
handles.BlinkButton.Enable = 'off';

h = imrect(handles.EyeInHead);
setColor(h, [1 1 0])
RectPos = wait(h); delete(h);
set(handles.figure1, 'waitstatus', 'waiting');

t1 = RectPos(1); t2 = RectPos(1) + RectPos(3);
n1 = findClosest(handles.T, t1); n2 = findClosest(handles.T, t2);

LabelData.LabelStruct(L+1).LabelTime = [t1 t2];
LabelData.LabelStruct(L+1).LabelLoc = [n1 n2];
LabelData.LabelStruct(L+1).Label = 4;
LabelData.Labels = GenerateLabelsfromStruct(LabelData);

DrawPatch(handles.HeadVelocity, [t1 t2 0 max(handles.Head_vel)], [1 1 0]);
DrawPatch(handles.EyeInHead, [t1 t2 0 max(handles.EIH_vel)], [1 1 0]);

handles.LabeledSections.String = getHistoryStr(LabelData.LabelStruct);

% buttons on
handles.FixationButton.Enable = 'on';
handles.GazePursuitButton.Enable = 'on';
handles.SaccadeButton.Enable = 'on';
handles.GazeFollowing.Enable = 'on';
handles.BlinkButton.Enable = 'on';
% Hint: get(hObject,'Value') returns toggle state of BlinkButton



function EyeInHead_CreateFcn(hObject, eventdata, handles)
fprintf('Eye In Head axis created\n')


% --- Executes on button press in BoredButton.
function BoredButton_Callback(hObject, eventdata, handles)
% hObject    handle to BoredButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
button = questdlg('Stop labelling and save current progress?');
if strcmp(button,'Yes')
    handles.State = 2;
    %uiresume(handles.figure1);
    set(handles.figure1, 'waitstatus', 'inactive');
    guidata(hObject, handles);
end


% --- Executes on selection change in LabeledSections.
function LabeledSections_Callback(hObject, eventdata, handles)
% hObject    handle to LabeledSections (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function LabeledSections_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LabeledSections (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in RemoveButton.
function RemoveButton_Callback(hObject, eventdata, handles)
% hObject    handle to RemoveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global LabelData
DelIdx = handles.LabeledSections.Value;

LabelData.LabelStruct(DelIdx) = [];
handles.LabeledSections.String = getHistoryStr(LabelData.LabelStruct);

UpdateView(handles, LabelData)
LabelData.Labels = GenerateLabelsfromStruct(LabelData);

if (DelIdx > length(handles.LabeledSections.String))
   set(handles.LabeledSections, 'Value', max([1,length(handles.LabeledSections.String)])); 
end


% --- Executes on button press in GotoButton.
function GotoButton_Callback(hObject, eventdata, handles)
% hObject    handle to GotoButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global LabelData
DelIdx = handles.LabeledSections.Value;
if (length(LabelData.LabelStruct) <  1)
    return;
end
val = LabelData.LabelStruct(DelIdx).LabelTime(1) + (LabelData.LabelStruct(DelIdx).LabelTime(2) - LabelData.LabelStruct(DelIdx).LabelTime(1))/2;
handles.TemporalSlider.Value = val;
UpdateTime(handles, val);


% --- Executes on button press in Record.
function Record_Callback(hObject, eventdata, handles)
% hObject    handle to Record (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
vidDur = 7;
frRate = 30;

% Save current operation time
tempTime = handles.TemporalSlider.Value;

% Estimate time jumps for frRate FPS
T_Steps = linspace(tempTime, tempTime + vidDur, 4*frRate*vidDur);

v = VideoWriter('Trial.avi');
v.FrameRate = frRate;
v.Quality = 97;

% Record movie
Tr_Mov(length(T_Steps)) = struct('cdata', [], 'colormap', []);
set(handles.CurrentTime, 'String', 'Recording ..');
for i = 1:length(T_Steps)
    UpdateTime(handles, T_Steps(i))
    Tr_Mov(i) = getframe(handles.figure1);
    im{i} = imresize(frame2im(Tr_Mov(i)), 0.5);
    disp(i/length(T_Steps))
end
disp('Done!')
set(handles.CurrentTime, 'String', num2str(tempTime));
UpdateTime(handles, tempTime);

% Save the movie
open(v);
writeVideo(v, Tr_Mov);
close(v);
clear Tr_Mov

% Save the GIF
fName = 'TrialGIF.gif';
for idx = 1:length(T_Steps)
    [A, map] = rgb2ind(im{idx}, 256);
    if idx == 1
        imwrite(A, map, fName, 'gif', 'LoopCount', inf, 'DelayTime', 1/frRate);
    else
        imwrite(A, map, fName, 'gif', 'WriteMode', 'append', 'DelayTime', 1/frRate);
    end
end


% --- Executes on button press in DepthBox.
function DepthBox_Callback(hObject, eventdata, handles)
% hObject    handle to DepthBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global DepthMode

% Hint: get(hObject,'Value') returns toggle state of DepthBox
if get(hObject, 'Value') == 0
   % Depth is OFF
   DepthMode = 0;
else 
   % Depth is ON 
   DepthMode = 1;
end


% --- Executes on slider movement.
function ShiftLabels_Callback(hObject, eventdata, handles)
% hObject    handle to ShiftLabels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global LabelData
N = length(LabelData.Labels);
ShiftLabels = zeros(N, 1);

x = 1:N; x = x - handles.ShiftLabels.Value;
loc = x > 0 & x <= N;
ShiftLabels(loc) = LabelData.Labels(x(loc));

LabelData.Labels = ShiftLabels;
LabelData.LabelStruct = GenerateLabelStruct(LabelData.Labels, handles.T);

% Update current view
UpdateView(handles, LabelData)
disp(['Shifted by: ', num2str(handles.ShiftLabels.Value)])
handles.ShiftLabels.Value = 0.0;


% --- Executes during object creation, after setting all properties.
function ShiftLabels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ShiftLabels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function YSlider_Callback(hObject, eventdata, handles)
% hObject    handle to YSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function YSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to YSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in Go_Fix.
function Go_Fix_Callback(hObject, eventdata, handles)
% hObject    handle to Go_Fix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global LabelData
handles.TimeVals = cell2mat({LabelData.LabelStruct.LabelTime}');
handles.LabelSequence = [LabelData.LabelStruct.Label].';

currentPos = handles.TemporalSlider.Value;
loc = find(handles.TimeVals(:, 1) > currentPos...
    & handles.LabelSequence == 1, 1);

val = handles.TimeVals(loc, 1) + diff(handles.TimeVals(loc, :))/2;

if ~isempty(val) && ~isnan(val) && val >=0 
    handles.TemporalSlider.Value = val;
else
    disp('Event does not exist')
end
UpdateTime(handles, val);


% --- Executes on button press in Go_Pur.
function Go_Pur_Callback(hObject, eventdata, handles)
% hObject    handle to Go_Pur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global LabelData
handles.TimeVals = cell2mat({LabelData.LabelStruct.LabelTime}');
handles.LabelSequence = [LabelData.LabelStruct.Label].';
currentPos = handles.TemporalSlider.Value;

cond = 1;
m = 1;

while cond 
    loc = find(handles.TimeVals(:, 1) > currentPos...
        & handles.LabelSequence == 2, m);
    val = handles.TimeVals(loc, 1) + diff(handles.TimeVals(loc, :))/2;
    
    % Check if gain in near 1
    n1 = findClosest(handles.T, handles.TimeVals(loc, 1));
    n2 = findClosest(handles.T, handles.TimeVals(loc, 2));
    s1 = handles.EIH_El_vel(n1:n2)./handles.Head_El_vel(n1:n2);
    s2 = handles.EIH_Az_vel(n1:n2)./handles.Head_Az_vel(n1:n2);
    
    loc = (abs(s1) > 0.85 | abs(s1) < 1.15) | (abs(s2) > 0.85 | abs(s2) < 1.15);
    if sum(loc)/length(loc) > 0.85
        % 85% or greater is gaze fix behavior
        cond = 0;
    else
        m = m + 1;
        cond = 1;
    end
end

% handles.TimeVals = cell2mat({LabelData.LabelStruct.LabelTime}');
% handles.LabelSequence = [LabelData.LabelStruct.Label].';

% currentPos = handles.TemporalSlider.Value;
% loc = find(handles.TimeVals(:, 1) > currentPos...
%     & handles.LabelSequence == 2, 1);
% 
% val = handles.TimeVals(loc, 1) + diff(handles.TimeVals(loc, :))/2;

if ~isempty(val) && ~isnan(val) && val >=0 
    handles.TemporalSlider.Value = val;
else
    disp('Event does not exist')
end
UpdateTime(handles, val);


% --- Executes on button press in Go_Sac.
function Go_Sac_Callback(hObject, eventdata, handles)
% hObject    handle to Go_Sac (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global LabelData
handles.TimeVals = cell2mat({LabelData.LabelStruct.LabelTime}');
handles.LabelSequence = [LabelData.LabelStruct.Label].';

currentPos = handles.TemporalSlider.Value;
loc = find(handles.TimeVals(:, 1) > currentPos...
    & handles.LabelSequence == 3, 1);

val = handles.TimeVals(loc, 1) + diff(handles.TimeVals(loc, :))/2;

if ~isempty(val) && ~isnan(val) && val >=0 
    handles.TemporalSlider.Value = val;
else
    disp('Event does not exist')
end
UpdateTime(handles, val);


% --- Executes on button press in Go_Fol.
function Go_Fol_Callback(hObject, eventdata, handles)
% hObject    handle to Go_Fol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global LabelData
handles.TimeVals = cell2mat({LabelData.LabelStruct.LabelTime}');
handles.LabelSequence = [LabelData.LabelStruct.Label].';

currentPos = handles.TemporalSlider.Value;
loc = find(handles.TimeVals(:, 1) > currentPos...
    & handles.LabelSequence == 5, 1);

val = handles.TimeVals(loc, 1) + diff(handles.TimeVals(loc, :))/2;

if ~isempty(val) && ~isnan(val) && val >=0 
    handles.TemporalSlider.Value = val;
else
    disp('Event does not exist')
end
UpdateTime(handles, val);


% --- Executes on button press in FixHeadVector.
function FixHeadVector_Callback(hObject, eventdata, handles)
% hObject    handle to FixHeadVector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global HeadVec_obj HeadRotFix Head_Az_obj Head_El_obj Head_vel_obj
HeadPose = normr(str2double(handles.FixHeadPose.Data(1, :)));
n = findClosest(handles.T, handles.TemporalSlider.Value);
[~, r] = RotateVectors(handles.OrigHeadPose(n, :), HeadPose);
HeadRotFix = [HeadRotFix; [handles.TemporalSlider.Value, rotationMatrixToVector(r)]];
disp(HeadRotFix)
RotMats = interp1(HeadRotFix(:, 1), HeadRotFix(:, 2:4), (handles.T), 'linear', 'extrap');
for i = 1:length(handles.T)
    handles.Headvector(i, :) = handles.OrigHeadPose(i, :)*rotationVectorToMatrix(RotMats(i, :));
end
for i = 1:length(HeadVec_obj)
   HeadVec_obj(i).YData = handles.Headvector(:, i);
end
[az, el, ~] = cart2sph(-handles.Headvector(:, 1), handles.Headvector(:, 3), handles.Headvector(:, 2));

Head_vel_obj.YData = findHeadVelocity(handles.T(:), handles.Headvector);
Head_Az_obj.YData = findAngularVelocity(handles.T(:), az);
Head_El_obj.YData = findAngularVelocity(handles.T(:), el);
guidata(hObject, handles)


% --- Executes when entered data in editable cell(s) in FixHeadPose.
function FixHeadPose_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to FixHeadPose (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
