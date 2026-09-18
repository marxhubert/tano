package com.marxhubert.tanonote

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            setRecentsScreenshotEnabled(false)
        } else {
            // Older Android cannot disable only task previews. This also blocks
            // screenshots/screen recording on those versions.
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }
}
