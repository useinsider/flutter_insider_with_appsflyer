package com.useinsider.insider.flutter_insider;

import android.os.Handler;
import android.os.Looper;

import com.useinsider.insider.Insider;
import com.useinsider.insider.InsiderEventListener;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.EventChannel;

/**
 * EventChannel stream handler for the `insider_event_listener` channel.
 *
 * The native SDK delivers {@code onEventRecorded} on a dedicated background
 * thread. Flutter's {@link EventChannel.EventSink} is only safe to touch from
 * the platform main thread, so every emission is hopped onto the main looper.
 *
 * The SDK holds registered observers strongly, so the observer is explicitly
 * removed in {@link #onCancel(Object)} to avoid leaking the sink.
 *
 * <p><b>Single-engine assumption.</b> The sink and the observer are process-global
 * statics, matching {@link InsiderIDStreamHandler}. With more than
 * one {@code FlutterEngine} (add-to-app hosting) the most recently attached engine
 * wins the sink, and a detach from any engine removes the observer for all of them.
 * Detaching an engine likewise tears the observer down while Dart still believes it
 * is subscribed, so listeners must be re-created after a detach. Single-engine is
 * the supported mode for this plugin; keying the sink per engine is what this would
 * need to change.
 */
public class InsiderEventStreamHandler implements EventChannel.StreamHandler {
    // volatile because the SDK delivers on its own background thread while onListen /
    // onCancel write these from the platform main thread. The iOS handler guards the
    // equivalent state with @synchronized; this is the Java counterpart.
    private static volatile EventChannel.EventSink eventSink = null;
    // Built once at class load rather than lazily: triggerEvent runs on the SDK's
    // background thread, so an unsynchronized null-check could construct two of these.
    // Both would post to the main looper and nothing would break, but final states the
    // intent and removes the question.
    private static final Handler handler = new Handler(Looper.getMainLooper());
    private static volatile InsiderEventListener listener = null;

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        InsiderEventStreamHandler.eventSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
        InsiderEventStreamHandler.eventSink = null;
        removeObserver();
    }

    /**
     * Registers the observer with the SDK, if it is not registered already.
     *
     * {@code Insider.Instance.events()} returns a no-op instance before the SDK
     * is initialised, so the {@code InsiderEvents} object is resolved fresh on
     * every call rather than cached.
     *
     * @throws RuntimeException if the SDK rejected the observer. The Dart side rolls its
     *         subscribe back and reports the failure to the caller, so swallowing it here
     *         would hand out a subscription that can never deliver — the caller would wait
     *         on a stream with no observer behind it and no signal that anything was wrong.
     */
    static void addObserver() {
        try {
            if (listener != null) return;

            InsiderEventListener candidate = new InsiderEventListener() {
                @Override
                public void onEventRecorded(String name, Map<String, Object> parameters, long timestamp) {
                    triggerEvent(name, parameters, timestamp);
                }
            };

            // The field is assigned only AFTER the SDK accepted the observer.
            // Assigning it first would permanently wedge the bridge if
            // addObserver threw: every later call would early-return believing
            // an observer exists, and no event would ever arrive.
            Insider.Instance.events().addObserver(candidate);
            listener = candidate;
        } catch (Exception e) {
            Insider.Instance.putException(e);

            throw new RuntimeException("Insider addObserver failed", e);
        }
    }

    /** Unregisters the observer from the SDK, if one is registered. */
    public static void removeObserver() {
        try {
            if (listener == null) return;

            // Symmetrically, the field is cleared only after the SDK accepted
            // the removal, so a throwing removeObserver cannot leave the bridge
            // believing it is unregistered while the SDK still holds it.
            Insider.Instance.events().removeObserver(listener);
            listener = null;
        } catch (Exception e) {
            Insider.Instance.putException(e);
        }
    }

    /** Called from teardown to drop both the sink and the SDK registration. */
    public static void dispose() {
        InsiderEventStreamHandler.eventSink = null;
        removeObserver();
    }

    /**
     * Encodes one recorded event and delivers it to the sink on the main thread.
     *
     * Only invoked by the {@link InsiderEventListener} registered in
     * {@link #addObserver()} — unlike {@code InsiderIDStreamHandler.triggerEvent},
     * nothing outside this class calls it, so it stays private.
     */
    private static void triggerEvent(final String name,
                                     final Map<String, Object> parameters,
                                     final long timestamp) {
        try {
            if (InsiderEventStreamHandler.eventSink == null) return;

            final Map<String, Object> payload = new HashMap<>();
            // Coalesced to match iOS, which sends `name ?: @""`. Putting null here would
            // make the Dart decoder reject the whole event, so the same SDK behaviour
            // would silently drop an event on one platform and deliver it on the other.
            payload.put("name", name != null ? name : "");
            payload.put("parameters", encodeParameters(parameters));
            payload.put("timestamp", timestamp);

            handler.post(new Runnable() {
                @Override
                public void run() {
                    // Re-check: the sink may have been nulled by onCancel between
                    // the check above and this Runnable executing on the main thread.
                    EventChannel.EventSink sink = InsiderEventStreamHandler.eventSink;
                    if (sink != null) {
                        sink.success(payload);
                    }
                }
            });
        } catch (Exception e) {
            // Reported rather than swallowed: an un-encodable parameter shape
            // would otherwise drop the event with no trace at all. Consistent
            // with addObserver / removeObserver above.
            Insider.Instance.putException(e);
        }
    }

    /**
     * Copies the SDK's unmodifiable parameter map into a codec-safe map.
     *
     * StandardMessageCodec cannot encode raw Java arrays, and event parameters
     * added via {@code addParameterWithStringArray} /
     * {@code addParameterWithNumericArray} arrive as {@code String[]} /
     * {@code Number[]}, so arrays are converted to {@link java.util.List}.
     *
     * <p>Dates need no special case: {@code addParameterWithDate} stores the
     * result of {@code StaticUtils.formatDate}, so no {@link java.util.Date}
     * ever reaches this method.</p>
     */
    static Map<String, Object> encodeParameters(Map<String, Object> parameters) {
        Map<String, Object> encoded = new HashMap<>();
        if (parameters == null) return encoded;

        for (Map.Entry<String, Object> entry : parameters.entrySet()) {
            encoded.put(entry.getKey(), encodeValue(entry.getValue()));
        }

        return encoded;
    }

    private static Object encodeValue(Object value) {
        if (value == null) return null;

        if (value instanceof Object[]) {
            Object[] array = (Object[]) value;
            java.util.List<Object> list = new java.util.ArrayList<>(array.length);
            for (Object item : array) {
                list.add(encodeValue(item));
            }
            return list;
        }

        if (value instanceof int[]) {
            int[] array = (int[]) value;
            java.util.List<Object> list = new java.util.ArrayList<>(array.length);
            for (int item : array) list.add(item);
            return list;
        }

        if (value instanceof long[]) {
            long[] array = (long[]) value;
            java.util.List<Object> list = new java.util.ArrayList<>(array.length);
            for (long item : array) list.add(item);
            return list;
        }

        if (value instanceof double[]) {
            double[] array = (double[]) value;
            java.util.List<Object> list = new java.util.ArrayList<>(array.length);
            for (double item : array) list.add(item);
            return list;
        }

        if (value instanceof float[]) {
            float[] array = (float[]) value;
            java.util.List<Object> list = new java.util.ArrayList<>(array.length);
            for (float item : array) list.add((double) item);
            return list;
        }

        if (value instanceof boolean[]) {
            boolean[] array = (boolean[]) value;
            java.util.List<Object> list = new java.util.ArrayList<>(array.length);
            for (boolean item : array) list.add(item);
            return list;
        }

        if (value instanceof Map) {
            Map<?, ?> map = (Map<?, ?>) value;
            Map<String, Object> encoded = new HashMap<>();
            for (Map.Entry<?, ?> entry : map.entrySet()) {
                if (entry.getKey() == null) continue;
                encoded.put(entry.getKey().toString(), encodeValue(entry.getValue()));
            }
            return encoded;
        }

        if (value instanceof java.util.List) {
            java.util.List<?> source = (java.util.List<?>) value;
            java.util.List<Object> list = new java.util.ArrayList<>(source.size());
            for (Object item : source) {
                list.add(encodeValue(item));
            }
            return list;
        }

        if (value instanceof Float) {
            return ((Float) value).doubleValue();
        }

        // Types StandardMessageCodec encodes natively. The primitive arrays it also
        // supports are converted to Lists above and never reach here.
        if (value instanceof String
                || value instanceof Boolean
                || value instanceof Integer
                || value instanceof Long
                || value instanceof Double
                || value instanceof byte[]) {
            return value;
        }

        // Unknown type — degrade to a string, matching the iOS encoder. Returning it
        // unchanged would make the codec throw, and the outer catch would then drop the
        // WHOLE event rather than just this one parameter.
        return String.valueOf(value);
    }
}
