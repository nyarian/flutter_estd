abstract interface class ApplicationRouter {
  void navigate(String path, {bool addOnTop = false});

  String? get location;
}
