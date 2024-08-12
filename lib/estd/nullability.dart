T requireNotNull<T>(T? object, [String? message]) {
  if (object == null) {
    throw StateError(message ?? 'Null is forbidden');
  } else {
    return object;
  }
}
