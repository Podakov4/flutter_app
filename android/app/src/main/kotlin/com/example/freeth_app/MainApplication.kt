package com.example.freeth_app

import com.tencent.mmkv.MMKV
import io.flutter.app.FlutterApplication

class MainApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        MMKV.initialize(this)
    }
}