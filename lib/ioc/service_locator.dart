import 'package:flutter_estd/estd/functional/std.dart';
import 'package:flutter_estd/estd/resource.dart';
import 'package:flutter_estd/estd/scoped.dart';
import 'package:flutter_estd/ioc/retained.dart';
import 'package:meta/meta.dart';

abstract interface class ServiceLocator {
  ScopedService<T> get<T extends Object>();

  T shared<T extends Object>();

  T owned<T extends Object>();
}

extension AnyScope on ServiceLocator {
  T anyScope<T extends Object>() => get<T>().service;
}

extension RetainedLocator on ServiceLocator {
  Retained<T> retained<T extends Resource>() => shared<Retained<T>>();
}

enum Scope { shared, owned }

@immutable
class ScopedService<T> {
  const ScopedService(this.scope, this.service);

  const ScopedService.shared(this.service) : scope = Scope.shared;

  const ScopedService.owned(this.service) : scope = Scope.owned;

  Scoped<T> asScoped() => Scoped(service, owned: scope == Scope.owned);

  final Scope scope;
  final T service;
}

extension ScopedResourceAsResource<T extends Resource> on ScopedService<T> {
  Resource asResource() =>
      scope == Scope.owned ? service : const NullResource();
}

typedef ServiceFactory<T> = T Function(ServiceLocator l);

abstract interface class ServiceLocatorBuilder {
  void addShared<T extends Object>(T service);

  void addLazyShared<T extends Object>(ServiceFactory<T> factory);

  void addFactory<T extends Object>(ServiceFactory<T> factory);

  ServiceLocator build();
}

extension RetainedBuilder on ServiceLocatorBuilder {
  void addRetained<T extends Resource>(ServiceFactory<T> factory) {
    addFactory<T>(factory);
    addLazyShared<Retained<T>>(Retained<T>.new);
  }
}

abstract interface class ServiceLocatorConfiguration {
  Future<void> apply(ServiceLocatorBuilder builder);
}

class AbsentConfiguration implements ServiceLocatorConfiguration {
  const AbsentConfiguration();

  @override
  Future<void> apply(ServiceLocatorBuilder builder) => Future.value();
}

typedef DynamicConfigurationBlock = Future<void> Function(
    ServiceLocatorBuilder builder);

@immutable
class DynamicConfiguration implements ServiceLocatorConfiguration {
  const DynamicConfiguration(this._block);

  @override
  Future<void> apply(ServiceLocatorBuilder builder) => _block(builder);

  final DynamicConfigurationBlock _block;
}

@immutable
class CompositeConfiguration implements ServiceLocatorConfiguration {
  const CompositeConfiguration(this._configurations);

  @override
  Future<void> apply(ServiceLocatorBuilder builder) async {
    for (final configuration in _configurations) {
      await configuration.apply(builder);
    }
  }

  final Iterable<ServiceLocatorConfiguration> _configurations;
}

abstract interface class ServiceLocatorFactory<T extends Object> {
  T create(ServiceLocator locator);
}

class FactoryServiceLocationConfiguration<T extends Object>
    implements ServiceLocatorConfiguration {
  const FactoryServiceLocationConfiguration(this._factory);

  @override
  Future<void> apply(ServiceLocatorBuilder builder) async {
    return builder.addLazyShared(_factory.create);
  }

  final ServiceLocatorFactory<T> _factory;
}

extension FluentBuilder on ServiceLocatorBuilder {
  void configure(Consumer<ServiceLocatorBuilder> configuration) {
    configuration(this);
  }

  Future<ServiceLocatorBuilder> configureAsync(
    Future<void> Function(ServiceLocatorBuilder) configuration,
  ) async {
    await configuration(this);
    return this;
  }
}

@immutable
final class ServiceNotRegistered implements Exception {
  final String? message;
  final Object? cause;

  const ServiceNotRegistered({this.cause, this.message});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceNotRegistered &&
        other.message == message &&
        other.cause == cause;
  }

  @override
  int get hashCode => message.hashCode ^ cause.hashCode;

  @override
  String toString() => 'ServiceNotRegistered(message: $message, cause: $cause)';
}
