// Picks the browser implementation on the web and a no-op on Android/iOS.
export 'web_notify_stub.dart' if (dart.library.js_interop) 'web_notify_web.dart';
