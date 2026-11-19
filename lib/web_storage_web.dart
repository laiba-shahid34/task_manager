import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('localStorage')
external JSObject get _localStorage;

String? webStorageGet(String key) {
  try {
    final r = _localStorage.callMethod<JSAny?>('getItem'.toJS, key.toJS);
    return r == null ? null : (r as JSString).toDart;
  } catch (_) {
    return null;
  }
}

void webStorageSet(String key, String value) {
  try {
    _localStorage.callMethod<JSAny?>('setItem'.toJS, key.toJS, value.toJS);
  } catch (_) {}
}
