import 'package:flutter_estd/estd/resource.dart';
import 'package:meta/meta.dart';

@immutable
class Scoped<T> {
  final bool owned;
  final T object;

  const Scoped(this.object, {required this.owned});

  const Scoped.owned(this.object) : owned = true;

  const Scoped.shared(this.object) : owned = false;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Scoped<T> && other.owned == owned && other.object == object;
  }

  @override
  int get hashCode => owned.hashCode ^ object.hashCode;

  @override
  String toString() => 'Scoped(owned: $owned, object: $object)';
}

extension DisposableScopedResource<T extends Resource> on Scoped<T> {
  Resource asDisposableIfOwned() => owned ? object : const NullResource();
}
