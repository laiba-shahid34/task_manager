// Browser storage (localStorage) on the web, no-op on Android / iOS.
export 'web_storage_stub.dart' if (dart.library.js_interop) 'web_storage_web.dart';
