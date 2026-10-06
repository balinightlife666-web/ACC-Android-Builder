package id.nadmo.ardaos;

import android.app.Activity;
import android.app.ActivityManager;
import android.app.AlertDialog;
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
import android.view.HapticFeedbackConstants;
import android.view.MotionEvent;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
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
    private final int BG = Color.rgb(3, 7, 11);
    private final int PANEL = Color.rgb(8, 16, 24);
    private final int PANEL_2 = Color.rgb(11, 24, 34);
    private final int PANEL_3 = Color.rgb(14, 29, 40);
    private final int CYAN = Color.rgb(42, 238, 255);
    private final int MAGENTA = Color.rgb(255, 49, 153);
    private final int TEXT = Color.rgb(232, 246, 249);
    private final int MUTED = Color.rgb(111, 148, 160);
    private final int DIM = Color.rgb(28, 69, 81);

    private LinearLayout root;
    private LauncherApps launcherApps;
    private UserManager userManager;

    private List<AppEntry> appCache;
    private long appCacheAt = 0L;

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
        if (root != null && isDefaultHome()) {
            showHome();
        }
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
        gd.setCornerRadius(dp(3));
        gd.setStroke(dp(1), strokeColor, dp(6), dp(3));
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

    private void makeInteractive(View view) {
        view.setClickable(true);
        view.setOnTouchListener((v, event) -> {
            if (event.getAction() == MotionEvent.ACTION_DOWN) {
                v.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP);
                v.animate()
                        .scaleX(0.965f)
                        .scaleY(0.965f)
                        .alpha(0.72f)
                        .setDuration(55)
                        .start();
            } else if (event.getAction() == MotionEvent.ACTION_UP
                    || event.getAction() == MotionEvent.ACTION_CANCEL) {
                v.animate()
                        .scaleX(1f)
                        .scaleY(1f)
                        .alpha(1f)
                        .setDuration(90)
                        .start();
            }
            return false;
        });
    }

    private FrameLayout cyberScreen() {
        FrameLayout frame = new FrameLayout(this);
        frame.setBackgroundColor(BG);
        CodeStreamView stream = new CodeStreamView(this);
        frame.addView(stream, new FrameLayout.LayoutParams(-1, -1));
        View veil = new View(this);
        veil.setBackgroundColor(Color.argb(72, 0, 5, 9));
        frame.addView(veil, new FrameLayout.LayoutParams(-1, -1));
        return frame;
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
        List<AppEntry> installed = getAllApps();

        FrameLayout frame = cyberScreen();
        root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(12), dp(9), dp(12), dp(10));
        root.setBackgroundColor(Color.TRANSPARENT);
        frame.addView(root, new FrameLayout.LayoutParams(-1, -1));
        setContentView(frame);

        LinearLayout topRail = new LinearLayout(this);
        topRail.setGravity(Gravity.CENTER_VERTICAL);
        topRail.setPadding(dp(9), dp(5), dp(6), dp(5));
        topRail.setBackground(hudDrawable(Color.argb(190, 8, 16, 24), DIM));

        TextView pulse = text("●", 12, CYAN, true);
        pulse.setGravity(Gravity.CENTER);
        topRail.addView(pulse, new LinearLayout.LayoutParams(dp(24), dp(30)));

        LinearLayout identity = new LinearLayout(this);
        identity.setOrientation(LinearLayout.VERTICAL);
        identity.addView(text("ARDA OS // NADMO CYBERDECK", 11, CYAN, true));
        identity.addView(text("CODESTREAM ACTIVE  //  " + installed.size() + " NODES", 8, MUTED, false));
        topRail.addView(identity, new LinearLayout.LayoutParams(0, -2, 1));

        TextView gear = text("⚙", 19, CYAN, false);
        gear.setGravity(Gravity.CENTER);
        gear.setBackground(panelDrawable(Color.argb(180, 14, 29, 40), 2, CYAN));
        makeInteractive(gear);
        gear.setOnClickListener(v -> startActivity(new Intent(Settings.ACTION_SETTINGS)));
        topRail.addView(gear, new LinearLayout.LayoutParams(dp(34), dp(34)));
        root.addView(topRail);

        LinearLayout nodeRow = new LinearLayout(this);
        nodeRow.setGravity(Gravity.CENTER_VERTICAL);
        nodeRow.setPadding(dp(3), dp(7), dp(3), dp(2));
        nodeRow.addView(text("SYSTEM NODE INDEX", 8, MUTED, true), new LinearLayout.LayoutParams(0, -2, 1));
        nodeRow.addView(text(installed.size() + " ONLINE", 8, MAGENTA, true));
        root.addView(nodeRow);

        LinearLayout line = new LinearLayout(this);
        View cyan = new View(this);
        cyan.setBackgroundColor(CYAN);
        line.addView(cyan, new LinearLayout.LayoutParams(0, dp(2), 82));
        View mag = new View(this);
        mag.setBackgroundColor(MAGENTA);
        line.addView(mag, new LinearLayout.LayoutParams(0, dp(2), 7));
        View dark = new View(this);
        dark.setBackgroundColor(Color.argb(130, 60, 86, 94));
        line.addView(dark, new LinearLayout.LayoutParams(0, dp(2), 11));
        root.addView(line);

        LinearLayout timeRow = new LinearLayout(this);
        timeRow.setGravity(Gravity.CENTER_VERTICAL);
        timeRow.setPadding(dp(2), dp(7), dp(2), dp(4));

        TextClock clock = new TextClock(this);
        clock.setFormat12Hour("HH:mm");
        clock.setFormat24Hour("HH:mm");
        clock.setTextSize(39);
        clock.setTextColor(Color.WHITE);
        clock.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
        timeRow.addView(clock, new LinearLayout.LayoutParams(0, -2, 1));

        LinearLayout rightTime = new LinearLayout(this);
        rightTime.setOrientation(LinearLayout.VERTICAL);
        rightTime.setGravity(Gravity.END);
        TextView core = text("CORE // ONLINE", 9, CYAN, true);
        core.setGravity(Gravity.END);
        TextClock date = new TextClock(this);
        date.setFormat12Hour("EEE • dd MMM");
        date.setFormat24Hour("EEE • dd MMM");
        date.setTextSize(9);
        date.setTextColor(TEXT);
        date.setTypeface(Typeface.MONOSPACE);
        date.setGravity(Gravity.END);
        rightTime.addView(core);
        rightTime.addView(date);
        timeRow.addView(rightTime);
        root.addView(timeRow);

        LinearLayout telemetry = new LinearLayout(this);
        telemetry.setPadding(0, dp(2), 0, dp(4));
        addTelemetry(telemetry, "BAT", batteryText());
        addTelemetry(telemetry, "RAM", memoryText());
        addTelemetry(telemetry, "STO", storageText());
        root.addView(telemetry);

        if (!isDefaultHome()) {
            TextView setup = text("HOME ROLE OFF  //  TAP TO FIX", 9, MAGENTA, true);
            setup.setGravity(Gravity.CENTER);
            setup.setPadding(dp(6), dp(6), dp(6), dp(6));
            setup.setBackground(hudDrawable(Color.argb(190, 8, 16, 24), MAGENTA));
            makeInteractive(setup);
            setup.setOnClickListener(v -> openHomeSettings());
            LinearLayout.LayoutParams slp = new LinearLayout.LayoutParams(-1, -2);
            slp.setMargins(0, dp(5), 0, 0);
            root.addView(setup, slp);
        }

        TextView section = text("FASTLINK // PRIMARY NODES", 8, MUTED, true);
        section.setPadding(dp(2), dp(8), 0, dp(4));
        root.addView(section);

        LinearLayout commandZone = new LinearLayout(this);
        commandZone.setGravity(Gravity.TOP);
        commandZone.setOrientation(LinearLayout.HORIZONTAL);

        LinearLayout atmosphere = new LinearLayout(this);
        atmosphere.setOrientation(LinearLayout.VERTICAL);
        atmosphere.setPadding(dp(6), dp(8), dp(8), 0);

        TextView rail = text("│\n│\n◆\n│\n│\n└─", 15, CYAN, false);
        rail.setAlpha(0.85f);
        atmosphere.addView(rail);

        TextView rootStatus = text("ROOT@ARDA\nFASTLINK READY\nPROFILE MAP OK", 8, MUTED, false);
        rootStatus.setPadding(dp(3), dp(2), 0, 0);
        atmosphere.addView(rootStatus);

        commandZone.addView(atmosphere, new LinearLayout.LayoutParams(0, -2, 1));

        LinearLayout stack = new LinearLayout(this);
        stack.setOrientation(LinearLayout.VERTICAL);
        stack.setGravity(Gravity.END);

        addCompactNode(stack, "ACC OS X   >", "acc", CYAN, true);
        addCompactNode(stack, "WA        >", "wa", MAGENTA, false);
        addCompactNode(stack, "NOTE      >", "note", CYAN, false);
        addCompactNode(stack, "FB        >", "fb", CYAN, false);
        addCompactNode(stack, "IG        >", "ig", MAGENTA, false);

        commandZone.addView(stack, new LinearLayout.LayoutParams(dp(176), -2));
        root.addView(commandZone);

        View spacer = new View(this);
        root.addView(spacer, new LinearLayout.LayoutParams(1, 0, 1));

        LinearLayout bottom = new LinearLayout(this);
        bottom.setGravity(Gravity.RIGHT | Gravity.CENTER_VERTICAL);

        TextView hint = text("tap to search", 8, MUTED, false);
        bottom.addView(hint, new LinearLayout.LayoutParams(0, -2, 1));

        Button apps = cyberButton("APPS  >", false, CYAN);
        apps.setGravity(Gravity.CENTER);
        apps.setOnClickListener(v -> showApps(""));
        bottom.addView(apps, new LinearLayout.LayoutParams(dp(126), dp(40)));
        root.addView(bottom);

        TextView footer = text("v0.6.2  •  COMPACT HUD  •  CODESTREAM", 7, MUTED, false);
        footer.setGravity(Gravity.CENTER);
        footer.setPadding(0, dp(5), 0, 0);
        root.addView(footer);
    }

    private void addTelemetry(LinearLayout parent, String key, String value) {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(7), dp(4), dp(7), dp(4));
        box.setBackground(panelDrawable(Color.argb(150, 8, 16, 24), 2, DIM));

        TextView k = text(key + " //", 8, MUTED, true);
        TextView v = text(value, 12, CYAN, true);
        box.addView(k);
        box.addView(v);

        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, dp(40), 1);
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

    private Button cyberButton(String label, boolean hero, int accent) {
        Button b = new Button(this);
        b.setAllCaps(false);
        b.setText(label);
        b.setTextColor(hero ? accent : TEXT);
        b.setTextSize(hero ? 12 : 10);
        b.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
        b.setGravity(Gravity.CENTER_VERTICAL);
        b.setPadding(dp(10), 0, dp(10), 0);
        b.setMinHeight(0);
        b.setMinimumHeight(0);
        b.setMinWidth(0);
        b.setMinimumWidth(0);
        b.setStateListAnimator(null);
        b.setBackground(hero
                ? hudDrawable(PANEL_3, accent)
                : panelDrawable(PANEL_2, 3, accent));
        makeInteractive(b);
        return b;
    }

    private void addHomeNode(LinearLayout row, String label, String target, int accent) {
        Button b = cyberButton(label, false, accent);
        b.setOnClickListener(v -> launchTarget(target));

        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, -1, 1);
        lp.setMargins(dp(2), 0, dp(2), 0);
        row.addView(b, lp);
    }

    private void addCompactNode(LinearLayout parent, String label, String target, int accent, boolean primary) {
        Button b = cyberButton(label, primary, accent);
        b.setGravity(Gravity.CENTER_VERTICAL);
        b.setSingleLine(true);
        b.setOnClickListener(v -> launchTarget(target));

        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-1, dp(primary ? 42 : 36));
        lp.setMargins(0, 0, 0, dp(5));
        parent.addView(b, lp);
    }

    private List<AppEntry> getAllApps() {
        long now = System.currentTimeMillis();
        if (appCache != null && now - appCacheAt < 30000L) {
            return appCache;
        }

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
                result.add(new AppEntry(
                        null,
                        android.os.Process.myUserHandle(),
                        label,
                        info.activityInfo.packageName,
                        info.loadIcon(pm)
                ));
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

        appCache = result;
        appCacheAt = now;
        return appCache;
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
                    ok = l.equals("facebook")
                            || l.startsWith("facebook ")
                            || p.equals("com.facebook.katana")
                            || p.equals("com.facebook.lite");
                    break;

                case "ig":
                    ok = l.contains("instagram") || p.contains("instagram");
                    break;

                case "note":
                    ok = l.equals("notes")
                            || l.equals("note")
                            || l.contains("notepad")
                            || l.contains("keep notes")
                            || p.contains("notebook")
                            || p.contains(".note")
                            || p.contains("keep");
                    break;

                case "acc":
                    ok = l.contains("acc os x")
                            || l.contains("acc os")
                            || p.contains("accos")
                            || p.contains("acc.os");
                    break;
            }

            if (ok) matches.add(e);
        }

        return matches;
    }

    private void launchTarget(String target) {
        List<AppEntry> matches = findTargetApps(target);

        if (matches.isEmpty()) {
            Toast.makeText(this, "Target belum ditemukan. Pilih dari Apps.", Toast.LENGTH_SHORT).show();
            showApps(target);
            return;
        }

        if (matches.size() == 1) {
            launchApp(matches.get(0));
            return;
        }

        String title;
        switch (target) {
            case "wa": title = "PILIH WHATSAPP"; break;
            case "fb": title = "PILIH FACEBOOK"; break;
            case "ig": title = "PILIH INSTAGRAM"; break;
            case "note": title = "PILIH NOTES"; break;
            default: title = "PILIH TARGET";
        }

        String[] names = new String[matches.size()];
        for (int i = 0; i < matches.size(); i++) {
            names[i] = matches.get(i).displayLabel;
        }

        AlertDialog dialog = new AlertDialog.Builder(this)
                .setTitle(title + "  //  " + matches.size() + " INSTANCE")
                .setItems(names, (d, which) -> launchApp(matches.get(which)))
                .setNegativeButton("BATAL", null)
                .create();

        dialog.setOnShowListener(d -> {
            if (dialog.getWindow() != null) {
                dialog.getWindow().setDimAmount(0.72f);
            }
        });

        dialog.show();
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
        List<AppEntry> allApps = getAllApps();

        FrameLayout frame = cyberScreen();
        LinearLayout shell = new LinearLayout(this);
        shell.setOrientation(LinearLayout.VERTICAL);
        shell.setPadding(dp(12), dp(10), dp(12), dp(10));
        shell.setBackgroundColor(Color.TRANSPARENT);
        frame.addView(shell, new FrameLayout.LayoutParams(-1, -1));
        setContentView(frame);

        LinearLayout head = new LinearLayout(this);
        head.setGravity(Gravity.CENTER_VERTICAL);
        head.setPadding(dp(8), dp(6), dp(8), dp(6));
        head.setBackground(hudDrawable(PANEL, DIM));

        Button home = cyberButton("← HOME", false, CYAN);
        home.setGravity(Gravity.CENTER);
        home.setOnClickListener(v -> showHome());
        head.addView(home, new LinearLayout.LayoutParams(dp(98), dp(42)));

        LinearLayout drawerTitle = new LinearLayout(this);
        drawerTitle.setOrientation(LinearLayout.VERTICAL);
        drawerTitle.setPadding(dp(10), 0, 0, 0);
        drawerTitle.addView(text("APP DRAWER // " + allApps.size(), 11, CYAN, true));
        drawerTitle.addView(text("ALL PROFILES + CLONES", 8, MUTED, false));
        head.addView(drawerTitle, new LinearLayout.LayoutParams(0, -2, 1));

        shell.addView(head);

        EditText search = new EditText(this);
        search.setSingleLine(true);
        search.setHint("SEARCH APPS...");
        search.setHintTextColor(MUTED);
        search.setTextColor(TEXT);
        search.setTextSize(12);
        search.setTypeface(Typeface.MONOSPACE);
        search.setPadding(dp(14), 0, dp(14), 0);
        search.setBackground(hudDrawable(PANEL_2, CYAN));

        LinearLayout.LayoutParams searchLp = new LinearLayout.LayoutParams(-1, dp(46));
        searchLp.setMargins(0, dp(8), 0, dp(8));
        shell.addView(search, searchLp);

        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        scroll.setVerticalScrollBarEnabled(false);

        GridLayout grid = new GridLayout(this);
        grid.setColumnCount(4);
        grid.setAlignmentMode(GridLayout.ALIGN_BOUNDS);
        grid.setUseDefaultMargins(false);
        grid.setPadding(0, 0, 0, dp(18));
        scroll.addView(grid);

        shell.addView(scroll, new LinearLayout.LayoutParams(-1, 0, 1));

        final Runnable[] renderHolder = new Runnable[1];

        renderHolder[0] = () -> {
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
                card.setPadding(dp(4), dp(7), dp(4), dp(5));
                card.setBackground(panelDrawable(PANEL, 3, DIM));
                makeInteractive(card);

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
                gp.height = dp(90);
                gp.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
                gp.setMargins(dp(3), dp(3), dp(3), dp(3));
                grid.addView(card, gp);
            }
        };

        search.addTextChangedListener(new android.text.TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                renderHolder[0].run();
            }

            @Override
            public void afterTextChanged(android.text.Editable s) {}
        });

        if (presetQuery == null) presetQuery = "";
        if (presetQuery.equals("wa")) presetQuery = "whatsapp";
        if (presetQuery.equals("fb")) presetQuery = "facebook";
        if (presetQuery.equals("ig")) presetQuery = "instagram";
        if (presetQuery.equals("note")) presetQuery = "note";
        if (presetQuery.equals("acc")) presetQuery = "acc";

        search.setText(presetQuery);
        search.setSelection(search.getText().length());
        renderHolder[0].run();
    }

    @Override
    public void onBackPressed() {
        showHome();
    }
}
