# import skimage.io as io
# import skimage.transform as trans
import numpy as np
from keras.models import load_model
#from keras.layers import *
from keras.backend import clear_session
from scipy.io import savemat
import glob
import cv2
import numpy as np
from pathlib import Path
from array2gif import write_gif
from tensorflow import Graph, Session
import functools

def requireFrameSize(func):
    @functools.wraps(func)
    def wrapper(self, *args, **kwargs):
        # Do something before
        if self.frameW is None or self.frameH is None:
            raise ValueError("This method requires the segSpec to be initialized to the frame size using the initialize method")
        value = func(self, *args, **kwargs)
        # Do something after
        return value
    return wrapper

#import matplotlib.pyplot as plt

class SegSpec:
    # A class to hold all info about how to segment the parts of the image.

    # Offset anchor points - from which corner of image is mask part offset from?
    NW='nw'
    NE='ne'
    SW='sw'
    SE='se'

    # Provide a list of part names, and correspondingly indexed lists of part widths, heights, xOffsets, and yOffsets
    # Width or height entries may be None, which means the part extends the maximum distance to the edge of the frame
    # neuralNetworkPaths are a list of file paths leading to .h5 or .hd5 tensorflow trained neural network files
    def __init__(self, partNames=[], widths=[], heights=[], xOffsets=[], yOffsets=[], neuralNetworkPaths=[], offsetAnchors=[], frameW=None, frameH=None):
        N = len(partNames)

        self.frameW = frameW
        self.frameH = frameH

        # Fill incomplete parameters with default values
        xOffsets = xOffsets + [0    for k in range(N - len(xOffsets))]
        yOffsets = yOffsets + [0    for k in range(N - len(yOffsets))]
        widths   = widths   + [None for k in range(N - len(widths))]
        heights  = heights  + [None for k in range(N - len(heights))]
        offsetAnchors = offsetAnchors + [SegSpec.NW for k in range(N - len(offsetAnchors))]

        self._partNames = partNames                                                                                         # Names of parts of image to mask
        self._maskDims =        dict(zip(partNames, [list(dims) for dims in zip(widths, heights, xOffsets, yOffsets)]))     # Dimensions of masks
        self._networkPaths =    dict(zip(partNames, neuralNetworkPaths))                                                    # Paths to model files
        self._networks =        dict(zip(partNames, [None for k in partNames]))                                             # Loaded models
        self._graphs =          dict(zip(partNames, [None for k in partNames]))                                             # Separate tensorflow graphs for each model
        self._sessions =        dict(zip(partNames, [None for k in partNames]))                                             # Separate tensorflow sessions for each model
        xAnchors = []
        yAnchors = []
        for k, partName in enumerate(self._partNames):
            if   offsetAnchors[k] == SegSpec.NW:
                xAnchor = 1
                yAnchor = 1
            elif offsetAnchors[k] == SegSpec.NE:
                xAnchor = -1
                yAnchor = 1
            elif offsetAnchors[k] == SegSpec.SW:
                xAnchor = 1
                yAnchor = -1
            elif offsetAnchors[k] == SegSpec.SE:
                xAnchor = -1
                yAnchor = -1
            else:
                raise ValueError("Error - invalid offset anchor: {offsetAnchor}".format(offsetAnchor=offsetAnchors[k]))
            xAnchors.append(xAnchor)
            yAnchors.append(yAnchor)
            w, h, x, y = self._maskDims[partName]
            print("Got mask dims: (w + x) x (h + y) = ({w} + {x}) x ({h} + {y})".format(w=w, h=h, x=x, y=y))

        self._anchors = dict(zip(partNames, zip(xAnchors, yAnchors)))

    def _paramsValid(self):
        for partName in self._partNames:
            if None in self._maskDims[partName]:
                return (False, 'Uninitialized mask dimension')
            w, h, x, y = self._maskDims[partName]
            if self.frameW is not None and self.frameH is not None:
                if (x+w > self.frameW) or (y+h > self.frameH):
                    return (False, 'Mask does not fit in frame')
        return (True, '')

    def getPartNames(self):
        return self._partNames

    def getNetworkPath(self, partName):
        return self._networkPaths[partName]

    def getNetwork(self, partName):
        return self._networks[partName]

    def getSize(self, partName):
        return self._maskDims[partName][0:2]

    def getWidth(self, partName):
        return self._maskDims[partName][0]

    @requireFrameSize
    def getXLim(self, partName):
        w, _, x, _ = self._maskDims[partName]
        xA, _ = self._anchors[partName]
        if xA == 1:
            xLim = [x, x+w]
        else:
            xLim = [self.frameW - (x+w), self.frameW - x]
        return xLim

    def getYLim(self, partName):
        _, h, _, y = self._maskDims[partName]
        _, yA = self._anchors[partName]
        if yA == 1:
            yLim = [y, y+h]
        else:
            yLim = [self.frameH - (y+h), self.frameH - y]
        return yLim

    def getXSlice(self, partName):
        return slice(*self.getXLim(partName))

    def getYSlice(self, partName):
        return slice(*self.getYLim(partName))

    def getHeight(self, partName):
        return self._maskDims[partName][1]

    def getXOffset(self, partName):
        return self._maskDims[partName][2]

    def getYOffset(self, partName):
        return self._maskDims[partName][3]

    def initialize(self, vcap):
        # Initialize segspec with video information, so we can give more informed output
        self.frameW = int(vcap.get(cv2.CAP_PROP_FRAME_WIDTH))
        self.frameH = int(vcap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        print('Got frame size from video: {w} x {h}'.format(w=self.frameW, h=self.frameH))
        for partName in self._maskDims:
            [w, h, x, y] = self._maskDims[partName]
            if w is None:
                w = self.frameW - x
            if h is None:
                h = self.frameH - y
            self._maskDims[partName] = [w, h, x, y]
        valid, reason = self._paramsValid()
        if not valid:
            raise ValueError(reason)

    def initializeNetworks(self, partNames=None, loadShape=True, overwriteShape=False):
        # Initialize segspec networks and get width/height info from networks
        clear_session()
        if partNames is None:
            partNames = self._networkPaths.keys()
        for partName in partNames:
            self._graphs[partName] = Graph()
            with self._graphs[partName].as_default():
                self._sessions[partName] = Session()
                with self._sessions[partName].as_default():
                    self._networks[partName] = load_model(self._networkPaths[partName])
                    if loadShape:
                        # Load width and height based on neural network input shapes
                        try:
                            _, h, w, _ = self._networks[partName].input_shape
                            print('Got mask shape from neural network: {w} x {h}'.format(w=w, h=h))
                        except:
                            # Loading shape from neural network failed
                            print('Was not able to load mask shape from neural network')
                            w = None
                            h = None
                        if w is not None and (overwriteShape or (self._maskDims[partName][0] is None)):
                            # We got a width from the network, and either we're overwriting width, or width was not specified.
                            self._maskDims[partName][0] = w
                        if h is not None and (overwriteShape or (self._maskDims[partName][1] is None)):
                            # We got a height from the network, and either we're overwriting height, or height  was not specified.
                            self._maskDims[partName][1] = h
        valid, reason = self._paramsValid()
        if not valid:
            raise ValueError(reason)

    def predict(self, partName, imageBuffer):
        if self._networks[partName] is None:
            raise ValueError("Networks must be intialized before predicting")
        with self._graphs[partName].as_default():
            with self._sessions[partName].as_default():
                return self._networks[partName].predict(imageBuffer)

def segmentVideo(videoPath=None, segSpec=None, maskSaveDirectory=None, videoIndex=None, binaryThreshold=0.3, generatePreview=True, skipExisting=False):
    # Save one or more predicted mask files for a given video and segmenting neural network
    #   videoPath: The path to the video file in question
    #   segSpec: a SegSpec object, which defines how to split the image up into parts to do separate segmentations
    #   maskSaveDirectory: The directory in which to save the completed binary mask predictions
    #   videoIndex: An integer indicating which video this is in the series of videos. This will be used to number the output masks
    if None in [videoPath, segSpec, maskSaveDirectory, videoIndex]:
        raise ValueError('Missing argument')

    if type(videoPath) != type(str()):
        videoPath = str(videoPath)

    if skipExisting:
        # Check if masks already exist
        savePaths = [getMaskSavePath(partName, videoIndex, maskSaveDirectory) for partName in segSpec.getPartNames()]
        pathsExist = [p.exists() for p in savePaths]
        if all(pathsExist):
            # All masks have already been created - skip!
            return

    # Open video for reading
    cap = cv2.VideoCapture(videoPath)
#   This appears to not be necessary?
#    cap.open()

    nFrames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    # Initialize segSpec with video file:
    segSpec.initialize(cap)

    # Prepare video buffer arrays to receive data
    imageBuffers = {}
    for partName in segSpec.getPartNames():
        imageBuffers[partName] = np.zeros((nFrames,segSpec.getHeight(partName),segSpec.getWidth(partName),1))

    k=0
    while(True):
        # Read frame from video
        ret,frame = cap.read()
        if ret == True:
            for partName in segSpec.getPartNames():
                # Get info on how to separate the frame into parts
                xS = segSpec.getXSlice(partName)
                yS = segSpec.getYSlice(partName)
                # Write the frame part into the video buffer array
                imageBuffers[partName][k, :, :, :] = frame[yS, xS, 1].reshape(1, segSpec.getHeight(partName), segSpec.getWidth(partName), 1)
            k = k+1
        # Break the loop
        else:
            break

    cap.release()

    gifSaveTemplate = "{partName}.gif"

    # Make predictions and save to disk
    maskPredictions = {}
    for partName in segSpec.getPartNames():
        print('Making prediction for {partName}'.format(partName=partName))
        # Convert image to uint8
        imageBuffers[partName] = imageBuffers[partName].astype(np.uint8)
        # Create predicted mask and threshold to make it binary
        maskPredictions[partName] = segSpec.predict(partName, imageBuffers[partName]) > binaryThreshold
        # Generate save name for mask
        savePath = getMaskSavePath(partName, videoIndex, maskSaveDirectory)
        # Generate gif of the latest mask for monitoring purposes
        if generatePreview:
            try:
                gifSaveName = gifSaveTemplate.format(partName=partName)
                gifSavePath = Path(maskSaveDirectory) / gifSaveName
                spaceSkip = 3; timeSkip = 15
                gifData = maskPredictions[partName][::timeSkip, ::spaceSkip, ::spaceSkip, 0].astype('uint8') * 255
                gifData = np.stack([gifData, gifData, gifData])
                gifData = [gifData[:, k, :, :] for k in range(gifData.shape[1])]
                write_gif(gifData, gifSavePath, fps=40)
            except:
                print("Mask preview creation failed.")

        # Save mask to disk
        savemat(savePath,{'mask_pred':maskPredictions[partName]}, do_compression=True)

def getMaskSavePath(partName, videoIndex, maskSaveDirectory):
    maskSaveName = "{partName}_{index:03d}.mat".format(partName=partName, index=videoIndex)
    savePath = Path(maskSaveDirectory) / maskSaveName
    return savePath
