package com.sap.ve;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.Typeface;
import android.text.TextPaint;
import android.util.Log;

import com.sap.ve.DVLScene.DynamicLabel;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class DVLUtils {
    private static int ProcessTextureSize(int s, int maxResolution, boolean mustBePowerOfTwo) {
        if ((maxResolution > 0) && (s > maxResolution))
            s = maxResolution;

        if (!mustBePowerOfTwo)
            return s;

        int p2Size = 1;
        while (p2Size < s)
            p2Size <<= 1;

        if (((maxResolution > 0) && (p2Size > maxResolution)) || ((p2Size - s) > (p2Size >> 2)))
            p2Size >>= 1;

        return p2Size;
    }

    public static Bitmap DecodeImage(byte[] data, int length, int maxResolution, boolean mustBePowerOfTwo) {
        try {
            Bitmap bitmap = BitmapFactory.decodeByteArray(data, 0, length);
            if (bitmap == null)
                return null;

            int newWidth = ProcessTextureSize(bitmap.getWidth(), maxResolution, mustBePowerOfTwo);
            int newHeight = ProcessTextureSize(bitmap.getHeight(), maxResolution, mustBePowerOfTwo);
            if ((newWidth != bitmap.getWidth()) || (newHeight != bitmap.getHeight()))
                bitmap = Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true);

            return bitmap;
        } catch (Throwable e) {
            Log.w("DecodeImage", e.getMessage());
            return null;
        }
    }

    public static Pattern RegexCompile(String strPattern) {
        try {
            Pattern p = Pattern.compile(strPattern);
            return p;
        } catch (Throwable e) {
            Log.w("Regex.Compile", e.getMessage());
            return null;
        }
    }

    public static boolean RegexMatch(Pattern p, String inputString, boolean bAnchored) {
        try {
            Matcher m = p.matcher(inputString);
            if (bAnchored)
                return m.matches();

            m.useAnchoringBounds(false);
            return m.find();
        } catch (Throwable e) {
            Log.w("Regex.Match", e.getMessage());
            return false;
        }
    }

    public static Bitmap CreateBitmap(int width, int height) {
        try {
            return Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        } catch (Throwable e) {
            Log.e("CreateBitmap", e.getMessage());
            return null;
        }
    }

    public static Canvas CreateCanvas(Bitmap bitmap) {
        try {
            return new Canvas(bitmap);
        } catch (Throwable e) {
            Log.e("CreateCanvas", e.getMessage());
            return null;
        }
    }

    public static void ClearCanvas(Canvas canvas) {
        canvas.drawColor(android.graphics.Color.MAGENTA, android.graphics.PorterDuff.Mode.CLEAR);
    }

    public static void DrawDynamicLabel(Canvas canvas, DynamicLabel dl, RectF rc, RectF rcClip) {
        canvas.clipRect(rcClip);

        rc.inset(dl.frameThickness * 0.5f, dl.frameThickness * 0.5f);
        if (rc.isEmpty())
            return;

        Paint paint = new Paint();

        if (dl.opacity > 0.f) {
            paint.setStyle(Paint.Style.FILL);
            if (dl.image != null) {
                paint.setColor(0xFFFFFFFF);
                paint.setAlpha((int) (dl.opacity * 255));
                paint.setFilterBitmap(true);

                float iw = rc.width(), ih = rc.height();
                if (iw * (float) dl.image.getHeight() > ih * (float) dl.image.getWidth())
                    iw = ih * (float) dl.image.getWidth() / (float) dl.image.getHeight();
                else
                    ih = iw * (float) dl.image.getHeight() / (float) dl.image.getWidth();

                RectF rcImage = new RectF();
                rcImage.left = rc.left + (rc.width() - iw) * 0.5f;
                rcImage.top = rc.top + (rc.height() - ih) * 0.5f;
                rcImage.right = rcImage.left + iw;
                rcImage.bottom = rcImage.top + ih;
                canvas.drawBitmap(dl.image, new android.graphics.Rect(0, 0, dl.image.getWidth(), dl.image.getHeight()), rcImage, paint);
            } else {
                paint.setColor(dl.bgColor);
                canvas.drawRoundRect(rc, dl.frameRadius, dl.frameRadius, paint);
            }
        }

        if ((dl.frameColor & 0xFF000000) != 0) {
            paint.setColor(dl.frameColor);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(dl.frameThickness);
            canvas.drawRoundRect(rc, dl.frameRadius, dl.frameRadius, paint);
        }

        if (dl.text != null) {
            rc.inset(dl.marginX + dl.frameThickness * 0.5f, dl.marginY + dl.frameThickness * 0.5f);
            if (rc.isEmpty())
                return;

            TextPaint textPaint = new TextPaint();
            textPaint.setAntiAlias(true);
            textPaint.setStyle(Paint.Style.FILL);
            textPaint.setColor(dl.textColor | 0xFF000000);
            textPaint.setTypeface(dl.font != null ? dl.font : Typeface.DEFAULT);
            textPaint.setTextAlign(Paint.Align.LEFT);
            textPaint.setTextSize(dl.fontSize);

            String split[] = dl.text.split("\n");
            float fontSpacing = textPaint.getFontSpacing();
            int numLines = Math.min(split.length, (int) (rc.height() / fontSpacing));
            float y = rc.top - textPaint.getFontMetrics().ascent;
            if (dl.alignmentY > 0)
                y += (rc.height() - numLines * fontSpacing) * 0.5f * (float) dl.alignmentY;

            for (int i = 0; i < numLines; i++) {
                CharSequence cs = android.text.TextUtils.ellipsize(split[i], textPaint, rc.width(), android.text.TextUtils.TruncateAt.END);
                float x = rc.left;
                if (dl.alignmentX > 0)
                    x += (rc.width() - textPaint.measureText(cs, 0, cs.length())) * 0.5f * (float) dl.alignmentX;

                canvas.drawText(cs, 0, cs.length(), x, y, textPaint);
                y += fontSpacing;
            }
        }
    }
}