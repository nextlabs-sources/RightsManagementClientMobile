package errorHandler;

public class ErrorCode {
    public final static int DOWN_LOAD_FAILED = 0;
    public final static int DECRYPT_FAILED = 1;
    public final static int NO_RIGHT = 2;
    public final static int INVALID_FILE_PARAMETER = 3;
    public final static int NOT_NXL_FILE = 4;
    public final static int RINGGS_IS_EMPTY = 5;
    public final static int CAN_NOT_GET_KEYBLOB = 6;
    public final static int CAN_NOT_GET_TAGS = 7;
    public final static int FILL_NOT_EXIST = 8;
    public final static int INTENT_IS_NULL = 9;
    public final static int INTENT_NOT_MATCH = 10;
    public final static int OFFICE_NOT_RENDER = 11;
    public final static int PDF_NOT_RENDER = 12;
    public final static int FILE_FORMAT_NOT_SUPPORT = 13;

    public final static int SET_TIMEOUT_ERROR = 14;

    public final static int NOT_GET_SUPPORTED_CAD_FORMATS = 15;

    public final static int SHARE_POINT_LOGIN_ERROR = 16;
    public final static int SHARE_POINT_ONLINE_LOGIN_ERROR = 17;
    public final static int NETWORK_NOT_AVAILABLE_ERROR = 18;

    public final static int USER_NOT_INPUT_ERROR = 19;

    public final static int BOUND_SERVICE_HAD_BIND = 20;

    public final static int UPLOAD_FILE_FAILED_ERROR = 21;

    public final static int GET_REPOSITORY_INFO_ERROR = 22;

    public final static int BOUND_SERVICE_BIND_FAILED = 23;

    public final static int REPO_UPDATE_FAILED = 24;

    public final static int REPO_SYS_INITIALIZATION_FAINED = 25;
    public final static int REPO_ONE_DRIVE_INIT_FAILED = 26;

    public final static int RECLASSIFY_FAILED = 27;

    public final static int ERROR_NOT_GET_NAME_OR_UID = 28;

    public final static int NO_CONTENT = 204;

    public static int SHARE_POINT_UPLOAD_REQUEST_ERROR = -1;
    public static int SHARE_POINT_ONLINE_UPLOAD_REQUEST_ERROR = -1;


    // Error for Runtime
    public static final String E_RT_PARAM_INVALID = "Error, invalid param";
    public static final String E_RT_PARAM_CALLBACK_INVALID = "Error, invalid callback param";
    public static final String E_RT_PARAM_DOC_INVALID = "Error, invalid document param";
    public static final String E_RT_PARAM_SERVICE_INVALID = "Error, invalid service param";

    public static final String E_RT_SHOULD_NEVER_REACH_HERE = "Error, should never reach here";

    // Error for file system
    public static final String E_FS_INSTALL_REPO = "Error, can not install repo";
    public static final String E_FS_MOUNTPOINT_INVALID = "Error,invalid mount point";

    // Error for Nxl format
    public static final String E_NXLF_PARAM_FOLDER_REQUIRED = "Error, param required a folder";

    // Error for Repository
    public static final String E_REPO_NO_REPOS = "Error, no repositories";
    public static final String E_REPO_NULL_LINKED_SERVICE = "Error, null linked service";
    public static final String E_REPO_CANNOT_FIND_LOCAL_REPO = "Error, can not find the local repo";
    // Error for UI
    // Error for IO
    // Error for Network
    public static final String E_IO_NO_NETWORK = "Error, no net work";

}
