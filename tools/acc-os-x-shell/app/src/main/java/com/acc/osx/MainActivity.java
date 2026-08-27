package com.acc.osx;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

public class MainActivity extends Activity {
    private static final String HOME_URL = "https://acc-os-x-baxkup.ardarawk.workers.dev/";
    private static final String HOME_HOST = "acc-os-x-baxkup.ardarawk.workers.dev";
    private static final int FILE_CHOOSER_REQUEST = 5001;

    private static final Set<String> ALLOWED_PACKAGES = new HashSet<>(Arrays.asList(
            "com.acc.cleaner",
            "com.kaitradex.app.dev",
            "com.kaitradex.app",
            "com.nadmo.ai",
            "com.kai.casinox",
            "com.accbuilder.accmediadownloader",
            "com.accbuilder.aimashupbootlegstudio",
            "com.acc.contenthub"
    ));

    private WebView webView;
    private ValueCallback<Uri[]> fileCallback;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        webView = new WebView(this);
        setContentView(webView);

        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setDatabaseEnabled(true);
        settings.setLoadsImagesAutomatically(true);
        settings.setMediaPlaybackRequiresUserGesture(false);
        settings.setBuiltInZoomControls(false);
        settings.setDisplayZoomControls(false);
        settings.setCacheMode(WebSettings.LOAD_NO_CACHE);
        settings.setUserAgentString(settings.getUserAgentString() + " ACCOSXNative/1.1");
        webView.clearCache(true);

        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public boolean onShowFileChooser(WebView view, ValueCallback<Uri[]> callback, FileChooserParams params) {
                if (fileCallback != null) fileCallback.onReceiveValue(null);
                fileCallback = callback;
                try {
                    startActivityForResult(params.createIntent(), FILE_CHOOSER_REQUEST);
                    return true;
                } catch (ActivityNotFoundException e) {
                    fileCallback = null;
                    Toast.makeText(MainActivity.this, "File picker tidak tersedia.", Toast.LENGTH_SHORT).show();
                    return false;
                }
            }
        });

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                return handleUri(request.getUrl());
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                return handleUri(Uri.parse(url));
            }
        });

        webView.setDownloadListener((url, userAgent, contentDisposition, mimeType, contentLength) -> {
            try {
                startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url)));
            } catch (Exception e) {
                Toast.makeText(this, "Download tidak bisa dibuka dari shell.", Toast.LENGTH_SHORT).show();
            }
        });

        if (savedInstanceState == null) {
            webView.loadUrl(HOME_URL);
        } else {
            webView.restoreState(savedInstanceState);
        }
    }

    private boolean handleUri(Uri uri) {
        if (uri == null) return false;
        String scheme = uri.getScheme() == null ? "" : uri.getScheme().toLowerCase();

        if ("accapp".equals(scheme) && "launch".equalsIgnoreCase(uri.getHost())) {
            String packages = uri.getQueryParameter("packages");
            if (packages == null || packages.trim().isEmpty()) {
                Toast.makeText(this, "Target APK kosong.", Toast.LENGTH_SHORT).show();
                return true;
            }
            for (String pkg : packages.split(",")) {
                String candidate = pkg.trim();
                if (ALLOWED_PACKAGES.contains(candidate) && launchPackage(candidate)) return true;
            }
            Toast.makeText(this, "APK belum terpasang di HP.", Toast.LENGTH_SHORT).show();
            return true;
        }

        // Backward compatibility for the old OWNER APP LAUNCHER cache.
        // Old tiles used intent:#Intent;...;package=<id>;...;end and WebView previously rendered ERR_UNKNOWN_URL_SCHEME.
        if ("intent".equals(scheme)) {
            try {
                Intent parsed = Intent.parseUri(uri.toString(), Intent.URI_INTENT_SCHEME);
                String pkg = parsed.getPackage();
                if (pkg != null && ALLOWED_PACKAGES.contains(pkg)) {
                    if (launchPackage(pkg)) return true;
                    Toast.makeText(this, "APK belum terpasang di HP.", Toast.LENGTH_SHORT).show();
                    return true;
                }
            } catch (Exception ignored) {
            }
            Toast.makeText(this, "Target APK tidak dikenali.", Toast.LENGTH_SHORT).show();
            return true;
        }

        if ("http".equals(scheme) || "https".equals(scheme)) {
            String host = uri.getHost();
            if (host != null && HOME_HOST.equalsIgnoreCase(host)) return false;
            try {
                startActivity(new Intent(Intent.ACTION_VIEW, uri));
            } catch (Exception e) {
                Toast.makeText(this, "Link tidak bisa dibuka.", Toast.LENGTH_SHORT).show();
            }
            return true;
        }

        return false;
    }

    private boolean launchPackage(String packageName) {
        Intent launch = getPackageManager().getLaunchIntentForPackage(packageName);
        if (launch == null) return false;
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED);
        startActivity(launch);
        return true;
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        webView.saveState(outState);
        super.onSaveInstanceState(outState);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == FILE_CHOOSER_REQUEST && fileCallback != null) {
            Uri[] result = WebChromeClient.FileChooserParams.parseResult(resultCode, data);
            fileCallback.onReceiveValue(result);
            fileCallback = null;
        }
    }

    @Override
    public void onBackPressed() {
        if (webView != null && webView.canGoBack()) webView.goBack();
        else super.onBackPressed();
    }

    @Override
    protected void onDestroy() {
        if (webView != null) {
            webView.stopLoading();
            webView.destroy();
        }
        super.onDestroy();
    }
}
