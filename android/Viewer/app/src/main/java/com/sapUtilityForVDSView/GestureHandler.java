package com.sapUtilityForVDSView;

import android.view.MotionEvent;
import android.view.View;

import java.util.concurrent.ConcurrentLinkedQueue;

/**
 * to handle gesture for VDS page.
 */
public class GestureHandler implements View.OnTouchListener {
    ConcurrentLinkedQueue<Event> m_events;
    int m_iPointer;
    float m_posX1, m_posY1;
    float m_posX2, m_posY2;
    boolean m_bGesture;

    public GestureHandler() {
        m_events = new ConcurrentLinkedQueue<Event>();

        m_iPointer = 0;
        m_bGesture = false;
    }

    public boolean onTouch(View v, MotionEvent e) {
        switch (e.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_MOVE:
            case MotionEvent.ACTION_POINTER_DOWN:
            case MotionEvent.ACTION_POINTER_UP:
                m_events.add(new Event(e));
                return true;
        }

        return false;
    }

    public void update(com.sap.ve.DVLRenderer renderer) {
        while (true) {
            Event ev = m_events.poll();
            if (ev == null)
                break;

            switch (ev.event) {
                case MotionEvent.ACTION_DOWN:
                    m_iPointer = 1;
                    m_posX1 = ev.x1;
                    m_posY1 = ev.y1;
                    break;

                case MotionEvent.ACTION_UP:
                    m_iPointer = 0;
                    if (m_bGesture) {
                        m_bGesture = false;
                        renderer.EndGesture();
                    } else {
                        renderer.Tap(ev.x1, ev.y1, false);
                    }
                    break;

                case MotionEvent.ACTION_MOVE:
                    if (ev.pointerCount > 1) {
                        float mx1 = (m_posX1 + m_posX2) * 0.5f;
                        float my1 = (m_posY1 + m_posY2) * 0.5f;

                        if (!m_bGesture && renderer.BeginGesture(mx1, my1).Succeeded())
                            m_bGesture = true;

                        {// pan
                            float mx2 = (ev.x1 + ev.x2) * 0.5f;
                            float my2 = (ev.y1 + ev.y2) * 0.5f;
                            renderer.Pan(mx2 - mx1, my2 - my1);
                        }

                        {// zoom
                            float dx1 = (m_posX2 - m_posX1);
                            float dy1 = (m_posY2 - m_posY1);
                            float dx2 = (ev.x2 - ev.x1);
                            float dy2 = (ev.y2 - ev.y1);
                            float d1 = (float) Math.sqrt(dx1 * dx1 + dy1 * dy1);
                            float d2 = (float) Math.sqrt(dx2 * dx2 + dy2 * dy2);
                            if ((d2 != d1) && (d1 != 0.0f))
                                renderer.Zoom(d2 / d1);
                        }

                        m_posX1 = ev.x1;
                        m_posY1 = ev.y1;
                        m_posX2 = ev.x2;
                        m_posY2 = ev.y2;
                    } else {
                        if ((m_iPointer & 1) != 0) {
                            if ((ev.x1 != m_posX1) || (ev.y1 != m_posY1)) {// rotate
                                if (!m_bGesture && renderer.BeginGesture(ev.x1, ev.y1).Succeeded())
                                    m_bGesture = true;

                                renderer.Rotate(ev.x1 - m_posX1, ev.y1 - m_posY1);
                                m_posX1 = ev.x1;
                                m_posY1 = ev.y1;
                            }
                        } else {
                            if ((ev.x1 != m_posX2) || (ev.y1 != m_posY2)) {// rotate
                                if (!m_bGesture && renderer.BeginGesture(ev.x1, ev.y1).Succeeded())
                                    m_bGesture = true;

                                renderer.Rotate(ev.x1 - m_posX2, ev.y1 - m_posY2);
                                m_posX2 = ev.x1;
                                m_posY2 = ev.y1;
                            }
                        }
                    }
                    break;

                case MotionEvent.ACTION_POINTER_DOWN:
                    if (m_bGesture) {
                        m_bGesture = false;
                        renderer.EndGesture();
                    }

                    if (ev.actionIndex == 1) {
                        m_iPointer |= 2;
                        m_posX2 = ev.x2;
                        m_posY2 = ev.y2;
                    } else if (ev.actionIndex == 0) {
                        m_iPointer |= 1;
                        m_posX1 = ev.x1;
                        m_posY1 = ev.y1;
                    }
                    break;

                case MotionEvent.ACTION_POINTER_UP:
                    if (ev.actionIndex == 1) {
                        m_iPointer &= ~2;
                    } else if (ev.actionIndex == 0) {
                        m_iPointer &= ~1;
                    }
                    break;
            }
        }
    }

    static final class Event {
        public int event;
        public int pointerCount;
        public int actionIndex;
        public float x1, y1;
        public float x2, y2;

        Event(MotionEvent e) {
            event = e.getActionMasked();
            x1 = e.getX();
            y1 = e.getY();
            pointerCount = e.getPointerCount();
            actionIndex = e.getActionIndex();
            if (pointerCount > 1) {
                MotionEvent.PointerCoords pc = new MotionEvent.PointerCoords();
                e.getPointerCoords(1, pc);
                x2 = pc.x;
                y2 = pc.y;
            } else {
                x2 = 0.f;
                y2 = 0.f;
            }
        }
    }
}
