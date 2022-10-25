package com.sap.ve;

public class DVLTypes {
    public static final long DVLID_INVALID = -1;


    //
    //DVLRESULT
    //
    /// Defines the result of the operation. May be successful or not.
    public enum DVLRESULT {
        /// The file is encrypted and password was either not provided or is incorrect
        ENCRYPTED,

        /// The file is not found
        FILENOTFOUND,

        /// The library has not been initialized properly
        NOTINITIALIZED,

        /// The version is wrong (file version, library version, etc)
        WRONGVERSION,

        /// The name does not have an extension
        MISSINGEXTENSION,

        /// Access is denied
        ACCESSDENIED,

        /// There is no such interface
        NOINTERFACE,

        /// Out of memory
        OUTOFMEMORY,

        /// Invalid call
        INVALIDCALL,

        /// The item or file is not found
        NOTFOUND,

        /// The argument is invalid
        BADARG,

        /// Failure, something went completely wrong
        FAIL,

        /// Invalid thread
        BADTHREAD,

        /// Incorrect format
        BADFORMAT,

        /// File reading error
        FILEERROR,

        /// The requested feature is not yet implemented
        NOTIMPLEMENTED,

        /// Hardware error
        HARDWAREERROR,

        MINUS_2,

        /// The process has been interrupted
        INTERRUPTED,

        /// Negative result
        FALSE,

        /// Everything is OK
        OK,

        /// Nothing was changed as a result of processing/action (similar to OK), for example if you want to "hide a node that is already hidden"
        PROCESSED,

        /// The initialization has been made already (it is OK to initialize multiple times, just not optimal)
        ALREADYINITIALIZED;

        public static DVLRESULT fromInt(int i) {
            return values()[i + 19];
        }

        public int toInt() {
            return ordinal() - 19;
        }

        public boolean Failed() {
            return ordinal() < 19;
        }

        public boolean Succeeded() {
            return ordinal() > 19;
        }
    }

    ;


    //
    //DVLZOOMTO
    //
    /// Defines the \a Zoom \a To options
    public enum DVLZOOMTO {
        /// bounding box of the whole scene
        ALL,

        /// bounding box of visible nodes
        VISIBLE,

        /// bounding box of selected nodes
        SELECTED,

        /// bounding box of a specific node and its children
        NODE,

        /// same as ::NODE, but also does IDVLRenderer::SetIsolatedNode() for the node
        NODE_SETISOLATION,

        /// previously saved view [view is saved every time IDVLRenderer::ZoomTo() is executed]
        RESTORE,

        /// same as ::RESTORE, but also does IDVLRenderer::SetIsolatedNode() with ::DVLID_INVALID parameter
        RESTORE_REMOVEISOLATION
    }

    ;


    //
    //DVLRENDEROPTION
    //
    /// Defines the rendering options
    public enum DVLRENDEROPTION {
        /// Show Debug Info like FPS or not, default: OFF
        SHOW_DEBUG_INFO,

        /// Display backfacing triangles or not, default: OFF
        SHOW_BACKFACING,

        /// Show shadow or not, default: ON
        SHOW_SHADOW,

        /// Orbit or Turntable, default: OFF (Turntable)
        CAMERA_ROTATION_MODE_ORBIT,

        /// Clear the color buffer during each Renderer::RenderFrame() or not, default: ON.
        /// By setting this option OFF, you can draw a textured background or paint video camera frame.
        /// The caller application would need to clear color buffer itself before calling RenderFrame() if option is OFF.
        CLEAR_COLOR_BUFFER,

        /// Ambient Occlusion effect. If turned ON, would disable stereo effect.
        /// It is not possible to have both Stereo and Ambient occlusion.
        AMBIENT_OCCLUSION,

        /// Anaglyph Stereo effect. If turned ON, would disable left+right stereo effect and ambient occlusion effect.
        /// It is not possible to have both Stereo and Ambient occlusion.
        ANAGLYPH_STEREO,

        /// Left+Right Stereo effect. If turned ON, would disable anaglyph stereo effect and ambient occlusion effect.
        /// It is not possible to have both Stereo and Ambient occlusion.
        LEFT_RIGHT_STEREO,

        /// Half resolution render (downsampling). If turned ON, would disable supersampling.
        HALF_RESOLUTION,

        /// Double resolution render (supersampling). If turned ON, would disable downsampling.
        DOUBLE_RESOLUTION,

        /// Show all hotspots or not, default: OFF. This is only working for 2D .cgm scenes.
        SHOW_ALL_HOTSPOTS,
    }

    ;

    //
    //DVLRENDEROPTIONF
    //
    /// Defines the rendering options
    public enum DVLRENDEROPTIONF {
        /// DPI (Dots Per Inch) setting. Defaults to 132.0 on iPad and 96.0 on other platforms.
        /// Use in calculating size of sprites and polyline thickness. Highly recommended to set it properly.
        DPI,

        /// Amount of millions of triangles in scene for using "dynamic loading".
        /// If scene has less than the given number of triangles, normal rendering is performed.
        /// Otherwise, "dynamic loading" is done: meshes are loaded on demand and rendering via occlusion culling is performed.
        /// Default: 3.0 (3,000,000 triangles in scene is needed to use "dynamic loading")
        /// Set to 0.0f to always have dynamic loading
        /// Set to -1.0f to disable dynamic loading
        DYNAMIC_LOADING_THRESHOLD,

        /// Maximum amount of video memory (in megabytes) that DVL Core may use for loading meshes
        /// Default: 256 MB on iPad and 512 MB on other platforms
        VIDEO_MEMORY_SIZE,
    }

    ;


    //
    //DVLSCENEACTION
    //
    /// Defines the scene actions
    public enum DVLSCENEACTION {
        /// Make all nodes in the scene 'visible'
        SHOW_ALL,

        /// Make all nodes in the scene 'hidden'
        HIDE_ALL,

        /// Make selected nodes and all their children 'visible'
        SHOW_SELECTED,

        /// Make selected nodes and all their children 'hidden'
        HIDE_SELECTED,
    }

    ;


    //
    //DVLEXECUTE
    //
    /// Defines the language type of the string passed into Execute()
    public enum DVLEXECUTE {
        /// VE query language, for example "everything() select()". Only for 3D files.
        QUERY,

        /// SAP Paint XML, for example "<PAINT_LIST ASSEMBLY_PAINTING_ENABLED="true" ASSEMBLY_LEVEL="5"><PAINT COLOR="#008000" OPACITY="1.0" VISIBLE="true" ALLOW_OVERRIDE="false"><NODE ID="0__moto_x_asm"></NODE></PAINT></PAINT_LIST>". Only for 3D files.
        PAINTXML,

        /// CGM navigate action, for example "pictid(engine_top).id(oil-pump-t,full+newHighlight)". Only for 2D files. See http://www.w3.org/TR/webcgm20/WebCGM20-IC.html
        CGMNAVIGATEACTION,

        /// Dynamic labels XML
        DYNAMICLABELS,
    }

    ;


    /// Defines the type of parts to put in the list
    public enum DVLPARTSLISTTYPE {
        /// Build a list using all the nodes
        ALL,

        /// Build a list using only the visible nodes
        VISIBLE,

        /// Build a list using only the nodes, consumed by a particular step (step DVLID is passed as a parameter to the BuildPartsList() call)
        CONSUMED_BY_STEP,
    }


    /// Defines the sorting order for the parts list
    public enum DVLPARTSLISTSORT {
        /// Sort from A to Z
        NAME_ASCENDING,

        /// Sort from Z to A
        NAME_DESCENDING,

        /// Sort by the number of nodes in the part, parts with smaller number of nodes go first
        COUNT_ASCENDING,

        /// Sort by the number of nodes in the part, parts with larger number of nodes go first
        COUNT_DESCENDING,
    }

    ;


    /// Defines the type of node search to perform
    public enum DVLFINDNODETYPE {
        /// Find node by "node name"
        NODE_NAME,

        /// Find node by "asset id" (asset id is stored inside some VDS files [it is optional])
        ASSET_ID,

        /// Find node by "unique id" (unique id is stored inside some VDS files [it is optional])
        UNIQUE_ID,

        /// Find node by "DS selector id" (unique id is stored inside some VDS files [it is optional])
        DSSELECTOR_ID,
    }


    /// Defines the string comparison mode
    public enum DVLFINDNODEMODE {
        /// Match nodes by comparing node name/assetid/uniqueid with "str" (case sensitive, fastest option [does buffer compare without UTF8 parsing])
        EQUAL,

        /// Match nodes by comparing node name/assetid/uniqueid with "str" (case insensitive, UTF8-aware)
        EQUAL_CASE_INSENSITIVE,

        /// Match nodes by finding "str" substring in node name/assetid/uniqueid (case sensitive, UTF8-aware)
        SUBSTRING,

        /// Match nodes by finding "str" substring in node name/assetid/uniqueid (case insensitive, UTF8-aware)
        SUBSTRING_CASE_INSENSITIVE,

        /// Match nodes by comparing first "strlen(str)" symbols of node name/assetid/uniqueid with "str" (case sensitive, UTF8-aware)
        STARTS_WITH,

        /// Match nodes by comparing first "strlen(str)" symbols of node name/assetid/uniqueid with "str" (case insensitive, UTF8-aware)
        STARTS_WITH_CASE_INSENSITIVE,
    }

    //
    //DVLNODEFLAG
    //
    public class DVLNODEFLAG {
        /// The node is visible
        public static final int VISIBLE = 0x0001;
        /// The node is selected
        public static final int SELECTED = 0x0002;
        /// The node is closed (the node itself and all children are treated as a single node)
        public static final int CLOSED = 0x0008;
        /// The node is single-sided
        public static final int SINGLE_SIDED = 0x0010;
        /// The node is double-sided
        public static final int DOUBLE_SIDED = 0x0020;
        /// The node can't be hit (transparent to the mouse clicks or taps)
        public static final int UNHITABLE = 0x0040;
        /// The node is a common billboard, scales with camera but is always orthogonal
        public static final int BILLBOARD_VIEW = 0x0080;
        /// The node is positioned on a 2D layer on top of the screen
        public static final int BILLBOARD_LOCK_TO_VIEWPORT = 0x0100;
    }

    //
    //DVLFLAGOP
    //
    public class DVLFLAGOP {
        /// Set the flag
        public static final int SET = 0;

        /// Clear the flag
        public static final int CLEAR = 1;

        /// if ::DVLFLAGOP_MODIFIER_RECURSIVE, then child node flags are set to parent values. So for example if parent is visible and child is hidden, after this operation both will be hidden
        public static final int INVERT = 2;

        /// if ::DVLFLAGOP_MODIFIER_RECURSIVE, then child nodes are inverted. So for example if parent is visible and child is hidden, after this operation parent will be hidden and child visible
        public static final int INVERT_INDIVIDUAL = 3;

        public static final int VALUES_BITMASK = 0x7F;

        /// Do the operation recursively for all the subitems
        public static final int MODIFIER_RECURSIVE = 0x80;
    }

    //
    //DVLSCENEINFO
    //
    public class DVLSCENEINFO {
        /// Retrieve the list of child nodes
        public static final int CHILDREN = 0x0001;
        /// Retrieve the list of selected nodes
        public static final int SELECTED = 0x0002;
        /// Retrieve the prefix for scene localization
        public static final int LOCALIZATION_PREFIX = 0x0004;
        /// Retrieve scene dimensions
        public static final int DIMENSIONS = 0x0008;
    }

    //
    //DVLNODEINFO
    //
    public class DVLNODEINFO {
        /// Retrieve the node name
        public static final int NAME = 0x0001;
        /// Retrieve the node asset id
        public static final int ASSETID = 0x0002;
        /// Retrieve the node unique id
        public static final int UNIQUEID = 0x0004;
        /// Retrieve parents of the node
        public static final int PARENTS = 0x0008;
        /// Retrieve children of the node
        public static final int CHILDREN = 0x0010;
        /// Retrieve node flags
        public static final int FLAGS = 0x0020;
        /// Retrieve node opacity
        public static final int OPACITY = 0x0040;
        /// Retrieve node highlight color
        public static final int HIGHLIGHT_COLOR = 0x0080;
        /// Retrieve node URIs
        public static final int URI = 0x0100;
    }

    //
    //DVLPARTSLIST
    //
    public class DVLPARTSLIST {
        /// Recommended number of parts for a BuildPartsList() call
        public static final int RECOMMENDED_uMaxParts = 1000;

        /// Recommended limitation of nodes in a single part for BuildPartsList() call
        public static final int RECOMMENDED_uMaxNodesInSinglePart = 1000;

        /// Recommended limitation of part name's length for BuildPartsList() call
        public static final int RECOMMENDED_uMaxPartNameLength = 200;

        /// Do not limit the number of parts in BuildPartsList() call
        public static final int UNLIMITED_uMaxParts = 0;

        /// Do not limit the number of nodes in a part for BuildPartsList() call
        public static final int UNLIMITED_uMaxNodesInSinglePart = 0;

        /// Do not limit the part's name length for BuildPartsList() call
        public static final int UNLIMITED_uMaxPartNameLength = 0;
    }
}