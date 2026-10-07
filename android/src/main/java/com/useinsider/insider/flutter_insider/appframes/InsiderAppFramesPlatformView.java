package com.useinsider.insider.flutter_insider.appframes;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.useinsider.insider.Insider;
import com.useinsider.insider.InsiderAppFramesError;
import com.useinsider.insider.InsiderAppFramesView;
import com.useinsider.insider.InsiderAppFramesViewListener;
import com.useinsider.insider.InsiderAppFramesViewStatus;
import com.useinsider.insider.flutter_insider.FlutterInsiderUtils;

import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

/**
 * Hosts a native {@link InsiderAppFramesView} inside the Flutter view hierarchy and relays every
 * {@link InsiderAppFramesViewListener} callback to Dart over a per-view {@link MethodChannel}.
 *
 * <p>The native view subscribes to its placement on window attach and unsubscribes on detach, so
 * mounting and unmounting the Flutter widget drives the whole lifecycle. There is nothing to start
 * or stop explicitly, and the placement is fixed for the life of the view — the Dart widget
 * recreates the platform view when its {@code placementId} changes rather than mutating this one.
 *
 * <p>The channel is one-way (native to Dart). Dart never invokes anything on it, so no method call
 * handler is installed.
 */
final class InsiderAppFramesPlatformView
        implements PlatformView, InsiderAppFramesViewListener {

    /** Must match {@code Constants.APP_FRAMES_CHANNEL_PREFIX} on the Dart side. */
    private static final String CHANNEL_PREFIX = "flutter_insider_app_frames_";

    // native -> Dart
    private static final String METHOD_ON_STATUS_CHANGED = "onStatusChanged";
    private static final String METHOD_ON_LOAD_FAILED = "onLoadFailed";
    private static final String METHOD_ON_HEIGHT_CHANGE_REQUESTED = "onHeightChangeRequested";
    private static final String METHOD_ON_DISMISS_REQUESTED = "onDismissRequested";
    private static final String METHOD_ON_ACTION_TRIGGERED = "onActionTriggered";

    // Argument keys
    private static final String ARG_HEIGHT = "height";
    private static final String ARG_ACTION_DATA = "actionData";
    private static final String ARG_STATUS = "status";
    private static final String ARG_PREVIOUS_STATUS = "previousStatus";

    @NonNull
    private final InsiderAppFramesView appFramesView;

    @NonNull
    private final MethodChannel channel;

    /**
     * The SDK does not document which thread its listener callbacks arrive on, and
     * {@link MethodChannel#invokeMethod} is {@code @UiThread} — the engine hard-throws
     * ("Methods marked with @UiThread must be executed on the main thread") rather than degrading.
     * Every other native-to-Dart path in this plugin hops to the main looper for the same reason;
     * see {@code MethodResultWrapper} and {@code InsiderIDStreamHandler.triggerEvent}.
     */
    @NonNull
    private final Handler mainThreadHandler = new Handler(Looper.getMainLooper());

    private final float density;

    InsiderAppFramesPlatformView(@NonNull Context context,
                                 @NonNull BinaryMessenger messenger,
                                 int viewId,
                                 @Nullable String placementId) {
        this.density = context.getResources().getDisplayMetrics().density;
        this.appFramesView = new InsiderAppFramesView(context);
        this.appFramesView.setLayoutParams(new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT));

        this.channel = new MethodChannel(messenger, CHANNEL_PREFIX + viewId);
        this.appFramesView.setAppFramesListener(this);

        if (placementId != null && !placementId.isEmpty()) {
            this.appFramesView.setPlacementId(placementId);
        } else {
            // The Dart widget requires a non-empty placement id, so an absent one means the
            // creation params did not survive the channel. The view is still returned — Flutter
            // has already committed to it — but it subscribes to nothing and the frame collapses,
            // which is the documented silent-failure behaviour for App Frames.
            Insider.Instance.putException(new IllegalArgumentException(
                    "InsiderAppFramesView created without a placement id; the frame will not load."));
        }
    }

    @NonNull
    @Override
    public View getView() {
        return appFramesView;
    }

    @Override
    public void dispose() {
        appFramesView.setAppFramesListener(null);
        // A callback that arrived off the main thread may still be queued; dropping it here keeps
        // it from reaching Dart after the widget has torn the per-view channel down.
        mainThreadHandler.removeCallbacksAndMessages(null);
        // The SDK exposes no destroy()/release() on InsiderAppFramesView, so its internal WebView
        // cannot be torn down here. Tracked as a native gap on epic MOB-27633.
    }

    /** Delivers a callback to Dart on the main thread; see {@link #mainThreadHandler}. */
    private void invokeOnDart(@NonNull final String method, @Nullable final Object arguments) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            channel.invokeMethod(method, arguments);
            return;
        }
        mainThreadHandler.post(new Runnable() {
            @Override
            public void run() {
                channel.invokeMethod(method, arguments);
            }
        });
    }

    // region InsiderAppFramesViewListener

    @Override
    public void onStatusChanged(@NonNull InsiderAppFramesView view,
                                @NonNull InsiderAppFramesViewStatus status,
                                @NonNull InsiderAppFramesViewStatus previousStatus) {
        Map<String, Object> args = new HashMap<>();
        args.put(ARG_STATUS, FlutterInsiderUtils.mapAppFramesStatus(status));
        args.put(ARG_PREVIOUS_STATUS, FlutterInsiderUtils.mapAppFramesStatus(previousStatus));
        invokeOnDart(METHOD_ON_STATUS_CHANGED, args);
    }

    @Override
    public void onLoadFailed(@NonNull InsiderAppFramesView view,
                             @NonNull InsiderAppFramesError error) {
        invokeOnDart(METHOD_ON_LOAD_FAILED, FlutterInsiderUtils.appFramesErrorToMap(error));
    }

    @Override
    public void onHeightChangeRequested(@NonNull InsiderAppFramesView view, int optimalHeight) {
        // The SDK reports pixels (the template's dp value already multiplied by the display
        // density). Flutter lays out in logical pixels, so convert back.
        Map<String, Object> args = new HashMap<>();
        args.put(ARG_HEIGHT, density > 0 ? optimalHeight / density : (double) optimalHeight);
        invokeOnDart(METHOD_ON_HEIGHT_CHANGE_REQUESTED, args);
    }

    @Override
    public void onDismissRequested(@NonNull InsiderAppFramesView view) {
        invokeOnDart(METHOD_ON_DISMISS_REQUESTED, null);
    }

    @Override
    public void onActionTriggered(@NonNull InsiderAppFramesView view,
                                  @NonNull JSONObject actionData) {
        // Keys and value types are campaign-defined and arbitrarily nested, so the payload crosses
        // the channel as JSON rather than as a converted map.
        Map<String, Object> args = new HashMap<>();
        args.put(ARG_ACTION_DATA, actionData.toString());
        invokeOnDart(METHOD_ON_ACTION_TRIGGERED, args);
    }

    // endregion
}
