abstract class StringKeyValueStorage {
  Future<void> actualize();

  Future<void> putString(String key, String value);

  Future<String?> getString(String key);

  Future<void> removeForKey(String key);

  Future<void> clearStorage();
}

abstract class KeyValueStorage implements StringKeyValueStorage {
  /// Returns the stored bool, or [otherwise] when the key is absent.
  ///
  /// [otherwise] defaults to null, so a missing key can be told from a
  /// stored `false`.
  Future<bool?> getBool(String key, {bool? otherwise});

  Future<void> putBool(String key, {required bool value});

  /// Returns the stored int, or [otherwise] when the key is absent.
  ///
  /// [otherwise] defaults to null, so a missing key can be told from a
  /// stored `0`.
  Future<int?> getInt(String key, [int? otherwise]);

  Future<void> putInt(String key, int value);
}
