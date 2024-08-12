import 'package:meta/meta.dart';

abstract interface class Pair<T, U> {
  factory Pair(T first, U second) = _Pair;

  static Pair<T, U> of<T, U>(T left, U right) => Pair(left, right);

  T get first;

  U get second;
}

@immutable
class _Pair<T, U> implements Pair<T, U> {
  const _Pair(this.first, this.second);

  @override
  final T first;
  @override
  final U second;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is _Pair<T, U> &&
        other.first == first &&
        other.second == second;
  }

  @override
  int get hashCode => first.hashCode ^ second.hashCode;

  @override
  String toString() => '_Pair(first: $first, second: $second)';
}
