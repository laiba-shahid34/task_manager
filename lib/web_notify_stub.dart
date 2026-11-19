// Used on Android / iOS: browser notifications do not exist there.
String webPermission() => 'unsupported';

Future<bool> webRequestPermission() async => false;

void webShow(String title, String body) {}
