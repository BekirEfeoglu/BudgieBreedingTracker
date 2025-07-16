package com.budgienest.app;

import android.os.Bundle;
import android.webkit.WebView;
import android.webkit.WebSettings;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Enable WebView debugging
        WebView.setWebContentsDebuggingEnabled(true);
        
        // Add error handling
        try {
            // Load main app
            if (bridge != null && bridge.getWebView() != null) {
                WebView webView = bridge.getWebView();
                WebSettings settings = webView.getSettings();
                
                // Enable CORS for local files
                settings.setAllowFileAccessFromFileURLs(true);
                settings.setAllowUniversalAccessFromFileURLs(true);
                settings.setDomStorageEnabled(true);
                settings.setAllowContentAccess(true);
                
                webView.setBackgroundColor(0xFFFFFFFF); // White background
                webView.loadUrl("file:///android_asset/public/index.html");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
