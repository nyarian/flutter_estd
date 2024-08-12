import 'package:built_collection/built_collection.dart';
import 'package:flutter_estd/ioc/service_locator.dart';

class _InMemoryServiceLocator implements ServiceLocator {
  _InMemoryServiceLocator._(
    Map<Type, Object> shared,
    this._lazyShared,
    this._proprietary,
  )
  // Defensive copy
  : _shared = Map.of(shared);

  @override
  ScopedService<T> get<T extends Object>() {
    return _get<T>(
      resolve: () => _shared[T],
      ifExists: ScopedService.shared,
      ifNull: _resolveLazyOrProprietary,
    );
  }

  @override
  T shared<T extends Object>() {
    return _get<T>(
      resolve: () => _shared[T],
      ifExists: ScopedService.shared,
      ifNull: _resolveLazy,
    ).service;
  }

  @override
  T owned<T extends Object>() {
    return _get<T>(
      resolve: () => _shared[T],
      ifExists: ScopedService.shared,
      ifNull: _resolveProprietary,
    ).service;
  }

  ScopedService<T> _resolveLazyOrProprietary<T extends Object>() =>
      _resolveLazyOr(_resolveProprietary);

  ScopedService<T> _resolveLazy<T extends Object>() =>
      _resolveLazyOr(() => throw StateError("Unregistered type: $T"));

  ScopedService<T> _resolveLazyOr<T extends Object>(
    ScopedService<T> Function() ifNull,
  ) {
    return _get<T>(
      resolve: () => _withFactory(_lazyShared[T]),
      ifExists: (T service) {
        _shared[T] = service;
        return ScopedService.shared(service);
      },
      ifNull: ifNull,
    );
  }

  ScopedService<T> _resolveProprietary<T extends Object>() => _get<T>(
        resolve: () => _withFactory(_proprietary[T]),
        ifExists: ScopedService.owned,
        ifNull: () => throw StateError("Unregistered type: $T"),
      );

  Object? _withFactory(ServiceFactory<Object>? factory) =>
      factory == null ? null : factory(this);

  ScopedService<T> _get<T extends Object>({
    required Object? Function() resolve,
    required ScopedService<T> Function(T) ifExists,
    required ScopedService<T> Function() ifNull,
  }) {
    final service = resolve();
    if (service == null) {
      return ifNull();
    } else if (service is! T) {
      throw StateError(
        'Proprietary factory registered for type "$T" '
        'returned an instance of type ${service.runtimeType}: $service',
      );
    } else {
      return ifExists(service);
    }
  }

  final Map<Type, Object> _shared;
  final BuiltMap<Type, ServiceFactory<Object>> _lazyShared;
  final BuiltMap<Type, ServiceFactory<Object>> _proprietary;
}

class InMemoryServiceLocatorBuilder implements ServiceLocatorBuilder {
  @override
  void addShared<T extends Object>(T service) => _shared[T] = service;

  @override
  void addLazyShared<T extends Object>(ServiceFactory<T> factory) =>
      _lazyShared[T] = factory;

  @override
  void addFactory<T extends Object>(ServiceFactory<T> factory) =>
      _proprietary[T] = factory;

  @override
  ServiceLocator build() => _InMemoryServiceLocator._(
        _shared,
        _lazyShared.build(),
        _proprietary.build(),
      );

  final Map<Type, Object> _shared = <Type, Object>{};
  final Map<Type, ServiceFactory<Object>> _lazyShared =
      <Type, ServiceFactory<Object>>{};
  final Map<Type, ServiceFactory<Object>> _proprietary =
      <Type, ServiceFactory<Object>>{};
}
