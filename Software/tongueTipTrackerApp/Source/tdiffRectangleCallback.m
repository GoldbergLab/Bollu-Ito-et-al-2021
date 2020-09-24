function tdiffRectangleCallback(rectangle, event)
% This is a callback function for the time-alignment rectangles in
% tongueTipTrackerApp.mlapp.

currentSeries = rectangle.UserData.series;
ax = rectangle.Parent;
f = ax.Parent;
if ~isempty(ax.UserData.selectedRectangle)
    % Deselect previously selected rectangle, if any
    ax.UserData.selectedRectangle.(currentSeries).FaceColor = f.UserData.faceColors.(currentSeries);
    ax.UserData.selectedRectangle.(currentSeries) = [];
end
% Make rectangle the selected rectangle
rectangle.FaceColor = [1, 0, 0];
ax.UserData.selectedRectangle.(currentSeries) = rectangle;
% Shift all rectangles in that session/series
rectangles = ax.UserData.rectangles.(currentSeries);
ax.UserData.StartingTrialNum.(currentSeries) = rectangle.UserData.trialNum;
seriesShift = ax.UserData.t.(currentSeries)(ax.UserData.StartingTrialNum.(currentSeries));
for trialNum = 1:numel(rectangles)
    newPosition = [ax.UserData.t.(currentSeries)(trialNum) - seriesShift, f.UserData.yVal.(currentSeries), ax.UserData.tdiff.(currentSeries)(trialNum), f.UserData.h];
    rectangles(trialNum).Position = newPosition;
end