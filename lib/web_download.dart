// Saves a file from the browser (web) - does nothing on Android / iOS.
export 'web_download_stub.dart' if (dart.library.js_interop) 'web_download_web.dart';
