function parsave(filename, varstruct)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% parsave: parallelizable version of save
% usage:  parsave(fname, varstruct)
%
% where,
%    filename is a char array representing the filename to save the
%       variables to
%    varstruct is a structure containing the variables to be saved
%
% MATLAB's "save" function is not parallelizable - it can't be used in a
%   parallel worker. This function can. Pass in a structure ('varstruct')
%   containing the variables to be saved. Note that the structure itself
%   will not be saved, but each field of the structure will be saved as a
%   separate variable.
%
% See also: save

% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

save(filename, '-struct', 'varstruct');