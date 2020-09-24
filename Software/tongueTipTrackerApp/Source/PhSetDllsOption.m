function [ HRES ] = PhSetDllsOption( optionSelector, pValue )
%pValue - libpointer to the value for option selector

[HRES dummy] = calllib('phcon','PhSetDllsOption', optionSelector, pValue);

end

