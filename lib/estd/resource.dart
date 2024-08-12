import 'dart:async';

import 'package:meta/meta.dart';

abstract interface class Resource {
  void release();
}

class CompositeResource implements Resource {
  CompositeResource() : _resources = <Resource>[];

  CompositeResource.of(Iterable<Resource> resources)
      : _resources = List.of(resources);

  void add(Resource resource) {
    _resources.add(resource);
  }

  void addAll(Iterable<Resource> resources) => _resources.addAll(resources);

  @override
  void release() {
    _resources.reversed.forEach(_close);
    _resources.clear();
  }

  void _close(Resource resource) => resource.release();

  final List<Resource> _resources;
}

class StreamSubscriptionResource implements Resource {
  StreamSubscriptionResource(this._subscription);

  @override
  void release() => _subscription.cancel();

  final StreamSubscription<void> _subscription;
}

class StreamSubscriptionsResource implements Resource {
  StreamSubscriptionsResource() : _subscriptions = [];

  StreamSubscriptionsResource.of(List<StreamSubscription<void>> subscriptions)
      : _subscriptions = List.of(subscriptions);

  @override
  void release() {
    for (final StreamSubscription<void> value in _subscriptions) {
      value.cancel();
    }
  }

  final List<StreamSubscription<void>> _subscriptions;
}

class SinkResource implements Resource {
  SinkResource(this._sink);

  @override
  void release() => _sink.close();

  final Sink<Object> _sink;
}

class StreamControllerResource implements Resource {
  StreamControllerResource(this._controller);

  @override
  void release() => _controller.close();

  final StreamController<void> _controller;
}

@immutable
class NullResource implements Resource {
  const NullResource();

  @override
  void release() {
    // No-op
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NullResource;
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'NullResource{}';
}

class DelegatingResource implements Resource {
  const DelegatingResource(this._delegate);

  @override
  void release() => _delegate();

  final ResourceDelegate _delegate;
}

typedef ResourceDelegate = void Function();
