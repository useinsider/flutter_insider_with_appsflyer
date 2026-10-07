package com.useinsider.insider.flutter_insider.appframes;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

/**
 * Creates the platform view backing the Dart {@code InsiderAppFramesView} widget.
 */
public final class InsiderAppFramesViewFactory extends PlatformViewFactory {

    /** Must match {@code Constants.APP_FRAMES_VIEW_TYPE} on the Dart side. */
    public static final String VIEW_TYPE =
            "com.useinsider.insider.flutter_insider/app_frames_view";

    /** Must match {@code Constants.APP_FRAMES_PLACEMENT_ID} on the Dart side. */
    private static final String ARG_PLACEMENT_ID = "placementId";

    @NonNull
    private final BinaryMessenger messenger;

    public InsiderAppFramesViewFactory(@NonNull BinaryMessenger messenger) {
        super(StandardMessageCodec.INSTANCE);
        this.messenger = messenger;
    }

    @NonNull
    @Override
    public PlatformView create(Context context, int viewId, @Nullable Object args) {
        String placementId = null;
        if (args instanceof Map) {
            Object rawPlacementId = ((Map<?, ?>) args).get(ARG_PLACEMENT_ID);
            if (rawPlacementId instanceof String) {
                placementId = (String) rawPlacementId;
            }
        }
        return new InsiderAppFramesPlatformView(context, messenger, viewId, placementId);
    }
}
