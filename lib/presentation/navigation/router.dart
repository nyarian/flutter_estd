import 'package:flutter_estd/navigation.dart';

abstract interface class ApplicationRouter {
  void navigate(String path, {bool addOnTop = false});

  URLPath? get location;
}
