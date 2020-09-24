from waitress import serve
from wsgi_basic_auth import BasicAuth
import os
if os.name == 'nt':
    import win32net
import traceback
import logging
import datetime as dt
import time
import sys
from subprocess import Popen, PIPE
import urllib
import requests
from pathlib import Path, PureWindowsPath, PurePosixPath
import fnmatch
from ServerJob import ServerJob
from TongueSegmentation import SegSpec
import queue
import numpy as np
from scipy.io import loadmat
import json
from collections import OrderedDict as odict
import multiprocessing as mp
import itertools
from base64 import b64decode
import json
from webob import Request
import re

# Tensorflow barfs a ton of debug output - restrict this to only warnings/errors
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '1'

def initializeLogger():
    logger = logging.getLogger(__name__)

    # create logger with 'spam_application'
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    # create file handler which logs even debug messages
    datetimeString = dt.datetime.now().strftime('%Y-%m-%d_%H-%M-%S.%f')
    fh = logging.FileHandler('./{logs}/{n}_{d}.log'.format(d=datetimeString, n=__name__, logs=LOGS_SUBFOLDER))
    fh.setLevel(logging.INFO)
    # create console handler with a higher log level
    # ch = logging.StreamHandler(stream=sys.stdout)
    # ch.setLevel(logging.DEBUG)
    # create formatter and add it to the handlers
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    fh.setFormatter(formatter)
    # ch.setFormatter(formatter)
    # add the handlers to the logger
    logger.addHandler(fh)
    # logger.addHandler(ch)
    return logger

NEURAL_NETWORK_EXTENSIONS = ['.h5', '.hd5']
NETWORKS_SUBFOLDER = 'networks'
LOGS_SUBFOLDER = 'logs'
STATIC_SUBFOLDER = 'static'
ROOT = '.'
PRIVATE_FOLDER = 'private'

DEFAULT_TOP_NETWORK_NAME="lickbot_net_9952_loss0_0111_09262018_top.h5"
DEFAULT_BOT_NETWORK_NAME="lickbot_net_9973_loss_0062_10112018_scale3_Bot.h5"

HTML_DATE_FORMAT='%Y-%m-%d %H:%M:%S'
ROOT_PATH = Path(ROOT)
NETWORKS_FOLDER = ROOT_PATH / NETWORKS_SUBFOLDER
LOGS_FOLDER = ROOT_PATH / LOGS_SUBFOLDER
STATIC_FOLDER = ROOT_PATH / STATIC_SUBFOLDER
REQUIRED_SUBFOLDERS = [NETWORKS_FOLDER, LOGS_FOLDER, STATIC_FOLDER]
for reqFolder in REQUIRED_SUBFOLDERS:
    if not reqFolder.exists():
        logger.log(logging.INFO, 'Creating required directory: {reqDir}'.format(reqDir=reqFolder))
        reqFolder.mkdir()

AUTH_FILE = PRIVATE_FOLDER / Path('Auth.json')

logger = initializeLogger()

def validPassword(password):
    valid = re.search('[a-zA-Z]', password) is not None and re.search('[0-9]', password) is not None and len(password) >= 6 and len(password) <= 15
    return valid

def changePassword(user, currentPass, newPass):
    reason = None
    passwordChanged = False
    if USERS[user] == currentPass:
        # Authentication succeeded
        if validPassword(newPass):
            USERS[user] = newPass
            userData = {U:(USERS[U], USER_LVLS[U]) for U in USERS}
            with open(AUTH_FILE, 'w') as f:
                f.write(json.dumps(userData))
                passwordChanged = True
        else:
            reason = "Password must be 6 - 15 characters with at least one number and one letter"
    else:
        reason = "Current password incorrect"
    return passwordChanged, reason


def loadAuth():
    try:
        with open(AUTH_FILE, 'r') as f:
            userData = json.loads(f.read())
    except:
        logger.log(logging.ERROR, "Error loading authentication file")
        sys.exit()
    users = dict((user, userData[user][0]) for user in userData)
    user_lvls = dict((user, userData[user][1]) for user in userData)
    logger.log(logging.INFO, "Authentication reloaded.")
    return users, user_lvls

USERS, USER_LVLS = loadAuth()

BASE_USER='glab'
ADMIN_USER='admin'

# How often monitoring pages auto-reload, in ms
AUTO_RELOAD_INTERVAL=5000

def isWriteAuthorized(user, owner):
    # Check if user is authorized to modify/terminate owner's job
    userLvl = USER_LVLS[user]
    ownerLvl = USER_LVLS[owner]
    return (user == owner) or (userLvl > ownerLvl)
def isAdmin(user):
    # Check if user has at least lvl 2 privileges
    return USER_LVLS[user] >= 2

# Set environment variables for authentication
# envVars = dict(os.environ)  # or os.environ.copy()
# try:
#     envVars['WSGI_AUTH_CREDENTIALS']='{UN}:{PW}'.format(UN=USER, PW=PASSWORD)
# finally:
#     os.environ.clear()
#     os.environ.update(envVars)

def reRootDirectory(rootMountPoint, pathStyle, directory):
    #   rootMountPoint - the root of the videoDirs. If videoDirs contains a drive root, replace it.
    #   directories - a list of strings representing directory paths to re-root
    #   pathStyle - the style of the videoDirs paths - either 'windowsStyle' or 'posixStyle'

    reRootedDirectory = []
    if pathStyle == 'windowsStylePaths':
        OSPurePath = PureWindowsPath
    elif pathStyle == 'posixStylePaths':
        OSPurePath = PurePosixPath
    else:
        raise ValueError('Invalid path style: {pathStyle}'.format(pathStyle=pathStyle))

    directoryPath = OSPurePath(directory)
    if directoryPath.parts[0] == directoryPath.anchor:
        # This path includes the root - remove it.
        rootlessDirectoryPathParts = directoryPath.parts[1:]
    else:
        rootlessDirectoryPathParts = directoryPath.parts
    reRootedDirectory = Path(rootMountPoint) / Path(*rootlessDirectoryPathParts)
    return reRootedDirectory

def getVideoList(videoDirs, videoFilter='*'):
    # Generate a list of video Path objects from the given directories using the given path filters
    #   videoDirs - a list of strings representing video directory paths to look in
    #   pathStyle - the style of the videoDirs paths - either 'windowsStyle' or 'posixStyle'
    videoList = []
    for p in videoDirs:
        for videoPath in p.iterdir():
            if videoPath.suffix.lower() == ".avi":
                if videoPath.match(videoFilter):
                    videoList.append(videoPath)
    return videoList

def getUsername(environ):
    request = Request(environ)
    auth = request.authorization
    if auth and auth[0] == 'Basic':
        credentials = b64decode(auth[1]).decode('UTF-8')
        username, password = credentials.split(':', 1)
    return username

def addMessage(environ, message):
    environ["segserver.message"] = message

class UpdaterDaemon(mp.Process):
    def __init__(self,
                *args,
                interval=5,             # Time in seconds to wait between update requests
                port=80,                # Port to send request to
                host="localhost",       # Host to send request to
                url="/updateQueue",     # Relative URL for triggering queue update
                **kwargs):
        mp.Process.__init__(self, *args, daemon=True, **kwargs)
        self.fullURL = "http://{host}:{port}{url}".format(host=host, port=port, url=url)
        logger.log(logging.INFO, "UpdaterDaemon ready with update url {url}".format(url=self.fullURL))
        self.interval = interval

        # # create a password manager
        # password_mgr = urllib.request.HTTPPasswordMgrWithDefaultRealm()
        # # Add the username and password.
        # # If we knew the realm, we could use it instead of None.
        # top_level_url = "http://{host}/".format(host=host)
        # password_mgr.add_password(None, top_level_url, USER, PASSWORD)
        # handler = urllib.request.HTTPBasicAuthHandler(password_mgr)
        #
        # # create "opener" (OpenerDirector instance)
        # self.opener = urllib.request.build_opener(handler)

    def run(self):
        while True:
            r = requests.get(self.fullURL, auth=(BASE_USER, USERS[BASE_USER]))
            # # use the opener to fetch a URL
            # self.opener.open(self.fullURL)
            # urllib.request.urlopen(self.fullURL)
            time.sleep(self.interval)

class SegmentationServer:
    newJobNum = itertools.count().__next__   # Source of this clever little idea: https://stackoverflow.com/a/1045724/1460057
    def __init__(self, port=80, webRoot='.'):
        self.port = port
        self.routes = [
            ('/static/*',           self.staticHandler),
            ('/finalizeJob',        self.finalizeJobHandler),
            ('/confirmJob/*',       self.confirmJobHandler),
            ('/checkProgress/*',    self.checkProgressHandler),
            ('/updateQueue',        self.updateJobQueueHandler),
            ('/cancelJob/*',        self.cancelJobHandler),
            ('/serverManagement',   self.serverManagementHandler),
            ('/restartServer',      self.restartServerHandler),
            ('/maskPreview/*',      self.getMaskPreviewHandler),
            ('/myJobs',             self.myJobsHandler),
            ('/help',               self.helpHandler),
            ('/changePassword',     self.changePasswordHandler),
            ('/finalizePassword',   self.finalizePasswordHandler),
            ('/reloadAuth',         self.reloadAuthHandler),
            ('/',                   self.rootHandler)
        ]
        self.webRootPath = Path(webRoot).resolve()
        self.maxActiveJobs = 1          # Maximum # of jobs allowed to be running at once
        self.jobQueue = odict()         # List of job parameters for waiting jobs

        self.startTime = dt.datetime.now()

        self.cleanupTime = 86400        # Number of seconds to wait before deleting finished/dead jobs

        self.basic_auth_app = None

        # Start daemon that periodically makes http request that prompts server to update its job queue
        self.updaterDaemon = UpdaterDaemon(interval=3, port=self.port)
        self.updaterDaemon.start()

    def __call__(self, environ, start_fn):
        # Handle routing
        for path, handler in self.routes:
            if fnmatch.fnmatch(environ['PATH_INFO'], path):
                logger.log(logging.DEBUG, 'Matched url {path} to route {route} with handler {handler}'.format(path=environ['PATH_INFO'], route=path, handler=handler))
                return handler(environ, start_fn)
        return self.invalidHandler(environ, start_fn)

    def linkBasicAuth(self, basic_auth_app):
        # Link auth app to allow for dynamic changes in authentication
        self.basic_auth_app = basic_auth_app

    def reloadPasswords(self):
        USERS, USER_LVLS = loadAuth()
        self.basic_auth_app._users = USERS

    def formatHTML(self, environ, templateFilename, **parameters):
        # Check to see if we should be putting up an alert
        if 'segserver.message' in environ:
            message = environ['segserver.message']
        else:
            message = ''

        with open('NavBar.html', 'r') as f:
            navBarHTML = f.read()
            jobsRemaining = self.countJobsRemaining()
            videosRemaining = self.countVideosRemaining()
            if jobsRemaining > 0 and videosRemaining > 0:
                serverStatus = "Status: {jobsRemaining} jobs, {videosRemaining} videos".format(jobsRemaining=jobsRemaining, videosRemaining=videosRemaining)
            else:
                serverStatus = "Status: idle"
            user = getUsername(environ)
            navBarHTML = navBarHTML.format(user=user, serverStatus=serverStatus)
        with open('HeadLinks.html', 'r') as f:
            headLinksHTML = f.read()
            headLinksHTML = headLinksHTML.format(message=message)

        with open(templateFilename, 'r') as f:
            htmlTemplate = f.read()
            html = htmlTemplate.format(
                navBarHTML=navBarHTML,
                headLinksHTML=headLinksHTML,
                **parameters
            )
        return [html.encode('utf-8')]

    def formatError(self, environ, errorTitle='Error', errorMsg='Unknown error!', linkURL='/', linkAction='retry job creation'):
        return self.formatHTML(environ, 'Error.html', errorTitle=errorTitle, errorMsg=errorMsg, linkURL=linkURL, linkAction=linkAction)

    def getMountList(self, includePosixLocal=False):
        mounts = {}
        if os.name == 'nt':
            # Get a list of drives
            resume = 0
            while 1:
                (_drives, total, resume) = win32net.NetShareEnum (None, 2, resume)
                for drive in _drives:
                    mounts[drive['netname']] = drive['path']
                if not resume: break

            # Add to that list the list of network shares
            resume = 0
            while 1:
                (_drives, total, resume) = win32net.NetUseEnum (None, 0, resume)
                for drive in _drives:
                    if drive['local']:
                        mounts[drive['remote']] = drive['local']
                if not resume: break
        elif os.name == 'posix':
            if includeLocal:
                mounts['Local'] = 'LOCAL'
    #        p = Popen('mount', stdout=PIPE, stderr=PIPE, shell=True)
            p = Popen("mount | awk '$5 ~ /cifs|drvfs/ {print $0}'", stdout=PIPE, stderr=PIPE, shell=True)
            stdout, stderr = p.communicate()
            mountLines = stdout.decode('utf-8').strip().split('\n')
            for mountLine in mountLines:
                elements = mountLine.split(' ')
                mounts[elements[0]] = elements[2]
            logger.log(logging.DEBUG, 'Got mount list: ' + str(mounts))
        else:
            # Uh oh...
            raise OSError('This software is only compatible with POSIX or Windows')
        return mounts

    def getNeuralNetworkList(self):
        # Generate a list of available neural networks
        p = Path('.') / NETWORKS_SUBFOLDER
        networks = []
        for item in p.iterdir():
            if item.suffix in NEURAL_NETWORK_EXTENSIONS:
                # This is a neural network file
                networks.append(item.name)
        return networks

    def createOptionList(self, optionValues, defaultValue=None, optionNames=None):
        if optionNames is None:
            optionNames = optionValues
        options = []
        for optionValue, optionName in zip(optionValues, optionNames):
            if optionValue == defaultValue:
                selected = "selected"
            else:
                selected = ""
            options.append('<option value="{v}" {s}>{n}</option>'.format(v=optionValue, n=optionName, s=selected))
        optionText = "\n".join(options)
        return optionText

    def staticHandler(self, environ, start_fn):
        URLparts = environ['PATH_INFO'].split('/')
        requestedStaticFileRelativePath = environ['PATH_INFO'].strip('/')

        if len(URLparts) < 2:
            logger.log(logging.ERROR, 'Could not find that static file: {p}'.format(p=requestedStaticFilePath))
            start_fn('404 Not Found', [('Content-Type', 'text/html')])
            with open('Error.html', 'r') as f: htmlTemplate = f.read()
            return [htmlTemplate.format(
                errorTitle='Static file not found',
                errorMsg='Static file {name} not found'.format(name=requestedStaticFileRelativePath),
                linkURL='/',
                linkAction='return to job creation page'
                ).encode('utf-8')]
        else:
            subfolder = environ['PATH_INFO'].split('/')[-2]

        logger.log(logging.DEBUG, 'Serving static file: {path}'.format(path=requestedStaticFileRelativePath))
        requestedStaticFilePath = self.webRootPath / requestedStaticFileRelativePath
        if requestedStaticFilePath.exists():
            logger.log(logging.DEBUG, 'Found that static file')
            if subfolder == "css":
                start_fn('200 OK', [('Content-Type', 'text/css')])
                with requestedStaticFilePath.open('r') as f:
                    return [f.read().encode('utf-8')]
            elif subfolder == "favicon":
                start_fn('200 OK', [('Content-Type', "image/x-icon")])
                with requestedStaticFilePath.open('rb') as f:
                    return [f.read()]
            elif subfolder == "images":
                type = requestedStaticFilePath.suffix.strip('.').lower()
                if type not in ['png', 'gif', 'bmp', 'jpg', 'jpeg', 'ico', 'tiff']:
                    start_fn('404 Not Found', [('Content-Type', 'text/html')])
                    return self.formatError(
                        environ,
                        errorTitle='Unknown image type',
                        errorMsg='Unknown image type: {type}'.format(type=type),
                        linkURL='/',
                        linkAction='return to job creation page (or use browser back button)'
                        )
                else:
                    # Convert some extensions to mime types
                    if type == 'jpg': type = 'jpeg'
                    if type in ['ico', 'cur']: type = 'x-icon'
                    if type == 'svg': type = 'svg+xml'
                    if type == 'tif': type = 'tiff'
                    start_fn('200 OK', [('Content-Type', "image/{type}".format(type=type))])
                    with requestedStaticFilePath.open('rb') as f:
                        return [f.read()]
        else:
            logger.log(logging.ERROR, 'Could not find that static file: {p}'.format(p=requestedStaticFilePath))
            start_fn('404 Not Found', [('Content-Type', 'text/html')])
            with open('Error.html', 'r') as f: htmlTemplate = f.read()
            return [htmlTemplate.format(
                errorTitle='Static file not found',
                errorMsg='Static file {name} not found'.format(name=requestedStaticFileRelativePath),
                linkURL='/',
                linkAction='return to job creation page'
                ).encode('utf-8')]

    def countJobsRemaining(self, beforeJobNum=None):
        activeJobsAhead = 0
        queuedJobsAhead = 0
        for jobNum in self.jobQueue:
            if beforeJobNum is not None and jobNum == beforeJobNum:
                # This is the specified job num - stop, don't count any more
                break
            if not self.isComplete(jobNum):
                if not self.isStarted(jobNum):
                    queuedJobsAhead += 1
                else:
                    activeJobsAhead += 1
        jobsAhead = queuedJobsAhead + activeJobsAhead
        return jobsAhead

    def countVideosRemaining(self, beforeJobNum=None):
        completedVideosAhead = 0
        queuedVideosAhead = 0
        for jobNum in self.jobQueue:
            if beforeJobNum is not None and jobNum == beforeJobNum:
                # This is the specified job num - stop, don't count any more
                break
            if self.jobQueue[jobNum]['completionTime'] is None:
                completedVideosAhead += len(self.jobQueue[jobNum]['completedVideoList'])
                queuedVideosAhead += len(self.jobQueue[jobNum]['videoList'])
        videosAhead = queuedVideosAhead - completedVideosAhead
        return videosAhead

    def finalizeJobHandler(self, environ, start_fn):
        # Display page showing what job will be, and offering opportunity to go ahead or cancel
        postDataRaw = environ['wsgi.input'].read().decode('utf-8')
        postData = urllib.parse.parse_qs(postDataRaw, keep_blank_values=False)

        try:
            rootMountPoint = postData['rootMountPoint'][0]
            videoDirs = postData['videoRoot'][0].strip().splitlines()
            videoFilter = postData['videoFilter'][0]
            maskSaveDirectory = postData['maskSaveDirectory'][0]
            pathStyle = postData['pathStyle'][0]
            topNetworkPath = NETWORKS_FOLDER / postData['topNetworkName'][0]
            botNetworkPath = NETWORKS_FOLDER / postData['botNetworkName'][0]
            binaryThreshold = float(postData['binaryThreshold'][0])
            topOffset = int(postData['topOffset'][0])
            if 'topHeight' not in postData or len(postData['topHeight'][0]) == 0:
                topHeight = None
            else:
                topHeight = int(postData['topHeight'][0])
            if 'topHeight' not in postData or len(postData['topHeight'][0]) == 0:
                botHeight = None
            else:
                botHeight = int(postData['botHeight'][0])
            if 'generatePreview' in postData:
                logger.log(logging.INFO, "generatePreview retrieved from form: {generatePreview}".format(generatePreview=postData['generatePreview'][0]))
                generatePreview = True
            else:
                generatePreview = False
            if 'skipExisting' in postData:
                logger.log(logging.INFO, "skipExisting retrieved from form: {skipExisting}".format(skipExisting=postData['skipExisting'][0]))
                skipExisting = True
            else:
                skipExisting = False
            jobName = postData['jobName'][0]
        except KeyError:
            # Missing one of the postData arguments
            start_fn('404 Not Found', [('Content-Type', 'text/html')])
            return self.formatError(
                environ,
                errorTitle='Missing parameter',
                errorMsg='A required field is missing. Please retry with all required fields filled in.',
                linkURL='/',
                linkAction='return to job creation page (or use browser back button)'
                )

        segSpec = SegSpec(
            partNames=['Bot', 'Top'],
            heights=[botHeight, topHeight],
            yOffsets=[0, topOffset],
            offsetAnchors=[SegSpec.SW, SegSpec.NW],
            neuralNetworkPaths=[botNetworkPath, topNetworkPath]
        )
        # Re-root directories
        reRootedVideoDirs = [reRootDirectory(rootMountPoint, pathStyle, videoDir) for videoDir in videoDirs]
        maskSaveDirectory = reRootDirectory(rootMountPoint, pathStyle, maskSaveDirectory)

        # Check if all parameters are valid. If not, display error and offer to go back
        valid = True
        errorMessages = []
        if not maskSaveDirectory.exists():
            valid = False
            errorMessages.append('Mask save directory not found: {maskSaveDirectory}. Hint: Did you pick the right root?'.format(maskSaveDirectory=maskSaveDirectory))
        for videoDir in reRootedVideoDirs:
            if not videoDir.exists():
                valid = False
                errorMessages.append('Video directory not found: {videoDir}'.format(videoDir=videoDir))
        # keys = ['rootMountPoint', 'videoRoot', 'videoFilter', 'maskSaveDirectory', 'pathStyle', 'topNetworkName', 'botNetworkName', 'topOffset', 'topHeight', 'botHeight', 'binaryThreshold', 'jobName']
        # missingKeys = [key for key in keys if key not in postData]
        # if len(missingKeys) > 0:
        #     # Not all form parameters got POSTed
        #     valid = False
        #     errorMessages.append('Job creation parameters missing: {params}'.format(params=', '.join(missingKeys)))

        if not valid:
            start_fn('404 Not Found', [('Content-Type', 'text/html')])
            return self.formatError(
                environ,
                errorTitle='Invalid job parameter',
                errorMsg="<br/>".join(errorMessages),
                linkURL='/',
                linkAction='return to job creation page (or use browser back button)'
                )

        # Generate list of videos
        videoList = getVideoList(reRootedVideoDirs, videoFilter=videoFilter)

        # Error out if no videos are found
        if len(videoList) == 0:
            start_fn('404 Not Found', [('Content-Type', 'text/html')])
            return self.formatError(
                environ,
                errorTitle='No videos found',
                errorMsg="No videos found with the given video root and filters. Please adjust the parameters, or upload videos, then try again.",
                linkURL='/',
                linkAction='return to job creation page (or use browser back button)'
                )

        # Add job parameters to queue
        jobNum = SegmentationServer.newJobNum()

        jobsAhead = self.countJobsRemaining(beforeJobNum=jobNum)
        videosAhead = self.countVideosRemaining(beforeJobNum=jobNum)

        self.jobQueue[jobNum] = dict(
            job=None,                               # Job process object
            jobName=jobName,                        # Name/description of job
            owner=getUsername(environ),             # Owner of job, has special privileges
            jobNum=jobNum,                          # Job ID
            confirmed=False,                        # Has user confirmed params yet
            cancelled=False,                        # Has the user cancelled this job?
            videoList=videoList,                    # List of video paths to process
            maskSaveDirectory=maskSaveDirectory,    # Path to save masks
            segSpec=segSpec,                        # segSpec
            generatePreview=generatePreview,        # Should we generate gif previews of masks?
            skipExisting=skipExisting,              # Should we skip generating masks that already exist?
            binaryThreshold=binaryThreshold,        # Threshold to use to change grayscale masks to binary
            completedVideoList=[],                  # List of processed videos
            times=[],                               # List of video processing start times
            creationTime=time.time_ns(),            # Time job was created
            startTime=None,                         # Time job was started
            completionTime=None,                    # Time job was completed
            log=[],                                 # List of log output from job
            exitCode=ServerJob.INCOMPLETE           # Job exit code
        )

        if topHeight is None:
            topHeightText = "Use network size"
        else:
            topHeightText = str(topHeight)
        if botHeight is None:
            botHeightText = "Use network size"
        else:
            botHeightText = str(botHeight)

        start_fn('200 OK', [('Content-Type', 'text/html')])
        return self.formatHTML(
            environ,
            'FinalizeJob.html',
            videoList="\n".join(["<li>{v}</li>".format(v=v) for v in videoList]),
            topNetworkName=topNetworkPath.name,
            botNetworkName=botNetworkPath.name,
            binaryThreshold=binaryThreshold,
            topOffset=topOffset,
            topHeight=topHeightText,
            botHeight=botHeightText,
            generatePreview=generatePreview,
            skipExisting=skipExisting,
            jobID=jobNum,
            jobName=jobName,
            jobsAhead=jobsAhead,
            videosAhead=videosAhead
        )

    def startJob(self, jobNum):
        self.jobQueue[jobNum]['job'] = ServerJob(
            verbose = 1,
            logger=logger,
            **self.jobQueue[jobNum]
            )

        logger.log(logging.INFO, 'Starting job {jobNum}'.format(jobNum=jobNum))
        self.jobQueue[jobNum]['job'].start()
        self.jobQueue[jobNum]['job'].msgQueue.put((ServerJob.START, None))
        self.jobQueue[jobNum]['job'].msgQueue.put((ServerJob.PROCESS, None))
        self.jobQueue[jobNum]['startTime'] = time.time_ns()

    def isConfirmed(self, jobNum):
        return self.jobQueue[jobNum]['confirmed']
    def isCancelled(self, jobNum):
        return self.jobQueue[jobNum]['cancelled']
    def isStarted(self, jobNum):
        return (self.jobQueue[jobNum]['job'] is not None) and (self.jobQueue[jobNum]['startTime'] is not None)
    def isActive(self, jobNum):
        return (self.isStarted(jobNum)) and (not self.isComplete(jobNum))
    def isComplete(self, jobNum):
        return (self.jobQueue[jobNum]['exitCode'] != ServerJob.INCOMPLETE) or (self.jobQueue[jobNum]['completionTime'] is not None)
    def isSucceeded(self, jobNum):
        return (self.jobQueue[jobNum]['exitCode'] == ServerJob.SUCCEEDED)
    def isFailed(self, jobNum):
        return (self.jobQueue[jobNum]['exitCode'] == ServerJob.FAILED)
    def isOwnedBy(self, jobNum, owner):
        return (self.jobQueue[jobNum]['owner'] == owner)
    def isEnqueued(self, jobNum):
        return self.isConfirmed(jobNum) and (not self.isStarted(jobNum)) and (not self.isCancelled(jobNum)) and (not self.isComplete(jobNum))

    def getJobNums(self, confirmed=None, started=None, active=None, completed=None, owner=None, succeeded=None, failed=None, cancelled=None):
        # For each filter argument, "None" means do not filter
        jobNums = []
        for jobNum in self.jobQueue:
            job = self.jobQueue[jobNum]
            # logger.log(logging.INFO, "Job {jobNum} checking for inclusion...".format(jobNum=jobNum))
            if   (owner is not None) and (not self.isOwnedBy(jobNum, owner)):
                # logger.log(logging.INFO, "Job {jobNum} rejected by owned filter".format(jobNum=jobNum))
                continue
            elif (confirmed is not None) and (confirmed != self.isConfirmed(jobNum)):
                # logger.log(logging.INFO, "Job {jobNum} rejected by confirmed filter".format(jobNum=jobNum))
                continue
            elif (active is not None) and (active != self.isActive(jobNum)):
                # logger.log(logging.INFO, "Job {jobNum} rejected by active filter".format(jobNum=jobNum))
                continue
            elif (completed is not None) and (completed != self.isComplete(jobNum)):
                # logger.log(logging.INFO, "Job {jobNum} rejected by completed filter".format(jobNum=jobNum))
                continue
            elif (succeeded is not None) and (succeeded != self.isSucceeded(jobNum)):
                # logger.log(logging.INFO, "Job {jobNum} rejected by succeeded filter".format(jobNum=jobNum))
                continue
            elif (failed is not None) and (failed != self.isFailed(jobNum)):
                # logger.log(logging.INFO, "Job {jobNum} rejected by failed filter".format(jobNum=jobNum))
                continue
            elif (started is not None) and (started != self.isStarted(jobNum)):
                # logger.log(logging.INFO, "Job {jobNum} rejected by started filter".format(jobNum=jobNum))
                continue
            # logger.log(logging.INFO, "Job {jobNum} accepted".format(jobNum=jobNum))
            jobNums.append(jobNum)
        return jobNums

    def confirmJobHandler(self, environ, start_fn):
        # Get jobNum from URL
        jobNum = int(environ['PATH_INFO'].split('/')[-1])
#        logger.log(logging.INFO, 'getJobNums(active=False, completed=False) - is job {jobNum} ready for confirming?'.format(jobNum=jobNum))
        if jobNum not in self.getJobNums(active=False, completed=False):
            # Invalid jobNum
            start_fn('404 Not Found', [('Content-Type', 'text/html')])
            return self.formatError(
                environ,
                errorTitle='Invalid job ID',
                errorMsg='Invalid job ID {jobID}'.format(jobID=jobNum),
                linkURL='/',
                linkAction='recreate job'
                )
        elif not isWriteAuthorized(getUsername(environ), self.jobQueue[jobNum]['owner']):
            # User is not authorized
            return self.unauthorizedHandler(environ, start_fn)
        else:
            # Valid enqueued job - set confirmed flag to True, so it can be started when at the front
            self.jobQueue[jobNum]['confirmed'] = True
        start_fn('303 See Other', [('Location','/checkProgress/{jobID}'.format(jobID=jobNum))])
        return []

    def removeJob(self, jobNum, waitingPeriod=0):
        # waitingPeriod = amount of time in seconds to wait after job completionTime before removing from queue
        expired = False
        if self.jobQueue[jobNum]['confirmed']:
            if self.jobQueue[jobNum]['completionTime'] is not None:
                if (time.time_ns() - self.jobQueue[jobNum]['completionTime']) / 1000000000 > waitingPeriod:
                    expired = True
        else:
            if self.jobQueue[jobNum]['creationTime'] is not None:
                if (time.time_ns() - self.jobQueue[jobNum]['creationTime']) / 1000000000 > waitingPeriod:
                    expired = True
            else:
                expire = True
                # Creation time should never be None
                raise ValueError('Job creation time should never be None')

        if expired:
            # Delete expired job
            logger.log(logging.INFO, 'Removing job {jobNum}'.format(jobNum=jobNum))
            del self.jobQueue[jobNum]

    def updateJobQueueHandler(self, environ, start_fn):
        # Handler for automated calls to update the queue
        self.updateJobQueue()

        # logger.log(logging.INFO, 'Got automated queue update reminder')
        #
        start_fn('200 OK', [('Content-Type', 'text/html')])
        return []

    def updateJobQueue(self):
        # Remove stale unconfirmed jobs:
#        logger.log(logging.INFO, "getJobNums(confirmed=False) - removing unconfirmed jobs")
        for jobNum in self.getJobNums(confirmed=False):
            self.removeJob(jobNum, waitingPeriod=self.cleanupTime)
        # Check if the current job is done. If it is, remove it and start the next job
#        logger.log(logging.INFO, "getJobNums(active=True) checking if active job is done")
        for jobNum in self.getJobNums(active=True):
            # Loop over active jobs, see if they're done, and pop them off if so
            job = self.jobQueue[jobNum]['job']
            jobState = job.publishedStateVar.value
            # Update progress
            self.updateJobProgress(jobNum)
#            jobStateName = ServerJob.stateList[jobState]
            if jobState == ServerJob.STOPPED:
                pass
            elif jobState == ServerJob.INITIALIZING:
                pass
            elif jobState == ServerJob.WAITING:
                pass
            elif jobState == ServerJob.WORKING:
                pass
            elif jobState == ServerJob.STOPPING:
                pass
            elif jobState == ServerJob.ERROR:
                pass
                # job.terminate()
                # self.removeJob(jobNum)
                # logger.log(logging.INFO, "Removing job {jobNum} in error state".format(jobNum=jobNum))
            elif jobState == ServerJob.EXITING:
                pass
            elif jobState == ServerJob.DEAD:
                self.jobQueue[jobNum]['completionTime'] = time.time_ns()
                self.removeJob(jobNum, waitingPeriod=self.cleanupTime)
                logger.log(logging.INFO, "Removing job {jobNum} in dead state".format(jobNum=jobNum))
            elif jobState == -1:
                pass

#        logger.log(logging.INFO, "getJobNums(active=True) - checking if room for new job")
        if len(self.getJobNums(active=True)) < self.maxActiveJobs:
            # Start the next job, if any
            # Loop over confirmed, inactive (queued) job nums
#            logger.log(logging.INFO, "getJobNums(active=False, confirmed=True) - looking for job to start")
            for jobNum in self.getJobNums(confirmed=True, started=False, completed=False):
                # This is the next queued confirmed job - start it
                self.startJob(jobNum)
                break;

    def updateJobProgress(self, jobNum):
        if jobNum in self.jobQueue and self.jobQueue[jobNum]['job'] is not None:
            while True:
                try:
                    progress = self.jobQueue[jobNum]['job'].progressQueue.get(block=False)
                    # Get any new log output from job
                    self.jobQueue[jobNum]['log'].extend(progress['log'])
                    # Get updated exit code from job
                    self.jobQueue[jobNum]['exitCode'] = progress['exitCode']
                    # Get the path to the last video the job has completed
                    if progress['lastCompletedVideoPath'] is not None:
                        self.jobQueue[jobNum]['completedVideoList'].append(progress['lastCompletedVideoPath'])
                    # Get the time when the last video started processing
                    if progress['lastProcessingStartTime'] is not None:
                        self.jobQueue[jobNum]['times'].append(progress['lastProcessingStartTime'])
                except queue.Empty:
                    # Got all progress
                    break

    def formatLogHTML(self, log):
        logHTMLList = []
        for logEntry in log:
            logHTMLList.append('<p>{logEntry}</p>'.format(logEntry=logEntry))
        logHTML = "\n".join(logHTMLList)
        return logHTML

    def getMaskPreviewHandler(self, environ, start_fn):
        # Get jobNum from URL
        jobNum = int(environ['PATH_INFO'].split('/')[-2])
        if jobNum not in self.jobQueue:
            # Invalid jobNum
            start_fn('404 Not Found', [('Content-Type', 'text/html')])
            return self.formatError(
                environ,
                errorTitle='Invalid job ID',
                errorMsg='Invalid job ID {jobID}'.format(jobID=jobNum),
                linkURL='/',
                linkAction='create a new job'
                )

        maskPart = environ['PATH_INFO'].split('/')[-1].lower()
        if maskPart == "top":
            preview = self.jobQueue[jobNum]['maskSaveDirectory'] / 'Top.gif'
        elif maskPart == "bot":
            preview = self.jobQueue[jobNum]['maskSaveDirectory'] / 'Bot.gif'
        else:
            # Invalid mask part
            start_fn('404 Not Found', [('Content-Type', 'text/html')])
            return self.formatError(
                environ,
                errorTitle='Invalid mask part',
                errorMsg='Invalid mask part: {maskPart}'.format(maskPart=maskPart),
                linkURL='/',
                linkAction='create a new job'
                )

        if not preview.exists():
            # Preview mask doesn't exist. Instead, serve a static placeholder gif
            environ['PATH_INFO'] = "/static/images/MaskPreviewPlaceholder.gif"
            return self.staticHandler(environ, start_fn)

        start_fn('200 OK', [('Content-Type', "image/gif")])
        with preview.open('rb') as f:
            return [f.read()]

    def checkProgressHandler(self, environ, start_fn):
        # Get jobNum from URL
        jobNum = int(environ['PATH_INFO'].split('/')[-1])
        allJobNums = self.getJobNums()
#        logger.log(logging.INFO, 'jobNum={jobNum}, allJobNums={allJobNums}, jobQueue={jobQueue}'.format(jobNum=jobNum, allJobNums=allJobNums, jobQueue=self.jobQueue))
        if jobNum not in allJobNums:
            # Invalid jobNum
            start_fn('404 Not Found', [('Content-Type', 'text/html')])
            return self.formatError(
                environ,
                errorTitle='Invalid job ID',
                errorMsg='Invalid job ID {jobID}'.format(jobID=jobNum),
                linkURL='/',
                linkAction='create a new job'
                )
        if self.jobQueue[jobNum]['job'] is not None:
            # Job has started. Check its state
            jobState = self.jobQueue[jobNum]['job'].publishedStateVar.value
            jobStateName = ServerJob.stateList[jobState]
            # Get all pending updates on its progress
            self.updateJobProgress(jobNum)
        else:
            # Job has not started
            jobStateName = "ENQUEUED"

        # Get some parameters about job ready for display
        binaryThreshold = self.jobQueue[jobNum]['binaryThreshold']
        maskSaveDirectory = self.jobQueue[jobNum]['maskSaveDirectory']
        segSpec = self.jobQueue[jobNum]['segSpec']
        topNetworkName = segSpec.getNetworkPath('Top').name
        botNetworkName = segSpec.getNetworkPath('Bot').name
        topOffset = segSpec.getYOffset('Top')
        topHeight = segSpec.getHeight('Top')
        botHeight = segSpec.getHeight('Bot')
        if topHeight is None:
            topHeightText = "Use network size"
        else:
            topHeightText = str(topHeight)
        if botHeight is None:
            botHeightText = "Use network size"
        else:
            botHeightText = str(botHeight)

        topMaskPreviewSrc = '/maskPreview/{jobNum}/top'.format(jobNum=jobNum)
        botMaskPreviewSrc = '/maskPreview/{jobNum}/bot'.format(jobNum=jobNum)

        creationTime = ""
        startTime = "Not started yet"
        completionTime = "Not complete yet"
        if self.jobQueue[jobNum]['creationTime'] is not None:
            creationTime = dt.datetime.fromtimestamp(self.jobQueue[jobNum]['creationTime']/1000000000).strftime(HTML_DATE_FORMAT)
        if self.jobQueue[jobNum]['startTime'] is not None:
            startTime = dt.datetime.fromtimestamp(self.jobQueue[jobNum]['startTime']/1000000000).strftime(HTML_DATE_FORMAT)
        if self.jobQueue[jobNum]['completionTime'] is not None:
            completionTime = dt.datetime.fromtimestamp(self.jobQueue[jobNum]['completionTime']/1000000000).strftime(HTML_DATE_FORMAT)

        numVideos = len(self.jobQueue[jobNum]['videoList'])
        numCompletedVideos = len(self.jobQueue[jobNum]['completedVideoList'])
        percentComplete = "{percentComplete:.1f}".format(percentComplete=100*numCompletedVideos/numVideos)
        if len(self.jobQueue[jobNum]['times']) > 1:
            deltaT = np.diff(self.jobQueue[jobNum]['times'])/1000000000
            meanTime = np.mean(deltaT)
            meanTimeStr = "{meanTime:.1f}".format(meanTime=meanTime)
            timeConfInt = np.std(deltaT)*1.96
            timeConfIntStr = "{timeConfInt:.1f}".format(timeConfInt=timeConfInt)
            if self.jobQueue[jobNum]['completionTime'] is None:
                estimatedSecondsRemaining = (numVideos - numCompletedVideos) * meanTime
                days, remainder = divmod(estimatedSecondsRemaining, 86400)
                hours, remainder = divmod(remainder, 3600)
                minutes, seconds = divmod(remainder, 60)
                if days > 0:
                    estimatedDaysRemaining = '{days} d, '.format(days=int(days))
                else:
                    estimatedDaysRemaining = ''
                if hours > 0 or days > 0:
                    estimatedHoursRemaining = '{hours} h, '.format(hours=int(hours))
                else:
                    estimatedHoursRemaining = ''
                if minutes > 0 or hours > 0 or days > 0:
                    estimatedMinutesRemaining = '{minutes} m, '.format(minutes=int(minutes))
                else:
                    estimatedMinutesRemaining = ''
                estimatedSecondsRemaining = '{seconds} s'.format(seconds=int(seconds))
                estimatedTimeRemaining = estimatedDaysRemaining + estimatedHoursRemaining + estimatedMinutesRemaining + estimatedSecondsRemaining
            else:
                estimatedTimeRemaining = "None"
        else:
            meanTime = 0
            meanTimeStr = "Unknown"
            timeConfInt = 0
            timeConfIntStr = "Unknown"
            estimatedTimeRemaining = "Unknown"

        completedVideoListHTML = "\n".join(["<li>{v}</li>".format(v=v) for v in self.jobQueue[jobNum]['completedVideoList']])
        if len(completedVideoListHTML.strip()) == 0:
            completedVieoListHTML = "None"

        exitCode = self.jobQueue[jobNum]['exitCode']
        stateDescription = ''
        processDead = "true"
        if exitCode == ServerJob.INCOMPLETE:
            processDead = "false"
            if not self.isStarted(jobNum):
                jobsAhead = self.countJobsRemaining(beforeJobNum=jobNum)
                videosAhead = self.countVideosRemaining(beforeJobNum=jobNum)
                if self.isCancelled(jobNum):
                    exitCodePhrase = 'has been cancelled.'
                    stateDescription = 'This job has been cancelled.'
                elif self.isConfirmed(jobNum):
                    exitCodePhrase = 'is enqueued, but not started.'
                    stateDescription = '<br/>There are <strong>{jobsAhead} jobs</strong> \
                                        ahead of you with <strong>{videosAhead} total videos</strong> \
                                        remaining. Your job will be enqueued to start as soon \
                                        as any/all previous jobs are done.'.format(jobsAhead=jobsAhead, videosAhead=videosAhead)
                else:
                    exitCodePhrase = 'has not been confirmed yet. <form action="/confirmJob/{jobID}"><input class="button button-primary" type="submit" value="Confirm and enqueue job" /></form>'.format(jobID=jobNum)
                    stateDescription = '<br/>There are <strong>{jobsAhead} jobs</strong> \
                                        ahead of you with <strong>{videosAhead} total videos</strong> \
                                        remaining. Your job will be enqueued after you confirm it.'
            else:
                if self.isCancelled(jobNum):
                    exitCodePhrase = 'has been cancelled.'
                    stateDescription = 'This job has been cancelled, and will stop after the current video is complete. All existing masks will remain in place. Stand by...'
                else:
                    exitCodePhrase = 'is <strong>in progress</strong>!'
        elif self.isSucceeded(jobNum):
            if self.isCancelled(jobNum):
                exitCodePhrase = 'has been <strong>cancelled</strong>.'
            else:
                exitCodePhrase = 'is <strong>complete!</strong>'
        elif self.isFailed(jobNum):
            exitCodePhrase = 'has exited with errors :(  Please see debug output below.'
        else:
            exitCodePhrase = 'is in an unknown exit code state...'

        logHTML = self.formatLogHTML(self.jobQueue[jobNum]['log'])

        owner = self.jobQueue[jobNum]['owner']
        if owner == getUsername(environ):
            owner = owner + " (you)"

        generatePreview = self.jobQueue[jobNum]['generatePreview']
        if not generatePreview:
            hidePreview = "hidden"
        else:
            hidePreview = ""

        skipExisting = self.jobQueue[jobNum]['skipExisting']

        start_fn('200 OK', [('Content-Type', 'text/html')])
        with open('CheckProgress.html', 'r') as f: htmlTemplate = f.read()
        return self.formatHTML(
            environ,
            'CheckProgress.html',
            meanTime=meanTimeStr,
            confInt=timeConfIntStr,
            videoList=completedVideoListHTML,
            jobStateName=jobStateName,
            jobNum=jobNum,
            estimatedTimeRemaining=estimatedTimeRemaining,
            jobName=self.jobQueue[jobNum]['jobName'],
            owner=owner,
            creationTime=creationTime,
            startTime=startTime,
            completionTime=completionTime,
            exitCodePhrase=exitCodePhrase,
            logHTML=logHTML,
            percentComplete=percentComplete,
            numComplete=numCompletedVideos,
            numTotal=numVideos,
            stateDescription=stateDescription,
            processDead=processDead,
            binaryThreshold=binaryThreshold,
            maskSaveDirectory=maskSaveDirectory,
            topNetworkName=topNetworkName,
            botNetworkName=botNetworkName,
            topOffset=topOffset,
            topHeight=topHeightText,
            botHeight=botHeightText,
            generatePreview=generatePreview,
            skipExisting=skipExisting,
            topMaskPreviewSrc=topMaskPreviewSrc,
            botMaskPreviewSrc=botMaskPreviewSrc,
            autoReloadInterval=AUTO_RELOAD_INTERVAL,
            hidePreview=hidePreview
        )

    def rootHandler(self, environ, start_fn):
        logger.log(logging.INFO, 'Serving root file')
        neuralNetworkList = self.getNeuralNetworkList()
        mountList = self.getMountList(includePosixLocal=True)
        mountURIs = mountList.keys()
        mountPaths = [mountList[k] for k in mountURIs]
        mountOptionsText = self.createOptionList(mountPaths, optionNames=mountURIs, defaultValue='Z:')
        if 'QUERY_STRING' in environ:
            queryString = environ['QUERY_STRING']
        else:
            queryString = 'None'
        postDataRaw = environ['wsgi.input'].read().decode('utf-8')
        postData = urllib.parse.parse_qs(postDataRaw, keep_blank_values=False)

        logger.log(logging.INFO, 'Creating return data')

        username = getUsername(environ)

        if len(neuralNetworkList) > 0:
            topNetworkOptionText = self.createOptionList(neuralNetworkList, defaultValue=DEFAULT_TOP_NETWORK_NAME)
            botNetworkOptionText = self.createOptionList(neuralNetworkList, defaultValue=DEFAULT_BOT_NETWORK_NAME)
            start_fn('200 OK', [('Content-Type', 'text/html')])
            return self.formatHTML(
                environ,
                'Index.html',
                query=queryString,
                mounts=mountList,
                # environ=environ,
                input=postData,
                remoteUser=username,
                path=environ['PATH_INFO'],
                nopts_bot=botNetworkOptionText,
                nopts_top=topNetworkOptionText,
                mopts=mountOptionsText
                )
        else:
            start_fn('404 Not Found', [('Content-Type', 'text/html')])
            return self.formatError(
                environ,
                errorTitle='Neural network error',
                errorMsg='No neural networks found! Please upload a .h5 or .hd5 neural network file to the ./{nnsubfolder} folder.'.format(nnsubfolder=NETWORKS_SUBFOLDER),
                linkURL='/',
                linkAction='retry job creation once a neural network has been uploaded'
            )

    def cancelJobHandler(self, environ, start_fn):
        # Get jobNum from URL
        jobNum = int(environ['PATH_INFO'].split('/')[-1])
        if jobNum not in self.getJobNums():
            # Invalid jobNum
            start_fn('404 Not Found', [('Content-Type', 'text/html')])
            return self.formatError(
                environ,
                errorTitle='Invalid job ID',
                errorMsg='Invalid job ID {jobID}'.format(jobID=jobNum),
                linkURL='/',
                linkAction='recreate job'
            )
        elif jobNum in self.getJobNums(completed=True):
            # Job is already finished, can't cancel
            start_fn('404 Not Found', [('Content-Type', 'text/html')])
            return self.formatError(
                environ,
                errorTitle='Cannot terminate completed job',
                errorMsg='Can\'t terminate job {jobID} because it has already finished processing.'.format(jobID=jobNum),
                linkURL='/',
                linkAction='create a new job'
            )
        elif not isWriteAuthorized(getUsername(environ), self.jobQueue[jobNum]['owner']):
            # User is not authorized
            return self.unauthorizedHandler(environ, start_fn)
        else:
            # Valid enqueued job - set cancelled flag to True, and
            logger.log(logging.INFO, 'Cancelling job {jobNum}'.format(jobNum=jobNum))
            self.jobQueue[jobNum]['cancelled'] = True
            now = time.time_ns()
            if self.jobQueue[jobNum]['creationTime'] is None:
                self.jobQueue[jobNum]['creationTime'] = now
            # if self.jobQueue[jobNum]['startTime'] is None:
            #     self.jobQueue[jobNum]['startTime'] = now
            self.jobQueue[jobNum]['completionTime'] = now
            if self.jobQueue[jobNum]['job'] is not None:
                self.jobQueue[jobNum]['job'].msgQueue.put((ServerJob.EXIT, None))
        start_fn('303 See Other', [('Location','/checkProgress/{jobID}'.format(jobID=jobNum))])
        return []

    def getHumanReadableJobState(self, jobNum):
        state = 'Unknown'
        if self.isCancelled(jobNum):
            state = 'Cancelled'
        elif self.jobQueue[jobNum]['exitCode'] == ServerJob.INCOMPLETE:
            if not self.isConfirmed(jobNum):
                state = 'Unconfirmed'
            elif self.isEnqueued(jobNum):
                state = 'Enqueued'
            else:
                state = 'Working'
        elif self.isSucceeded(jobNum):
            state = 'Succeeded'
        elif self.isFailed(jobNum):
            state = 'Failed'
        return state

    def myJobsHandler(self, environ, start_fn):
        user = getUsername(environ)

        with open('MyJobsTableRowTemplate.html', 'r') as f:
            jobEntryTemplate = f.read()

        jobEntries = []
        for jobNum in self.getJobNums(owner=user):
            state = self.getHumanReadableJobState(jobNum)

            numVideos = len(self.jobQueue[jobNum]['videoList'])
            numCompletedVideos = len(self.jobQueue[jobNum]['completedVideoList'])
            percentComplete = "{percentComplete:.1f}".format(percentComplete=100*numCompletedVideos/numVideos)

            jobEntries.append(jobEntryTemplate.format(
                percentComplete=percentComplete,
                jobNum=jobNum,
                jobDescription=self.jobQueue[jobNum]['jobName'],
                state=state
            ))
        jobEntryTableBody = '\n'.join(jobEntries)
        start_fn('200 OK', [('Content-Type', 'text/html')])
        return self.formatHTML(
            environ,
            'MyJobs.html',
            tbody=jobEntryTableBody,
            autoReloadInterval=AUTO_RELOAD_INTERVAL,
            user=user
        )

    def serverManagementHandler(self, environ, start_fn):
        if not isAdmin(getUsername(environ)):
            # User is not authorized
            return self.unauthorizedHandler(environ, start_fn)

        allJobNums = self.getJobNums()

        with open('ServerManagementTableRowTemplate.html', 'r') as f:
            jobEntryTemplate = f.read()

        serverStartTime = self.startTime.strftime(HTML_DATE_FORMAT)

        jobEntries = []
        for jobNum in allJobNums:
            state = self.getHumanReadableJobState(jobNum)

            numVideos = len(self.jobQueue[jobNum]['videoList'])
            numCompletedVideos = len(self.jobQueue[jobNum]['completedVideoList'])
            percentComplete = "{percentComplete:.1f}".format(percentComplete=100*numCompletedVideos/numVideos)

            jobEntries.append(jobEntryTemplate.format(
                numVideos = numVideos,
                numCompletedVideos = numCompletedVideos,
                percentComplete = percentComplete,
                jobNum=jobNum,
                jobDescription = self.jobQueue[jobNum]['jobName'],
                confirmed=self.jobQueue[jobNum]['confirmed'],
                cancelled=self.jobQueue[jobNum]['cancelled'],
                state=state,
                owner=self.jobQueue[jobNum]['owner']
            ))
        jobEntryTableBody = '\n'.join(jobEntries)
        start_fn('200 OK', [('Content-Type', 'text/html')])
        return self.formatHTML(
            environ,
            'ServerManagement.html',
            tbody=jobEntryTableBody,
            startTime=serverStartTime,
            autoReloadInterval=AUTO_RELOAD_INTERVAL,
        )

    def restartServerHandler(self, environ, start_fn):
        if not isAdmin(getUsername(environ)):
            # User is not authorized
            return self.unauthorizedHandler(environ, start_fn)
        raise SystemExit("Server restart requested")

    def reloadAuthHandler(self, environ, start_fn):
        if not isAdmin(getUsername(environ)):
            # User is not authorized
            return self.unauthorizedHandler(environ, start_fn)

        message = "Authentication file successfully reloaded!"
        addMessage(environ, message)
        return self.serverManagementHandler(environ, start_fn)

    def helpHandler(self, environ, start_fn):
        user = getUsername(environ)

        start_fn('200 OK', [('Content-Type', 'text/html')])
        return self.formatHTML(
            environ,
            'Help.html',
            user=user
        )

    def changePasswordHandler(self, environ, start_fn):
        user = getUsername(environ)

        start_fn('200 OK', [('Content-Type', 'text/html')])
        return self.formatHTML(
            environ,
            'ChangePassword.html',
            user=user
        )

    def finalizePasswordHandler(self, environ, start_fn):
        # Display page showing what job will be, and offering opportunity to go ahead or cancel
        postDataRaw = environ['wsgi.input'].read().decode('utf-8')
        postData = urllib.parse.parse_qs(postDataRaw, keep_blank_values=False)

        user = getUsername(environ)
        try:
            oldPassword  = postData['oldPassword' ][0]
            newPassword  = postData['newPassword' ][0]
            newPassword2 = postData['newPassword2'][0]
        except KeyError:
            # Missing one of the postData arguments
            start_fn('404 Not Found', [('Content-Type', 'text/html')])
            return self.formatError(
                environ,
                errorTitle='Missing parameter',
                errorMsg='A required field is missing. Please retry with all required fields filled in.',
                linkURL='/changePassword',
                linkAction='return to change password page (or use browser back button)'
                )

        # Check if all parameters are valid. If not, display error and offer to go back
        if newPassword == newPassword2:
            success, reason = changePassword(user, oldPassword, newPassword)
        else:
            success = False
            reason = "New password does not match confirmation. Please retype."

        if not success:
            start_fn('404 Not Found', [('Content-Type', 'text/html')])
            return self.formatError(
                environ,
                errorTitle='Invalid job parameter',
                errorMsg=reason,
                linkURL='/changePassword',
                linkAction='return to change password page (or use browser back button)'
                )

        start_fn('200 OK', [('Content-Type', 'text/html')])
        return self.formatHTML(
            environ,
            'PasswordChanged.html',
            user=user,
            message="Password succesfully changed!"
        )

    def invalidHandler(self, environ, start_fn):
        logger.log(logging.INFO, 'Serving invalid warning')
        start_fn('404 Not Found', [('Content-Type', 'text/html')])
        return self.formatError(
            environ,
            errorTitle='Path not recognized',
            errorMsg='Path {name} not recognized!'.format(name=environ['PATH_INFO']),
            linkURL='/',
            linkAction='return to job creation page'
        )

    def unauthorizedHandler(self, environ, start_fn):
        start_fn('404 Not Found', [('Content-Type', 'text/html')])
        return self.formatError(
            environ,
            errorTitle='Not authorized',
            errorMsg='User {user} is not authorized to perform that action!'.format(user=getUsername(environ)),
            linkURL='/',
            linkAction='return to job creation page'
        )

if __name__ == '__main__':
    if len(sys.argv) > 1:
        port = int(sys.argv[1])
    else:
        port = 80

    logger.log(logging.INFO, 'Spinning up server!')
    while True:
        s = SegmentationServer(webRoot=ROOT, port=port)
        application = BasicAuth(s, users=USERS)
        s.linkBasicAuth(application)
        try:
            logger.log(logging.INFO, 'Starting segmentation server...')
            serve(application, host='0.0.0.0', port=port, url_scheme='http')
            logger.log(logging.INFO, '...segmentation server started!')
        except KeyboardInterrupt:
            logger.exception('Keyboard interrupt')
            break
        except SystemExit:
            logger.exception('Server restart requested by user')
        except:
            logger.exception('Server crashed!')
        time.sleep(1)
