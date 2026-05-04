package com.freeth;

import android.content.Intent;
import android.net.VpnService;
import android.os.ParcelFileDescriptor;

public class MyVpnService extends VpnService {
    private ParcelFileDescriptor vpnInterface;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Builder builder = new Builder();
        builder.setSession("Freeth Secure Connection")
               .addAddress("10.0.0.2", 24)
               .addRoute("0.0.0.0", 0);

        vpnInterface = builder.establish();

        if (vpnInterface == null) {
            stopSelf();
            return START_NOT_STICKY;
        }

        return START_STICKY;
    }

    @Override
    public void onRevoke() {
        super.onRevoke();
        closeInterface();
        stopSelf();
    }

    @Override
    public void onDestroy() {
        closeInterface();
        super.onDestroy();
    }

    private void closeInterface() {
        if (vpnInterface != null) {
            try {
                vpnInterface.close();
            } catch (Exception ignored) {
            }
            vpnInterface = null;
        }
    }
}