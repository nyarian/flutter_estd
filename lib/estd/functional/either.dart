import 'package:flutter_estd/estd/functional/std.dart';
import 'package:meta/meta.dart';

abstract interface class Either<T, U> {
  factory Either.left(T left) = _Left;

  factory Either.right(U left) = _Right;

  R fold<R>(Transformation<T, R> onLeft, Transformation<U, R> onRight);
}

@immutable
class _Left<T, U> implements Either<T, U> {
  const _Left(this._value);

  @override
  R fold<R>(Transformation<T, R> onLeft, Transformation<U, R> onRight) {
    return onLeft(_value);
  }

  final T _value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _Left<T, U> && other._value == _value;
  }

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => '_Left(_value: $_value)';
}

@immutable
class _Right<T, U> implements Either<T, U> {
  const _Right(this._value);

  @override
  R fold<R>(Transformation<T, R> onLeft, Transformation<U, R> onRight) {
    return onRight(_value);
  }

  final U _value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _Right<T, U> && other._value == _value;
  }

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => '_Right(_value: $_value)';
}
