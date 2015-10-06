__author__ = 'Vash'



include "cnative.pxd"


#DECORATORS
def check_npresult(func):
    """Checks if the output of a function matches the Motive Error Values, and raises a Python error if so."""
    error_dict = {1: (IOError, "File Not Found"),
                  2: (Exception, "Load Failed"),
                  3: (Exception, "Failed"),
                  8: (IOError, "Invalid File"),
                  9: (IOError, "Invalid Calibration File"),
                  10: (EnvironmentError, "Unable To Initialize"),
                  11: (EnvironmentError, "Invalid License"),
                  14: (RuntimeWarning, "No Frames Available")}
    def wrapper(*args, **kwargs):
        npresult = func(*args, **kwargs)
        if npresult in error_dict:
            error, msg = error_dict[npresult]
            raise error(msg)
    return wrapper


def block_for_frame(secs_to_timeout=1):
    """Decorator to continually call a function until it stops raising a RuntimeWarning or until timeout."""
    import time
    def decorator_fun(func):
        def wrapper(*args, **kwargs):
            end_time = time.time() + secs_to_timeout
            while time.time() < end_time:
                try:
                    return func(*args, **kwargs)
                except RuntimeWarning:
                    pass
            else:
                raise RuntimeWarning("No Frames Available: Timed Out after {} seconds".format(secs_to_timeout))
        return wrapper
    return decorator_fun

def check_cam_setting(func):
    def wrapper(*args, **kwargs):
        check=func(*args, **kwargs)
        if check<0:
            raise Exception("Value Not Available. Usually Camera Index Not Valid Or Devices Not Initialized")
        else:
            return check
    return wrapper

def autoupdate(func):
    def wrapper(*args, **kwargs):
        """Decorator, to call update() right after calling the function."""
        output = func(*args, **kwargs)
        update()
        return output
    return wrapper

#CONSTANTS
BUILD_NUMBER = TT_BuildNumber()


#STARTUP / SHUTDOWN
@autoupdate
@check_npresult
def initialize():
    """
    initialize library
    """
    return TT_Initialize()

@check_npresult
def shutdown():
    """
    shutdown library
    """
    return TT_Shutdown()


#RIGID BODY INTERFACE FILES
@check_npresult
def load_calibration(str calib_filename):
    """
    load calibration
    """
    return TT_LoadCalibration(calib_filename)

@check_npresult
def load_rigid_bodies(str load_bodies_file):
    """
    load rigid bodies
    """
    return TT_LoadRigidBodies(load_bodies_file)

@check_npresult
def save_rigid_bodies(str rigid_filename):
    """
    save rigid bodies
    """
    return TT_SaveRigidBodies(rigid_filename)

@check_npresult
def add_rigid_bodies(str rigid_bodies_file):
    """
    add rigid bodies
    """
    return TT_AddRigidBodies(rigid_bodies_file)

@check_npresult
def load_project(str project_file):
    """
    load project file
    """
    return TT_LoadProject(project_file)

@check_npresult
def save_project(str project_file):
    """
    save project file
    """
    return TT_SaveProject(project_file)

@check_npresult
def load_calibration_from_memory(buffername, int buffersize):
    assert isinstance(buffername, str), "Buffername Needs To Be String"
    cdef unsigned char * buff=buffername
    return TT_LoadCalibrationFromMemory(buff, buffersize)

@block_for_frame(secs_to_timeout=3)
@check_npresult
def update_single_frame():
    """
    Process incoming camera data
    """
    return TT_UpdateSingleFrame()

@block_for_frame(secs_to_timeout=3)
@check_npresult
def update():
    """
    Process incoming camera data. More than one frame
    """
    return TT_Update()


#DATA STREAMING
@check_npresult
def stream_trackd(bool enabled):
    """
    Start/stop Trackd Stream.
    TrackD Streaming Engine: Streams rigid body data via the Trackd protocol
    """
    return TT_StreamTrackd(enabled)

@check_npresult
def stream_vrpn(bool enabled, int port=3883):
    """
    Start/stop VRPN Stream.
    VRPN Streaming Engine: Streams rigid body data via the VRPN protocol.
    VRPN Broadcast Port: Specifies the broadcast port for VRPN streaming.
    """
    return TT_StreamVRPN(enabled, port)

@check_npresult
def stream_np(bool enabled):
    """
    Start/stop NaturalPoint Stream
    """
    return TT_StreamNP(enabled)


#MARKERS
def frame_markers():
    """
    Returns list of all marker positions.
    """
    return [[TT_FrameMarkerX(idx), TT_FrameMarkerY(idx), TT_FrameMarkerZ(idx)] for idx in xrange(TT_FrameMarkerCount())]


# def unident_markers(int rigidBody_count):
#     """
#     returns a list of all markers which
#     are not in rigid Bodies
#     """
#     markers=frame_markers()
#     unimarkers=[]
#     imarkers=[]
#     for i in range (0,rigidBody_count):
#         for ik in rigidBody_markers(i):
#            imarkers.append(ik)
#            print "{}\n".format(ik)
#         print '\n{}\n\n'.format(imarkers)
#     for k in markers:
#         if k not in imarkers:
#            unimarkers.append(k)
#            print '{}\n'.format(k)
#     return unimarkers




def frame_time_stamp():
    """
    Time Stamp of Frame (seconds)
    """
    return TT_FrameTimeStamp()

def flush_camera_queues():
    """
    In the event that you are tracking a very high number of 2D and/or 3D markers (hundreds of 3D markers),
    and you find that the data you're getting out has sufficient latency you can call TT_FlushCameraQueues()
    to catch up before calling TT_Update(). Ideally, after calling TT_FlushCameraQueues() you'll want to not
    call it again until after TT_Update() returns 0
    """
    TT_FlushCameraQueues()


#CAMERA GROUP SUPPORT
def camera_group_count():
    """
    Returns number of camera groups
    """
    return TT_CameraGroupCount()

def create_camera_group():
    """
    Add an additional group
    """
    if not TT_CreateCameraGroup():
        raise Exception("Could Not Create Camera Group")

def remove_camera_group(int groupIndex):
    """
    Remove a camera group (must be empty)
    """
    if not TT_RemoveCameraGroup(groupIndex):
        raise Exception("Could Not Remove. Check If Group Empty")

def set_group_shutter_delay(int groupIndex, int microseconds):
    """
    Set camera group's shutter delay
    """
    TT_SetGroupShutterDelay(groupIndex, microseconds)


#RIGID BODY CONTROL


rigidBodyCount=0

def rigidBody_count():
    """
    returns number of rigid bodies
    """
    return rigidBodyCount



@check_npresult
def create_rigid_body(str name, markerList):
     """
     The marker list is expected to contain a list of marker coordinates in the order:
     x1,y1,z1,x2,y2,z2,...xN,yN,zN.
     """
     id = rigidBody_count()-1
     cdef float markerListp[1000]
     markerCount=len(markerList)
     assert markerCount<=1000, "Due to need of const C array size, markerList max items=1000. \n Please resize const in native.pyx"
     for i in range(0,len(markerList)):
         markerListp[3*i]=markerList[i][0]
         markerListp[3*i+1]=markerList[i][1]
         markerListp[3*i+2]=markerList[i][2]
     if (TT_CreateRigidBody(name, id, markerCount, markerListp)==0):
         global rigidBodyCount
         rigidBodyCount=rigidBodyCount+1
     return TT_CreateRigidBody(name, id, markerCount, markerListp)

@check_npresult
def remove_rigid_body(int rigidIndex):
    """
    Remove single rigid body
    """
    if (TT_RemoveRigidBody(rigidIndex)==0):
        global rigidBodyCount
        rigidBodyCount=rigidBodyCount-1
    return TT_RemoveRigidBody(rigidIndex)

def clear_rigid_body_list():
    """
    Clear all rigid bodies
    """
    TT_ClearRigidBodyList()
    global rigidBodyCount
    rigidBodyCount=0


class RigidBody(object):
    def __init__(self, rigidIndex):
        #assert 0<=rigidIndex<rigidBodyCount, "There Are Only {0} Rigid Bodies".format(rigidBodyCount)
        self.index=rigidIndex

    def __str__(self):
        return "Rigid Body: {}".format(self.name)

    @property
    def name(self):
        """Returns RigidBody Name"""
        return "{0}".format(TT_RigidBodyName(self.index))

    @property
    def user_data(self):
        """
        Get RigidBodies User Data
        """
        return "Rigid body ID: {0}".format(TT_RigidBodyUserData(self.index))

    @user_data.setter
    def user_data(self,value):
        """
        returns int index
        """
        return TT_SetRigidBodyUserData(self.index,value)

    @property
    def tracking_enabled(self):
        """Get tracking (bool)"""
        return TT_RigidBodyEnabled(self.index)

    @tracking_enabled.setter
    def tracking_enabled(self, value):
        TT_SetRigidBodyEnabled(self.index, value)

    @property
    def is_tracked(self):
        """
        Is rigid body currently tracked
        """
        return TT_IsRigidBodyTracked(self.index)

    def get_all_spatial_data(self):
        """Returns dict: {'location': (x, y, z), 'rotation':(yaw, pitch, roll), 'rotation_quats':(qx, qy, qz, qw)}.
        This is done in a single C function call, so it's really fast if you want all the data."""
        cdef float x = 0., y = 0., z = 0., qx = 0., qy = 0., qz = 0., qw = 0., yaw = 0., pitch = 0., roll = 0.
        TT_RigidBodyLocation(self.index,  &x, &y, &z,  &qx, &qy, &qz, &qw, &yaw, &pitch, &roll)
        return {'location': (x, y, z), 'rotation': (yaw, pitch, roll),'rotation_quats': (qx, qy, qz, qw)}

    @property
    def location(self):
        """(x, y, z) position."""
        return self.get_all_spatial_data()['location']

    @property
    def rotation(self):
        """(yaw, pitch, roll) rotation"""
        return self.get_all_spatial_data()['rotation']

    @property
    def rotation_quats(self):
        """(qx, qy, qz, qw) quaternion rotation."""
        return self.get_all_spatial_data()['rotation_quats']

    @property
    def markers(self):
        """Get list of rigid body marker position"""
        markers=[]
        cdef float x = 0, y = 0, z = 0
        for i in range(0, TT_RigidBodyMarkerCount(self.index)):
            TT_RigidBodyMarker(self.index, i, &x, &y, &z)
            markers.append([x, y, z])
        return markers

    @property
    def point_cloud_markers(self):
        """Gets list of point cloud markers."""
        markers = []
        cdef int markerIndex
        cdef bool tracked = True
        cdef float x = 0, y = 0, z = 0  # Says it works at http://docs.cython.org/src/userguide/pyrex_differences.html
        for markerIndex in xrange(TT_RigidBodyMarkerCount(self.index)):
            # Get marker position.
            TT_RigidBodyPointCloudMarker(self.index, markerIndex, tracked, x, y, z)

            # Add the marker if one was found (tracked was True). Else, put None in its position in the list!
            # TODO: decide what to do with the not_tracked case.
            marker = [x, y, z] if tracked else None
            markers.append([x, y, z])

        return markers

    @check_npresult
    def translate_pivot(self, float x, float y, float z):
        """
        Rigid Body Pivot-Point Translation: Sets a translation offset for the centroid of the rigid body.
        Reported values for the location of the rigid body, as well as the 3D visualization, will be shifted
        by the amount provided in the fields on either the X, Y, or Z axis. Values are entered in meters. """
        return TT_RigidBodyTranslatePivot(self.index, x, y, z)

    def reset_orientation(self):
        """Reset orientation to match the current tracked orientation of the rigid body."""
        TT_RigidBodyResetOrientation(self.index)


#MARKER SIZE SETTINGS
@check_npresult
def set_camera_group_reconstruction(int groupIndex, bool enable):
    return TT_SetCameraGroupReconstruction(groupIndex, enable)

@check_npresult
def set_enabled_filter_switch(bool enabled):
    return TT_SetEnabledFilterSwitch(enabled)

def is_filter_switch_enabled():
    return TT_IsFilterSwitchEnabled()



#ADDITIONAL FUNCTIONALITY
def set_frame_id_based_timing(bool enable):
    return TT_SetFrameIDBasedTiming(enable)

def set_suppress_out_of_order(bool enable):
    return TT_SetSuppressOutOfOrder(enable)

@check_npresult
def orient_tracking_bar(float positionX, float positionY, float positionZ,
                        float orientationX, float orientationY, float orientationZ, float orientationW):
    return TT_OrientTrackingBar(positionX, positionY, positionZ,
                                orientationX, orientationY, orientationZ, orientationW)


