import 'dart:js_interop';

/// The browser's built-in Notification API.
@JS('Notification')
extension type _BrowserNotification._(JSObject _) implements JSObject {
  external _BrowserNotification(String title, [JSObject? options]);
  external static String get permission;
  external static JSPromise<JSString> requestPermission();
}

/// 'granted', 'denied', 'default' or 'unsupported'.
String webPermission() {
  try {
    return _BrowserNotification.permission;
  } catch (_) {
    return 'unsupported';
  }
}

/// Must be called from a button tap, otherwise the browser ignores it.
Future<bool> webRequestPermission() async {
  try {
    final r = await _BrowserNotification.requestPermission().toDart;
    return r.toDart == 'granted';
  } catch (_) {
    return false;
  }
}

void webShow(String title, String body) {
  try {
    if (webPermission() != 'granted') return;
    _BrowserNotification(
      title,
      {'body': body, 'icon': 'icons/Icon-192.png'}.jsify() as JSObject,
    );
  } catch (_) {}
}
