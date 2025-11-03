package com.example.ticket_printer_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_LOCKED_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {

            Log.d("AGETIM_BOOT", "Redémarrage détecté")

            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val wasRunning = prefs.getBoolean("flutter.service_was_running", false)

            if (wasRunning) {
                Log.d("AGETIM_BOOT", "Relance service...")

                try {
                    val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                    launchIntent?.let {
                        it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        it.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        context.startActivity(it)
                        Log.d("AGETIM_BOOT", "App lancée")
                    }
                } catch (e: Exception) {
                    Log.e("AGETIM_BOOT", "Erreur: ${e.message}")
                }
            }
        }
    }
}