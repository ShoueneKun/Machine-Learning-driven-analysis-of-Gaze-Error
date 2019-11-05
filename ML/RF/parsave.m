function [] = parsave(varargin)
%PARSAVE Enables saving in a parfor loop
%   This function ensure there is no variable lock and save functions
%   operate within the parallel computing framework.
fName = varargin{1};
savestruct = cell2struct(varargin{3:2:end}, varargin{2:2:end}, 2);
save(fName, '-struct', 'savestruct', '-v7.3')
end

