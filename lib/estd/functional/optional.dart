import 'package:flutter_estd/estd/functional/std.dart';
import 'package:meta/meta.dart';

typedef IfEmpty<R> = R Function();

sealed class Optional<T> {
  factory Optional.ofNullable(T? value) =>
      value == null ? const Absent() : Present(value);

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
  const Present(this.value);

  @override
  Optional<R> map<R>(Transformation<T, R> transformation) =>
      Present(transformation(value));

  @override
  Optional<R> flatMap<R>(Transformation<T, Optional<R>> transformation) =>
      transformation(value);

  @override
  R fold<R>(Transformation<T, R> ifPresent, IfEmpty<R> ifEmpty) =>
      ifPresent(value);

  final T value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Present<T> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Present(value: $value)';
}

@immutable
class Absent<T> implements Optional<T> {
  const Absent();

  @override
  Optional<R> map<R>(Transformation<T, R> transformation) => const Absent();

  @override
  Optional<R> flatMap<R>(Transformation<T, Optional<R>> transformation) =>
      const Absent();

  @override
  R fold<R>(Transformation<T, R> ifPresent, IfEmpty<R> ifEmpty) => ifEmpty();

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is Absent<T>;
  }

  @override
  int get hashCode => 0;

  @override
  String toString() => 'Absent()';
}

extension Iterated<T> on Iterable<Optional<T>> {
  Iterable<T> filterPresent() => where((e) => e.getOrElseNull() != null)
      .map((e) => e.getOrElseThrow(() => throw AssertionError()));
}
