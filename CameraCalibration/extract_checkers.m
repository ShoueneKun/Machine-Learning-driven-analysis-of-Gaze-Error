function checkers = extract_checkers(Path2Video, BoardSize)
if exist(Path2Video, 'file') == 2
    % Extracting checkers from Scene video
    vidObj = VideoReader(Path2Video);
    checkers = cell(round(vidObj.Duration*vidObj.FrameRate), 1);
    m = 1;
    fprintf('Starting checker extraction from Scene video.\n')
    while hasFrame(vidObj)
        I = readFrame(vidObj);
        [imagePoints, Bsize] = detectCheckerboardPoints(I);
        if prod(Bsize == BoardSize)
           checkers{m, 1} =  imagePoints;
        end
        m = m+1;
    end
elseif exist(Path2Video, 'dir') == 7
    % Extracting checkers from Left images
    D = dir(fullfile(Path2Video, '*.jpg'));
    checkers = cell(length(D), 1);
    fprintf('Starting checker extraction from Left images.\n')
    for i = 1:length(D)
        [~, strName, ~] = fileparts(D(i).name);
        strName = str2double(strName);
        [~, FilePerms] = fileattrib(fullfile(D(i).folder, D(i).name));
        if FilePerms.UserRead
            I = imread(fullfile(D(i).folder, D(i).name));
            [imagePoints, Bsize] = detectCheckerboardPoints(I);
            if prod(Bsize == BoardSize)
               checkers{strName + 1, 1} =  imagePoints;
            end
        else
            fprintf('Read permission denied on image number: %s', D(i).name)
        end
        fprintf('Image %s of %d\n', D(i).name, length(D))
    end
end
end