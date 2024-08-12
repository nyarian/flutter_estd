import 'package:flutter_estd/estd/resource.dart';
import 'package:flutter_estd/ioc/service_locator.dart';

abstract interface class ScopedResource implements Resource {
  factory ScopedResource(ScopedService<Resource> resource) =>
      resource.scope == Scope.owned
          ? _OwnedResource(resource.service)
          : const _SharedNoOpResource();
}

class _SharedNoOpResource implements ScopedResource {
  const _SharedNoOpResource();

  @override
  void release() {
    // No-op
  }
}

class _OwnedResource implements ScopedResource {
  const _OwnedResource(this._resource);

  @override
  void release() => _resource.release();

  final Resource _resource;
}

extension FluentResource<T extends Resource> on ScopedService<T> {
  T releasedBy(CompositeResource resource) {
    resource.add(ScopedResource(this));
    return service;
  }
}
