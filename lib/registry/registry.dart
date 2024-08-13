abstract class StringKeyValueStorage {
  Future<void> actualize();

  Future<void> putString(String key, String value);

  Future<String?> getString(String key);

  Future<void> removeForKey(String key);

  Future<void> clearStorage();
}

abstract class KeyValueStorage implements StringKeyValueStorage {
  Future<bool?> getBool(String key, {required bool otherwise});

  Future<void> putBool(String key, {required bool value});

  Future<int?> getInt(String key, int otherwise);

  Future<void> putInt(String key, int value);
}
