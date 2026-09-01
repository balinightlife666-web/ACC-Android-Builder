package com.ardac.hpppasar;

import android.app.AlertDialog;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Bundle;
import android.text.InputType;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.text.NumberFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class MainActivity extends AppCompatActivity {
    private EditText ingredientInput, priceInput, spendInput;
    private TextView sourceText, resultText, reportText, totalText;
    private SharedPreferences prefs;
    private JSONArray reportItems = new JSONArray();
    private String currentSource = "Manual";
    private final Locale idLocale = new Locale("id", "ID");

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        prefs = getSharedPreferences("hpp_pasar", MODE_PRIVATE);
        ingredientInput = findViewById(R.id.ingredientInput);
        priceInput = findViewById(R.id.priceInput);
        spendInput = findViewById(R.id.spendInput);
        sourceText = findViewById(R.id.sourceText);
        resultText = findViewById(R.id.resultText);
        reportText = findViewById(R.id.reportText);
        totalText = findViewById(R.id.totalText);

        try {
            reportItems = new JSONArray(prefs.getString("report_items", "[]"));
        } catch (Exception ignored) {
            reportItems = new JSONArray();
        }
        renderReport();

        findViewById(R.id.calculateButton).setOnClickListener(v -> calculate());
        findViewById(R.id.addButton).setOnClickListener(v -> addToReport());
        findViewById(R.id.checkPriceButton).setOnClickListener(v -> checkOnlinePrice());
        findViewById(R.id.shareButton).setOnClickListener(v -> shareReport());
        findViewById(R.id.resetButton).setOnClickListener(v -> resetReport());
        findViewById(R.id.settingsButton).setOnClickListener(v -> showSettings());
    }

    private double readNumber(EditText input) {
        String raw = input.getText().toString().trim().replace("Rp", "").replace(" ", "");
        if (raw.isEmpty()) return 0;
        if (raw.matches(".*[.,].*[.,].*")) raw = raw.replace(".", "").replace(",", "");
        else if (raw.matches("\\d{1,3}[.]\\d{3}")) raw = raw.replace(".", "");
        else if (raw.matches("\\d{1,3},\\d{3}")) raw = raw.replace(",", "");
        else raw = raw.replace(',', '.');
        try { return Double.parseDouble(raw); } catch (Exception e) { return 0; }
    }

    private void calculate() {
        double price = readNumber(priceInput);
        double spend = readNumber(spendInput);
        if (price <= 0 || spend <= 0) {
            Toast.makeText(this, "Isi harga per kg dan nominal belanja.", Toast.LENGTH_SHORT).show();
            return;
        }
        double kg = spend / price;
        resultText.setText(formatWeight(kg) + "\n" + formatMoney(spend) + " ÷ " + formatMoney(price) + "/kg");
    }

    private String formatWeight(double kg) {
        if (kg >= 1) return String.format(idLocale, "%.2f kg (%d gram)", kg, Math.round(kg * 1000));
        return Math.round(kg * 1000) + " gram";
    }

    private String formatMoney(double value) {
        NumberFormat nf = NumberFormat.getCurrencyInstance(idLocale);
        nf.setMaximumFractionDigits(0);
        nf.setMinimumFractionDigits(0);
        return nf.format(value);
    }

    private String today() {
        return new SimpleDateFormat("dd MMM yyyy HH:mm", idLocale).format(new Date());
    }

    private void addToReport() {
        String ingredient = ingredientInput.getText().toString().trim();
        double price = readNumber(priceInput);
        double spend = readNumber(spendInput);
        if (ingredient.isEmpty() || price <= 0 || spend <= 0) {
            Toast.makeText(this, "Lengkapi nama bahan, harga, dan nominal belanja.", Toast.LENGTH_SHORT).show();
            return;
        }
        double kg = spend / price;
        try {
            JSONObject item = new JSONObject();
            item.put("ingredient", ingredient);
            item.put("price", price);
            item.put("spend", spend);
            item.put("kg", kg);
            item.put("source", currentSource);
            item.put("date", today());
            reportItems.put(item);
            saveReport();
            renderReport();
            ingredientInput.setText("");
            priceInput.setText("");
            spendInput.setText("");
            resultText.setText("Hasil akan muncul di sini");
            currentSource = "Manual";
            sourceText.setText("Sumber harga: manual");
        } catch (Exception e) {
            Toast.makeText(this, "Gagal menambah laporan.", Toast.LENGTH_SHORT).show();
        }
    }

    private void saveReport() {
        prefs.edit().putString("report_items", reportItems.toString()).apply();
    }

    private void renderReport() {
        if (reportItems.length() == 0) {
            reportText.setText("Belum ada item.");
            totalText.setText("TOTAL: Rp0");
            return;
        }
        StringBuilder out = new StringBuilder();
        double total = 0;
        for (int i = 0; i < reportItems.length(); i++) {
            JSONObject item = reportItems.optJSONObject(i);
            if (item == null) continue;
            double spend = item.optDouble("spend", 0);
            total += spend;
            out.append(i + 1).append(". ").append(item.optString("ingredient"))
                    .append("\n   Harga: ").append(formatMoney(item.optDouble("price"))).append("/kg")
                    .append("\n   Beli: ").append(formatMoney(spend))
                    .append(" → ").append(formatWeight(item.optDouble("kg")))
                    .append("\n   Sumber: ").append(item.optString("source", "Manual"))
                    .append("\n   ").append(item.optString("date", ""))
                    .append("\n\n");
        }
        reportText.setText(out.toString().trim());
        totalText.setText("TOTAL: " + formatMoney(total));
    }

    private void resetReport() {
        new AlertDialog.Builder(this)
                .setTitle("Reset laporan?")
                .setMessage("Semua item laporan hari ini akan dihapus dari aplikasi.")
                .setNegativeButton("Batal", null)
                .setPositiveButton("Reset", (d, w) -> {
                    reportItems = new JSONArray();
                    saveReport();
                    renderReport();
                }).show();
    }

    private void shareReport() {
        if (reportItems.length() == 0) {
            Toast.makeText(this, "Laporan masih kosong.", Toast.LENGTH_SHORT).show();
            return;
        }
        String text = "LAPORAN BELANJA / HPP PASAR\n" + today() + "\n\n" + reportText.getText() + "\n\n" + totalText.getText();
        Intent send = new Intent(Intent.ACTION_SEND);
        send.setType("text/plain");
        send.putExtra(Intent.EXTRA_TEXT, text);
        startActivity(Intent.createChooser(send, "Bagikan laporan"));
    }

    private void checkOnlinePrice() {
        String ingredient = ingredientInput.getText().toString().trim();
        if (ingredient.isEmpty()) {
            Toast.makeText(this, "Isi nama bahan dulu.", Toast.LENGTH_SHORT).show();
            return;
        }
        String apiKey = prefs.getString("google_api_key", "");
        String cx = prefs.getString("google_cx", "");
        String location = prefs.getString("market_location", "Bali");
        String query = "harga " + ingredient + " 1 kg hari ini " + location;

        if (apiKey.isEmpty() || cx.isEmpty()) {
            currentSource = "Google Search (manual)";
            sourceText.setText("Sumber harga: Google Search — masukkan harga yang terlihat");
            Intent browser = new Intent(Intent.ACTION_VIEW, Uri.parse("https://www.google.com/search?q=" + Uri.encode(query)));
            startActivity(browser);
            return;
        }

        sourceText.setText("Mencari harga online…");
        new Thread(() -> {
            try {
                String endpoint = "https://customsearch.googleapis.com/customsearch/v1?key=" +
                        URLEncoder.encode(apiKey, StandardCharsets.UTF_8.name()) + "&cx=" +
                        URLEncoder.encode(cx, StandardCharsets.UTF_8.name()) + "&q=" +
                        URLEncoder.encode(query, StandardCharsets.UTF_8.name());
                HttpURLConnection conn = (HttpURLConnection) new URL(endpoint).openConnection();
                conn.setConnectTimeout(10000);
                conn.setReadTimeout(10000);
                conn.setRequestProperty("Accept", "application/json");
                int code = conn.getResponseCode();
                if (code < 200 || code >= 300) throw new Exception("HTTP " + code);

                BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream()));
                StringBuilder body = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) body.append(line);
                reader.close();

                JSONObject json = new JSONObject(body.toString());
                JSONArray items = json.optJSONArray("items");
                if (items == null || items.length() == 0) throw new Exception("Harga tidak ditemukan");

                List<Long> candidates = new ArrayList<>();
                String firstDomain = items.optJSONObject(0) != null ? items.optJSONObject(0).optString("displayLink", "web") : "web";
                Pattern p = Pattern.compile("(?i)Rp\\s*([0-9]{1,3}(?:[.,][0-9]{3})+|[0-9]{4,8})");
                for (int i = 0; i < Math.min(items.length(), 7); i++) {
                    JSONObject item = items.optJSONObject(i);
                    if (item == null) continue;
                    String searchable = item.optString("title") + " " + item.optString("snippet");
                    Matcher m = p.matcher(searchable);
                    while (m.find()) {
                        String digits = m.group(1).replace(".", "").replace(",", "");
                        try {
                            long v = Long.parseLong(digits);
                            if (v >= 1000 && v <= 5000000) candidates.add(v);
                        } catch (Exception ignored) { }
                    }
                }
                if (candidates.isEmpty()) throw new Exception("Angka harga tidak terbaca");
                Collections.sort(candidates);
                long selected = candidates.get(candidates.size() / 2);
                String source = "Estimasi web via Google • " + firstDomain + " • " + today();

                runOnUiThread(() -> {
                    priceInput.setText(String.valueOf(selected));
                    currentSource = source;
                    sourceText.setText("Sumber harga: " + source + "\nPeriksa sebelum dimasukkan ke laporan.");
                    calculate();
                });
            } catch (Exception e) {
                runOnUiThread(() -> {
                    sourceText.setText("Harga otomatis belum tersedia: " + e.getMessage());
                    Toast.makeText(this, "Bisa tetap cari lewat Google atau isi harga manual.", Toast.LENGTH_LONG).show();
                });
            }
        }).start();
    }

    private void showSettings() {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        int pad = (int) (20 * getResources().getDisplayMetrics().density);
        box.setPadding(pad, pad / 2, pad, 0);

        EditText key = new EditText(this);
        key.setHint("Google API Key");
        key.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
        key.setText(prefs.getString("google_api_key", ""));
        box.addView(key, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        EditText cx = new EditText(this);
        cx.setHint("Programmable Search Engine ID (cx)");
        cx.setText(prefs.getString("google_cx", ""));
        box.addView(cx, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        EditText location = new EditText(this);
        location.setHint("Lokasi pasar, contoh: Bali");
        location.setText(prefs.getString("market_location", "Bali"));
        box.addView(location, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        new AlertDialog.Builder(this)
                .setTitle("Harga Online")
                .setMessage("Tanpa API key, tombol Cek Harga akan membuka Google Search. Dengan key + cx, aplikasi mencoba membaca estimasi harga langsung dari hasil web.")
                .setView(box)
                .setNegativeButton("Batal", null)
                .setPositiveButton("Simpan", (d, w) -> prefs.edit()
                        .putString("google_api_key", key.getText().toString().trim())
                        .putString("google_cx", cx.getText().toString().trim())
                        .putString("market_location", location.getText().toString().trim().isEmpty() ? "Bali" : location.getText().toString().trim())
                        .apply())
                .show();
    }
}
