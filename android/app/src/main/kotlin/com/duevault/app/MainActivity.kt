package com.duevault.app

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge for backward compatibility (required for targetSdk 35+)
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
