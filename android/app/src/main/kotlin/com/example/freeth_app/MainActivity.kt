package com.example.freeth_app

import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.freeth_app/installed_apps",
        ).setMethodCallHandler { call, result ->
            if (call.method == "getInstalledApps") {
                result.success(getInstalledUserApps())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getInstalledUserApps(): List<Map<String, String>> {
        val pm = packageManager
        val allApps = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledApplications(
                PackageManager.ApplicationInfoFlags.of(PackageManager.GET_META_DATA.toLong()),
            )
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledApplications(PackageManager.GET_META_DATA)
        }

        return allApps
            .filter { info ->
                val isUser = (info.flags and ApplicationInfo.FLAG_SYSTEM) == 0
                val isUpdatedSystem = (info.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
                val hasLauncher = pm.getLaunchIntentForPackage(info.packageName) != null
                (isUser || isUpdatedSystem) && hasLauncher
            }
            .map { info ->
                mapOf(
                    "packageName" to info.packageName,
                    "name" to pm.getApplicationLabel(info).toString(),
                )
            }
            .sortedBy { it["name"]?.lowercase() ?: "" }
    }
}
