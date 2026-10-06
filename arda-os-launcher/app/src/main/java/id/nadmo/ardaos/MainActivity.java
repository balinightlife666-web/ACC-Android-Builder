package id.nadmo.ardaos;

import android.app.Activity;
import android.app.ActivityManager;
import android.app.AlertDialog;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.LauncherActivityInfo;
import android.content.pm.LauncherApps;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.os.BatteryManager;
import android.os.Bundle;
import android.os.StatFs;
import android.os.UserHandle;
import android.os.UserManager;
import android.provider.Settings;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.GridLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextClock;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

public class MainActivity extends Activity {
    private final int BG = Color.rgb(5, 8, 13);
    private final int PANEL = Color.rgb(9, 17, 26);
    private final int PANEL_2 = Color.rgb(12, 23, 34);
    private final int CYAN = Color.rgb(57, 226, 255);
    private final int MAGENTA = Color.rgb(255, 53, 173);
    private final int TEXT = Color.rgb(232, 244, 248);
    private final int MUTED = Color.rgb(122, 151, 164);
    private LinearLayout root;

    private LauncherApps launcherApps;
    private UserManager userManager;

    private static class AppEntry {
        LauncherActivityInfo info;
        UserHandle user;
        String label;
        String displayLabel;
        String packageName;
        Drawable icon;

        AppEntry(LauncherActivityInfo info, UserHandle user, String label, String packageName, Drawable icon) {
            this.info = info;
            this.user = user;
            this.label = label;
            this.displayLabel = label;
            this.packageName = packageName;
            this.icon = icon;
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        launcherApps = (LauncherApps) getSystemService(LAUNCHER_APPS_SERVICE);
        userManager = (UserManager) getSystemService(USER_SERVICE);
        showHome();
        if (!isDefaultHome()) openHomeSettings();
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (root != null) showHome();
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

    private GradientDrawable panelDrawable(int color, int radius, int strokeColor) {
        GradientDrawable gd = new GradientDrawable();
        gd.setColor(color);
        gd.setCornerRadius(dp(radius));
        gd.setStroke(dp(1), strokeColor);
        return gd;
    }

    private GradientDrawable hudDrawable(int color, int strokeColor) {
        GradientDrawable gd = new GradientDrawable();
        gd.setColor(color);
        gd.setCornerRadius(dp(4));
        gd.setStroke(dp(1), strokeColor, dp(5), dp(3));
        return gd;
    }

    private TextView text(String value, int size, int color, boolean bold) {
        TextView t = new TextView(this);
        t.setText(value);
        t.setTextSize(size);
        t.setTextColor(color);
        t.setTypeface(Typeface.MONOSPACE, bold ? Typeface.BOLD : Typeface.NORMAL);
        return t;
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

    private void showHome() {
        root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(14), dp(12), dp(14), dp(14));
        root.setBackgroundColor(BG);
        setContentView(root);

        LinearLayout header = new LinearLayout(this);
        header.setGravity(Gravity.CENTER_VERTICAL);
        TextView brand = text("ARDA OS", 17, CYAN, true);
        TextView sys = text("  // NADMO CYBERDECK", 10, MUTED, false);
        header.addView(brand);
        header.addView(sys, new LinearLayout.LayoutParams(0, -2, 1));
        TextView gear = text("⚙", 24, CYAN, false);
        gear.setGravity(Gravity.CENTER);
        gear.setOnClickListener(v -> startActivity(new Intent(Settings.ACTION_SETTINGS)));
        header.addView(gear, new LinearLayout.LayoutParams(dp(42), dp(42)));
        root.addView(header);

        LinearLayout timeRow = new LinearLayout(this);
        timeRow.setGravity(Gravity.CENTER_VERTICAL);
        timeRow.setPadding(0, dp(8), 0, dp(8));
        TextClock clock = new TextClock(this);
        clock.setFormat12Hour("HH:mm");
        clock.setFormat24Hour("HH:mm");
        clock.setTextSize(46);
        clock.setTextColor(TEXT);
        clock.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
        timeRow.addView(clock, new LinearLayout.LayoutParams(0, -2, 1));

        LinearLayout rightTime = new LinearLayout(this);
        rightTime.setOrientation(LinearLayout.VERTICAL);
        rightTime.setGravity(Gravity.END);
        TextView core = text("CORE // ONLINE", 11, CYAN, true);
        core.setGravity(Gravity.END);
        TextClock date = new TextClock(this);
        date.setFormat12Hour("EEE dd MMM");
        date.setFormat24Hour("EEE dd MMM");
        date.setTextSize(11);
        date.setTextColor(MUTED);
        date.setTypeface(Typeface.MONOSPACE);
        date.setGravity(Gravity.END);
        rightTime.addView(core);
        rightTime.addView(date);
        timeRow.addView(rightTime);
        root.addView(timeRow);

        View line = new View(this);
        line.setBackgroundColor(CYAN);
        root.addView(line, new LinearLayout.LayoutParams(-1, dp(1)));

        LinearLayout telemetry = new LinearLayout(this);
        telemetry.setPadding(0, dp(10), 0, dp(10));
        addTelemetry(telemetry, "BAT", batteryText());
        addTelemetry(telemetry, "RAM", memoryText());
        addTelemetry(telemetry, "STO", storageText());
        root.addView(telemetry);

        if (!isDefaultHome()) {
            TextView setup = text("HOME ROLE NOT ACTIVE  //  TAP TO FIX", 11, MAGENTA, true);
            setup.setGravity(Gravity.CENTER);
            setup.setPadding(dp(8), dp(10), dp(8), dp(10));
            setup.setBackground(hudDrawable(PANEL, MAGENTA));
            setup.setOnClickListener(v -> openHomeSettings());
            LinearLayout.LayoutParams slp = new LinearLayout.LayoutParams(-1, -2);
            slp.setMargins(0, 0, 0, dp(10));
            root.addView(setup, slp);
        }

        TextView section = text(">> PRIMARY NODES", 10, MUTED, true);
        section.setPadding(0, dp(4), 0, dp(8));
        root.addView(section);

        Button acc = cyberButton("ACC OS X", true);
        acc.setOnClickListener(v -> launchTarget("acc"));
        LinearLayout.LayoutParams heroLp = new LinearLayout.LayoutParams(-1, dp(66));
        heroLp.setMargins(0, 0, 0, dp(8));
        root.addView(acc, heroLp);

        LinearLayout row1 = new LinearLayout(this);
        addHomeNode(row1, "WA", "wa");
        addHomeNode(row1, "NOTE", "note");
        root.addView(row1, new LinearLayout.LayoutParams(-1, dp(66)));

        LinearLayout row2 = new LinearLayout(this);
        addHomeNode(row2, "FB", "fb");
        addHomeNode(row2, "IG", "ig");
        LinearLayout.LayoutParams row2Lp = new LinearLayout.LayoutParams(-1, dp(66));
        row2Lp.setMargins(0, dp(8), 0, 0);
        root.addView(row2, row2Lp);

        View spacer = new View(this);
        root.addView(spacer, new LinearLayout.LayoutParams(1, 0, 1));

        Button apps = cyberButton("APPS  //  ALL INSTALLED + CLONES", false);
        apps.setOnClickListener(v -> showApps(""));
        LinearLayout.LayoutParams appsLp = new LinearLayout.LayoutParams(-1, dp(54));
        appsLp.setMargins(0, dp(10), 0, 0);
        root.addView(apps, appsLp);

        TextView footer = text("ARDA OS v0.4  •  PROFILE-AWARE LAUNCHER", 9, MUTED, false);
        footer.setGravity(Gravity.CENTER);
        footer.setPadding(0, dp(8), 0, 0);
        root.addView(footer);
    }

    private void addTelemetry(LinearLayout parent, String key, String value) {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(10), dp(8), dp(10), dp(8));
        box.setBackground(panelDrawable(PANEL, 4, Color.rgb(27, 68, 79)));
        TextView k = text(key + " //", 9, MUTED, true);
        TextView v = text(value, 13, CYAN, true);
        box.addView(k);
        box.addView(v);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, dp(54), 1);
        lp.setMargins(dp(2), 0, dp(2), 0);
        parent.addView(box, lp);
    }

    private String batteryText() {
        BatteryManager bm = (BatteryManager) getSystemService(BATTERY_SERVICE);
        int pct = bm == null ? -1 : bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY);
        return pct < 0 ? "--" : pct + "%";
    }

    private String memoryText() {
        ActivityManager am = (ActivityManager) getSystemService(ACTIVITY_SERVICE);
        ActivityManager.MemoryInfo mi = new ActivityManager.MemoryInfo();
        if (am == null) return "--";
        am.getMemoryInfo(mi);
        long avail = mi.availMem / (1024L * 1024L * 1024L);
        return avail + "G";
    }

    private String storageText() {
        try {
            StatFs stat = new StatFs(getFilesDir().getAbsolutePath());
            long free = stat.getAvailableBytes() / (1024L * 1024L * 1024L);
            return free + "G";
        } catch (Exception e) {
            return "--";
        }
    }

    private Button cyberButton(String label, boolean hero) {
        Button b = new Button(this);
        b.setAllCaps(false);
        b.setText(label);
        b.setTextColor(hero ? CYAN : TEXT);
        b.setTextSize(hero ? 15 : 13);
        b.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
        b.setGravity(Gravity.CENTER_VERTICAL);
        b.setPadding(dp(16), 0, dp(16), 0);
        b.setBackground(hero ? hudDrawable(PANEL_2, CYAN) : panelDrawable(PANEL, 4, Color.rgb(29, 72, 84)));
        return b;
    }

    private void addHomeNode(LinearLayout row, String label, String target) {
        Button b = cyberButton(label, false);
        b.setOnClickListener(v -> launchTarget(target));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, -1, 1);
        lp.setMargins(dp(2), 0, dp(2), 0);
        row.addView(b, lp);
    }

    private List<AppEntry> getAllApps() {
        List<AppEntry> result = new ArrayList<>();

        if (launcherApps != null && userManager != null) {
            try {
                List<UserHandle> profiles = userManager.getUserProfiles();
                for (UserHandle user : profiles) {
                    List<LauncherActivityInfo> activities = launcherApps.getActivityList(null, user);
                    for (LauncherActivityInfo info : activities) {
                        if (info.getApplicationInfo().packageName.equals(getPackageName())) continue;
                        String label = info.getLabel() == null
                                ? info.getApplicationInfo().packageName
                                : info.getLabel().toString();
                        result.add(new AppEntry(
                                info,
                                user,
                                label,
                                info.getApplicationInfo().packageName,
                                info.getBadgedIcon(0)
                        ));
                    }
                }
            } catch (Exception ignored) {
            }
        }

        if (result.isEmpty()) {
            PackageManager pm = getPackageManager();
            Intent main = new Intent(Intent.ACTION_MAIN, null);
            main.addCategory(Intent.CATEGORY_LAUNCHER);
            List<ResolveInfo> apps = pm.queryIntentActivities(main, 0);
            for (ResolveInfo info : apps) {
                if (info.activityInfo.packageName.equals(getPackageName())) continue;
                String label = info.loadLabel(pm).toString();
                result.add(new AppEntry(null, android.os.Process.myUserHandle(), label,
                        info.activityInfo.packageName, info.loadIcon(pm)));
            }
        }

        Collections.sort(result, Comparator.comparing(a -> a.label.toLowerCase(Locale.ROOT)));

        Map<String, Integer> totals = new HashMap<>();
        for (AppEntry e : result) {
            String key = e.label.toLowerCase(Locale.ROOT);
            totals.put(key, totals.getOrDefault(key, 0) + 1);
        }

        Map<String, Integer> seen = new HashMap<>();
        for (AppEntry e : result) {
            String key = e.label.toLowerCase(Locale.ROOT);
            int count = totals.getOrDefault(key, 1);
            if (count > 1) {
                int idx = seen.getOrDefault(key, 0) + 1;
                seen.put(key, idx);
                e.displayLabel = e.label + " " + idx;
            }
        }
        return result;
    }

    private List<AppEntry> findTargetApps(String target) {
        List<AppEntry> matches = new ArrayList<>();
        for (AppEntry e : getAllApps()) {
            String l = e.label.toLowerCase(Locale.ROOT);
            String p = e.packageName.toLowerCase(Locale.ROOT);
            boolean ok = false;
            switch (target) {
                case "wa":
                    ok = l.contains("whatsapp") || p.contains("whatsapp");
                    break;
                case "fb":
                    ok = l.equals("facebook") || l.startsWith("facebook ")
                            || p.equals("com.facebook.katana") || p.equals("com.facebook.lite");
                    break;
                case "ig":
                    ok = l.contains("instagram") || p.contains("instagram");
                    break;
                case "note":
                    ok = l.equals("notes") || l.equals("note") || l.contains("notepad")
                            || l.contains("keep notes") || p.contains("notebook")
                            || p.contains(".note") || p.contains("keep");
                    break;
                case "acc":
                    ok = l.contains("acc os x") || l.contains("acc os")
                            || p.contains("accos") || p.contains("acc.os");
                    break;
            }
            if (ok) matches.add(e);
        }
        return matches;
    }

    private void launchTarget(String target) {
        List<AppEntry> matches = findTargetApps(target);
        if (matches.isEmpty()) {
            Toast.makeText(this, "Target belum ditemukan. Buka Apps untuk pilih manual.", Toast.LENGTH_SHORT).show();
            showApps(target);
            return;
        }
        if (matches.size() == 1) {
            launchApp(matches.get(0));
            return;
        }

        String title;
        switch (target) {
            case "wa": title = "Pilih WhatsApp"; break;
            case "fb": title = "Pilih Facebook"; break;
            case "ig": title = "Pilih Instagram"; break;
            case "note": title = "Pilih Notes"; break;
            default: title = "Pilih aplikasi";
        }

        String[] names = new String[matches.size()];
        for (int i = 0; i < matches.size(); i++) {
            names[i] = matches.get(i).displayLabel;
        }

        new AlertDialog.Builder(this)
                .setTitle(title + "  //  " + matches.size() + " instance")
                .setItems(names, (dialog, which) -> launchApp(matches.get(which)))
                .setNegativeButton("Batal", null)
                .show();
    }

    private void launchApp(AppEntry entry) {
        if (entry.info != null && launcherApps != null) {
            try {
                launcherApps.startMainActivity(entry.info.getComponentName(), entry.user, null, null);
                return;
            } catch (Exception ignored) {
            }
        }

        Intent launch = getPackageManager().getLaunchIntentForPackage(entry.packageName);
        if (launch != null) {
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(launch);
        } else {
            Toast.makeText(this, "Tidak bisa membuka " + entry.displayLabel, Toast.LENGTH_SHORT).show();
        }
    }

    private void showApps(String presetQuery) {
        LinearLayout shell = new LinearLayout(this);
        shell.setOrientation(LinearLayout.VERTICAL);
        shell.setPadding(dp(12), dp(12), dp(12), dp(12));
        shell.setBackgroundColor(BG);
        setContentView(shell);

        LinearLayout head = new LinearLayout(this);
        head.setGravity(Gravity.CENTER_VERTICAL);
        Button home = cyberButton("← HOME", false);
        home.setOnClickListener(v -> showHome());
        head.addView(home, new LinearLayout.LayoutParams(dp(104), dp(46)));
        TextView title = text("  APP GRID // ALL PROFILES", 12, CYAN, true);
        head.addView(title, new LinearLayout.LayoutParams(0, -2, 1));
        shell.addView(head);

        EditText search = new EditText(this);
        search.setSingleLine(true);
        search.setHint("SEARCH INSTALLED APPS...");
        search.setHintTextColor(MUTED);
        search.setTextColor(TEXT);
        search.setTextSize(12);
        search.setTypeface(Typeface.MONOSPACE);
        search.setPadding(dp(14), 0, dp(14), 0);
        search.setBackground(hudDrawable(PANEL, CYAN));
        LinearLayout.LayoutParams searchLp = new LinearLayout.LayoutParams(-1, dp(48));
        searchLp.setMargins(0, dp(10), 0, dp(10));
        shell.addView(search, searchLp);

        ScrollView scroll = new ScrollView(this);
        GridLayout grid = new GridLayout(this);
        grid.setColumnCount(4);
        grid.setAlignmentMode(GridLayout.ALIGN_BOUNDS);
        grid.setUseDefaultMargins(false);
        grid.setPadding(0, 0, 0, dp(24));
        scroll.addView(grid);
        shell.addView(scroll, new LinearLayout.LayoutParams(-1, 0, 1));

        List<AppEntry> allApps = getAllApps();

        Runnable render = () -> {
            String q = search.getText().toString().trim().toLowerCase(Locale.ROOT);
            grid.removeAllViews();
            for (AppEntry entry : allApps) {
                if (!q.isEmpty()
                        && !entry.displayLabel.toLowerCase(Locale.ROOT).contains(q)
                        && !entry.packageName.toLowerCase(Locale.ROOT).contains(q)) {
                    continue;
                }

                LinearLayout card = new LinearLayout(this);
                card.setOrientation(LinearLayout.VERTICAL);
                card.setGravity(Gravity.CENTER);
                card.setPadding(dp(4), dp(7), dp(4), dp(6));
                card.setBackground(panelDrawable(PANEL, 4, Color.rgb(24, 57, 68)));

                ImageView icon = new ImageView(this);
                icon.setImageDrawable(entry.icon);
                card.addView(icon, new LinearLayout.LayoutParams(dp(40), dp(40)));

                TextView label = text(entry.displayLabel, 9, TEXT, false);
                label.setGravity(Gravity.CENTER);
                label.setMaxLines(2);
                LinearLayout.LayoutParams labelLp = new LinearLayout.LayoutParams(-1, 0, 1);
                labelLp.setMargins(0, dp(5), 0, 0);
                card.addView(label, labelLp);

                card.setOnClickListener(v -> launchApp(entry));

                GridLayout.LayoutParams gp = new GridLayout.LayoutParams();
                gp.width = 0;
                gp.height = dp(92);
                gp.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
                gp.setMargins(dp(3), dp(3), dp(3), dp(3));
                grid.addView(card, gp);
            }
        };

        search.addTextChangedListener(new android.text.TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override public void onTextChanged(CharSequence s, int start, int before, int count) { render.run(); }
            @Override public void afterTextChanged(android.text.Editable s) {}
        });

        if (presetQuery == null) presetQuery = "";
        if (presetQuery.equals("wa")) presetQuery = "whatsapp";
        if (presetQuery.equals("fb")) presetQuery = "facebook";
        if (presetQuery.equals("ig")) presetQuery = "instagram";
        if (presetQuery.equals("note")) presetQuery = "note";
        if (presetQuery.equals("acc")) presetQuery = "acc";
        search.setText(presetQuery);
        search.setSelection(search.getText().length());
        render.run();
    }

    @Override
    public void onBackPressed() {
        showHome();
    }
}
