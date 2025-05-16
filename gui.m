function varargout = gui(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gui_OpeningFcn, ...
                   'gui_OutputFcn',  @gui_OutputFcn, ...
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


% --- Executes just before gui is made visible.
function gui_OpeningFcn(hObject, ~, handles, varargin)
% Initialize filter options
set(handles.popupmenu1, 'String', {'Correlation', 'Weighted'});
set(handles.popupmenu1, 'Value', 1);
set(handles.edit1, 'String', '0');
set(handles.edit2, 'String', '255');

% Initialize default kernel
handles.filterKernel = ones(3,3)/9;
if isfield(handles, 'uitable3')
    set(handles.uitable3, 'Data', num2cell(handles.filterKernel));
end

% Initialize non-linear filter options
nonLinearFilters = {
    'Min Filter', 
    'Max Filter', 
    'Mean Filter', 
    'Midpoint Filter', 
    'Median Filter'
    };
set(handles.popupmenu3, 'String', nonLinearFilters);
set(handles.popupmenu3, 'Value', 1); % Default to first option

noiseFilters = {
    'Min Filter', 
    'Max Filter', 
    'Mean Filter', 
    'Median Filter', 
    'Midpoint Filter'
};

set(handles.popupmenu6, 'String', noiseFilters); % Assuming popupmenu3 is for noise filters
set(handles.popupmenu6, 'Value', 1); % Default to first option

set(handles.edit7, 'String', '0.05');  % Salt & Pepper PS
set(handles.edit8, 'String', '0.05');  % Salt & Pepper PP
set(handles.edit9, 'String', '10');    % Uniform a
set(handles.edit10, 'String', '200');  % Uniform b
set(handles.edit11, 'String', '10');   % Uniform P
set(handles.edit12, 'String', '10');   % Gaussian seg
set(handles.edit13, 'String', '10');   % Gaussian m
set(handles.edit14, 'String', '10');   % Gaussian P
set(handles.edit17, 'String', '10');   % Exponential a
set(handles.edit18, 'String', '200');  % Exponential b
set(handles.edit19, 'String', '240');  % Rayleigh b
set(handles.edit20, 'String', '240');  % Rayleigh a
set(handles.edit21, 'String', '0');    % Gamma a
set(handles.edit22, 'String', '255');  % Gamma b
% Initialize image fields
handles.currentImage = [];
handles.filteredImage = [];
% Initialize point operations menu
pointOperations = {'Point Detection', 'Point Sharpening'};
set(handles.popupmenu7, 'String', pointOperations);
set(handles.popupmenu7, 'Value', 1); % Default to Point Detection
% Initialize line operations menu
lineOperations = {
    'Line Detection (Sobel)', 
    'Line Detection (Roberts)', 
    'Line Sharpening'
};
set(handles.popupmenu8, 'String', lineOperations);
set(handles.popupmenu8, 'Value', 1); % Default to Sobel
    
% Initialize direction buttons as invisible
set([handles.pushbutton31, handles.pushbutton32, handles.pushbutton33, handles.pushbutton34], 'Visible', 'on','Enable', 'on');
set(handles.pushbutton31, 'String', 'H');
set(handles.pushbutton32, 'String', 'V');
set(handles.pushbutton33, 'String', 'DL');
set(handles.pushbutton34, 'String', 'DR');
% Initialize transformation parameters
handles.transformationParams = struct(...
    'gammaValue', 1.0, ...      % Default gamma value
    'logConstant', 1.0, ...     % Constant for log transformation
    'negativeActive', false ...  % Flag for negative transformation
);

% Set default gamma value in the edit box
set(handles.edit23, 'String', num2str(handles.transformationParams.gammaValue));
% Initialize frequency domain filter parameters
set(handles.edit26, 'String', '5');  % D0 cutoff frequency
set(handles.edit27, 'String', '1');  % Butterworth order

% Initialize filter type popupmenu
filterTypes = {
    'Ideal Low Pass', 
    'Ideal High Pass', 
    'Butterworth Low Pass', 
    'Butterworth High Pass', 
    'Gaussian Low Pass', 
    'Gaussian High Pass'
};
set(handles.popupmenu10, 'String', filterTypes);
set(handles.popupmenu10, 'Value', 1); % Default to Ideal Low Pass
% Initialize brightness parameters
set(handles.edit28, 'String', '10');  % Default brightness adjustment value
handles.brightnessValue = 10; 
% Choose default command line output
handles.output = hObject;
handles.currentImage = [];
handles.noisyImage = [];
handles.frequencyFilteredImage = [];
% Initialize Fourier transform variables
handles.fourierData = [];       % Will store Fourier transform data
handles.reconstructedImage = []; % Will store reconstructed image
% Initialize conversion parameters
set(handles.edit29, 'String', '127');  % Default binary threshold
set(handles.edit30, 'String', '1');    % Default grayscale method (1-5)
% Initialize other variables
handles.currentImage = [];
handles.processedImage = [];
% Initialize default values for Fourier display
handles.fourierDisplayMode = 'magnitude'; % Can be 'magnitude' or 'phase'
% Initialize kernel size (default 3x3)
handles.kernelSize = 3;

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = gui_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

% --- Helper function to validate numeric input
function valid = validateInput(handle, minVal, maxVal, isInteger)
str = get(handle, 'String');
num = str2double(str);
if isnan(num) || num < minVal || num > maxVal
    valid = false;
    set(handle, 'String', '');
    errordlg(sprintf('Please enter a number between %.2f and %.2f', minVal, maxVal), 'Invalid Input');
else
    if isInteger
        num = round(num);
        set(handle, 'String', num2str(num));
    end
    valid = true;
end

% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
set(handles.uitable3, 'Data', handles.filterKernel);


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in apply.
function apply_Callback(hObject, eventdata, handles)
% Check if image exists
if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
    errordlg('Please load an image first using the "Load Image" button.', 'No Image Found');
    return;
end

try
    % Initialize default kernel if not exists
    if ~isfield(handles, 'filterKernel')
        handles.filterKernel = ones(3,3)/9;
    end
    
    % Get selected filter type
    filterTypes = get(handles.popupmenu1, 'String');
    selectedFilter = filterTypes{get(handles.popupmenu1, 'Value')};
    
    % Get kernel data safely
    if isfield(handles, 'uitable3')
        kernelData = get(handles.uitable3, 'Data');
        if iscell(kernelData)
            % Convert cell to matrix, handling empty/non-numeric values
            kernelData = cellfun(@(x) ifelse(isempty(x)||~isnumeric(x),0,x), kernelData, 'UniformOutput', false);
            handles.filterKernel = cell2mat(kernelData);
        else
            handles.filterKernel = kernelData;
        end
    end
    
    % Use filtered image if it exists, otherwise use original
    if isfield(handles, 'filteredImage') && ~isempty(handles.filteredImage)
        img = handles.filteredImage;
    else
        img = handles.currentImage;
    end
    
    % Process image
    if size(img, 3) == 3
        img = rgb2gray(img);
    end
    
    % Apply selected filter
    switch selectedFilter
        case 'Correlation'
            filteredImg = imfilter(double(img), handles.filterKernel, 'corr', 'same');
        case 'Weighted'
            % Normalize kernel
            normalizedKernel = handles.filterKernel / sum(handles.filterKernel(:));
            filteredImg = imfilter(double(img), normalizedKernel, 'conv', 'same');
    end
    
    % Always show original in axes1
    axes(handles.axes1);
    imshow(handles.currentImage);
    title('Original Image');
    
    % Show filtered result in axes2
    axes(handles.axes2);
    imshow(filteredImg, []);
    title([selectedFilter ' Result']);
    
    % Store for next operation
    handles.filteredImage = filteredImg;
    guidata(hObject, handles);
    
catch e
    errordlg(['Error applying filter: ' e.message], 'Filter Error');
end

% Helper function
function y = ifelse(condition, trueval, falseval)
if condition
    y = trueval;
else
    y = falseval;
end

% --------------------------------------------------------------------
function uitable3_ButtonDownFcn(hObject, eventdata, handles)


% --- Executes when entered data in editable cell(s) in uitable3.
function uitable3_CellEditCallback(hObject, eventdata, handles)
try
    newData = get(hObject, 'Data');
    % Convert from cell if needed
    if iscell(newData)
        newData = cell2mat(newData);
    end
    handles.filterKernel = newData;
    guidata(hObject, handles);
catch e
    errordlg(['Invalid kernel value: ' e.message], 'Input Error');
end


% --- Executes during object deletion, before destroying properties.
function uitable4_DeleteFcn(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function uitable4_CreateFcn(hObject, eventdata, handles)


% --- Executes during object deletion, before destroying properties.
function uipanel1_DeleteFcn(hObject, eventdata, handles)


% --- Executes on selection change in popupmenu3.
function popupmenu3_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function popupmenu3_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
handles.filterKernel = ones(3,3)/9;
set(handles.uitable3, 'Data', handles.filterKernel);
guidata(hObject, handles);
msgbox('Kernel reset to default 3x3 averaging filter.', 'Reset Complete');


% --- Executes on button press in pushbutton18 (Salt & Pepper Noise).
function pushbutton18_Callback(hObject, eventdata, handles)
    try
        % Get salt & pepper probabilities
        ps = str2double(get(handles.edit7, 'String'));
        pp = str2double(get(handles.edit8, 'String'));
        
        % Validate inputs
        if isnan(ps) || isnan(pp) || ps < 0 || pp < 0 || (ps+pp) > 1
            errordlg('Please enter valid probabilities (0 <= PS,PP <= 1, PS+PP <= 1)', 'Invalid Input');
            return;
        end
        
        % Check if image exists
        if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
            errordlg('Please load an image first!', 'No Image');
            return;
        end
        
        % Use filtered image if it exists, otherwise use original
        if isfield(handles, 'filteredImage') && ~isempty(handles.filteredImage)
            img = handles.filteredImage;
        else
            img = handles.currentImage;
        end
        
        % Add salt & pepper noise
        noisy_img = imnoise(img, 'salt & pepper', ps+pp);
        
        % Always show original in axes1
        axes(handles.axes1);
        imshow(handles.currentImage);
        title('Original Image');
        
        % Show noisy result in axes2
        axes(handles.axes2);
        imshow(noisy_img);
        title(['Salt & Pepper Noise (PS=' num2str(ps) ', PP=' num2str(pp) ')']);
        
        % Store for next operation
        handles.filteredImage = noisy_img;
        guidata(hObject, handles);
        
    catch ME
        errordlg(['Error adding salt & pepper noise: ' ME.message], 'Processing Error');
    end
% --- Executes on selection change in popupmenu6.
function popupmenu6_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function popupmenu6_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton15.
function pushbutton15_Callback(hObject, eventdata, handles)


% --- Executes on button press in pushbutton8.
function pushbutton8_Callback(hObject, eventdata, handles)
% Check if images exist
if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
    errordlg('Please load an image first.', 'No Image Found');
    return;
end

if ~isfield(handles, 'filteredImage') || isempty(handles.filteredImage)
    errordlg('No processed image available. Please apply a filter first.', 'No Processed Image');
    return;
end

try
    originalImg = handles.currentImage;
    filteredImg = handles.filteredImage;
    
    % Create figure for histogram comparison
    hFig = figure('Name', 'Histogram Comparison', 'NumberTitle', 'off', 'Position', [100 100 1000 800]);
    
    % Original image
    subplot(2,2,1);
    if size(originalImg, 3) == 3
        imshow(originalImg);
        title('Original Color Image');
        
        % RGB histograms
        subplot(2,2,3);
        imhist(originalImg(:,:,1));
        hold on;
        imhist(originalImg(:,:,2));
        imhist(originalImg(:,:,3));
        hold off;
        title('Original RGB Histograms');
        legend('Red','Green','Blue');
    else
        imshow(originalImg);
        title('Original Grayscale Image');
        
        subplot(2,2,3);
        imhist(originalImg);
        title('Original Histogram');
    end
    
    % Processed image
    subplot(2,2,2);
    imshow(filteredImg);
    title('Processed Image');
    
    subplot(2,2,4);
    if size(filteredImg, 3) == 3
        imhist(filteredImg(:,:,1));
        hold on;
        imhist(filteredImg(:,:,2));
        imhist(filteredImg(:,:,3));
        hold off;
        title('Processed RGB Histograms');
        legend('Red','Green','Blue');
    else
        imhist(filteredImg);
        title('Processed Histogram');
    end
    
    % Add main title
    annotation(hFig, 'textbox', [0.3 0.95 0.4 0.05], 'String', ...
        'Histogram Comparison: Original vs Processed Image', ...
        'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
        'FontSize', 12, 'FontWeight', 'bold');
    
catch e
    errordlg(['Error displaying histograms: ' e.message], 'Display Error');
end

% --- Executes on button press in pushbutton10.
% --- Executes on button press in pushbutton10.
function pushbutton10_Callback(hObject, eventdata, handles)
% Check if image exists
if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
    errordlg('Please load an image first.', 'No Image Found');
    return;
end

img = handles.currentImage;

try
    % Convert to grayscale if RGB
    if size(img, 3) == 3
        img = rgb2gray(img);
    end
    
    % Apply histogram equalization
    equalizedImg = histeq(img);
    
    % Display results
    axes(handles.axes2); % Assuming axes2 is for processed images
    imshow(equalizedImg);
    title('Histogram Equalization Result');
    
    % Show histograms comparison
    figure;
    subplot(2,1,1); imhist(img); title('Original Histogram');
    subplot(2,1,2); imhist(equalizedImg); title('Equalized Histogram');
    
    % Store the processed image
    handles.filteredImage = equalizedImg;
    guidata(hObject, handles);
    
catch e
    errordlg(['Error in histogram equalization: ' e.message], 'Processing Error');
end



function edit1_Callback(hObject, eventdata, handles)
% Validate new min value
val = str2double(get(hObject, 'String'));
if isnan(val) || val < 0 || val > 255
    set(hObject, 'String', '0');
    errordlg('Please enter a value between 0 and 255', 'Invalid Input');
end

% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit2_Callback(hObject, eventdata, handles)
% Validate new max value
val = str2double(get(hObject, 'String'));
if isnan(val) || val < 0 || val > 255
    set(hObject, 'String', '255');
    errordlg('Please enter a value between 0 and 255', 'Invalid Input');
end

% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton11.
function pushbutton11_Callback(hObject, eventdata, handles)
% Check if image exists
if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
    errordlg('Please load an image first.', 'No Image Found');
    return;
end

% Get min and max values from edit boxes
try
    newMin = str2double(get(handles.edit1, 'String'));
    newMax = str2double(get(handles.edit2, 'String'));
    
    if isnan(newMin) || isnan(newMax) || newMin >= newMax
        errordlg('Please enter valid min/max values (min < max).', 'Invalid Input');
        return;
    end
    
    img = handles.currentImage;
    
    % Convert to grayscale if RGB
    if size(img, 3) == 3
        img = rgb2gray(img);
    end
    
    % Perform contrast stretching
    minVal = double(min(img(:)));
    maxVal = double(max(img(:)));
    
    stretchedImg = (double(img) - minVal) .* ((newMax - newMin)/(maxVal - minVal)) + newMin;
    stretchedImg = uint8(stretchedImg);
    
    % Display results
    axes(handles.axes2);
    imshow(stretchedImg);
    title(['Contrast Stretching [' num2str(newMin) ' to ' num2str(newMax) ']']);
    
    % Store the processed image
    handles.filteredImage = stretchedImg;
    guidata(hObject, handles);
    
catch e
    errordlg(['Error in contrast stretching: ' e.message], 'Processing Error');
end



% --- Edit box callbacks (validation)
function edit7_Callback(hObject, eventdata, handles)
validateInput(hObject, 0, 1, false); % Salt & Pepper PS (0-1)
% --- Executes during object creation, after setting all properties.
function edit7_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit8_Callback(hObject, eventdata, handles)
validateInput(hObject, 0, 1, false); % Salt & Pepper PP (0-1)

% --- Executes during object creation, after setting all properties.
function edit8_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton19 (Uniform Noise).
function pushbutton19_Callback(hObject, eventdata, handles)
    try
        % Get parameters
        a = str2double(get(handles.edit9, 'String'));
        b = str2double(get(handles.edit10, 'String'));
        P = str2double(get(handles.edit11, 'String'))/100;
        
        % Validate
        if isnan(a) || isnan(b) || isnan(P) || b <= a || P <= 0 || P > 1
            errordlg('Invalid parameters (a < b, 0 < P <= 100)', 'Error');
            return;
        end
        
        % Check image
        if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
            errordlg('Load image first!', 'Error');
            return;
        end
        
        % Use filtered image if it exists, otherwise use original
        if isfield(handles, 'filteredImage') && ~isempty(handles.filteredImage)
            img = handles.filteredImage;
        else
            img = handles.currentImage;
        end
        
        [rows, cols, ch] = size(img);
        
        % Generate and scale noise properly
        noise = a + (b-a)*rand(rows, cols, ch);
        noisy_img = double(img) + P*noise;
        
        % Ensure proper range
        noisy_img = max(0, min(255, noisy_img));
        noisy_img = uint8(noisy_img);
        
        % Always show original in axes1
        axes(handles.axes1);
        imshow(handles.currentImage);
        title('Original Image');
        
        % Show noisy result in axes2
        axes(handles.axes2);
        imshow(noisy_img);
        title('Uniform Noise Added');
        
        % Store for next operation
        handles.filteredImage = noisy_img;
        guidata(hObject, handles);
        
    catch ME
        errordlg(['Error: ' ME.message], 'Error');
    end
function edit9_Callback(hObject, eventdata, handles)
validateInput(hObject, -255, 255, true); % Uniform a

function edit9_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit10_Callback(hObject, eventdata, handles)
validateInput(hObject, -255, 255, true); % Uniform b

% --- Executes during object creation, after setting all properties.
function edit10_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit11_Callback(hObject, eventdata, handles)
validateInput(hObject, 0, 100, false); % Uniform P (0-100%)

% --- Executes during object creation, after setting all properties.
function edit11_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in pushbutton20 (Gaussian Noise).
function pushbutton20_Callback(hObject, eventdata, handles)
    try
        seg = str2double(get(handles.edit12, 'String'));
        m = str2double(get(handles.edit13, 'String'));
        P = str2double(get(handles.edit14, 'String'))/100;
        
        if isnan(seg) || isnan(m) || isnan(P) || seg <= 0 || P <= 0 || P > 1
            errordlg('Invalid parameters (seg > 0, 0 < P <= 100)', 'Error');
            return;
        end
        
        if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
            errordlg('Load image first!', 'Error');
            return;
        end
        
        % Use filtered image if it exists, otherwise use original
        if isfield(handles, 'filteredImage') && ~isempty(handles.filteredImage)
            img = handles.filteredImage;
        else
            img = handles.currentImage;
        end
        
        [rows, cols, ch] = size(img);
        
        % Generate Gaussian noise
        noise = m + seg*randn(rows, cols, ch);
        noisy_img = double(img) + P*noise;
        
        % Clip and convert
        noisy_img = max(0, min(255, noisy_img));
        noisy_img = uint8(noisy_img);
        
        % Always show original in axes1
        axes(handles.axes1);
        imshow(handles.currentImage);
        title('Original Image');
        
        % Show noisy result in axes2
        axes(handles.axes2);
        imshow(noisy_img);
        title('Gaussian Noise Added');
        
        % Store for next operation
        handles.filteredImage = noisy_img;
        guidata(hObject, handles);
        
    catch ME
        errordlg(['Error: ' ME.message], 'Error');
    end

function edit12_Callback(hObject, eventdata, handles)
validateInput(hObject, 0, 100, false); % Gaussian seg

% --- Executes during object creation, after setting all properties.
function edit12_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit13_Callback(hObject, eventdata, handles)
validateInput(hObject, -255, 255, true); % Gaussian m
function edit13_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit14_Callback(hObject, eventdata, handles)
validateInput(hObject, 0, 100, false); % Gaussian P (0-100%)
function edit14_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton21 (Rayleigh Noise).
function pushbutton21_Callback(hObject, eventdata, handles)
    try
        a = str2double(get(handles.edit20, 'String'));
        b = str2double(get(handles.edit19, 'String'));
        
        if isnan(a) || isnan(b) || b <= 0
            errordlg('Invalid parameters (b > 0)', 'Error');
            return;
        end
        
        if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
            errordlg('Load image first!', 'Error');
            return;
        end
        
        % Use filtered image if it exists, otherwise use original
        if isfield(handles, 'filteredImage') && ~isempty(handles.filteredImage)
            img = handles.filteredImage;
        else
            img = handles.currentImage;
        end
        
        [rows, cols, ch] = size(img);
        
        % Generate Rayleigh noise
        noise = a + (-b*log(1 - rand(rows, cols, ch))).^0.5;
        noisy_img = double(img) + noise;
        
        % Normalize to 0-255 range
        noisy_img = max(0, min(255, noisy_img));
        noisy_img = uint8(noisy_img);
        
        % Always show original in axes1
        axes(handles.axes1);
        imshow(handles.currentImage);
        title('Original Image');
        
        % Show noisy result in axes2
        axes(handles.axes2);
        imshow(noisy_img);
        title('Rayleigh Noise Added');
        
        % Store for next operation
        handles.filteredImage = noisy_img;
        guidata(hObject, handles);
        
    catch ME
        errordlg(['Error: ' ME.message], 'Error');
    end

% --- Executes on button press in pushbutton22 (Exponential Noise).
function pushbutton22_Callback(hObject, eventdata, handles)
    try
        a = str2double(get(handles.edit17, 'String'));
        b = str2double(get(handles.edit18, 'String'));
        
        if isnan(a) || isnan(b) || a <= 0
            errordlg('Invalid parameters (a > 0)', 'Error');
            return;
        end
        
        if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
            errordlg('Load image first!', 'Error');
            return;
        end
        
        % Use filtered image if it exists, otherwise use original
        if isfield(handles, 'filteredImage') && ~isempty(handles.filteredImage)
            img = handles.filteredImage;
        else
            img = handles.currentImage;
        end
        
        [rows, cols, ch] = size(img);
        
        % Generate Exponential noise
        noise = (-1/a)*log(1 - rand(rows, cols, ch));
        noisy_img = double(img) + b*noise;
        
        % Normalize
        noisy_img = max(0, min(255, noisy_img));
        noisy_img = uint8(noisy_img);
        
        % Always show original in axes1
        axes(handles.axes1);
        imshow(handles.currentImage);
        title('Original Image');
        
        % Show noisy result in axes2
        axes(handles.axes2);
        imshow(noisy_img);
        title('Exponential Noise Added');
        
        % Store for next operation
        handles.filteredImage = noisy_img;
        guidata(hObject, handles);
        
    catch ME
        errordlg(['Error: ' ME.message], 'Error');
    end
function edit17_Callback(hObject, eventdata, handles)
validateInput(hObject, 0.01, 100, false); % Exponential a
% --- Executes during object creation, after setting all properties.
function edit17_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit18_Callback(hObject, eventdata, handles)
validateInput(hObject, 0, 255, true); % Exponential b
% --- Executes during object creation, after setting all properties.
function edit18_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit19_Callback(hObject, eventdata, handles)
validateInput(hObject, 0.01, 255, false); % Rayleigh b
% --- Executes during object creation, after setting all properties.
function edit19_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit20_Callback(hObject, eventdata, handles)
validateInput(hObject, 0, 255, true); % Rayleigh a
% --- Executes during object creation, after setting all properties.
function edit20_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton24 (Gamma Noise).
function pushbutton24_Callback(hObject, eventdata, handles)
    try
        a = str2double(get(handles.edit21, 'String'));
        b = str2double(get(handles.edit22, 'String'));
        
        if isnan(a) || isnan(b) || a <= 0 || b <= 0
            errordlg('Invalid parameters (a > 0, b > 0)', 'Error');
            return;
        end
        
        if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
            errordlg('Load image first!', 'Error');
            return;
        end
        
        % Use filtered image if it exists, otherwise use original
        if isfield(handles, 'filteredImage') && ~isempty(handles.filteredImage)
            img = handles.filteredImage;
        else
            img = handles.currentImage;
        end
        
        [rows, cols, ch] = size(img);
        
        % Generate Gamma noise
        if exist('gamrnd', 'file')
            noise = gamrnd(a, b, rows, cols, ch);
        else
            noise = zeros(rows, cols, ch);
            for k = 1:a
                noise = noise - b*log(1 - rand(rows, cols, ch));
            end
        end
        
        noisy_img = double(img) + noise;
        
        % Normalize
        noisy_img = max(0, min(255, noisy_img));
        noisy_img = uint8(noisy_img);
        
        % Always show original in axes1
        axes(handles.axes1);
        imshow(handles.currentImage);
        title('Original Image');
        
        % Show noisy result in axes2
        axes(handles.axes2);
        imshow(noisy_img);
        title('Gamma Noise Added');
        
        % Store for next operation
        handles.filteredImage = noisy_img;
        guidata(hObject, handles);
        
    catch ME
        errordlg(['Error: ' ME.message], 'Error');
    end
% --- Executes on selection change in popupmenu7.
function popupmenu7_Callback(hObject, eventdata, handles)
    % No special handling needed here - we'll use the selection in the apply button
    guidata(hObject, handles);
function popupmenu7_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


% --- Executes on button press in pushbutton25.
function pushbutton25_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton25 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function edit21_Callback(hObject, eventdata, handles)
validateInput(hObject, 0, 100, false); % Gamma a

% --- Executes during object creation, after setting all properties.function edit21_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit22_Callback(hObject, eventdata, handles)
validateInput(hObject, 0, 255, true); % Gamma b
% --- Executes during object creation, after setting all properties.
function edit22_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pushbutton56.
function pushbutton56_Callback(hObject, eventdata, handles)
if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
    errordlg('Please load an image first!', 'No Image');
    return;
end

try
    % Get threshold value
    threshold = str2double(get(handles.edit29, 'String'));
    if isnan(threshold) || threshold < 0 || threshold > 255
        errordlg('Threshold must be between 0-255!', 'Invalid Threshold');
        return;
    end
    
    % Convert to grayscale first if color image
    if size(handles.currentImage, 3) == 3
        grayImg = rgb2gray(handles.currentImage);
    else
        grayImg = handles.currentImage;
    end
    
    % Convert to binary
    handles.processedImage = imbinarize(grayImg, threshold/255);
    
    % Display result
    axes(handles.axes2);
    imshow(handles.processedImage);
    title(['Binary Image (Threshold: ' num2str(threshold) ')']);
    
    guidata(hObject, handles);
catch ME
    errordlg(['Error in binary conversion: ' ME.message], 'Processing Error');
end
% --- Executes on button press in pushbutton58.
function pushbutton58_Callback(hObject, eventdata, handles)
if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
    errordlg('Please load an image first!', 'No Image');
    return;
end

try
    % Get conversion method
    method = round(str2double(get(handles.edit30, 'String')));
    if isnan(method) || method < 1 || method > 5
        errordlg('Method must be 1-5!', 'Invalid Method');
        return;
    end
    
    % Apply selected grayscale conversion
    if size(handles.currentImage, 3) == 3
        switch method
            case 1 % Gray by Division (average)
                grayImg = mean(handles.currentImage, 3);
            case 2 % Gray by Percentage (weighted)
                weights = [0.2989, 0.5870, 0.1140]; % Standard luminance weights
                grayImg = handles.currentImage(:,:,1)*weights(1) + ...
                         handles.currentImage(:,:,2)*weights(2) + ...
                         handles.currentImage(:,:,3)*weights(3);
            case 3 % Red channel
                grayImg = handles.currentImage(:,:,1);
            case 4 % Green channel
                grayImg = handles.currentImage(:,:,2);
            case 5 % Blue channel
                grayImg = handles.currentImage(:,:,3);
        end
        handles.processedImage = uint8(grayImg);
    else
        handles.processedImage = handles.currentImage; % Already grayscale
    end
    
    % Display result
    axes(handles.axes2);
    imshow(handles.processedImage);
    
    % Set appropriate title
    methodNames = {'Average', 'Luminance', 'Red Channel', 'Green Channel', 'Blue Channel'};
    title(['Grayscale (' methodNames{method} ')']);
    
    guidata(hObject, handles);
catch ME
    errordlg(['Error in grayscale conversion: ' ME.message], 'Processing Error');
end


function edit29_Callback(hObject, eventdata, handles)
% Validate binary threshold input
val = str2double(get(hObject, 'String'));
if isnan(val) || val < 0 || val > 255
    errordlg('Threshold must be 0-255!', 'Invalid Input');
    set(hObject, 'String', '127'); % Reset to default
end

function edit29_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject, 'String', '127'); % Default threshold

function edit30_Callback(hObject, eventdata, handles)
% Validate grayscale method input
val = round(str2double(get(hObject, 'String')));
if isnan(val) || val < 1 || val > 5
    errordlg('Method must be 1-5!', 'Invalid Input');
    set(hObject, 'String', '1'); % Reset to default
end

function edit30_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject, 'String', '1'); % Default method


function pushbutton52_Callback(hObject, eventdata, handles)
if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
    errordlg('Please load an image first!', 'No Image');
    return;
end

try
    value = str2double(get(handles.edit28, 'String'));
    if isnan(value)
        errordlg('Please enter a valid number!', 'Invalid Input');
        return;
    end
    
    % Use filtered image if it exists, otherwise use original
    if isfield(handles, 'filteredImage') && ~isempty(handles.filteredImage)
        img = handles.filteredImage;
    else
        img = handles.currentImage;
    end
    
    % Add value to each pixel (clamping to 255)
    adjusted = double(img) + value;
    handles.filteredImage = uint8(min(adjusted, 255));
    
    % Always show original in axes1
    axes(handles.axes1);
    imshow(handles.currentImage);
    title('Original Image');
    
    % Display result
    axes(handles.axes2);
    imshow(handles.filteredImage);
    title(['Brightness Increased (Add ' num2str(value) ')']);
    
    guidata(hObject, handles);
catch ME
    errordlg(['Error: ' ME.message], 'Processing Error');
end

function pushbutton53_Callback(hObject, eventdata, handles)
if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
    errordlg('Please load an image first!', 'No Image');
    return;
end

try
    value = str2double(get(handles.edit28, 'String'));
    if isnan(value) || value <= 0
        errordlg('Please enter a positive number!', 'Invalid Input');
        return;
    end
    
    % Use filtered image if it exists, otherwise use original
    if isfield(handles, 'filteredImage') && ~isempty(handles.filteredImage)
        img = handles.filteredImage;
    else
        img = handles.currentImage;
    end
    
    % Multiply each pixel (clamping to 255)
    adjusted = double(img) * value;
    handles.filteredImage = uint8(min(adjusted, 255));
    
    % Always show original in axes1
    axes(handles.axes1);
    imshow(handles.currentImage);
    title('Original Image');
    
    % Display result
    axes(handles.axes2);
    imshow(handles.filteredImage);
    title(['Brightness Increased (Multiply by ' num2str(value) ')']);
    
    guidata(hObject, handles);
catch ME
    errordlg(['Error: ' ME.message], 'Processing Error');
end

function pushbutton54_Callback(hObject, eventdata, handles)
if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
    errordlg('Please load an image first!', 'No Image');
    return;
end

try
    value = str2double(get(handles.edit28, 'String'));
    if isnan(value)
        errordlg('Please enter a valid number!', 'Invalid Input');
        return;
    end
    
    % Use filtered image if it exists, otherwise use original
    if isfield(handles, 'filteredImage') && ~isempty(handles.filteredImage)
        img = handles.filteredImage;
    else
        img = handles.currentImage;
    end
    
    % Subtract value from each pixel (clamping to 0)
    adjusted = double(img) - value;
    handles.filteredImage = uint8(max(adjusted, 0));
    
    % Always show original in axes1
    axes(handles.axes1);
    imshow(handles.currentImage);
    title('Original Image');
    
    % Display result
    axes(handles.axes2);
    imshow(handles.filteredImage);
    title(['Brightness Decreased (Subtract ' num2str(value) ')']);
    
    guidata(hObject, handles);
catch ME
    errordlg(['Error: ' ME.message], 'Processing Error');
end

function pushbutton55_Callback(hObject, eventdata, handles)
if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
    errordlg('Please load an image first!', 'No Image');
    return;
end

try
    value = str2double(get(handles.edit28, 'String'));
    if isnan(value) || value <= 0
        errordlg('Please enter a positive number!', 'Invalid Input');
        return;
    end
    
    % Use filtered image if it exists, otherwise use original
    if isfield(handles, 'filteredImage') && ~isempty(handles.filteredImage)
        img = handles.filteredImage;
    else
        img = handles.currentImage;
    end
    
    % Divide each pixel (clamping to 0)
    adjusted = double(img) / value;
    handles.filteredImage = uint8(max(adjusted, 0));
    
    % Always show original in axes1
    axes(handles.axes1);
    imshow(handles.currentImage);
    title('Original Image');
    
    % Display result
    axes(handles.axes2);
    imshow(handles.filteredImage);
    title(['Brightness Decreased (Divide by ' num2str(value) ')']);
    
    guidata(hObject, handles);
catch ME
    errordlg(['Error: ' ME.message], 'Processing Error');
end

function edit28_Callback(hObject, eventdata, handles)
% Validate input
value = str2double(get(hObject, 'String'));
if isnan(value)
    errordlg('Please enter a valid number!', 'Invalid Input');
    set(hObject, 'String', '10'); % Reset to default
end
handles.brightnessValue = value;
guidata(hObject, handles);

function edit28_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject, 'String', '10'); % Default value


function edit26_Callback(hObject, eventdata, handles)
% D0 cutoff frequency - no action needed

function edit26_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject, 'String', '5'); % Default D0 value

function edit27_Callback(hObject, eventdata, handles)
% Butterworth order - no action needed

function edit27_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject, 'String', '1'); % Default Butterworth order


% --- Executes on selection change in popupmenu10.
function popupmenu10_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu10 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu10


% --- Executes during object creation, after setting all properties.
function popupmenu10_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% Helper function for Ideal Filter
function output = idealFilter(img, D0, type)
    [M, N] = size(img);
    [u, v] = meshgrid(1:N, 1:M);
    D = sqrt((u - N/2).^2 + (v - M/2).^2);
    
    if strcmpi(type, 'low')
        H = double(D <= D0);
    else % high pass
        H = double(D > D0);
    end
    
    output = applyFrequencyFilter(img, H);

% Helper function for Butterworth Filter
function output = butterworthFilter(img, D0, n, type)
    [M, N] = size(img);
    [u, v] = meshgrid(1:N, 1:M);
    D = sqrt((u - N/2).^2 + (v - M/2).^2);
    
    if strcmpi(type, 'low')
        H = 1 ./ (1 + (D./D0).^(2*n));
    else % high pass
        H = 1 ./ (1 + (D0./D).^(2*n));
    end
    
    output = applyFrequencyFilter(img, H);

% Helper function for Gaussian Filter
function output = gaussianFilter(img, D0, type)
    [M, N] = size(img);
    [u, v] = meshgrid(1:N, 1:M);
    D = sqrt((u - N/2).^2 + (v - M/2).^2);
    
    if strcmpi(type, 'low')
        H = exp(-(D.^2)./(2*D0^2));
    else % high pass
        H = 1 - exp(-(D.^2)./(2*D0^2));
    end
    
    output = applyFrequencyFilter(img, H);
% Common frequency filter application
function output = applyFrequencyFilter(img, H)
    % Convert to double
    img = im2double(img);
    
    % Compute DFT
    F = fftshift(fft2(img));
    
    % Apply filter
    G = H .* F;
    
    % Inverse DFT
    output = real(ifft2(ifftshift(G)));
    
    % Normalize to 0-1 range
    output = mat2gray(output);
% --- Executes on button press in pushbutton50 (Apply Frequency Filter).
function pushbutton50_Callback(hObject, eventdata, handles)
% Check if image exists
if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
    errordlg('Please load an image first!', 'No Image');
    return;
end

try
    % Get parameters from GUI
    D0 = str2double(get(handles.edit26, 'String'));
    n = str2double(get(handles.edit27, 'String')); % For Butterworth
    filterTypes = get(handles.popupmenu10, 'String');
    filterType = get(handles.popupmenu10, 'Value');
    selectedFilterName = filterTypes{filterType}; % Get the name of selected filter
    
    % Validate parameters
    if isnan(D0) || D0 <= 0
        errordlg('Please enter a valid positive D0 value!', 'Invalid Parameter');
        return;
    end
    
    if (filterType == 3 || filterType == 4) && (isnan(n) || n <= 0)
        errordlg('Please enter a valid positive Butterworth order!', 'Invalid Parameter');
        return;
    end
    
    % Convert to grayscale if color image
    if size(handles.currentImage, 3) == 3
        img = rgb2gray(handles.currentImage);
    else
        img = handles.currentImage;
    end
    
    % Apply selected frequency domain filter
    switch filterType
        case 1 % Ideal Low Pass
            filtered = idealFilter(img, D0, 'low');
        case 2 % Ideal High Pass
            filtered = idealFilter(img, D0, 'high');
        case 3 % Butterworth Low Pass
            filtered = butterworthFilter(img, D0, n, 'low');
        case 4 % Butterworth High Pass
            filtered = butterworthFilter(img, D0, n, 'high');
        case 5 % Gaussian Low Pass
            filtered = gaussianFilter(img, D0, 'low');
        case 6 % Gaussian High Pass
            filtered = gaussianFilter(img, D0, 'high');
    end
    
    % Always show original in axes1
    axes(handles.axes1);
    imshow(handles.currentImage);
    title('Original Image');
    
    % Show result in axes2
    axes(handles.axes2);
    imshow(filtered);
    title([selectedFilterName ' Filter']);
    
    % Store for next operation
    handles.filteredImage = filtered;
    guidata(hObject, handles);
    
catch ME
    errordlg(['Error in frequency filtering: ' ME.message], 'Processing Error');
end
% --- Executes on button press in pushbutton45 (Fourier Transform).
function pushbutton45_Callback(hObject, eventdata, handles)
% Check if image is loaded
if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
    errordlg('Please load an image first!', 'No Image');
    return;
end

try
    % Convert to grayscale if color image
    if size(handles.currentImage, 3) == 3
        img = rgb2gray(handles.currentImage);
    else
        img = handles.currentImage;
    end
    
    % Compute Fourier Transform
    f_img = fft2(double(img));
    fshift = fftshift(f_img);
    magnitude_spectrum = mat2gray(log(1 + abs(fshift)));
    
    % Store Fourier data
    handles.fourierData = fshift;
    
    % Display magnitude spectrum
    axes(handles.axes2);
    imshow(magnitude_spectrum, []);
    colormap(handles.axes2, gray); % Use colormap for better visualization
    colorbar(handles.axes2);
    title('Fourier Transform (Magnitude Spectrum)');
    
    % Update handles
    guidata(hObject, handles);
    
catch ME
    errordlg(['Error in Fourier Transform: ' ME.message], 'Processing Error');
end

% --- Executes on button press in pushbutton46 (Inverse Fourier Transform).
function pushbutton46_Callback(hObject, eventdata, handles)
% Check if Fourier data exists
if ~isfield(handles, 'fourierData') || isempty(handles.fourierData)
    errordlg('Please perform Fourier Transform first!', 'No Fourier Data');
    return;
end

try
    % Compute Inverse Fourier Transform
    f_ishift = ifftshift(handles.fourierData);
    img_back = ifft2(f_ishift);
    
    % Display reconstructed image
    axes(handles.axes2);
    imshow(img_back, []);
    title('Inverse Fourier Transform (Reconstructed Image)');
    colorbar(handles.axes2, 'off'); % Remove colorbar for spatial domain
    
    % Store reconstructed image
    handles.reconstructedImage = img_back;
    
    % Update handles
    guidata(hObject, handles);
    
catch ME
    errordlg(['Error in Inverse Fourier Transform: ' ME.message], 'Processing Error');
end


function edit24_Callback(hObject, eventdata, handles)
% hObject    handle to edit24 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit24 as text
%        str2double(get(hObject,'String')) returns contents of edit24 as a double


% --- Executes during object creation, after setting all properties.
function edit24_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton42.
function pushbutton42_Callback(hObject, eventdata, handles)
[filename, pathname] = uigetfile({'*.jpg;*.png;*.bmp;*.tif;*.tiff', 'Image Files'}, 'Select an Image');
if isequal(filename, 0)
    return; % User cancelled
end

try
    % Read and store the image
    img = imread(fullfile(pathname, filename));
    handles.currentImage = img;
    
    % Display the original image
    axes(handles.axes1); % Make sure you have an axes component named axes1
    imshow(img);
    title('Original Image');
    
    % Update handles structure
    guidata(hObject, handles);
catch e
    errordlg(['Error loading image: ' e.message], 'Image Load Error');
end
% --- Executes on button press in pushbutton43.
function pushbutton43_Callback(hObject, eventdata, handles)

% Check if there's a filtered image to save
if ~isfield(handles, 'filteredImage') || isempty(handles.filteredImage)
    errordlg('No filtered image available to save. Please apply a filter first.', 'Nothing to Save');
    return;
end

% Get the filtered image
filteredImg = handles.filteredImage;

% Prepare default filename with timestamp
defaultName = ['filtered_' datestr(now, 'yyyymmdd_HHMMSS') '.png'];

% Ask user for save location
[filename, pathname] = uiputfile(...
    {'*.png','PNG files (*.png)'; ...
     '*.jpg','JPEG files (*.jpg)'; ...
     '*.tif','TIFF files (*.tif)'; ...
     '*.*','All Files (*.*)'}, ...
    'Save Filtered Image As', ...
    defaultName);

if isequal(filename, 0) || isequal(pathname, 0)
    return; % User cancelled
end

try
    % Save the image with appropriate format
    [~, ~, ext] = fileparts(filename);
    switch lower(ext)
        case '.png'
            imwrite(filteredImg, fullfile(pathname, filename), 'png');
        case '.jpg'
            imwrite(filteredImg, fullfile(pathname, filename), 'jpg', 'Quality', 90);
        case '.tif'
            imwrite(filteredImg, fullfile(pathname, filename), 'tif');
        otherwise
            % Default to PNG if extension not recognized
            imwrite(filteredImg, fullfile(pathname, [filename '.png']), 'png');
    end
    
    % Notify user of successful save
    msgbox(['Image successfully saved to: ' fullfile(pathname, filename)], 'Save Complete');
    
catch e
    errordlg(['Error saving image: ' e.message], 'Save Error');
end

% --- Executes on button press in pushbutton37 (Negative).
function pushbutton37_Callback(hObject, eventdata, handles)
% Check if image exists and is loaded
if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
    errordlg('Please load an image first!', 'No Image Loaded');
    return;
end

try
    % Use filtered image if it exists, otherwise use original
    if isfield(handles, 'filteredImage') && ~isempty(handles.filteredImage)
        img = handles.filteredImage;
    else
        img = handles.currentImage;
    end
    
    % Apply negative transformation
    negative = 255 - img;
    
    % Always show original in axes1
    axes(handles.axes1);
    imshow(handles.currentImage);
    title('Original Image');
    
    % Show result in axes2
    axes(handles.axes2);
    imshow(negative);
    title('Negative Transform');
    
    % Store for next operation
    handles.filteredImage = negative;
    guidata(hObject, handles);
    
catch ME
    errordlg(['Error in negative transformation: ' ME.message], 'Processing Error');
end
% --- Executes on button press in pushbutton40 (Log).
function pushbutton40_Callback(hObject, eventdata, handles)
% Check if image exists and is loaded
if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
    errordlg('Please load an image first!', 'No Image Loaded');
    return;
end

try
    % Use filtered image if it exists, otherwise use original
    if isfield(handles, 'filteredImage') && ~isempty(handles.filteredImage)
        img = handles.filteredImage;
    else
        img = handles.currentImage;
    end
    
    % Convert image to double and normalize
    img = im2double(img);
    
    % Apply log transformation
    c = 1/log(1 + max(img(:))); % Scaling constant
    logImg = c * log(1 + img);
    
    % Convert back to uint8
    transformed = im2uint8(logImg);
    
    % Always show original in axes1
    axes(handles.axes1);
    imshow(handles.currentImage);
    title('Original Image');
    
    % Show result in axes2
    axes(handles.axes2);
    imshow(transformed);
    title('Log Transform');
    
    % Store for next operation
    handles.filteredImage = transformed;
    guidata(hObject, handles);
    
catch ME
    errordlg(['Error in log transformation: ' ME.message], 'Processing Error');
end
% --- Executes on button press in pushbutton41 (Gamma).
function pushbutton41_Callback(hObject, eventdata, handles)
% Check if image exists and is loaded
if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
    errordlg('Please load an image first!', 'No Image Loaded');
    return;
end

try
    % Get gamma value from edit box
    gammaStr = get(handles.edit23, 'String');
    gamma = str2double(gammaStr);
    
    % Validate gamma value
    if isnan(gamma) || gamma <= 0
        errordlg('Gamma must be a positive number!', 'Invalid Gamma Value');
        set(handles.edit23, 'String', '1.0'); % Reset to default
        return;
    end
    
    % Apply gamma transformation
    img = im2double(handles.currentImage);
    gammaImg = img.^gamma;
    handles.filteredImage = im2uint8(gammaImg);
    
    % Always show original in axes1
    axes(handles.axes1);
    imshow(handles.currentImage);
    title(['Gamma Correction (\gamma = ' num2str(gamma) ')']);
    
    % Show result in axes2
    axes(handles.axes2);
    imshow(handles.filteredImage);
    title(['Gamma Correction (\gamma = ' num2str(gamma) ')']);
    
    % Store for next operation
    handles.filteredImage = handles.filteredImage;
    guidata(hObject, handles);
    
catch ME
    errordlg(['Error in gamma transformation: ' ME.message], 'Processing Error');
end

function edit23_Callback(hObject, eventdata, handles)
% Get current gamma value
gammaStr = get(hObject, 'String');
gamma = str2double(gammaStr);

% Validate input
if isnan(gamma) || gamma <= 0
    errordlg('Gamma must be a positive number!', 'Invalid Input');
    set(hObject, 'String', '1.0'); % Reset to default
    return;
end

% If image is loaded, show preview
if isfield(handles, 'currentImage') && ~isempty(handles.currentImage)
    try
        % Create preview on a small version of the image
        smallImg = imresize(handles.currentImage, 0.2); % Reduce size for faster preview
        previewImg = im2uint8(im2double(smallImg).^gamma);
        
        % Display preview
        axes(handles.axes2);
        imshow(previewImg);
        title(['Gamma Preview (\gamma=' gammaStr ')']);
    catch
        % Fail silently for preview errors
    end
end
% --- Executes during object creation, after setting all properties.
function edit23_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject, 'String', '1.0'); % Default gamma value
function applyLineOperation(handles, direction)
    try
        % Check if image exists
        if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
            errordlg('Please load an image first!', 'No Image');
            return;
        end
        
        % Get selected operation
        operations = get(handles.popupmenu8, 'String');
        selectedOp = operations{get(handles.popupmenu8, 'Value')};
        
        % Convert to grayscale if needed
        if size(handles.currentImage, 3) == 3
            img = rgb2gray(handles.currentImage);
        else
            img = handles.currentImage;
        end
        
        % Convert to double for processing
        img = double(img);
        
        % Apply the selected operation
        switch selectedOp
            case 'Line Detection (Sobel)'
                switch direction
                    case 'H'
                        kernel = [-1 -2 -1; 0 0 0; 1 2 1]; % Horizontal Sobel
                    case 'V'
                        kernel = [-1 0 1; -2 0 2; -1 0 1]; % Vertical Sobel
                    case 'DL'
                        kernel = [0 1 2; -1 0 1; -2 -1 0]; % Diagonal Left Sobel
                    case 'DR'
                        kernel = [-2 -1 0; -1 0 1; 0 1 2]; % Diagonal Right Sobel
                end
                result = imfilter(img, kernel);
                
            case 'Line Detection (Roberts)'
                switch direction
                    case 'H'
                        kernel = [1 0; 0 -1]; % Horizontal Roberts
                    case 'V'
                        kernel = [0 1; -1 0]; % Vertical Roberts
                    case 'DL'
                        kernel = [0 -1; 1 0]; % Diagonal Left Roberts
                    case 'DR'
                        kernel = [-1 0; 0 1]; % Diagonal Right Roberts
                end
                result = imfilter(img, kernel);
                
            case 'Line Sharpening'
                switch direction
                    case 'H'
                        kernel = [0 -1 0; 0 3 0; 0 -1 0]; % Horizontal sharpening
                    case 'V'
                        kernel = [0 0 0; -1 3 -1; 0 0 0]; % Vertical sharpening
                    case 'DL'
                        kernel = [-1 0 0; 0 3 0; 0 0 -1]; % Diagonal Left sharpening
                    case 'DR'
                        kernel = [0 0 -1; 0 3 0; -1 0 0]; % Diagonal Right sharpening
                end
                result = imfilter(img, kernel);
        end
        
        % Normalize and convert to uint8
        result = mat2gray(result); % Normalize to [0,1]
        result = im2uint8(result); % Convert to uint8
        
        % Display results
        axes(handles.axes1);
        imshow(handles.currentImage);
        title('Original Image');
        
        axes(handles.axes2);
        imshow(result);
        title([selectedOp ' (' direction ' Direction)']);
        
        % Store result
        handles.filteredImage = result;
        guidata(handles.figure1, handles);
        
    catch ME
        errordlg(['Error in ' selectedOp ': ' ME.message], 'Processing Error');
    end

% --- Executes on selection change in popupmenu8 line detect and sharpening
function popupmenu8_Callback(hObject, eventdata, handles)
    % Keep buttons visible for all operations
    set([handles.pushbutton31, handles.pushbutton32, handles.pushbutton33, handles.pushbutton34], 'Visible', 'on');
    guidata(hObject, handles);

function popupmenu8_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end




% --- Executes on button press in pushbutton27.
function pushbutton27_Callback(hObject, eventdata, handles)
    try
        if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
            errordlg('Please load an image first!', 'No Image');
            return;
        end
        
        % Get selected operation
        operations = get(handles.popupmenu8, 'String');
        selectedOp = operations{get(handles.popupmenu8, 'Value')};
        
        % Convert to grayscale if needed
        if size(handles.currentImage, 3) == 3
            img = rgb2gray(handles.currentImage);
        else
            img = handles.currentImage;
        end
        
        % Apply selected operation
        switch selectedOp
            case 'Line Detection (Sobel)'
                % Default to horizontal for Sobel
                result = edge(img, 'sobel', 'horizontal');
                
            case 'Line Detection (Roberts)'
                % Default to horizontal for Roberts
                result = edge(img, 'roberts', 'horizontal');
                
            case 'Line Sharpening'
                % Unsharp masking for line sharpening
                blurred = imgaussfilt(img, 1);
                mask = img - blurred;
                result = img + 1.5*mask; % Increased sharpening factor
                result = uint8(min(max(result, 0), 255));
        end
        
        % Always show original in axes1
        axes(handles.axes1);
        imshow(handles.currentImage);
        title('Original Image');
        
        % Show result in axes2
        axes(handles.axes2);
        imshow(result);
        title([selectedOp ' Result']);
        
        % Store result
        handles.filteredImage = result;
        guidata(hObject, handles);
        
    catch ME
        errordlg(['Error in ' selectedOp ': ' ME.message], 'Processing Error');
    end

% --- Direction buttons callbacks
function pushbutton31_Callback(hObject, eventdata, handles)
    applyLineOperation(handles, 'H');

function pushbutton32_Callback(hObject, eventdata, handles)
    applyLineOperation(handles, 'V');

function pushbutton33_Callback(hObject, eventdata, handles)
    applyLineOperation(handles, 'DL');

function pushbutton34_Callback(hObject, eventdata, handles)
    applyLineOperation(handles, 'DR');

% --- Executes on button press in pushbutton28 (Apply Point Operation)
function pushbutton28_Callback(hObject, eventdata, handles)
    try
        % Check if image exists
        if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
            errordlg('Please load an image first!', 'No Image');
            return;
        end
        
        % Get selected operation
        operations = get(handles.popupmenu7, 'String');
        selectedOp = operations{get(handles.popupmenu7, 'Value')};
        
        % Convert to grayscale if color image
        if size(handles.currentImage, 3) == 3
            img = rgb2gray(handles.currentImage);
        else
            img = handles.currentImage;
        end
        
        % Apply selected operation
        switch selectedOp
            case 'Point Detection'
                % Laplacian for point detection
                h = [1 1 1; 1 -8 1; 1 1 1]; % Laplacian kernel
                filtered = imfilter(double(img), h, 'same');
                result = abs(filtered); % Get absolute values
                result = uint8(255 * mat2gray(result)); % Normalize to 0-255
                
            case 'Point Sharpening'
                % Unsharp masking for sharpening
                blurred = imgaussfilt(img, 2);
                mask = img - blurred;
                result = img + mask; % Add the mask back to original
                result = uint8(min(max(result, 0), 255)); % Clamp to 0-255
        end
        
        % Always show original in axes1
        axes(handles.axes1);
        imshow(handles.currentImage);
        title('Original Image');
        
        % Show result in axes2
        axes(handles.axes2);
        imshow(result);
        title(selectedOp);
        
        % Store result
        handles.filteredImage = result;
        guidata(hObject, handles);
        
    catch ME
        errordlg(['Error in ' selectedOp ': ' ME.message], 'Processing Error');
    end
% --- Executes on button press in pushbutton29.
function pushbutton29_Callback(hObject, eventdata, handles)
% Check if image exists
if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
    errordlg('Please load an image first.', 'No Image Found');
    return;
end

% Get selected filter
filterList = get(handles.popupmenu6, 'String');
selectedFilter = filterList{get(handles.popupmenu6, 'Value')};

try
    % Use filtered image if it exists, otherwise use original
    if isfield(handles, 'filteredImage') && ~isempty(handles.filteredImage)
        img = handles.filteredImage;
    else
        img = handles.currentImage;
    end
    
    originalImg = img; % Keep copy of original for histogram
    
    % Convert to grayscale if RGB (most noise filters work on grayscale)
    if size(img, 3) == 3
        img = rgb2gray(img);
        isRGB = true;
    else
        isRGB = false;
    end
    
    % Apply selected filter
    switch selectedFilter
        case 'Min Filter'
            filteredImg = ordfilt2(img, 1, ones(handles.kernelSize));
        case 'Max Filter'
            filteredImg = ordfilt2(img, handles.kernelSize^2, ones(handles.kernelSize));
        case 'Mean Filter'
            h = fspecial('average', handles.kernelSize);
            filteredImg = imfilter(img, h);
        case 'Median Filter'
            filteredImg = medfilt2(img, [handles.kernelSize handles.kernelSize]);
        case 'Midpoint Filter'
            minImg = ordfilt2(img, 1, ones(handles.kernelSize));
            maxImg = ordfilt2(img, handles.kernelSize^2, ones(handles.kernelSize));
            filteredImg = (double(minImg) + double(maxImg)) / 2;
            filteredImg = uint8(filteredImg);
    end
    
    % Convert back to RGB if original was RGB
    if isRGB
        filteredImg = cat(3, filteredImg, filteredImg, filteredImg);
    end
    
    % Always show original in axes1
    axes(handles.axes1);
    imshow(handles.currentImage);
    title('Original Image');
    
    % Show filtered result in axes2
    axes(handles.axes2);
    imshow(filteredImg);
    title([selectedFilter ' Result']);
    
    % Store for next operation
    handles.filteredImage = filteredImg;
    guidata(hObject, handles);
    
    % Create figure for histogram comparison
    hFig = figure('Name', 'Histogram Comparison', 'NumberTitle', 'off', 'Position', [100 100 1000 800]);
    
    % Original image
    subplot(2,2,1);
    if size(originalImg, 3) == 3
        imshow(originalImg);
        title('Original Color Image');
        
        % RGB histograms
        subplot(2,2,3);
        imhist(originalImg(:,:,1));
        hold on;
        imhist(originalImg(:,:,2));
        imhist(originalImg(:,:,3));
        hold off;
        title('Original RGB Histograms');
        legend('Red','Green','Blue');
    else
        imshow(originalImg);
        title('Original Grayscale Image');
        
        subplot(2,2,3);
        imhist(originalImg);
        title('Original Histogram');
    end
    
    % Processed image
    subplot(2,2,2);
    imshow(filteredImg);
    title([selectedFilter ' Result']);
    
    subplot(2,2,4);
    if isRGB
        imhist(filteredImg(:,:,1));
        hold on;
        imhist(filteredImg(:,:,2));
        imhist(filteredImg(:,:,3));
        hold off;
        title('Processed RGB Histograms');
        legend('Red','Green','Blue');
    else
        imhist(filteredImg);
        title('Processed Histogram');
    end
    
    % Add main title (alternative to sgtitle for older MATLAB versions)
    annotation(hFig, 'textbox', [0.3 0.95 0.4 0.05], 'String', ...
        ['Histogram Comparison: ' selectedFilter ' (Kernel: ' num2str(handles.kernelSize) 'x' num2str(handles.kernelSize) ')'], ...
        'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
        'FontSize', 12, 'FontWeight', 'bold');
    
catch e
    errordlg(['Error applying ' selectedFilter ': ' e.message], 'Filter Error');
end

% --- Executes on button press in pushbutton30.
function pushbutton30_Callback(hObject, eventdata, handles)
% Check if image exists
if ~isfield(handles, 'currentImage') || isempty(handles.currentImage)
    errordlg('Please load an image first.', 'No Image Found');
    return;
end

% Get selected filter
filterList = get(handles.popupmenu3, 'String');
selectedFilter = filterList{get(handles.popupmenu3, 'Value')};

try
    % Use filtered image if it exists, otherwise use original
    if isfield(handles, 'filteredImage') && ~isempty(handles.filteredImage)
        img = handles.filteredImage;
    else
        img = handles.currentImage;
    end
    
    % Convert to grayscale if RGB
    if size(img, 3) == 3
        img = rgb2gray(img);
    end
    
    % Apply selected filter
    switch selectedFilter
        case 'Min Filter'
            filteredImg = ordfilt2(img, 1, ones(3,3));
            
        case 'Max Filter'
            filteredImg = ordfilt2(img, 9, ones(3,3));
            
        case 'Mean Filter'
            h = fspecial('average', 3);
            filteredImg = imfilter(img, h);
            
        case 'Midpoint Filter'
            minImg = ordfilt2(img, 1, ones(3,3));
            maxImg = ordfilt2(img, 9, ones(3,3));
            filteredImg = (double(minImg) + double(maxImg)) / 2;
            filteredImg = uint8(filteredImg);
            
        case 'Median Filter'
            filteredImg = medfilt2(img, [3 3]);
            
    end
    
    % Always show original in axes1
    axes(handles.axes1);
    imshow(handles.currentImage);
    title('Original Image');
    
    % Show filtered result in axes2
    axes(handles.axes2);
    imshow(filteredImg);
    title([selectedFilter ' Result']);
    
    % Store for next operation
    handles.filteredImage = filteredImg;
    guidata(hObject, handles);
    
catch e
    errordlg(['Error applying ' selectedFilter ': ' e.message], 'Filter Error');
end
