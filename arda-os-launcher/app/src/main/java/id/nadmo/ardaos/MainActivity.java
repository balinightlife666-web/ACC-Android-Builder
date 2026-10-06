package id.nadmo.ardaos;

import android.app.Activity;
import android.app.role.RoleManager;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.HorizontalScrollView;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextClock;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

public class MainActivity extends Activity {
    private final int BG = Color.rgb(7, 11, 18);
    private final int PANEL = Color.rgb(16, 24, 35);
    private final int CYAN = Color.rgb(78, 224, 255);
    private final int TEXT = Color.rgb(232, 241, 247);
    private final int MUTED = Color.rgb(131, 150, 164);
    private LinearLayout root;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        showHome();
        if (!isDefaultHome()) {
            openHomeSettings();
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (root != null) showHome();
    }

    private boolean isDefaultHome() {
        Intent intent = new Intent(Intent.ACTION_MAIN);
        intent.addCategory(Intent.CATEGORY_HOME);
        ResolveInfo resolveInfo = getPackageManager().resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY);
        return resolveInfo != null && resolveInfo.activityInfo != null
                && getPackageName().equals(resolveInfo.activityInfo.packageName);
    }

    private void openHomeSettings() {
        Intent home = new Intent(Settings.ACTION_HOME_SETTINGS);
        if (home.resolveActivity(getPackageManager()) != null) {
            startActivity(home);
            return;
        }

        Intent defaults = new Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS);
        if (defaults.resolveActivity(getPackageManager()) != null) {
            startActivity(defaults);
            return;
        }

        startActivity(new Intent(Settings.ACTION_SETTINGS));
    }

    private void openDefaultAppsSettings() {
        Intent defaults = new Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS);
        if (defaults.resolveActivity(getPackageManager()) != null) {
            startActivity(defaults);
        } else {
            startActivity(new Intent(Settings.ACTION_SETTINGS));
        }
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

    private GradientDrawable rounded(int color, int radius, int strokeColor) {
        GradientDrawable gd = new GradientDrawable();
        gd.setColor(color);
        gd.setCornerRadius(dp(radius));
        if (strokeColor != Color.TRANSPARENT) gd.setStroke(dp(1), strokeColor);
        return gd;
    }

    private TextView text(String value, int size, int color, boolean bold) {
        TextView t = new TextView(this);
        t.setText(value);
        t.setTextSize(size);
        t.setTextColor(color);
        if (bold) t.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        return t;
    }

    private Button actionButton(String label) {
        Button b = new Button(this);
        b.setText(label);
        b.setTextColor(TEXT);
        b.setAllCaps(false);
        b.setTextSize(13);
        b.setBackground(rounded(PANEL, 14, Color.rgb(36, 58, 73)));
        b.setPadding(dp(14), dp(8), dp(14), dp(8));
        return b;
    }

    private void showHome() {
        root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(18), dp(20), dp(18), dp(16));
        root.setBackgroundColor(BG);
        setContentView(root);

        LinearLayout top = new LinearLayout(this);
        top.setGravity(Gravity.CENTER_VERTICAL);
        TextView brand = text("ARDA OS", 20, CYAN, true);
        TextView sub = text("  // NADMO SYSTEM", 11, MUTED, false);
        top.addView(brand);
        top.addView(sub);
        root.addView(top);

        TextClock clock = new TextClock(this);
        clock.setFormat12Hour("HH:mm");
        clock.setFormat24Hour("HH:mm");
        clock.setTextSize(58);
        clock.setTextColor(TEXT);
        clock.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        clock.setPadding(0, dp(24), 0, 0);
        root.addView(clock);

        TextClock date = new TextClock(this);
        date.setFormat12Hour("EEE, dd MMM yyyy");
        date.setFormat24Hour("EEE, dd MMM yyyy");
        date.setTextSize(15);
        date.setTextColor(MUTED);
        root.addView(date);

        LinearLayout status = new LinearLayout(this);
        status.setOrientation(LinearLayout.VERTICAL);
        status.setPadding(dp(16), dp(14), dp(16), dp(14));
        status.setBackground(rounded(PANEL, 18, Color.rgb(27, 63, 79)));
        LinearLayout.LayoutParams statusLp = new LinearLayout.LayoutParams(-1, -2);
        statusLp.setMargins(0, dp(28), 0, dp(12));
        root.addView(status, statusLp);

        if (isDefaultHome()) {
            status.addView(text("ARDA OS // HOME ACTIVE", 13, CYAN, true));
            TextView msg = text("Launcher ini sekarang mengendalikan Home Screen.", 12, MUTED, false);
            msg.setPadding(0, dp(6), 0, 0);
            status.addView(msg);
        } else {
            status.addView(text("SETUP REQUIRED", 13, Color.rgb(255, 194, 77), true));
            TextView msg = text("Android masih memakai launcher bawaan.", 12, MUTED, false);
            msg.setPadding(0, dp(6), 0, dp(10));
            status.addView(msg);

            Button setHome = actionButton("Jadikan ARDA OS sebagai Home");
            setHome.setOnClickListener(v -> openHomeSettings());
            status.addView(setHome, new LinearLayout.LayoutParams(-1, dp(48)));
        }

        TextView quickLabel = text("QUICK ACCESS", 11, MUTED, true);
        quickLabel.setPadding(0, dp(12), 0, dp(8));
        root.addView(quickLabel);

        HorizontalScrollView hsv = new HorizontalScrollView(this);
        hsv.setHorizontalScrollBarEnabled(false);
        LinearLayout quick = new LinearLayout(this);
        quick.setOrientation(LinearLayout.HORIZONTAL);
        hsv.addView(quick);
        root.addView(hsv);

        addQuick(quick, "Apps", v -> showApps());
        addQuick(quick, "Home App", v -> openHomeSettings());
        addQuick(quick, "Default Apps", v -> openDefaultAppsSettings());
        addQuick(quick, "Settings", v -> startActivity(new Intent(Settings.ACTION_SETTINGS)));
        addQuick(quick, "Wi-Fi", v -> startActivity(new Intent(Settings.ACTION_WIFI_SETTINGS)));
        addQuick(quick, "Bluetooth", v -> startActivity(new Intent(Settings.ACTION_BLUETOOTH_SETTINGS)));

        View spacer = new View(this);
        root.addView(spacer, new LinearLayout.LayoutParams(1, 0, 1));

        LinearLayout dock = new LinearLayout(this);
        dock.setGravity(Gravity.CENTER);
        dock.setPadding(dp(8), dp(8), dp(8), dp(8));
        dock.setBackground(rounded(Color.rgb(12, 19, 29), 22, Color.rgb(31, 50, 64)));
        root.addView(dock, new LinearLayout.LayoutParams(-1, -2));
        addDock(dock, "PHONE", "com.google.android.dialer");
        addDock(dock, "CHAT", "com.whatsapp");
        addDock(dock, "APPS", null);
        addDock(dock, "CAM", "com.android.camera");
    }

    private void addQuick(LinearLayout parent, String label, View.OnClickListener listener) {
        Button b = actionButton(label);
        b.setOnClickListener(listener);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-2, dp(46));
        lp.setMargins(0, 0, dp(8), 0);
        parent.addView(b, lp);
    }

    private void addDock(LinearLayout parent, String label, String packageName) {
        Button b = actionButton(label);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, dp(52), 1);
        lp.setMargins(dp(3), 0, dp(3), 0);
        parent.addView(b, lp);
        if (packageName == null) {
            b.setOnClickListener(v -> showApps());
        } else {
            b.setOnClickListener(v -> launchPackage(packageName));
        }
    }

    private void launchPackage(String pkg) {
        Intent launch = getPackageManager().getLaunchIntentForPackage(pkg);
        if (launch != null) {
            startActivity(launch);
        } else {
            showApps();
        }
    }

    private void showApps() {
        LinearLayout shell = new LinearLayout(this);
        shell.setOrientation(LinearLayout.VERTICAL);
        shell.setPadding(dp(14), dp(16), dp(14), dp(12));
        shell.setBackgroundColor(BG);
        setContentView(shell);

        LinearLayout header = new LinearLayout(this);
        header.setGravity(Gravity.CENTER_VERTICAL);
        Button back = actionButton("← Home");
        back.setOnClickListener(v -> showHome());
        header.addView(back, new LinearLayout.LayoutParams(-2, dp(46)));
        TextView title = text("   APP DRAWER", 17, CYAN, true);
        header.addView(title);
        shell.addView(header);

        ScrollView scroll = new ScrollView(this);
        LinearLayout list = new LinearLayout(this);
        list.setOrientation(LinearLayout.VERTICAL);
        list.setPadding(0, dp(14), 0, dp(30));
        scroll.addView(list);
        shell.addView(scroll, new LinearLayout.LayoutParams(-1, 0, 1));

        PackageManager pm = getPackageManager();
        Intent main = new Intent(Intent.ACTION_MAIN, null);
        main.addCategory(Intent.CATEGORY_LAUNCHER);
        List<ResolveInfo> apps = new ArrayList<>(pm.queryIntentActivities(main, 0));
        Collections.sort(apps, Comparator.comparing(a -> a.loadLabel(pm).toString().toLowerCase()));

        for (ResolveInfo info : apps) {
            if (info.activityInfo.packageName.equals(getPackageName())) continue;
            LinearLayout row = new LinearLayout(this);
            row.setGravity(Gravity.CENTER_VERTICAL);
            row.setPadding(dp(12), dp(10), dp(12), dp(10));
            row.setBackground(rounded(PANEL, 14, Color.rgb(26, 42, 55)));
            LinearLayout.LayoutParams rowLp = new LinearLayout.LayoutParams(-1, dp(66));
            rowLp.setMargins(0, 0, 0, dp(8));
            list.addView(row, rowLp);

            ImageView icon = new ImageView(this);
            icon.setImageDrawable(info.loadIcon(pm));
            row.addView(icon, new LinearLayout.LayoutParams(dp(42), dp(42)));

            TextView label = text(info.loadLabel(pm).toString(), 14, TEXT, true);
            label.setPadding(dp(14), 0, 0, 0);
            row.addView(label, new LinearLayout.LayoutParams(0, -1, 1));

            row.setOnClickListener(v -> {
                Intent i = new Intent(Intent.ACTION_MAIN);
                i.addCategory(Intent.CATEGORY_LAUNCHER);
                i.setClassName(info.activityInfo.packageName, info.activityInfo.name);
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(i);
            });
        }
    }

    @Override
    public void onBackPressed() {
        showHome();
    }
}
