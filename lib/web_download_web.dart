import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external _Blob(JSArray<JSAny> parts, JSObject options);
}

@JS('URL')
extension type _Url._(JSObject _) implements JSObject {
  external static String createObjectURL(JSObject blob);
  external static void revokeObjectURL(String url);
}

@JS('document')
external JSObject get _document;

/// Downloads [bytes] as a file through the browser.
void webDownload(String name, Uint8List bytes, String mime) {
  final parts = <JSAny>[bytes.toJS].toJS;
  final blob = _Blob(parts, {'type': mime}.jsify() as JSObject);
  final url = _Url.createObjectURL(blob);
  final a = _document.callMethod<JSObject>('createElement'.toJS, 'a'.toJS);
  a.setProperty('href'.toJS, url.toJS);
  a.setProperty('download'.toJS, name.toJS);
  _document.getProperty<JSObject>('body'.toJS).callMethod('appendChild'.toJS, a);
  a.callMethod('click'.toJS);
  a.callMethod('remove'.toJS);
  _Url.revokeObjectURL(url);
}
