package com.example.ticket_printer_app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Si lancé au boot, minimiser
        if (intent.flags and android.content.Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY == 0) {
            if (intent.getBooleanExtra("silent_start", false)) {
                moveTaskToBack(true)
            }
        }
    }
}