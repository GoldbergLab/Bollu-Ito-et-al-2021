function [ message ] = PhGetErrorMessage( errCode )

%suppose we do not have more than 4k of text in the errorMsg
messageBuffer = blanks(PhConConst.MAXERRMESS);
[HRES, message] = calllib('phcon', 'PhGetErrorMessage', errCode, messageBuffer);

end

