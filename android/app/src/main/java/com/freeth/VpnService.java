package com.freeth;

import android.content.Intent;
import android.net.VpnService;
import android.os.ParcelFileDescriptor;

import java.io.IOException;

public class MyVpnService extends VpnService {
    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Builder builder = new Builder();
        builder.setSession("Freeth Secure Connection")
               .addAddress("10.0.0.2", 24) // Пример IP адреса
               .addRoute("0.0.0.0", 0); // Маршрут по умолчанию

        // Настройка и подключение VPN
        try {
            ParcelFileDescriptor vpnInterface = builder.establish();
        } catch (IOException e) {
            e.printStackTrace();
        }

        return START_STICKY;
    }

    @Override
    public void onRevoke() {
        super.onRevoke();
        // Логика для отключения VPN
        stopSelf();
    }
}