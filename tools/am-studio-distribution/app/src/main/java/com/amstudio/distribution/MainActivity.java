package com.amstudio.distribution;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.HorizontalScrollView;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import com.amstudio.distribution.data.ReleaseStore;
import com.amstudio.distribution.distribution.DistributionGateway;
import com.amstudio.distribution.distribution.SandboxDistributionGateway;
import com.amstudio.distribution.domain.ReleaseDraft;
import com.amstudio.distribution.domain.ReleaseStatus;
import com.amstudio.distribution.media.MediaInspector;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public final class MainActivity extends Activity {
    private static final int REQUEST_AUDIO = 2101;
    private static final int REQUEST_ARTWORK = 2102;

    private static final int BG = Color.rgb(10, 12, 16);
    private static final int PANEL = Color.rgb(20, 23, 30);
    private static final int PANEL_2 = Color.rgb(27, 31, 40);
    private static final int TEXT = Color.rgb(245, 247, 250);
    private static final int MUTED = Color.rgb(154, 163, 178);
    private static final int ACCENT = Color.rgb(28, 145, 255);
    private static final int GREEN = Color.rgb(78, 214, 143);
    private static final int WARNING = Color.rgb(255, 186, 73);

    private ReleaseStore releaseStore;
    private DistributionGateway distributionGateway;
    private FrameLayout contentHost;

    private MediaInspector.FileInfo selectedAudio;
    private MediaInspector.FileInfo selectedArtwork;
    private TextView audioStateView;
    private TextView artworkStateView;

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
        root.setPadding(dp(18), dp(10), dp(18), dp(8));

        LinearLayout brand = new LinearLayout(this);
        brand.setGravity(Gravity.CENTER_VERTICAL);

        ImageView mark = new ImageView(this);
        mark.setImageResource(R.drawable.am_studio_logo);
        mark.setScaleType(ImageView.ScaleType.CENTER_CROP);
        brand.addView(mark, new LinearLayout.LayoutParams(dp(52), dp(52)));

        LinearLayout brandCopy = new LinearLayout(this);
        brandCopy.setOrientation(LinearLayout.VERTICAL);
        brandCopy.setPadding(dp(12), 0, 0, 0);
        brandCopy.addView(text("AM STUDIO", 18, TEXT, Typeface.BOLD));
        brandCopy.addView(text("MUSIC DISTRIBUTION • MEDIA PREFLIGHT", 9, MUTED, Typeface.BOLD));
        brand.addView(brandCopy, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));

        TextView badge = text("SANDBOX", 9, WARNING, Typeface.BOLD);
        badge.setPadding(dp(9), dp(6), dp(9), dp(6));
        badge.setBackground(roundRect(Color.rgb(48, 39, 20), 99));
        brand.addView(badge);
        root.addView(brand, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(64)));

        contentHost = new FrameLayout(this);
        root.addView(contentHost, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));

        HorizontalScrollView navScroll = new HorizontalScrollView(this);
        navScroll.setHorizontalScrollBarEnabled(false);
        LinearLayout nav = new LinearLayout(this);
        nav.setGravity(Gravity.CENTER);
        nav.setPadding(0, dp(6), 0, 0);
        nav.addView(navButton("HOME", this::showHome));
        nav.addView(navButton("RELEASES", this::showReleases));
        nav.addView(navButton("+ RELEASE", this::showNewRelease));
        nav.addView(navButton("EARNINGS", this::showEarnings));
        nav.addView(navButton("ACCOUNT", this::showAccount));
        navScroll.addView(nav);
        root.addView(navScroll, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(56)));
        setContentView(root);
    }

    private void showHome() {
        ScrollView scroll = pageScroll();
        LinearLayout page = pageColumn();
        page.addView(kicker("DISTRIBUTE • TRACK • EARN"));
        page.addView(title("Music distribution, built as infrastructure."));
        page.addView(body("AM STUDIO menyimpan identitas release sendiri, memvalidasi master + artwork + metadata, lalu mengirim lewat adapter distributor. Provider bisa diganti tanpa merusak katalog."));

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
        page.addView(infoCard("1. Prepare", "WAV/FLAC • cover • metadata • credits • rights"));
        page.addView(infoCard("2. Preflight", "Technical QC + metadata + rights gate"));
        page.addView(infoCard("3. Distribute", "AM STUDIO API → provider adapter → DSP"));
        page.addView(infoCard("4. Reconcile", "Statements → ledger → splits → wallet → payout"));

        page.addView(sectionHeader("LATEST RELEASES"));
        if (releases.isEmpty()) {
            page.addView(emptyCard("Belum ada release. Buat release package pertama; sandbox tidak mengirim ke DSP produksi."));
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
        page.addView(body("Status, media, metadata dan destination disimpan dengan ID canonical AM STUDIO."));
        List<ReleaseDraft> releases = releaseStore.all();
        if (releases.isEmpty()) page.addView(emptyCard("Catalog kosong."));
        else for (ReleaseDraft release : releases) page.addView(releaseCard(release));
        scroll.addView(page);
        swap(scroll);
    }

    private void showNewRelease() {
        selectedAudio = null;
        selectedArtwork = null;

        ScrollView scroll = pageScroll();
        LinearLayout page = pageColumn();
        page.addView(kicker("RELEASE WIZARD • v0.2"));
        page.addView(title("Build a release package"));
        page.addView(body("Pilih master dan artwork dari HP. APK membaca metadata teknis lokal, menyimpan URI dokumen, lalu menjalankan preflight sebelum sandbox submission."));

        page.addView(formLabel("MASTER AUDIO"));
        Button pickAudio = secondaryButton("SELECT WAV / FLAC");
        pickAudio.setOnClickListener(v -> pickDocument(REQUEST_AUDIO, "audio/*"));
        page.addView(pickAudio, buttonLp());
        audioStateView = body("Belum ada master dipilih.");
        audioStateView.setPadding(dp(4), dp(5), dp(4), dp(8));
        page.addView(audioStateView);

        page.addView(formLabel("COVER ARTWORK"));
        Button pickArtwork = secondaryButton("SELECT JPG / PNG");
        pickArtwork.setOnClickListener(v -> pickDocument(REQUEST_ARTWORK, "image/*"));
        page.addView(pickArtwork, buttonLp());
        artworkStateView = body("Belum ada cover dipilih. Target preflight: square ≥ 3000×3000 px.");
        artworkStateView.setPadding(dp(4), dp(5), dp(4), dp(8));
        page.addView(artworkStateView);

        page.addView(formLabel("RELEASE METADATA"));
        EditText titleInput = field("Release title / track title");
        EditText artistInput = field("Primary artist");
        EditText labelInput = field("Label name");
        labelInput.setText("AM STUDIO");
        EditText genreInput = field("Genre (example: Pop, Electronic, Hip-Hop)");
        EditText releaseDateInput = field("Release date (YYYY-MM-DD)");
        page.addView(titleInput);
        page.addView(artistInput);
        page.addView(labelInput);
        page.addView(genreInput);
        page.addView(releaseDateInput);

        page.addView(formLabel("CREDITS & RIGHTS"));
        EditText songwriterInput = field("Songwriter / lyricist");
        EditText composerInput = field("Composer");
        EditText copyrightInput = field("Copyright owner / master owner");
        page.addView(songwriterInput);
        page.addView(composerInput);
        page.addView(copyrightInput);

        CheckBox explicitCheck = checkbox("Explicit content");
        page.addView(explicitCheck);
        CheckBox rightsCheck = checkbox("I own or control the rights/licenses required to distribute this release");
        page.addView(rightsCheck);

        page.addView(formLabel("DISTRIBUTION DESTINATIONS"));
        String[] stores = new String[]{"Spotify", "Apple Music", "TikTok", "YouTube Music", "Instagram / Facebook", "Amazon Music", "Deezer", "TIDAL"};
        List<CheckBox> checks = new ArrayList<>();
        for (String store : stores) {
            CheckBox check = checkbox(store);
            checks.add(check);
            page.addView(check);
        }

        TextView preflightState = body("Preflight: belum dijalankan");
        preflightState.setPadding(0, dp(14), 0, dp(12));
        page.addView(preflightState);

        Button preflight = secondaryButton("RUN PREFLIGHT");
        Button save = secondaryButton("SAVE DRAFT");
        Button submit = primaryButton("SUBMIT PACKAGE TO SANDBOX");

        preflight.setOnClickListener(v -> {
            ReleaseDraft draft = draftFromForm(titleInput, artistInput, labelInput, genreInput, releaseDateInput,
                    songwriterInput, composerInput, copyrightInput, explicitCheck, rightsCheck, checks);
            DistributionGateway.ValidationResult result = distributionGateway.validateRelease(draft);
            if (result.isValid()) {
                draft.setStatus(ReleaseStatus.READY_FOR_REVIEW);
                preflightState.setText("Preflight: PASS • media + metadata + rights ready for sandbox review");
                preflightState.setTextColor(GREEN);
            } else {
                draft.setStatus(ReleaseStatus.PREFLIGHT_REQUIRED);
                preflightState.setText("Preflight: " + String.join("  •  ", result.getIssues()));
                preflightState.setTextColor(WARNING);
            }
        });

        save.setOnClickListener(v -> {
            ReleaseDraft draft = draftFromForm(titleInput, artistInput, labelInput, genreInput, releaseDateInput,
                    songwriterInput, composerInput, copyrightInput, explicitCheck, rightsCheck, checks);
            draft.setStatus(ReleaseStatus.DRAFT);
            releaseStore.save(draft);
            toast("Draft package tersimpan");
            showReleases();
        });

        submit.setOnClickListener(v -> {
            ReleaseDraft draft = draftFromForm(titleInput, artistInput, labelInput, genreInput, releaseDateInput,
                    songwriterInput, composerInput, copyrightInput, explicitCheck, rightsCheck, checks);
            DistributionGateway.SubmissionResult result = distributionGateway.submitRelease(draft);
            draft.setStatus(result.getStatus());
            releaseStore.save(draft);
            toast(result.getMessage());
            showReleases();
        });

        page.addView(preflight, buttonLp());
        page.addView(save, buttonLp());
        page.addView(submit, buttonLp());

        TextView warning = body("SANDBOX ONLY — v0.2 membaca file nyata dari HP tetapi belum meng-upload master atau metadata ke Spotify, TikTok, Apple Music, atau DSP lain.");
        warning.setTextColor(WARNING);
        warning.setPadding(0, dp(18), 0, dp(24));
        page.addView(warning);

        scroll.addView(page);
        swap(scroll);
    }

    private void pickDocument(int requestCode, String mime) {
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType(mime);
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
        startActivityForResult(intent, requestCode);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (resultCode != RESULT_OK || data == null || data.getData() == null) return;
        Uri uri = data.getData();
        try {
            int takeFlags = data.getFlags() & Intent.FLAG_GRANT_READ_URI_PERMISSION;
            if (takeFlags != 0) getContentResolver().takePersistableUriPermission(uri, takeFlags);
        } catch (Exception ignored) {}

        try {
            if (requestCode == REQUEST_AUDIO) {
                selectedAudio = MediaInspector.inspectAudio(this, uri);
                if (audioStateView != null) {
                    audioStateView.setText(selectedAudio.name + "\n" + formatBytes(selectedAudio.sizeBytes) + " • "
                            + formatDuration(selectedAudio.durationMs) + " • " + fallback(selectedAudio.mime, "unknown mime"));
                    audioStateView.setTextColor(GREEN);
                }
            } else if (requestCode == REQUEST_ARTWORK) {
                selectedArtwork = MediaInspector.inspectArtwork(this, uri);
                if (artworkStateView != null) {
                    artworkStateView.setText(selectedArtwork.name + "\n" + selectedArtwork.width + "×" + selectedArtwork.height
                            + " px • " + formatBytes(selectedArtwork.sizeBytes) + " • " + fallback(selectedArtwork.mime, "unknown mime"));
                    boolean good = selectedArtwork.width == selectedArtwork.height && selectedArtwork.width >= 3000;
                    artworkStateView.setTextColor(good ? GREEN : WARNING);
                }
            }
        } catch (Exception e) {
            toast("File tidak dapat diperiksa: " + fallback(e.getMessage(), e.getClass().getSimpleName()));
        }
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
        page.addView(emptyCard("Saldo tidak dihitung dari UI. Production memakai statement mentah → reconciliation → append-only ledger → splits → payout."));
        scroll.addView(page);
        swap(scroll);
    }

    private void showAccount() {
        ScrollView scroll = pageScroll();
        LinearLayout page = pageColumn();
        page.addView(kicker("IDENTITY & COMPLIANCE"));
        page.addView(title("Account"));
        page.addView(infoCard("Environment", "Media Preflight Sandbox"));
        page.addView(infoCard("KYC / KYB", "NOT CONNECTED"));
        page.addView(infoCard("Payout profile", "NOT CONNECTED"));
        page.addView(infoCard("Distribution provider", "SandboxDistributionGateway"));
        page.addView(infoCard("App identity", "com.amstudio.distribution • 0.2.0-media-preflight"));
        page.addView(sectionHeader("PRODUCTION GATES"));
        page.addView(emptyCard("Real distribution aktif setelah backend auth, encrypted media storage, provider sandbox/production credentials, KYC/KYB, rights controls, royalty ingestion, ledger dan payout terverifikasi."));
        scroll.addView(page);
        swap(scroll);
    }

    private ReleaseDraft draftFromForm(EditText title, EditText artist, EditText label, EditText genre, EditText releaseDate,
                                       EditText songwriter, EditText composer, EditText copyright,
                                       CheckBox explicitCheck, CheckBox rightsCheck, List<CheckBox> checks) {
        ReleaseDraft draft = new ReleaseDraft();
        draft.setTitle(title.getText().toString());
        draft.setArtistName(artist.getText().toString());
        draft.setLabelName(label.getText().toString());
        draft.setGenre(genre.getText().toString());
        draft.setReleaseDate(releaseDate.getText().toString());
        draft.setSongwriter(songwriter.getText().toString());
        draft.setComposer(composer.getText().toString());
        draft.setCopyrightOwner(copyright.getText().toString());
        draft.setExplicitContent(explicitCheck.isChecked());
        draft.setRightsConfirmed(rightsCheck.isChecked());

        if (selectedAudio != null) {
            draft.setAudio(selectedAudio.uri, selectedAudio.name, selectedAudio.mime, selectedAudio.sizeBytes, selectedAudio.durationMs);
        }
        if (selectedArtwork != null) {
            draft.setArtwork(selectedArtwork.uri, selectedArtwork.name, selectedArtwork.mime, selectedArtwork.sizeBytes,
                    selectedArtwork.width, selectedArtwork.height);
        }

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
        TextView status = text(formatStatus(release.getStatus()), 9, statusColor(release.getStatus()), Typeface.BOLD);
        status.setPadding(dp(9), dp(5), dp(9), dp(5));
        status.setBackground(roundRect(Color.rgb(35, 39, 48), 99));
        top.addView(status);
        card.addView(top);
        card.addView(text(release.getArtistName().isEmpty() ? "Artist belum diisi" : release.getArtistName(), 14, MUTED, Typeface.NORMAL));

        String media = (release.getAudioName().isEmpty() ? "MASTER —" : "MASTER ✓ " + release.getAudioName())
                + "\n" + (release.getArtworkName().isEmpty() ? "COVER —" : "COVER ✓ " + release.getArtworkName());
        TextView mediaText = text(media, 11, release.getAudioName().isEmpty() || release.getArtworkName().isEmpty() ? WARNING : GREEN, Typeface.NORMAL);
        mediaText.setPadding(0, dp(8), 0, 0);
        card.addView(mediaText);

        String stores = release.getDestinations().isEmpty() ? "No destinations" : String.join(" • ", release.getDestinations());
        TextView storeText = text(stores, 11, MUTED, Typeface.NORMAL);
        storeText.setPadding(0, dp(8), 0, 0);
        card.addView(storeText);
        TextView id = text(release.getId(), 10, Color.rgb(105, 113, 128), Typeface.NORMAL);
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

    private LinearLayout.LayoutParams buttonLp() {
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52));
        lp.setMargins(0, dp(6), 0, dp(4));
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

    private CheckBox checkbox(String label) {
        CheckBox check = new CheckBox(this);
        check.setText(label);
        check.setTextColor(TEXT);
        check.setTextSize(14);
        check.setButtonTintList(android.content.res.ColorStateList.valueOf(ACCENT));
        check.setPadding(dp(4), dp(6), dp(4), dp(6));
        return check;
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
        TextView view = text(value, 27, TEXT, Typeface.BOLD);
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

    private String formatBytes(long bytes) {
        if (bytes < 1024L) return bytes + " B";
        double kb = bytes / 1024d;
        if (kb < 1024d) return String.format(Locale.US, "%.1f KB", kb);
        return String.format(Locale.US, "%.1f MB", kb / 1024d);
    }

    private String formatDuration(long ms) {
        long total = Math.max(0L, ms / 1000L);
        long min = total / 60L;
        long sec = total % 60L;
        return String.format(Locale.US, "%d:%02d", min, sec);
    }

    private String fallback(String value, String fallback) {
        return value == null || value.trim().isEmpty() ? fallback : value.trim();
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

    private void toast(String value) {
        Toast.makeText(this, value, Toast.LENGTH_LONG).show();
    }
}
