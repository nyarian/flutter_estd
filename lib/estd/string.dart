extension Estd on String {
  /// Removes the [beginning] from the start of this String and returns the
  /// reminder. String is returned unchanged if it does not start with
  /// [beginning].
  String removeBeginning(String beginning) {
    return startsWith(beginning) ? substring(beginning.length) : this;
  }
}
