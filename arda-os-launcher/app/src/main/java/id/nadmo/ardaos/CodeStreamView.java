package id.nadmo.ardaos;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Typeface;
import android.os.SystemClock;
import android.view.View;

import java.util.Locale;

public class CodeStreamView extends View {
    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final String[] lines = new String[] {
            "ACC_OS_X::BOOT  NODE_SCAN  CACHE_WARM",
            "root@arda:~$ mount --cyberdeck /nadmo",
            "WA_INSTANCE_DETECTED  CHANNEL_READY",
            "IG_MEDIA_LINK::ONLINE  FB_SOCIAL::SYNC",
            "kernel.trace -> permissions:home/profile",
            "0xA9 NODE 149  HANDSHAKE ACCEPTED",
            "SYS_CLOCK SYNCHRONIZED  PROFILE_MAP OK",
            "NADMO://FASTLINK/ACC_OS_X/ROOT",
            "decrypt(session) -> access_granted",
            "launcher.apps --profiles --clones",
            "telemetry.stream bat ram storage",
            "notify.bridge :: listener awaiting packets",
            "comms.route -> whatsapp://instance/*",
            "media.route -> instagram://active",
            "social.route -> facebook://active",
            "notes.mount -> local_log_channel",
            "SYSTEM CACHE WARM  TOUCH_FEEDBACK ON",
            "CYBERDECK HUD v0.6.2  COMPACT MODE"
    };

    private float offset = 0f;
    private long lastFrame = 0L;
    private boolean running = true;

    public CodeStreamView(Context context) {
        super(context);
        paint.setTypeface(Typeface.MONOSPACE);
        paint.setTextSize(dp(10));
        paint.setColor(Color.argb(72, 42, 238, 255));
        setLayerType(View.LAYER_TYPE_SOFTWARE, null);
    }

    private float dp(float v) {
        return v * getResources().getDisplayMetrics().density;
    }

    @Override
    protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        running = true;
        lastFrame = SystemClock.uptimeMillis();
        postInvalidateOnAnimation();
    }

    @Override
    protected void onDetachedFromWindow() {
        running = false;
        super.onDetachedFromWindow();
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        if (!running) return;

        long now = SystemClock.uptimeMillis();
        long dt = lastFrame == 0 ? 16 : Math.min(80, now - lastFrame);
        lastFrame = now;

        offset -= dp(7.5f) * (dt / 1000f);
        float lineHeight = dp(22);
        if (offset <= -lineHeight) offset += lineHeight;

        int needed = (int) Math.ceil(getHeight() / lineHeight) + 3;
        for (int i = 0; i < needed; i++) {
            float y = offset + i * lineHeight;
            int idx = i % lines.length;
            String prefix = String.format(Locale.ROOT, "%02X ", (i * 17 + 9) & 0xff);
            canvas.drawText(prefix + lines[idx], dp(6), y, paint);

            if (i % 4 == 2) {
                paint.setColor(Color.argb(48, 255, 49, 153));
                canvas.drawText(":: " + lines[(idx + 5) % lines.length], dp(54), y + dp(9), paint);
                paint.setColor(Color.argb(72, 42, 238, 255));
            }
        }

        postInvalidateDelayed(66);
    }
}
