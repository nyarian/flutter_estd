import 'package:flutter_estd/ioc/service_locator.dart';
import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';

@immutable
class GetItServiceLocatorAdapter
    implements ServiceLocator, ServiceLocatorBuilder {
  const GetItServiceLocatorAdapter(this._delegate);

  @override
  ScopedService<T> get<T extends Object>() {
    if (!_delegate.isRegistered<ScopedService<T>>()) {
      throw _createException<T>(Scope.shared);
    } else {
      return _delegate.get<ScopedService<T>>();
    }
  }

  @override
  T shared<T extends Object>() {
    if (!_delegate.isRegistered<ScopedService<T>>()) {
      throw _createException<T>(Scope.shared);
    }
    final service = _delegate.get<ScopedService<T>>();
    if (service.scope == Scope.shared) {
      return service.service;
    } else {
      throw _createException<T>(Scope.shared);
    }
  }

  @override
  T owned<T extends Object>() {
    if (!_delegate.isRegistered<ScopedService<T>>()) {
      throw _createException<T>(Scope.owned);
    }
    final service = _delegate.get<ScopedService<T>>();
    if (service.scope == Scope.owned) {
      return service.service;
    } else {
      throw _createException<T>(Scope.owned);
    }
  }

  Exception _createException<T>([Scope? scope]) {
    final service = const {
      null: 'Service',
      Scope.shared: 'Singleton service',
      Scope.owned: 'Owned service',
    }[scope]!;
    final message = "$service of type $T isn't registered";
    throw ServiceNotRegistered(message: message);
  }

  @override
  void addShared<T extends Object>(T service) {
    _delegate
        .registerSingleton<ScopedService<T>>(ScopedService.shared(service));
  }

  @override
  void addLazyShared<T extends Object>(ServiceFactory<T> factory) {
    _delegate.registerLazySingleton<ScopedService<T>>(
      () => ScopedService.shared(factory(this)),
    );
  }

  @override
  void addFactory<T extends Object>(ServiceFactory<T> factory) {
    _delegate.registerFactory<ScopedService<T>>(
      () => ScopedService.owned(factory(this)),
    );
  }

  @override
  ServiceLocator build() => this;

  final GetIt _delegate;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GetItServiceLocatorAdapter && other._delegate == _delegate;
  }

  @override
  int get hashCode => _delegate.hashCode;

  @override
  String toString() => '_GetItServiceLocator(_delegate: $_delegate)';
}
