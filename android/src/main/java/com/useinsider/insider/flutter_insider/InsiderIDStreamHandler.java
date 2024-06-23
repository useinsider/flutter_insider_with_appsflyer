package com.useinsider.insider.flutter_insider;

import io.flutter.plugin.common.EventChannel;
import android.os.Handler;
import android.os.Looper;

public class InsiderIDStreamHandler implements EventChannel.StreamHandler {
    private static EventChannel.EventSink eventSink = null;
    private static Handler handler;

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        InsiderIDStreamHandler.eventSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
        InsiderIDStreamHandler.eventSink = null;
    }

    public static void triggerEvent(String data) {
        try {
            if (handler == null) {
                handler = new Handler(Looper.getMainLooper());
            }

            if (InsiderIDStreamHandler.eventSink != null) {
                handler.post(new Runnable() {
                    @Override
                    public void run() {
                        InsiderIDStreamHandler.eventSink.success(data);
                    }
                });
            }
        } catch (Exception ignore) {}
    }
}
