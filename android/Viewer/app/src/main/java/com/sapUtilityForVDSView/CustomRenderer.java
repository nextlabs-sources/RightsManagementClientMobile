package com.sapUtilityForVDSView;

import android.content.Context;
import android.opengl.GLSurfaceView;
import android.os.Handler;
import android.os.Message;

import com.sap.ve.DVLCore;
import com.sap.ve.DVLRenderer;
import com.sap.ve.DVLScene;
import com.sap.ve.DVLTypes;
import com.sap.ve.SDVLMatrix;
import com.sap.ve.SDVLPartsListInfo;
import com.sap.ve.SDVLProceduresInfo;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

/**
 * customRender for VDS file
 */
public class CustomRenderer implements GLSurfaceView.Renderer {
    public static final int CALC_FINISHED = 1;
    private DVLCore m_core;
    private DVLRenderer m_renderer;
    private DVLScene m_scene;
    private SDVLProceduresInfo m_proceduresInfo;
    private SDVLPartsListInfo m_partsListInfo;
    private GestureHandler m_gestures;
    private Context m_context;
    private String m_filePath;
    private Handler handler = null;

    public CustomRenderer(Context context, DVLCore core, GestureHandler gestures, String filePath) {
        m_context = context;
        m_core = core;
        m_gestures = gestures;
        m_filePath = filePath;
    }

    public void startCalc(Handler handler) {
        this.handler = handler;
    }

    public void onSurfaceCreated(GL10 gl, EGLConfig config) {
        DVLTypes.DVLRESULT res = m_core.InitRenderer();
        if (res.Failed())
            return;

        m_renderer = m_core.GetRenderer();
        m_renderer.SetBackgroundColor(50.0f / 255.0f, 50.0f / 255.0f, 50.0f / 255.0f, 1.0f, 1.0f, 1.0f);
        m_renderer.SetOption(DVLTypes.DVLRENDEROPTION.SHOW_SHADOW, true);

        m_scene = new DVLScene(0, m_context);
        res = m_core.LoadScene("file://" + m_filePath, null, m_scene);
        if (res.Failed())
            return;

        m_renderer.AttachScene(m_scene);

        m_proceduresInfo = new SDVLProceduresInfo();
        m_scene.RetrieveProcedures(m_proceduresInfo);

        if (m_proceduresInfo.portfolios.size() > 0) {
            m_scene.ActivateStep(m_proceduresInfo.portfolios.get(0).steps.get(0).id, true, true);
        } else {
            return;
        }

        if (handler != null) {
            // do calculation using GL handle
            int flag = CustomRenderer.CALC_FINISHED;
            handler.dispatchMessage(Message.obtain(handler, flag, m_proceduresInfo));
            // adds a message to the UI thread's message queue
            handler = null;
        }

        m_partsListInfo = new SDVLPartsListInfo();
        m_scene.BuildPartsList(DVLTypes.DVLPARTSLIST.RECOMMENDED_uMaxParts, DVLTypes.DVLPARTSLIST.RECOMMENDED_uMaxNodesInSinglePart, DVLTypes.DVLPARTSLIST.RECOMMENDED_uMaxPartNameLength,
                DVLTypes.DVLPARTSLISTTYPE.ALL, DVLTypes.DVLPARTSLISTSORT.NAME_ASCENDING, DVLTypes.DVLID_INVALID, "", m_partsListInfo);
    }

    public void onSurfaceChanged(GL10 gl, int w, int h) {
        m_renderer.SetDimensions(w, h);
    }

    public void onDrawFrame(GL10 gl) {
        m_gestures.update(m_renderer);

        SDVLMatrix matView = new SDVLMatrix();
        SDVLMatrix matProj = new SDVLMatrix();
        m_renderer.GetCameraMatrices(matView, matProj);

        m_renderer.RenderFrame();
    }

    public DVLScene getScene() {
        return m_scene;
    }
}
