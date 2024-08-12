import 'package:flutter_estd/estd/functional/std.dart';
import 'package:flutter_estd/estd/tuple.dart';

extension Windowed<E> on Iterable<E> {
  Iterable<List<E>> window(int size) sync* {
    if (size <= 0) throw ArgumentError.value(size, 'size', "can't be negative");
    final Iterator<E> iterator = this.iterator;
    while (iterator.moveNext()) {
      final List<E> slice = [iterator.current];
      for (int i = 1; i < size; i++) {
        if (!iterator.moveNext()) break;
        slice.add(iterator.current);
      }
      yield slice;
    }
  }
}

extension Nullable<E> on Iterable<E> {
  E? firstOrNull(Predicate<E> predicate) {
    for (final element in this) {
      if (predicate(element)) return element;
    }
    return null;
  }
}

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
