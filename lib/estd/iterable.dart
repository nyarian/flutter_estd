import 'package:flutter_estd/estd/functional/std.dart';
import 'package:flutter_estd/estd/tuple.dart';

typedef BiFunction<T, U, R> = R Function(T, U);

extension United<E> on Iterable<E> {
  Iterable<R> unite<T, R>(Iterable<T> other, BiFunction<E, T, R> mapper) sync* {
    final Iterator<E> leftIterator = iterator;
    final Iterator<T> rightIterator = other.iterator;
    while (leftIterator.moveNext() && rightIterator.moveNext()) {
      yield mapper(leftIterator.current, rightIterator.current);
    }
  }

  Iterable<Pair<E, T>> uniteToPairs<T>(Iterable<T> other) =>
      unite(other, Pair<E, T>.new);
}

extension WhereNotNull<E> on Iterable<E?> {
  Iterable<E> whereNotNull() => where((e) => e != null).map((e) => e!);
}

extension MapNotNull<E> on Iterable<E> {
  Iterable<T> mapNotNull<T>(Transformation<E, T?> mapper) =>
      map(mapper).whereNotNull();
}

extension Replace<E> on List<E> {
  List<E> replaceElement(E element, bool Function(E) predicate) {
    final index = indexWhere(predicate);
    return index == -1 ? this : (toList()..[index] = element);
  }
}
