package com.sap.ve;

public class DVLClient {
    public static boolean m_continueLoading = true;

    public static void startLoading() {
        m_continueLoading = true;
    }

    public static void cancelLoading() {
        m_continueLoading = false;
    }//use this method to interrupt file loading [see how m_continueLoading variable is used]

    public static void OnNodeSelectionChanged(long hScene, int numberOfSelectedNodes, long idFirstSelectedNode) {
        //ToDo: you can cache currently selected node id here
    }

    public static void LogMessage(int type, String source, String text) {
        //ToDo: you can use this callback to display some internal DVL warning messages
    }

    public static void OnStepEvent(int type, long stepId) {
        //ToDo: you can use this callback to switch currently selected step in your UI
    }

    public static boolean NotifyFileLoadProgress(float progress) {
        //ToDo: you can display a progress bar with the "progress" value
        return m_continueLoading;
    }

    ;

    public enum DVLLOGTYPE {
        /// Debugging information, usually can be ignored
        DEBUG,

        /// Information message, like name of the loading file or ID of the activated step
        INFO,

        /// Warning message, usually means that something went wrong but you can proceed
        WARNING,

        /// Error message, means that something has failed
        ERROR;

        public static DVLLOGTYPE fromInt(int i) {
            return values()[i];
        }
    }

    public enum DVLSTEPEVENT {
        /// step has started (stepId is a new step)
        STARTED,

        /// the previous step has finished and the new one is started (stepId is a new step)
        SWITCHED,

        /// the step has finished playing and no more steps are to be played (stepId is the old step)
        FINISHED;

        public static DVLSTEPEVENT fromInt(int i) {
            return values()[i];
        }
    }
}
