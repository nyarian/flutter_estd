import 'package:meta/meta.dart';

@immutable
class Query<T> {
  const Query({
    required this.value,
    this.start = defaultStart,
    this.size = defaultSize,
  });

  const Query.of(
    T value, {
    int start = defaultStart,
    int size = defaultSize,
  }) : this(value: value, start: start, size: size);

  bool isNextPageFor(Query<T> previous) =>
      previous.value == value && start == previous.start + previous.size;

  bool prolongs(Query<T> previous) =>
      previous.value == value && start > previous.start;

  Query<T> shift(int offset) {
    return Query(value: value, start: start + offset);
  }

  final T value;
  final int start;
  final int size;

  static const defaultStart = 0;
  static const defaultSize = 20;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Query<T> &&
        other.value == value &&
        other.start == start &&
        other.size == size;
  }

  @override
  int get hashCode => value.hashCode ^ start.hashCode ^ size.hashCode;

  @override
  String toString() => 'Query(query: $value, start: $start, size: $size)';
}
