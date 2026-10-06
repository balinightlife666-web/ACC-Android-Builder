package id.nadmo.ardaos;

import android.app.Notification;
import android.app.PendingIntent;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;

public class ArdaNotificationService extends NotificationListenerService {
    public static class NotificationItem {
        public final String key;
        public final String packageName;
        public final String title;
        public final String text;
        public final long postTime;
        public final PendingIntent contentIntent;

        NotificationItem(String key, String packageName, String title, String text,
                         long postTime, PendingIntent contentIntent) {
            this.key = key;
            this.packageName = packageName;
            this.title = title;
            this.text = text;
            this.postTime = postTime;
            this.contentIntent = contentIntent;
        }
    }

    private static volatile ArdaNotificationService instance;

    @Override
    public void onListenerConnected() {
        super.onListenerConnected();
        instance = this;
    }

    @Override
    public void onListenerDisconnected() {
        instance = null;
        super.onListenerDisconnected();
    }

    public static List<NotificationItem> snapshot() {
        ArdaNotificationService service = instance;
        if (service == null) return new ArrayList<>();

        StatusBarNotification[] active;
        try {
            active = service.getActiveNotifications();
        } catch (Exception e) {
            return new ArrayList<>();
        }

        if (active == null) return new ArrayList<>();
        Arrays.sort(active, Comparator.comparingLong(StatusBarNotification::getPostTime).reversed());

        List<NotificationItem> out = new ArrayList<>();
        for (StatusBarNotification sbn : active) {
            if (sbn == null || sbn.getNotification() == null) continue;
            if (sbn.getPackageName().equals(service.getPackageName())) continue;

            Notification n = sbn.getNotification();
            CharSequence titleCs = n.extras.getCharSequence(Notification.EXTRA_TITLE);
            CharSequence textCs = n.extras.getCharSequence(Notification.EXTRA_TEXT);

            String title = titleCs == null ? "" : titleCs.toString().trim();
            String text = textCs == null ? "" : textCs.toString().trim();
            if (title.isEmpty() && text.isEmpty()) continue;

            out.add(new NotificationItem(
                    sbn.getKey(),
                    sbn.getPackageName(),
                    title,
                    text,
                    sbn.getPostTime(),
                    n.contentIntent
            ));
        }
        return out;
    }

    public static boolean dismiss(String key) {
        ArdaNotificationService service = instance;
        if (service == null || key == null) return false;
        try {
            service.cancelNotification(key);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public static boolean dismissAll() {
        ArdaNotificationService service = instance;
        if (service == null) return false;
        try {
            service.cancelAllNotifications();
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
