package com.amstudio.distribution;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.HorizontalScrollView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import com.amstudio.distribution.data.ReleaseStore;
import com.amstudio.distribution.distribution.DistributionGateway;
import com.amstudio.distribution.distribution.SandboxDistributionGateway;
import com.amstudio.distribution.domain.ReleaseDraft;
import com.amstudio.distribution.domain.ReleaseStatus;

import java.text.DateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public final class MainActivity extends Activity {
    private static final int BG = Color.rgb(10, 12, 16);
    private static final int PANEL = Color.rgb(20, 23, 30);
    private static final int PANEL_2 = Color.rgb(27, 31, 40);
    private static final int TEXT = Color.rgb(245, 247, 250);
    private static final int MUTED = Color.rgb(154, 163, 178);
    private static final int ACCENT = Color.rgb(64, 133, 255);
    private static final int GREEN = Color.rgb(78, 214, 143);
    private static final int WARNING = Color.rgb(255, 186, 73);

    private ReleaseStore releaseStore;
    private DistributionGateway distributionGateway;
    private FrameLayout contentHost;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setStatusBarColor(BG);
        getWindow().setNavigationBarColor(BG);
        releaseStore = new ReleaseStore(this);
        distributionGateway = new SandboxDistributionGateway();
        buildShell();
        showHome();
    }

    private void buildShell() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(BG);
        root.setPadding(dp(18), dp(12), dp(18), dp(10));

        LinearLayout brand = new LinearLayout(this);
        brand.setGravity(Gravity.CENTER_VERTICAL);
        TextView mark = text("AM", 15, Color.WHITE, Typeface.BOLD);
        mark.setGravity(Gravity.CENTER);
        mark.setBackground(roundRect(ACCENT, 12));
        brand.addView(mark, new LinearLayout.LayoutParams(dp(44), dp(44)));

        LinearLayout brandCopy = new LinearLayout(this);
        brandCopy.setOrientation(LinearLayout.VERTICAL);
        brandCopy.setPadding(dp(12), 0, 0, 0);
        brandCopy.addView(text("AM STUDIO", 18, TEXT, Typeface.BOLD));
        brandCopy.addView(text("MUSIC DISTRIBUTION • FOUNDATION", 10, MUTED, Typeface.BOLD));
        brand.addView(brandCopy, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        TextView badge = text("SANDBOX", 10, WARNING, Typeface.BOLD);
        badge.setPadding(dp(10), dp(6), dp(10), dp(6));
        badge.setBackground(roundRect(Color.rgb(48, 39, 20), 99));
        brand.addView(badge);
        root.addView(brand, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(62)));

        contentHost = new FrameLayout(this);
        LinearLayout.LayoutParams contentParams = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f);
        root.addView(contentHost, contentParams);

        HorizontalScrollView navScroll = new HorizontalScrollView(this);
        navScroll.setHorizontalScrollBarEnabled(false);
        LinearLayout nav = new LinearLayout(this);
        nav.setGravity(Gravity.CENTER);
        nav.setPadding(0, dp(8), 0, 0);
        nav.addView(navButton("HOME", this::showHome));
        nav.addView(navButton("RELEASES", this::showReleases));
        nav.addView(navButton("+ RELEASE", this::showNewRelease));
        nav.addView(navButton("EARNINGS", this::showEarnings));
        nav.addView(navButton("ACCOUNT", this::showAccount));
        navScroll.addView(nav);
        root.addView(navScroll, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(58)));
        setContentView(root);
    }

    private void showHome() {
        ScrollView scroll = pageScroll();
        LinearLayout page = pageColumn();
        page.addView(kicker("DISTRIBUTE • TRACK • EARN"));
        page.addView(title("Release music without rebuilding your workflow."));
        page.addView(body("Fondasi AM STUDIO memisahkan aplikasi, data katalog, dan mesin distributor. Provider produksi bisa diganti tanpa mengganti ID release internal."));

        Button create = primaryButton("+ NEW RELEASE");
        create.setOnClickListener(v -> showNewRelease());
        LinearLayout.LayoutParams cta = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(54));
        cta.setMargins(0, dp(18), 0, dp(18));
        page.addView(create, cta);

        List<ReleaseDraft> releases = releaseStore.all();
        LinearLayout metrics = new LinearLayout(this);
        metrics.setWeightSum(3f);
        metrics.addView(metricCard(String.valueOf(releases.size()), "RELEASES"), weightedCard());
        metrics.addView(metricCard(String.valueOf(countStatus(releases, ReleaseStatus.IN_REVIEW)), "IN REVIEW"), weightedCard());
        metrics.addView(metricCard("Rp0", "VERIFIED ROYALTY"), weightedCard());
        page.addView(metrics);

        page.addView(sectionHeader("PIPELINE"));
        page.addView(infoCard("1. Prepare", "Audio • artwork • metadata • credits • rights"));
        page.addView(infoCard("2. Preflight", "QC dan rights gate sebelum submission"));
        page.addView(infoCard("3. Distribute", "AM STUDIO API → provider adapter → DSP"));
        page.addView(infoCard("4. Reconcile", "Statements → ledger → splits → wallet → payout"));

        page.addView(sectionHeader("LATEST RELEASES"));
        if (releases.isEmpty()) {
            page.addView(emptyCard("Belum ada release. Buat draft pertama tanpa mengirim apa pun ke DSP produksi."));
        } else {
            int max = Math.min(3, releases.size());
            for (int i = 0; i < max; i++) page.addView(releaseCard(releases.get(i)));
        }
        scroll.addView(page);
        swap(scroll);
    }

    private void showReleases() {
        ScrollView scroll = pageScroll();
        LinearLayout page = pageColumn();
        page.addView(kicker("CATALOG"));
        page.addView(title("Releases"));
        page.addView(body("Semua status di bawah menggunakan lifecycle canonical AM STUDIO."));
        List<ReleaseDraft> releases = releaseStore.all();
        if (releases.isEmpty()) {
            page.addView(emptyCard("Catalog kosong."));
        } else {
            for (ReleaseDraft release : releases) page.addView(releaseCard(release));
        }
        scroll.addView(page);
        swap(scroll);
    }

    private void showNewRelease() {
        ScrollView scroll = pageScroll();
        LinearLayout page = pageColumn();
        page.addView(kicker("RELEASE WIZARD • FOUNDATION STEP"));
        page.addView(title("Create release draft"));
        page.addView(body("v0.1 menyimpan data canonical dan menjalankan preflight sandbox. Upload master/artwork, credits detail, KYC dan backend delivery masuk fase berikutnya sesuai masterplan."));

        EditText titleInput = field("Release title");
        EditText artistInput = field("Primary artist");
        EditText labelInput = field("Label name");
        labelInput.setText("AM STUDIO");
        page.addView(formLabel("BASICS"));
        page.addView(titleInput);
        page.addView(artistInput);
        page.addView(labelInput);

        page.addView(formLabel("DISTRIBUTION DESTINATIONS"));
        String[] stores = new String[]{"Spotify", "Apple Music", "TikTok", "YouTube Music", "Instagram / Facebook", "Amazon Music", "Deezer", "TIDAL"};
        List<CheckBox> checks = new ArrayList<>();
        for (String store : stores) {
            CheckBox check = new CheckBox(this);
            check.setText(store);
            check.setTextColor(TEXT);
            check.setTextSize(15);
            check.setButtonTintList(android.content.res.ColorStateList.valueOf(ACCENT));
            check.setPadding(dp(4), dp(7), dp(4), dp(7));
            checks.add(check);
            page.addView(check);
        }

        TextView preflightState = body("Preflight: belum dijalankan");
        preflightState.setPadding(0, dp(12), 0, dp(12));
        page.addView(preflightState);

        Button preflight = secondaryButton("RUN PREFLIGHT");
        Button save = secondaryButton("SAVE DRAFT");
        Button submit = primaryButton("SUBMIT TO SANDBOX");

        View.OnClickListener populateAnd = v -> {};
        preflight.setOnClickListener(v -> {
            ReleaseDraft draft = draftFromForm(titleInput, artistInput, labelInput, checks);
            DistributionGateway.ValidationResult result = distributionGateway.validateRelease(draft);
            if (result.isValid()) {
                draft.setStatus(ReleaseStatus.READY_FOR_REVIEW);
                preflightState.setText("Preflight: PASS • ready for review");
                preflightState.setTextColor(GREEN);
            } else {
                draft.setStatus(ReleaseStatus.PREFLIGHT_REQUIRED);
                preflightState.setText("Preflight: " + String.join(" ", result.getIssues()));
                preflightState.setTextColor(WARNING);
            }
        });

        save.setOnClickListener(v -> {
            ReleaseDraft draft = draftFromForm(titleInput, artistInput, labelInput, checks);
            draft.setStatus(ReleaseStatus.DRAFT);
            releaseStore.save(draft);
            toast("Draft tersimpan");
            showReleases();
        });

        submit.setOnClickListener(v -> {
            ReleaseDraft draft = draftFromForm(titleInput, artistInput, labelInput, checks);
            DistributionGateway.SubmissionResult result = distributionGateway.submitRelease(draft);
            draft.setStatus(result.getStatus());
            releaseStore.save(draft);
            toast(result.getMessage());
            showReleases();
        });

        LinearLayout.LayoutParams action = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52));
        action.setMargins(0, dp(8), 0, 0);
        page.addView(preflight, action);
        page.addView(save, action);
        page.addView(submit, action);

        TextView warning = body("SANDBOX ONLY — tombol submit pada v0.1 tidak mengirim audio atau metadata ke Spotify, TikTok, Apple Music, atau DSP lain.");
        warning.setTextColor(WARNING);
        warning.setPadding(0, dp(18), 0, dp(24));
        page.addView(warning);

        scroll.addView(page);
        swap(scroll);
    }

    private void showEarnings() {
        ScrollView scroll = pageScroll();
        LinearLayout page = pageColumn();
        page.addView(kicker("ROYALTIES"));
        page.addView(title("Earnings"));
        page.addView(metricWide("Rp0", "VERIFIED PAYABLE BALANCE"));
        page.addView(infoCard("Gross royalties", "Rp0 • menunggu provider statement nyata"));
        page.addView(infoCard("AM STUDIO fee", "Rp0 • plan engine belum diaktifkan"));
        page.addView(infoCard("Artist payable", "Rp0 • ledger server-authoritative belum terhubung"));
        page.addView(sectionHeader("INTEGRITY RULE"));
        page.addView(emptyCard("Saldo tidak pernah dihitung dari angka UI. Production nanti memakai statement mentah → reconciliation → append-only ledger → splits → payout."));
        scroll.addView(page);
        swap(scroll);
    }

    private void showAccount() {
        ScrollView scroll = pageScroll();
        LinearLayout page = pageColumn();
        page.addView(kicker("IDENTITY & COMPLIANCE"));
        page.addView(title("Account"));
        page.addView(infoCard("Environment", "Foundation Sandbox"));
        page.addView(infoCard("KYC / KYB", "NOT CONNECTED"));
        page.addView(infoCard("Payout profile", "NOT CONNECTED"));
        page.addView(infoCard("Distribution provider", "SandboxDistributionGateway"));
        page.addView(infoCard("App identity", "com.amstudio.distribution • 0.1.0-foundation"));
        page.addView(sectionHeader("PRODUCTION GATES"));
        page.addView(emptyCard("Real distribution baru boleh diaktifkan setelah backend auth, secure media storage, provider sandbox, production account, rights controls, royalty ingestion, ledger dan payout workflow terverifikasi."));
        scroll.addView(page);
        swap(scroll);
    }

    private ReleaseDraft draftFromForm(EditText title, EditText artist, EditText label, List<CheckBox> checks) {
        ReleaseDraft draft = new ReleaseDraft();
        draft.setTitle(title.getText().toString());
        draft.setArtistName(artist.getText().toString());
        draft.setLabelName(label.getText().toString());
        List<String> destinations = new ArrayList<>();
        for (CheckBox check : checks) if (check.isChecked()) destinations.add(check.getText().toString());
        draft.setDestinations(destinations);
        return draft;
    }

    private View releaseCard(ReleaseDraft release) {
        LinearLayout card = card();
        LinearLayout top = new LinearLayout(this);
        TextView name = text(release.getTitle().isEmpty() ? "Untitled Release" : release.getTitle(), 17, TEXT, Typeface.BOLD);
        top.addView(name, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        TextView status = text(formatStatus(release.getStatus()), 10, statusColor(release.getStatus()), Typeface.BOLD);
        status.setPadding(dp(9), dp(5), dp(9), dp(5));
        status.setBackground(roundRect(Color.rgb(35, 39, 48), 99));
        top.addView(status);
        card.addView(top);
        card.addView(text(release.getArtistName().isEmpty() ? "Artist belum diisi" : release.getArtistName(), 14, MUTED, Typeface.NORMAL));
        String stores = release.getDestinations().isEmpty() ? "No destinations" : String.join(" • ", release.getDestinations());
        TextView storeText = text(stores, 11, MUTED, Typeface.NORMAL);
        storeText.setPadding(0, dp(8), 0, 0);
        card.addView(storeText);
        TextView id = text(release.getId(), 10, Color.rgb(105, 113, 128), Typeface.MONOSPACE.getStyle());
        id.setTypeface(Typeface.MONOSPACE);
        id.setPadding(0, dp(8), 0, 0);
        card.addView(id);
        return card;
    }

    private LinearLayout metricCard(String value, String label) {
        LinearLayout card = card();
        card.setPadding(dp(12), dp(14), dp(12), dp(14));
        card.addView(text(value, 20, TEXT, Typeface.BOLD));
        card.addView(text(label, 9, MUTED, Typeface.BOLD));
        return card;
    }

    private LinearLayout metricWide(String value, String label) {
        LinearLayout card = card();
        card.setPadding(dp(18), dp(22), dp(18), dp(22));
        card.addView(text(value, 32, TEXT, Typeface.BOLD));
        card.addView(text(label, 10, MUTED, Typeface.BOLD));
        return card;
    }

    private LinearLayout infoCard(String heading, String detail) {
        LinearLayout card = card();
        card.addView(text(heading, 15, TEXT, Typeface.BOLD));
        TextView copy = text(detail, 13, MUTED, Typeface.NORMAL);
        copy.setPadding(0, dp(5), 0, 0);
        card.addView(copy);
        return card;
    }

    private LinearLayout emptyCard(String copy) {
        LinearLayout card = card();
        card.addView(text(copy, 13, MUTED, Typeface.NORMAL));
        return card;
    }

    private LinearLayout card() {
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(16), dp(15), dp(16), dp(15));
        card.setBackground(roundRect(PANEL, 16));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.setMargins(0, dp(6), 0, dp(6));
        card.setLayoutParams(lp);
        return card;
    }

    private LinearLayout.LayoutParams weightedCard() {
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        lp.setMargins(dp(3), 0, dp(3), 0);
        return lp;
    }

    private TextView sectionHeader(String value) {
        TextView view = text(value, 11, MUTED, Typeface.BOLD);
        view.setPadding(0, dp(24), 0, dp(7));
        return view;
    }

    private TextView formLabel(String value) {
        TextView view = text(value, 11, MUTED, Typeface.BOLD);
        view.setPadding(0, dp(18), 0, dp(8));
        return view;
    }

    private EditText field(String hint) {
        EditText field = new EditText(this);
        field.setHint(hint);
        field.setHintTextColor(Color.rgb(112, 120, 135));
        field.setTextColor(TEXT);
        field.setSingleLine(true);
        field.setTextSize(15);
        field.setPadding(dp(14), 0, dp(14), 0);
        field.setBackground(roundRect(PANEL_2, 12));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52));
        lp.setMargins(0, dp(5), 0, dp(5));
        field.setLayoutParams(lp);
        return field;
    }

    private Button primaryButton(String label) {
        Button button = new Button(this);
        button.setText(label);
        button.setTextColor(Color.WHITE);
        button.setTextSize(13);
        button.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        button.setAllCaps(false);
        button.setBackground(roundRect(ACCENT, 14));
        return button;
    }

    private Button secondaryButton(String label) {
        Button button = primaryButton(label);
        button.setBackground(roundRect(PANEL_2, 14));
        return button;
    }

    private Button navButton(String label, Runnable action) {
        Button button = new Button(this);
        button.setText(label);
        button.setTextColor(MUTED);
        button.setTextSize(10);
        button.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        button.setAllCaps(false);
        button.setBackgroundColor(Color.TRANSPARENT);
        button.setOnClickListener(v -> action.run());
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(dp(label.contains("+") ? 92 : 78), dp(48));
        button.setLayoutParams(lp);
        return button;
    }

    private ScrollView pageScroll() {
        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        scroll.setClipToPadding(false);
        return scroll;
    }

    private LinearLayout pageColumn() {
        LinearLayout page = new LinearLayout(this);
        page.setOrientation(LinearLayout.VERTICAL);
        page.setPadding(0, dp(16), 0, dp(26));
        return page;
    }

    private TextView kicker(String value) {
        TextView view = text(value, 10, ACCENT, Typeface.BOLD);
        view.setPadding(0, dp(4), 0, dp(8));
        return view;
    }

    private TextView title(String value) {
        TextView view = text(value, 28, TEXT, Typeface.BOLD);
        view.setPadding(0, 0, 0, dp(8));
        return view;
    }

    private TextView body(String value) {
        TextView view = text(value, 13, MUTED, Typeface.NORMAL);
        view.setLineSpacing(0, 1.15f);
        return view;
    }

    private TextView text(String value, int sp, int color, int style) {
        TextView view = new TextView(this);
        view.setText(value);
        view.setTextSize(sp);
        view.setTextColor(color);
        view.setTypeface(Typeface.DEFAULT, style);
        return view;
    }

    private GradientDrawable roundRect(int color, int radiusDp) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(color);
        drawable.setCornerRadius(dp(radiusDp));
        return drawable;
    }

    private void swap(View view) {
        contentHost.removeAllViews();
        contentHost.addView(view, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
    }

    private int countStatus(List<ReleaseDraft> releases, ReleaseStatus target) {
        int count = 0;
        for (ReleaseDraft release : releases) if (release.getStatus() == target) count++;
        return count;
    }

    private String formatStatus(ReleaseStatus status) {
        return status.name().replace('_', ' ');
    }

    private int statusColor(ReleaseStatus status) {
        switch (status) {
            case LIVE:
            case PARTIALLY_LIVE:
            case APPROVED:
                return GREEN;
            case PREFLIGHT_REQUIRED:
            case NEEDS_CHANGES:
            case RIGHTS_HOLD:
            case FRAUD_HOLD:
                return WARNING;
            default:
                return ACCENT;
        }
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

    private void toast(String value) {
        Toast.makeText(this, value, Toast.LENGTH_LONG).show();
    }
}
