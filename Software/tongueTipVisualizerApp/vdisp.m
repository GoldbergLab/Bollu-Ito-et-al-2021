function vdisp(var, recurseDepth, maxLines)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% vdisp: A function to quickly display variable types, sizes, and structures
% usage:  vdisp(var)
%         vdisp(var, recurseDepth)
%         vdisp(var, recurseDepth, maxLines)
%
% where,
%    var is the variable to describe
%    recurseDepth is how many layers deep to go into the variable structure
%    maxLines is the # of lines to display for each recurse level before
%       abbreviating
%
% This is a way to display a flexible, detailed summary of a variable's
%   type, size, contents, and structure. This function wraps vinfo to avoid
%   having to call 'disp' on the output of 'vinfo'.
%
% See also: vinfo
% Version: <version>
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('recurseDepth', 'var')
    recurseDepth = 2;
end
if ~exist('maxLines', 'var')
    maxLines = -1;
end

indentLevel = 0;
varName = inputname(1);
showIntro = true;
suppressInitialIndent = false;

disp(vinfo(var, recurseDepth, maxLines, indentLevel, varName, showIntro, suppressInitialIndent))