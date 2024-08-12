import 'package:flutter_estd/estd/functional/std.dart';
import 'package:meta/meta.dart';

typedef IfEmpty<R> = R Function();

abstract interface class Optional<T> {
  factory Optional.ofNullable(T? value) =>
      value == null ? Absent() : Present(value);

  factory Optional.of(T value) = Present;

  factory Optional.empty() = Absent;

  Optional<R> map<R>(Transformation<T, R> transformation);

  Optional<R> flatMap<R>(Transformation<T, Optional<R>> transformation);

  R fold<R>(Transformation<T, R> ifPresent, IfEmpty<R> ifEmpty);
}

extension Get<T> on Optional<T> {
  T? getOrElseNull() => fold(identity, () => null);

  T getOrElse(IfEmpty<T> ifEmpty) => fold(identity, ifEmpty);

  T getOrElseThrow(IfEmpty<Object> exceptionFactory) =>
      // ignore: only_throw_errors
      fold(identity, () => throw exceptionFactory());
}

@immutable
class Present<T> implements Optional<T> {
  Present(this._value) {
    if (_value == null) throw ArgumentError.notNull("value");
  }

  @override
  Optional<R> map<R>(Transformation<T, R> transformation) =>
      Present(transformation(_value));

  @override
  Optional<R> flatMap<R>(Transformation<T, Optional<R>> transformation) =>
      transformation(_value);

  @override
  R fold<R>(Transformation<T, R> ifPresent, IfEmpty<R> ifEmpty) =>
      ifPresent(_value);

  final T _value;
}

@immutable
class Absent<T> implements Optional<T> {
  @override
  Optional<R> map<R>(Transformation<T, R> transformation) => Absent();

  @override
  Optional<R> flatMap<R>(Transformation<T, Optional<R>> transformation) =>
      Absent();

  @override
  R fold<R>(Transformation<T, R> ifPresent, IfEmpty<R> ifEmpty) => ifEmpty();
}

extension Iterated<T> on Iterable<Optional<T>> {
  Iterable<T> filterPresent() => where((e) => e.getOrElseNull() != null)
      .map((e) => e.getOrElseThrow(() => throw AssertionError()));
}
