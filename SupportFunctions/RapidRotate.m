function op = RapidRotate(varargin)
% RapidRotate Rotate vectors and matrices.
% If both inputs are matrices, the function assumes they are rotation
% matrices and multiples them. Note that MATLAB follows row major
% formatting. Hence, rotation matrices should be postmultiplied. That is,
% the op R = R1XR2. If either of the input is a vector, it assumes that
% rows corresponds to different vectors.

if length(varargin) == 3
    input_1 = varargin{1};
    input_2 = varargin{2};
    str = varargin{3};
elseif length(varargin) == 2
    input_1 = varargin{1};
    str = varargin{2};
end
switch str
    case 'mm'
        if size(input_1, 3) == size(input_2, 3)
            N = size(input_1, 3);
            op = arrayfun(@(i) input_1(:, :, i)*input_2(:, :, i), 1:N, ...
                'UniformOutput', 0);
            op = cell2mat(reshape(op, [1, 1, N]));
        elseif size(input_2, 3) ~= 1 && size(input_1, 3) == 1
            N = size(input_2, 3);
            op = arrayfun(@(i) input_1*input_2(:, :, i), 1:N, ...
                'UniformOutput', 0);
            op = cell2mat(reshape(op, [1, 1, N]));
        elseif size(input_2, 3) == 1 && size(input_1, 3) ~= 1
            N = size(input_1, 3);
            op = arrayfun(@(i) input_1(:, :, i)*input_2, 1:N, ...
                'UniformOutput', 0);
            op = cell2mat(reshape(op, [1, 1, N]));
        end
    case 'vm'
        if size(input_2, 3) == 1
            op = input_1*input_2;
        elseif size(input_1, 1) == size(input_2, 3)
            N = size(input_2, 3);
            op = arrayfun(@(i) input_1(i, :)*input_2(:, :, i), 1:N, ...
                'UniformOutput', 0);
            op = cell2mat(op(:));
        elseif size(input_1, 1) == 1
            N = size(input_2, 3);
            op = arrayfun(@(i) input_1*input_2(:, :, i), 1:N, ...
                'UniformOutput', 0);
            op = cell2mat(op(:));
        end
    case 'mv'
        if size(input_1, 3) == 1
            op = input_2*input_1;
        elseif size(input_2, 1) == size(input_1, 3)
            N = size(input_1, 3);
            op = arrayfun(@(i) input_2(i, :)*input_1(:, :, i), 1:N, ...
                'UniformOutput', 0);
            op = cell2mat(op(:));
        elseif size(input_2, 1) == 1
            N = size(input_1, 3);
            op = arrayfun(@(i) input_2*input_1(:, :, i), 1:N, ...
                'UniformOutput', 0);
            op = cell2mat(op(:));
        end
    case 'inv'
        N = size(input_1, 3);
        op = arrayfun(@(i) transpose(input_1(:, :, i)), 1:N, ...
            'UniformOutput', 0);
        op = cell2mat(reshape(op, [1, 1, N]));
end