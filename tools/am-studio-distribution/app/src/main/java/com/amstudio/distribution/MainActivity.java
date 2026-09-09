package com.amstudio.distribution;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.Bundle;
import android.text.InputType;
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
import com.amstudio.distribution.network.ApiClient;
import com.amstudio.distribution.network.BackendReleaseOrchestrator;
import com.amstudio.distribution.network.SandboxConnectionStore;

import org.json.JSONObject;

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
    private DistributionGateway localGateway;
    private SandboxConnectionStore connectionStore;
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
        localGateway = new SandboxDistributionGateway();
        connectionStore = new SandboxConnectionStore(this);
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

        LinearLayout copy = new LinearLayout(this);
        copy.setOrientation(LinearLayout.VERTICAL);
        copy.setPadding(dp(12), 0, 0, 0);
        copy.addView(text("AM STUDIO", 18, TEXT, Typeface.BOLD));
        copy.addView(text("MUSIC DISTRIBUTION • SANDBOX CONNECT", 9, MUTED, Typeface.BOLD));
        brand.addView(copy, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));

        TextView badge = text(connectionStore.isConfigured() ? "CONNECTED" : "SANDBOX", 9,
                connectionStore.isConfigured() ? GREEN : WARNING, Typeface.BOLD);
        badge.setPadding(dp(9), dp(6), dp(9), dp(6));
        badge.setBackground(roundRect(Color.rgb(35, 39, 48), 99));
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
        page.addView(title("Backend-ready music distribution."));
        page.addView(body("AM STUDIO memisahkan APK, katalog canonical, backend, dan provider adapter. v0.4 dapat mengirim release package ke AM STUDIO sandbox melalui HTTPS."));

        Button create = primaryButton("+ NEW RELEASE");
        create.setOnClickListener(v -> showNewRelease());
        page.addView(create, buttonLpTall());

        List<ReleaseDraft> releases = releaseStore.all();
        LinearLayout metrics = new LinearLayout(this);
        metrics.setWeightSum(3f);
        metrics.addView(metricCard(String.valueOf(releases.size()), "RELEASES"), weightedCard());
        metrics.addView(metricCard(String.valueOf(countStatus(releases, ReleaseStatus.IN_REVIEW)), "IN REVIEW"), weightedCard());
        metrics.addView(metricCard(connectionStore.isConfigured() ? "YES" : "NO", "BACKEND"), weightedCard());
        page.addView(metrics);

        page.addView(sectionHeader("PIPELINE"));
        page.addView(infoCard("1. Prepare", "WAV/FLAC • square cover • metadata • credits • rights"));
        page.addView(infoCard("2. Upload", "APK → AM STUDIO HTTPS API → server-side SHA-256 verification"));
        page.addView(infoCard("3. Review", "Canonical preflight → READY_FOR_REVIEW → IN_REVIEW"));
        page.addView(infoCard("4. Provider", "AM STUDIO backend → provider adapter → DSP (still commercially gated)"));

        page.addView(sectionHeader("LATEST RELEASES"));
        if (releases.isEmpty()) page.addView(emptyCard("Belum ada release."));
        else for (int i = 0; i < Math.min(3, releases.size()); i++) page.addView(releaseCard(releases.get(i)));
        scroll.addView(page);
        swap(scroll);
    }

    private void showReleases() {
        ScrollView scroll = pageScroll();
        LinearLayout page = pageColumn();
        page.addView(kicker("CATALOG"));
        page.addView(title("Releases"));
        page.addView(body("Local draft ID dan canonical backend release ID disimpan terpisah agar provider dapat diganti tanpa merusak histori."));
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
        page.addView(kicker("RELEASE WIZARD • v0.4"));
        page.addView(title("Build & submit release"));
        page.addView(body("Local preflight dijalankan lebih dulu. Saat backend sandbox terhubung, APK menghitung checksum + exact byte size lalu upload langsung ke AM STUDIO API."));

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
        artworkStateView = body("Belum ada cover dipilih. Target: square ≥ 3000×3000 px.");
        artworkStateView.setPadding(dp(4), dp(5), dp(4), dp(8));
        page.addView(artworkStateView);

        page.addView(formLabel("RELEASE METADATA"));
        EditText titleInput = field("Release title / track title");
        EditText artistInput = field("Primary artist");
        EditText labelInput = field("Label name");
        labelInput.setText("AM STUDIO");
        EditText genreInput = field("Genre");
        EditText releaseDateInput = field("Release date (YYYY-MM-DD)");
        page.addView(titleInput); page.addView(artistInput); page.addView(labelInput); page.addView(genreInput); page.addView(releaseDateInput);

        page.addView(formLabel("CREDITS & RIGHTS"));
        EditText songwriterInput = field("Songwriter / lyricist");
        EditText composerInput = field("Composer");
        EditText copyrightInput = field("Copyright owner / master owner");
        page.addView(songwriterInput); page.addView(composerInput); page.addView(copyrightInput);
        CheckBox explicitCheck = checkbox("Explicit content");
        CheckBox rightsCheck = checkbox("I own or control the rights/licenses required to distribute this release");
        page.addView(explicitCheck); page.addView(rightsCheck);

        page.addView(formLabel("DISTRIBUTION DESTINATIONS"));
        String[] stores = new String[]{"Spotify", "Apple Music", "TikTok", "YouTube Music", "Instagram / Facebook", "Amazon Music", "Deezer", "TIDAL"};
        List<CheckBox> checks = new ArrayList<>();
        for (String store : stores) { CheckBox check = checkbox(store); checks.add(check); page.addView(check); }

        TextView state = body("Preflight: belum dijalankan");
        state.setPadding(0, dp(14), 0, dp(12));
        page.addView(state);

        Button preflight = secondaryButton("RUN LOCAL PREFLIGHT");
        Button save = secondaryButton("SAVE DRAFT");
        Button submit = primaryButton("SUBMIT TO AM STUDIO SANDBOX");

        preflight.setOnClickListener(v -> {
            ReleaseDraft draft = draftFromForm(titleInput, artistInput, labelInput, genreInput, releaseDateInput,
                    songwriterInput, composerInput, copyrightInput, explicitCheck, rightsCheck, checks);
            DistributionGateway.ValidationResult result = localGateway.validateRelease(draft);
            if (result.isValid()) {
                draft.setStatus(ReleaseStatus.READY_FOR_REVIEW);
                state.setText("Local preflight: PASS");
                state.setTextColor(GREEN);
            } else {
                draft.setStatus(ReleaseStatus.PREFLIGHT_REQUIRED);
                state.setText("Local preflight: " + String.join(" • ", result.getIssues()));
                state.setTextColor(WARNING);
            }
        });

        save.setOnClickListener(v -> {
            ReleaseDraft draft = draftFromForm(titleInput, artistInput, labelInput, genreInput, releaseDateInput,
                    songwriterInput, composerInput, copyrightInput, explicitCheck, rightsCheck, checks);
            draft.setStatus(ReleaseStatus.DRAFT);
            releaseStore.save(draft);
            toast("Draft tersimpan");
            showReleases();
        });

        submit.setOnClickListener(v -> {
            ReleaseDraft draft = draftFromForm(titleInput, artistInput, labelInput, genreInput, releaseDateInput,
                    songwriterInput, composerInput, copyrightInput, explicitCheck, rightsCheck, checks);
            DistributionGateway.ValidationResult validation = localGateway.validateRelease(draft);
            if (!validation.isValid()) {
                state.setText("BLOCKED: " + String.join(" • ", validation.getIssues()));
                state.setTextColor(WARNING);
                return;
            }
            if (!connectionStore.isConfigured()) {
                state.setText("Backend belum terhubung. Buka ACCOUNT dan konfigurasi HTTPS endpoint + sandbox session token.");
                state.setTextColor(WARNING);
                return;
            }

            submit.setEnabled(false);
            state.setText("Uploading package to AM STUDIO sandbox…");
            state.setTextColor(ACCENT);
            releaseStore.save(draft);

            new Thread(() -> {
                try {
                    ApiClient api = new ApiClient(getContentResolver(), connectionStore.getBaseUrl(), connectionStore.getSessionToken());
                    BackendReleaseOrchestrator.Result result = new BackendReleaseOrchestrator(getContentResolver(), api).submit(draft);
                    draft.setBackendReleaseId(result.releaseId);
                    draft.setStatus(ReleaseStatus.safeValueOf(result.status));
                    releaseStore.save(draft);
                    runOnUiThread(() -> {
                        state.setText(result.submittedForReview
                                ? "Backend PASS • " + result.releaseId + " • " + result.status
                                : "Backend preflight blocked • " + result.status);
                        state.setTextColor(result.submittedForReview ? GREEN : WARNING);
                        submit.setEnabled(true);
                        toast(result.submittedForReview ? "Release masuk backend review" : "Backend meminta perbaikan");
                    });
                } catch (Exception error) {
                    runOnUiThread(() -> {
                        state.setText("Backend error: " + fallback(error.getMessage(), error.getClass().getSimpleName()));
                        state.setTextColor(WARNING);
                        submit.setEnabled(true);
                    });
                }
            }).start();
        });

        page.addView(preflight, buttonLp());
        page.addView(save, buttonLp());
        page.addView(submit, buttonLp());
        TextView warning = body("Provider DSP tetap DISABLED sampai akun/API provider resmi dikontrak dan sandbox evidence tersedia. Submit v0.4 hanya masuk AM STUDIO backend review.");
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
        page.addView(infoCard("Gross royalties", "Rp0 • provider statement belum aktif"));
        page.addView(infoCard("AM STUDIO fee", "Rp0 • billing engine belum diaktifkan"));
        page.addView(infoCard("Artist payable", "Rp0 • append-only royalty ledger belum diaktifkan"));
        page.addView(sectionHeader("INTEGRITY RULE"));
        page.addView(emptyCard("Tidak ada saldo estimasi palsu. Nilai hanya akan muncul dari provider statement → reconciliation → ledger → split → payout."));
        scroll.addView(page);
        swap(scroll);
    }

    private void showAccount() {
        ScrollView scroll = pageScroll();
        LinearLayout page = pageColumn();
        page.addView(kicker("SANDBOX CONNECTION"));
        page.addView(title("Account & Backend"));
        page.addView(body("Endpoint HTTPS disimpan di perangkat. Sandbox session token hanya disimpan di memory dan hilang saat app ditutup; provider API secret tidak pernah masuk APK."));

        EditText endpoint = field("https://sandbox-api.example.com");
        endpoint.setText(connectionStore.getBaseUrl());
        EditText token = field("Sandbox session token");
        token.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
        page.addView(endpoint);
        page.addView(token);

        TextView state = body(connectionStore.isConfigured() ? "Session configured for this app process." : "Backend session not connected.");
        state.setTextColor(connectionStore.isConfigured() ? GREEN : WARNING);
        state.setPadding(0, dp(10), 0, dp(10));
        page.addView(state);

        Button connect = primaryButton("SAVE & TEST CONNECTION");
        connect.setOnClickListener(v -> {
            try {
                connectionStore.setBaseUrl(endpoint.getText().toString());
                connectionStore.setSessionToken(token.getText().toString());
            } catch (Exception error) {
                state.setText(fallback(error.getMessage(), "Invalid API configuration"));
                state.setTextColor(WARNING);
                return;
            }
            if (!connectionStore.isConfigured()) {
                state.setText("HTTPS endpoint dan sandbox session token wajib diisi.");
                state.setTextColor(WARNING);
                return;
            }
            connect.setEnabled(false);
            state.setText("Testing authenticated /v1/me…");
            state.setTextColor(ACCENT);
            new Thread(() -> {
                try {
                    ApiClient api = new ApiClient(getContentResolver(), connectionStore.getBaseUrl(), connectionStore.getSessionToken());
                    JSONObject response = api.getMe();
                    String name = response.optString("displayName", response.optString("id", "Authenticated"));
                    String environment = response.optString("environment", "SANDBOX");
                    runOnUiThread(() -> {
                        state.setText("CONNECTED • " + name + " • " + environment);
                        state.setTextColor(GREEN);
                        connect.setEnabled(true);
                    });
                } catch (Exception error) {
                    runOnUiThread(() -> {
                        state.setText("Connection failed: " + fallback(error.getMessage(), error.getClass().getSimpleName()));
                        state.setTextColor(WARNING);
                        connect.setEnabled(true);
                    });
                }
            }).start();
        });
        page.addView(connect, buttonLp());

        Button clear = secondaryButton("CLEAR SESSION TOKEN");
        clear.setOnClickListener(v -> {
            connectionStore.clearSession();
            token.setText("");
            state.setText("Session token cleared. Endpoint retained.");
            state.setTextColor(MUTED);
        });
        page.addView(clear, buttonLp());

        page.addView(sectionHeader("STATUS"));
        page.addView(infoCard("App identity", "com.amstudio.distribution • 0.4.0-sandbox-connect"));
        page.addView(infoCard("Backend", connectionStore.getBaseUrl().isEmpty() ? "NOT CONFIGURED" : connectionStore.getBaseUrl()));
        page.addView(infoCard("Provider adapter", "LabelGrid target • DISABLED until commercial sandbox token"));
        page.addView(infoCard("KYC / KYB", "NOT CONNECTED"));
        page.addView(infoCard("Payout", "NOT CONNECTED"));
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
            int flags = data.getFlags() & Intent.FLAG_GRANT_READ_URI_PERMISSION;
            if (flags != 0) getContentResolver().takePersistableUriPermission(uri, flags);
        } catch (Exception ignored) {}
        try {
            if (requestCode == REQUEST_AUDIO) {
                selectedAudio = MediaInspector.inspectAudio(this, uri);
                if (audioStateView != null) {
                    audioStateView.setText(selectedAudio.name + "\n" + formatBytes(selectedAudio.sizeBytes) + " • " + formatDuration(selectedAudio.durationMs) + " • " + fallback(selectedAudio.mime, "unknown mime"));
                    audioStateView.setTextColor(GREEN);
                }
            } else if (requestCode == REQUEST_ARTWORK) {
                selectedArtwork = MediaInspector.inspectArtwork(this, uri);
                if (artworkStateView != null) {
                    artworkStateView.setText(selectedArtwork.name + "\n" + selectedArtwork.width + "×" + selectedArtwork.height + " px • " + formatBytes(selectedArtwork.sizeBytes));
                    artworkStateView.setTextColor(selectedArtwork.width == selectedArtwork.height && selectedArtwork.width >= 3000 ? GREEN : WARNING);
                }
            }
        } catch (Exception error) {
            toast("File tidak dapat diperiksa: " + fallback(error.getMessage(), error.getClass().getSimpleName()));
        }
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
        if (selectedAudio != null) draft.setAudio(selectedAudio.uri, selectedAudio.name, selectedAudio.mime, selectedAudio.sizeBytes, selectedAudio.durationMs);
        if (selectedArtwork != null) draft.setArtwork(selectedArtwork.uri, selectedArtwork.name, selectedArtwork.mime, selectedArtwork.sizeBytes, selectedArtwork.width, selectedArtwork.height);
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
        String media = (release.getAudioName().isEmpty() ? "MASTER —" : "MASTER ✓ " + release.getAudioName()) + "\n" + (release.getArtworkName().isEmpty() ? "COVER —" : "COVER ✓ " + release.getArtworkName());
        TextView mediaText = text(media, 11, release.getAudioName().isEmpty() || release.getArtworkName().isEmpty() ? WARNING : GREEN, Typeface.NORMAL);
        mediaText.setPadding(0, dp(8), 0, 0);
        card.addView(mediaText);
        if (!release.getBackendReleaseId().isEmpty()) {
            TextView backend = text("BACKEND " + release.getBackendReleaseId(), 10, ACCENT, Typeface.MONOSPACE.getStyle());
            backend.setTypeface(Typeface.MONOSPACE);
            backend.setPadding(0, dp(8), 0, 0);
            card.addView(backend);
        }
        TextView stores = text(release.getDestinations().isEmpty() ? "No destinations" : String.join(" • ", release.getDestinations()), 11, MUTED, Typeface.NORMAL);
        stores.setPadding(0, dp(8), 0, 0);
        card.addView(stores);
        return card;
    }

    private LinearLayout metricCard(String value, String label) { LinearLayout c = card(); c.setPadding(dp(12), dp(14), dp(12), dp(14)); c.addView(text(value, 20, TEXT, Typeface.BOLD)); c.addView(text(label, 9, MUTED, Typeface.BOLD)); return c; }
    private LinearLayout metricWide(String value, String label) { LinearLayout c = card(); c.setPadding(dp(18), dp(22), dp(18), dp(22)); c.addView(text(value, 32, TEXT, Typeface.BOLD)); c.addView(text(label, 10, MUTED, Typeface.BOLD)); return c; }
    private LinearLayout infoCard(String heading, String detail) { LinearLayout c = card(); c.addView(text(heading, 15, TEXT, Typeface.BOLD)); TextView d = text(detail, 13, MUTED, Typeface.NORMAL); d.setPadding(0, dp(5), 0, 0); c.addView(d); return c; }
    private LinearLayout emptyCard(String value) { LinearLayout c = card(); c.addView(text(value, 13, MUTED, Typeface.NORMAL)); return c; }
    private LinearLayout card() { LinearLayout c = new LinearLayout(this); c.setOrientation(LinearLayout.VERTICAL); c.setPadding(dp(16), dp(15), dp(16), dp(15)); c.setBackground(roundRect(PANEL, 16)); LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT); lp.setMargins(0, dp(6), 0, dp(6)); c.setLayoutParams(lp); return c; }
    private LinearLayout.LayoutParams weightedCard() { LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f); lp.setMargins(dp(3), 0, dp(3), 0); return lp; }
    private LinearLayout.LayoutParams buttonLp() { LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52)); lp.setMargins(0, dp(6), 0, dp(4)); return lp; }
    private LinearLayout.LayoutParams buttonLpTall() { LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(54)); lp.setMargins(0, dp(18), 0, dp(18)); return lp; }
    private TextView sectionHeader(String value) { TextView v = text(value, 11, MUTED, Typeface.BOLD); v.setPadding(0, dp(24), 0, dp(7)); return v; }
    private TextView formLabel(String value) { TextView v = text(value, 11, MUTED, Typeface.BOLD); v.setPadding(0, dp(18), 0, dp(8)); return v; }

    private EditText field(String hint) {
        EditText field = new EditText(this);
        field.setHint(hint); field.setHintTextColor(Color.rgb(112, 120, 135)); field.setTextColor(TEXT); field.setSingleLine(true); field.setTextSize(15);
        field.setPadding(dp(14), 0, dp(14), 0); field.setBackground(roundRect(PANEL_2, 12));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52)); lp.setMargins(0, dp(5), 0, dp(5)); field.setLayoutParams(lp);
        return field;
    }

    private CheckBox checkbox(String label) { CheckBox c = new CheckBox(this); c.setText(label); c.setTextColor(TEXT); c.setTextSize(14); c.setButtonTintList(android.content.res.ColorStateList.valueOf(ACCENT)); c.setPadding(dp(4), dp(6), dp(4), dp(6)); return c; }
    private Button primaryButton(String label) { Button b = new Button(this); b.setText(label); b.setTextColor(Color.WHITE); b.setTextSize(13); b.setTypeface(Typeface.DEFAULT, Typeface.BOLD); b.setAllCaps(false); b.setBackground(roundRect(ACCENT, 14)); return b; }
    private Button secondaryButton(String label) { Button b = primaryButton(label); b.setBackground(roundRect(PANEL_2, 14)); return b; }
    private Button navButton(String label, Runnable action) { Button b = new Button(this); b.setText(label); b.setTextColor(MUTED); b.setTextSize(10); b.setTypeface(Typeface.DEFAULT, Typeface.BOLD); b.setAllCaps(false); b.setBackgroundColor(Color.TRANSPARENT); b.setOnClickListener(v -> action.run()); b.setLayoutParams(new LinearLayout.LayoutParams(dp(label.contains("+") ? 92 : 78), dp(48))); return b; }
    private ScrollView pageScroll() { ScrollView s = new ScrollView(this); s.setFillViewport(true); s.setClipToPadding(false); return s; }
    private LinearLayout pageColumn() { LinearLayout p = new LinearLayout(this); p.setOrientation(LinearLayout.VERTICAL); p.setPadding(0, dp(16), 0, dp(26)); return p; }
    private TextView kicker(String value) { TextView v = text(value, 10, ACCENT, Typeface.BOLD); v.setPadding(0, dp(4), 0, dp(8)); return v; }
    private TextView title(String value) { TextView v = text(value, 27, TEXT, Typeface.BOLD); v.setPadding(0, 0, 0, dp(8)); return v; }
    private TextView body(String value) { TextView v = text(value, 13, MUTED, Typeface.NORMAL); v.setLineSpacing(0, 1.15f); return v; }
    private TextView text(String value, int sp, int color, int style) { TextView v = new TextView(this); v.setText(value); v.setTextSize(sp); v.setTextColor(color); v.setTypeface(Typeface.DEFAULT, style); return v; }
    private GradientDrawable roundRect(int color, int radiusDp) { GradientDrawable d = new GradientDrawable(); d.setColor(color); d.setCornerRadius(dp(radiusDp)); return d; }
    private void swap(View view) { contentHost.removeAllViews(); contentHost.addView(view, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)); }
    private int countStatus(List<ReleaseDraft> releases, ReleaseStatus target) { int count = 0; for (ReleaseDraft release : releases) if (release.getStatus() == target) count++; return count; }
    private String formatStatus(ReleaseStatus status) { return status.name().replace('_', ' '); }

    private int statusColor(ReleaseStatus status) {
        switch (status) {
            case LIVE: case PARTIALLY_LIVE: case APPROVED: return GREEN;
            case PREFLIGHT_REQUIRED: case NEEDS_CHANGES: case RIGHTS_HOLD: case FRAUD_HOLD: return WARNING;
            default: return ACCENT;
        }
    }

    private String formatBytes(long bytes) { if (bytes < 1024L) return bytes + " B"; double kb = bytes / 1024d; if (kb < 1024d) return String.format(Locale.US, "%.1f KB", kb); return String.format(Locale.US, "%.1f MB", kb / 1024d); }
    private String formatDuration(long ms) { long total = Math.max(0L, ms / 1000L); return String.format(Locale.US, "%d:%02d", total / 60L, total % 60L); }
    private String fallback(String value, String fallback) { return value == null || value.trim().isEmpty() ? fallback : value.trim(); }
    private int dp(int value) { return Math.round(value * getResources().getDisplayMetrics().density); }
    private void toast(String value) { Toast.makeText(this, value, Toast.LENGTH_LONG).show(); }
}
