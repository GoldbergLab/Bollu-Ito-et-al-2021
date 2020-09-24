function arrays = dealArray(arr, numChunks)
arrSize = numel(arr);
chunkSize = floor(arrSize/numChunks);
numLeftOvers = arrSize - chunkSize * numChunks;
numSmallChunks = numChunks - numLeftOvers;
numLargeChunks = numLeftOvers;
arrays = {};
for k = 1:numLargeChunks
    arrays = [arrays, arr((k-1)*(chunkSize+1)+1:k*(chunkSize+1))];
end
baseIndex = k*(chunkSize+1);
for k = 1:numSmallChunks
    arrays = [arrays, arr(baseIndex + (k-1)*chunkSize+1:baseIndex + k*chunkSize)];
end
if numel(arrays) < numChunks
    arrays{numChunks} = [];
end