import 'package:flutter_estd/registry/registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesKeyValueStorage implements KeyValueStorage {
  SharedPreferencesKeyValueStorage(this._delegate);

  @override
  Future<String?> getString(String key) {
    return Future.value(_delegate.getString(key));
  }

  @override
  Future<void> putString(String key, String value) {
    return _delegate.setString(key, value);
  }

  @override
  Future<bool?> getBool(String key, {required bool otherwise}) {
    return Future.value(_delegate.getBool(key) ?? otherwise);
  }

  @override
  Future<void> putBool(String key, {required bool value}) {
    return _delegate.setBool(key, value);
  }

  @override
  Future<int> getInt(String key, int otherwise) {
    return Future.value(_delegate.getInt(key) ?? otherwise);
  }

  @override
  Future<void> putInt(String key, int value) {
    return _delegate.setInt(key, value);
  }

  @override
  Future<void> removeForKey(String key) {
    return _delegate.remove(key);
  }

  @override
  Future<void> actualize() => _delegate.reload();

  @override
  Future<void> clearStorage() => _delegate.clear();

  final SharedPreferences _delegate;
}
