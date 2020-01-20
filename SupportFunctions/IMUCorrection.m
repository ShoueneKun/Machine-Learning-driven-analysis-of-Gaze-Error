function varargout = IMUCorrection(varargin)
% IMUCORRECTION MATLAB code for IMUCorrection.fig
%      IMUCORRECTION, by itself, creates a new IMUCORRECTION or raises the existing
%      singleton*.
%
%      H = IMUCORRECTION returns the handle to a new IMUCORRECTION or the handle to
%      the existing singleton*.
%
%      IMUCORRECTION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IMUCORRECTION.M with the given input arguments.
%
%      IMUCORRECTION('Property','Value',...) creates a new IMUCORRECTION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before IMUCorrection_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to IMUCorrection_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help IMUCorrection

% Last Modified by GUIDE v2.5 04-Apr-2019 14:42:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @IMUCorrection_OpeningFcn, ...
                   'gui_OutputFcn',  @IMUCorrection_OutputFcn, ...
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


% --- Executes just before IMUCorrection is made visible.
function IMUCorrection_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to IMUCorrection (see VARARGIN)


global rotm_h rotm_e flipX flipY flgs IMUScale

% Choose default command line output for IMUCorrection
handles.output = hObject;
handles.IMU_t = varargin{1};
handles.IMU_rMats = varargin{2};
handles.IMU_xyz = RapidRotate(handles.IMU_rMats, [0, 0, 1], 'mv');

ETG_t = varargin{3};
ETG_v = varargin{4}; ETG_v = cleanGazeData(ETG_t, ETG_v, 0);
IMUScale = varargin{7};
handles.ETG_v = interp1(ETG_t, ETG_v, handles.IMU_t, 'makima');

flipX = 1; flipY = 1;
rotm_h = eye(3); rotm_e = eye(3);

handles.T = handles.IMU_t(:);

hold(handles.QuatGraph, 'on')
handles.L1 = plot(handles.QuatGraph, handles.T - ETG_t(1), rotm2quat(handles.IMU_rMats), '-', 'LineWidth', 1);
plot(handles.QuatGraph, handles.T - ETG_t(1), zeros(length(handles.T), 1), '-', 'Color', [0,0,0], 'LineWidth', 2);
hold(handles.QuatGraph, 'off')
legend(handles.QuatGraph, 'Qw', 'Qx', 'Qy', 'Qz')
xlabel(handles.QuatGraph, 'Time')
ylabel(handles.QuatGraph, 'Quat value')
grid(handles.QuatGraph, 'on')
ylim(handles.QuatGraph, [-1 1])

hold(handles.VecGraph, 'on')
handles.L2 = plot(handles.VecGraph, handles.T - ETG_t(1), handles.IMU_xyz, '-', 'LineWidth', 1);
plot(handles.VecGraph, handles.T - ETG_t(1), handles.ETG_v, '-', 'LineWidth', 1);
plot(handles.VecGraph, handles.T - ETG_t(1), zeros(length(handles.T), 1), '-', 'Color', [0,0,0], 'LineWidth', 2);
legend(handles.VecGraph, 'X', 'Y', 'Z', 'eX', 'eY', 'eZ')
ylim(handles.VecGraph, [-1, 1])
hold(handles.VecGraph, 'off')
xlabel(handles.VecGraph, 'Time')
ylabel(handles.VecGraph, 'Vec')
grid(handles.VecGraph, 'on')

hold(handles.GIWGraph, 'on')
handles.L3 = plot(handles.GIWGraph, handles.T - ETG_t(1), handles.ETG_v, '-', 'LineWidth', 1);
ylim(handles.GIWGraph, [-1, 1])
hold(handles.GIWGraph, 'off')
grid(handles.GIWGraph, 'on')

imu_rotvec = rotationMatrixToVector(varargin{5});
etg_rotvec = rotationMatrixToVector(varargin{6});
flgs = varargin{8};

% Set the head sliders to 0
handles.h_slider_roll.Max = pi;
handles.h_slider_roll.Min = -pi;
handles.h_slider_roll.SliderStep = [0.10*pi/180, 1*pi/180];
handles.h_slider_roll.Value = imu_rotvec(1);
handles.h_slider_roll.String = num2str(handles.h_slider_roll.Value);

handles.h_slider_pitch.Max = pi;
handles.h_slider_pitch.Min = -pi;
handles.h_slider_pitch.SliderStep = [0.10*pi/180, 1*pi/180];
handles.h_slider_pitch.Value = imu_rotvec(2);
handles.h_slider_pitch.String = num2str(handles.h_slider_roll.Value);

handles.h_slider_yaw.Max = pi;
handles.h_slider_yaw.Min = -pi;
handles.h_slider_yaw.SliderStep = [0.10*pi/180, 1*pi/180];
handles.h_slider_yaw.Value = imu_rotvec(3);
handles.h_slider_yaw.String = num2str(handles.h_slider_roll.Value);

% Set the eye sliders to 0
handles.e_slider_roll.Max = pi;
handles.e_slider_roll.Min = -pi;
handles.e_slider_roll.SliderStep = [0.10*pi/180, 1*pi/180];
handles.e_slider_roll.Value = etg_rotvec(1);
handles.e_slider_roll.String = num2str(handles.e_slider_roll.Value);

handles.e_slider_pitch.Max = pi;
handles.e_slider_pitch.Min = -pi;
handles.e_slider_pitch.SliderStep = [0.10*pi/180, 1*pi/180];
handles.e_slider_pitch.Value = etg_rotvec(2);
handles.e_slider_pitch.String = num2str(handles.e_slider_roll.Value);

handles.e_slider_yaw.Max = pi;
handles.e_slider_yaw.Min = -pi;
handles.e_slider_yaw.SliderStep = [0.10*pi/180, 1*pi/180];
handles.e_slider_yaw.Value = etg_rotvec(3);
handles.e_slider_yaw.String = num2str(handles.e_slider_roll.Value);

handles.IMUScaleX.Max = 2.0;
handles.IMUScaleX.Min = 0.2;
handles.IMUScaleX.SliderStep = [0.005, 0.05];
handles.IMUScaleX.Value = IMUScale(1);

handles.IMUScaleY.Max = 2.0;
handles.IMUScaleY.Min = 0.2;
handles.IMUScaleY.SliderStep = [0.005, 0.05];
handles.IMUScaleY.Value = IMUScale(2);

handles.IMUScaleZ.Max = 2.0;
handles.IMUScaleZ.Min = 0.2;
handles.IMUScaleZ.SliderStep = [0.005, 0.05];
handles.IMUScaleZ.Value = IMUScale(3);

% Update initial values
UpdateSignals(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes IMUCorrection wait for user response (see UIRESUME)
uiwait(handles.figure1);

function [] = UpdateSignals(handles)
global rotm_h rotm_e flipX flipY flgs IMUScale
rotm_h = rotationVectorToMatrix([handles.h_slider_roll.Value, handles.h_slider_pitch.Value, handles.h_slider_yaw.Value]);
rotm_e = rotationVectorToMatrix([handles.e_slider_roll.Value, handles.e_slider_pitch.Value, handles.e_slider_yaw.Value]);
IMUScale = [handles.IMUScaleX.Value, handles.IMUScaleY.Value, handles.IMUScaleZ.Value];

n = find(flgs, 1, 'first');
% IMU Scaling
newR = handles.IMU_rMats;
newR = RapidRotate(newR, rotm_h, 'mm');
headCentered = RapidRotate(newR(:, :, n)', newR, 'mm');
headCentered(:, :, n:end) = smoothMove(headCentered(:, :, n:end), IMUScale);
temp1 = rotm2quat(headCentered);
temp2 = RapidRotate(RapidRotate(rotm_e, headCentered, 'mm'), [0, 0, 1], 'mv');
temp3 = RapidRotate(RapidRotate(rotm_e, headCentered, 'mm'), handles.ETG_v, 'mv');

handles.L1(1).YData = temp1(:, 1);
handles.L1(2).YData = temp1(:, 2);
handles.L1(3).YData = temp1(:, 3);
handles.L1(4).YData = temp1(:, 4);

handles.L2(1).YData = flipX*temp2(:, 1);
handles.L2(2).YData = flipY*temp2(:, 2);
handles.L2(3).YData = temp2(:, 3);

% handles.L3.YData = findGazeVelocity(handles.T, temp3, 0, 0);
handles.L3(1).YData = temp3(:, 1);
handles.L3(2).YData = temp3(:, 2);
handles.L3(3).YData = temp3(:, 3);

% --- Outputs from this function are returned to the command line.
function varargout = IMUCorrection_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
closereq

% Get default command line output from handles structure
global rotm_h rotm_e IMUScale
varargout{1} = rotm_h;
varargout{2} = rotm_e;
varargout{3} = IMUScale;

% --- Executes on slider movement.
function h_slider_roll_Callback(hObject, eventdata, handles)
% hObject    handle to h_slider_roll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
UpdateSignals(handles)


% --- Executes during object creation, after setting all properties.
function h_slider_roll_CreateFcn(hObject, eventdata, handles)
% hObject    handle to h_slider_roll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function h_slider_pitch_Callback(hObject, eventdata, handles)
% hObject    handle to h_slider_pitch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
UpdateSignals(handles)


% --- Executes during object creation, after setting all properties.
function h_slider_pitch_CreateFcn(hObject, eventdata, handles)
% hObject    handle to h_slider_pitch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function h_slider_yaw_Callback(hObject, eventdata, handles)
% hObject    handle to h_slider_yaw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
UpdateSignals(handles)


% --- Executes during object creation, after setting all properties.
function h_slider_yaw_CreateFcn(hObject, eventdata, handles)
% hObject    handle to h_slider_yaw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in Accept.
function Accept_Callback(hObject, eventdata, handles)
% hObject    handle to Accept (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.figure1, 'waitstatus', 'inactive')


% --- Executes on slider movement.
function e_slider_roll_Callback(hObject, eventdata, handles)
% hObject    handle to e_slider_roll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
UpdateSignals(handles)

% --- Executes during object creation, after setting all properties.
function e_slider_roll_CreateFcn(hObject, eventdata, handles)
% hObject    handle to e_slider_roll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function e_slider_pitch_Callback(hObject, eventdata, handles)
% hObject    handle to e_slider_pitch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
UpdateSignals(handles)


% --- Executes during object creation, after setting all properties.
function e_slider_pitch_CreateFcn(hObject, eventdata, handles)
% hObject    handle to e_slider_pitch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function e_slider_yaw_Callback(hObject, eventdata, handles)
% hObject    handle to e_slider_yaw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
UpdateSignals(handles)

% --- Executes during object creation, after setting all properties.
function e_slider_yaw_CreateFcn(hObject, eventdata, handles)
% hObject    handle to e_slider_yaw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in FlipX.
function FlipX_Callback(hObject, eventdata, handles)
% hObject    handle to FlipX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FlipX
global flipX
if hObject.Value
    flipX = -1;
else
    flipX = 1;
end
UpdateSignals(handles)
    


% --- Executes on button press in FlipY.
function FlipY_Callback(hObject, eventdata, handles)
% hObject    handle to FlipY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FlipY
global flipY
if hObject.Value
    flipY = -1;
else
    flipY = 1;
end
UpdateSignals(handles)


% --- Executes on slider movement.
function IMUScaleX_Callback(hObject, eventdata, handles)
% hObject    handle to IMUScaleX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
UpdateSignals(handles)

% --- Executes during object creation, after setting all properties.
function IMUScaleX_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IMUScaleX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function IMUScaleY_Callback(hObject, eventdata, handles)
% hObject    handle to IMUScaleY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
UpdateSignals(handles)

% --- Executes during object creation, after setting all properties.
function IMUScaleY_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IMUScaleY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function IMUScaleZ_Callback(hObject, eventdata, handles)
% hObject    handle to IMUScaleZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
UpdateSignals(handles)


% --- Executes during object creation, after setting all properties.
function IMUScaleZ_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IMUScaleZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
