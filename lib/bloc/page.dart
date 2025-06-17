import 'package:built_collection/built_collection.dart';
import 'package:flutter_estd/bloc/bloc.dart';
import 'package:flutter_estd/bloc/state.dart';
import 'package:flutter_estd/estd/functional/std.dart';
import 'package:flutter_estd/estd/object.dart';
import 'package:flutter_estd/estd/query.dart';
import 'package:meta/meta.dart';

// Add metadata regarding the last operation made (insert / remove / etc)?
// Useful for list operations optimizations in UI, but needs designing.

abstract interface class ElementComparisonStrategy<T> {
  bool isSameIdentity(T left, T right);

  T defineNewer(T current, T received);
}

@immutable
class NaturalComparisonStrategy<T> implements ElementComparisonStrategy<T> {
  const NaturalComparisonStrategy();

  @override
  bool isSameIdentity(T left, T right) => left == right;

  @override
  T defineNewer(T current, T received) => received;
}

abstract interface class ShortCircuitStrategy<T> {
  List<T> prepend({
    required ElementComparisonStrategy<T> strategy,
    required BuiltList<T> current,
    required Iterable<T> input,
    required Iterable<T> currentHead,
    required Iterable<T> inputHead,
  });

  List<T> append({
    required ElementComparisonStrategy<T> strategy,
    required BuiltList<T> current,
    required Iterable<T> input,
    required Iterable<T> currentTail,
    required Iterable<T> inputTail,
  });
}

class LatestShortCircuitStrategy<T> implements ShortCircuitStrategy<T> {
  const LatestShortCircuitStrategy();

  @override
  List<T> prepend({
    required ElementComparisonStrategy<T> strategy,
    required BuiltList<T> current,
    required Iterable<T> input,
    required Iterable<T> currentHead,
    required Iterable<T> inputHead,
  }) {
    return inputHead.toList();
  }

  @override
  List<T> append({
    required ElementComparisonStrategy<T> strategy,
    required BuiltList<T> current,
    required Iterable<T> input,
    required Iterable<T> currentTail,
    required Iterable<T> inputTail,
  }) {
    return inputTail.toList();
  }
}

class RetainingShortCircuitStrategy<T> implements ShortCircuitStrategy<T> {
  const RetainingShortCircuitStrategy();

  @override
  List<T> prepend({
    required ElementComparisonStrategy<T> strategy,
    required BuiltList<T> current,
    required Iterable<T> input,
    required Iterable<T> currentHead,
    required Iterable<T> inputHead,
  }) {
    final inputList = inputHead.toList();
    final result = <T>[];
    for (final currentElement in currentHead) {
      final index = inputList
          .indexWhere((e) => strategy.isSameIdentity(e, currentElement));
      if (index == -1) {
        result.add(currentElement);
      } else {
        final newElement = inputList.removeAt(index);
        result.add(strategy.defineNewer(currentElement, newElement));
      }
    }
    result.insertAll(0, inputList);
    return result;
  }

  @override
  List<T> append({
    required ElementComparisonStrategy<T> strategy,
    required BuiltList<T> current,
    required Iterable<T> input,
    required Iterable<T> currentTail,
    required Iterable<T> inputTail,
  }) {
    final inputList = inputTail.toList();
    final result = <T>[];
    for (final currentElement in currentTail) {
      final index = inputList
          .indexWhere((e) => strategy.isSameIdentity(e, currentElement));
      if (index == -1) {
        result.add(currentElement);
      } else {
        final newElement = inputList.removeAt(index);
        result.add(strategy.defineNewer(currentElement, newElement));
      }
    }
    result.addAll(inputList);
    return result;
  }
}

class PagedBloc<T, Q> implements Bloc<PageState<T, Q>> {
  PagedBloc(
    this._gateway,
    Query<Q> firstQuery, {
    Page<T>? initialData,
    int pageSize = Query.defaultSize,
    ElementComparisonStrategy<T>? strategy,
    ShortCircuitStrategy<T>? shortCircuit,
    TransformerFactory<Event<PageState<T, Q>>, PageState<T, Q>>? transformer,
  })  : _pageSize = pageSize,
        _strategy = strategy ?? NaturalComparisonStrategy<T>(),
        _shortCircuit = shortCircuit ?? LatestShortCircuitStrategy<T>(),
        _delegate = StreamTransformerBloc(
          transformer ?? FlatMapTransformerFactory(),
          initialState: initialData == null
              ? FetchingState(null, null, firstQuery)
              : FetchedState(
                  BuiltList.of(initialData.$1),
                  initialData.$2?.build(),
                  firstQuery,
                  hasMore: true,
                ),
          initialEvent: initialData == null
              ? _QueryEvent(
                  firstQuery,
                  _gateway,
                  strategy ?? NaturalComparisonStrategy<T>(),
                  shortCircuit ?? LatestShortCircuitStrategy<T>(),
                )
              : null,
        );

  void query(Query<Q> query) {
    _delegate.add(_QueryEvent(query, _gateway, _strategy, _shortCircuit));
  }

  void retry() {
    _delegate.add(_RetryEvent(_gateway, _strategy, _shortCircuit));
  }

  void page() {
    _delegate.add(_PageEvent(_pageSize, _gateway, _strategy, _shortCircuit));
  }

  void replaceSingle(T element, Predicate<T> predicate) {
    _delegate.add(_ReplaceEvent((_) => element, predicate));
  }

  void transformSingle(Transformation<T, T> map, Predicate<T> predicate) {
    _delegate.add(_ReplaceEvent(map, predicate));
  }

  void append(T element) => appendAll([element]);

  void appendAll(Iterable<T> elements) {
    _delegate.add(_AddEvent(elements, _strategy, _shortCircuit));
  }

  void prepend(T element) =>
      _delegate.add(_PrependEvent([element], _strategy, _shortCircuit));

  void prependAll(Iterable<T> elements) =>
      _delegate.add(_PrependEvent(elements, _strategy, _shortCircuit));

  void removeSingle(Predicate<T> predicate, [MetadataPatch<T>? patch]) {
    _delegate.add(_RemoveEvent(predicate, patch));
  }

  @override
  PageState<T, Q> currentState() => _delegate.currentState();

  @override
  Stream<PageState<T, Q>> state() => _delegate.state();

  @override
  void release() => _delegate.release();

  final MutableBloc<PageState<T, Q>> _delegate;
  final PagedGateway<T, Q> _gateway;
  final int _pageSize;
  final ElementComparisonStrategy<T> _strategy;
  final ShortCircuitStrategy<T> _shortCircuit;
}

typedef Page<T> = (Iterable<T>, Map<String, Object?>?);

abstract interface class PagedGateway<T, Q> {
  Future<Page<T>> get(Query<Q> query);
}

abstract class NoMetadataPagedGateway<T, Q> implements PagedGateway<T, Q> {
  const NoMetadataPagedGateway();

  @override
  Future<Page<T>> get(Query<Q> query) {
    return getElements(query).then((e) => (e, null));
  }

  Future<Iterable<T>> getElements(Query<Q> query);
}

sealed class PageState<T, Q> {
  const PageState();

  R visit<R>(PageStateVisitor<T, Q, R> visitor);

  BuiltList<T>? get current;
  BuiltMap<String, Object?>? get metadata;
  Query<Q> get query;

  PageState<T, Q> _fetching(Query<Q> query) =>
      transitionErrorMsg("Can't transit to fetching state from $this");

  PageState<T, Q> _fetched(
    Query<Q> query,
    Iterable<T> elements,
    Map<String, Object?>? metadata,
    ElementComparisonStrategy<T> strategy,
    ShortCircuitStrategy<T> shortCircuit,
  ) {
    return transitionErrorMsg("Can't transit to fetched state from $this");
  }

  PageState<T, Q> _failure(Query<Q> query, Object cause) =>
      transitionErrorMsg("Can't transit to failure state from $this");

  PageState<T, Q> _append(
    Iterable<T> source,
    ElementComparisonStrategy<T> strategy,
    ShortCircuitStrategy<T> shortCircuit,
  ) {
    return transitionErrorMsg("Can't append in $this");
  }

  PageState<T, Q> _prepend(
    Iterable<T> source,
    ElementComparisonStrategy<T> strategy,
    ShortCircuitStrategy<T> shortCircuit,
  ) {
    return transitionErrorMsg("Can't prepend in $this");
  }

  PageState<T, Q> _replace(
    Transformation<T, T> map,
    Predicate<T> predicate,
  ) {
    return transitionErrorMsg("Can't replace in $this");
  }

  // False positive from the linter?
  // ignore: unused_element_parameter
  PageState<T, Q> _remove(Predicate<T> predicate, [MetadataPatch<T>? patch]) {
    return transitionErrorMsg("Can't remove in $this");
  }
}

typedef MetadataPatch<T> = Map<String, Object?>? Function(
  List<T> updated,
  BuiltMap<String, Object?>? metadata,
);

BuiltList<T> _prependList<T>(
  BuiltList<T>? current,
  Iterable<T> source,
  ElementComparisonStrategy<T> strategy,
  ShortCircuitStrategy<T> shortCircuit,
) {
  return current?.let((e) => strategy._prepend(e, source, shortCircuit)) ??
      BuiltList.of(source);
}

BuiltList<T> _appendList<T>(
  BuiltList<T>? current,
  Iterable<T> source,
  ElementComparisonStrategy<T> strategy,
  ShortCircuitStrategy<T> shortCircuit,
) {
  return current?.let((e) => strategy._append(e, source, shortCircuit)) ??
      BuiltList.of(source);
}

// BuiltList<T> _prependElement<T>(
//   BuiltList<T>? current,
//   T source,
//   ElementComparisonStrategy<T> strategy,
// ) {
//   if (current == null) {
//     return BuiltList.of([source]);
//   } else {
//  final index = current.indexWhere((e) => strategy.isSameIdentity(e, source));
//     if (index == -1) {
//       return BuiltList.of(current.toList()..insert(0, source));
//     } else {
//       final newerRevision = strategy.defineNewer(current[index], source);
//       return BuiltList.of(current.toList()..[index] = newerRevision);
//     }
//   }
// }

BuiltList<T> _replaceElement<T>(
  BuiltList<T> source,
  Transformation<T, T> map,
  final Predicate<T> predicate,
) {
  final index = source.indexWhere(predicate);
  if (index == -1) {
    return source;
  } else {
    return BuiltList(source.toList()..[index] = map(source[index]));
  }
}

(T?, BuiltList<T>) _removeElement<T>(
  BuiltList<T> source,
  final Predicate<T> predicate,
) {
  final index = source.indexWhere(predicate);
  if (index == -1) {
    return (null, source);
  } else {
    final result = source.toList();
    final element = result.removeAt(index);
    return (element, BuiltList(result));
  }
}

abstract interface class PageStateVisitor<T, Q, R> {
  R fetching(Query<Q> query);

  R failure(Query<Q> query, Object cause);

  R fetched(
    Query<Q> query,
    BuiltList<T> elements, {
    required bool hasMore,
  });
}

abstract base class AdHocPageStateVisitor<T, Q, R>
    implements PageStateVisitor<T, Q, R> {
  const AdHocPageStateVisitor(this._stub);

  AdHocPageStateVisitor.value(R value) : this(() => value);

  @override
  R fetching(Query<Q> query) => _stub();

  @override
  R failure(Query<Q> query, Object cause) => _stub();

  @override
  R fetched(
    Query<Q> query,
    BuiltList<T> elements, {
    required bool hasMore,
  }) {
    return _stub();
  }

  final Producer<R> _stub;
}

@immutable
final class FetchingState<T, Q> extends PageState<T, Q> {
  const FetchingState(this.current, this.metadata, this.query);

  @override
  R visit<R>(PageStateVisitor<T, Q, R> visitor) => visitor.fetching(query);

  @override
  PageState<T, Q> _fetching(Query<Q> query) => FetchingState(
        query == this.query ? current : null,
        query == this.query ? metadata : null,
        query,
      );

  @override
  PageState<T, Q> _fetched(
    Query<Q> query,
    Iterable<T> elements,
    Map<String, Object?>? metadata,
    ElementComparisonStrategy<T> strategy,
    ShortCircuitStrategy<T> shortCircuit,
  ) {
    final result = _appendList(current, elements, strategy, shortCircuit);
    return FetchedState(
      result,
      metadata?.build(),
      query,
      hasMore: elements.length >= query.size,
    );
  }

  @override
  PageState<T, Q> _failure(Query<Q> query, Object cause) {
    return ErrorState(current, metadata, cause, query);
  }

  @override
  PageState<T, Q> _append(
    Iterable<T> source,
    ElementComparisonStrategy<T> strategy,
    ShortCircuitStrategy<T> shortCircuit,
  ) {
    final result = _appendList(current, source, strategy, shortCircuit);
    return FetchingState(result, metadata, query);
  }

  @override
  PageState<T, Q> _prepend(
    Iterable<T> source,
    ElementComparisonStrategy<T> strategy,
    ShortCircuitStrategy<T> shortCircuit,
  ) {
    final result = _prependList(current, source, strategy, shortCircuit);
    return FetchingState(result, metadata, query);
  }

  @override
  PageState<T, Q> _replace(Transformation<T, T> map, Predicate<T> predicate) {
    final result = current?.let((e) => _replaceElement(e, map, predicate));
    return FetchingState(result, metadata, query);
  }

  @override
  PageState<T, Q> _remove(Predicate<T> predicate, [MetadataPatch<T>? patch]) {
    final current = this.current;
    if (current == null) {
      return FetchingState(current, metadata, query);
    } else {
      final (element, result) = _removeElement(current, predicate);
      return FetchingState(
        result,
        patch == null || element == null
            ? metadata
            : patch([element], metadata)?.build(),
        query,
      );
    }
  }

  @override
  final BuiltList<T>? current;
  @override
  final BuiltMap<String, Object?>? metadata;
  @override
  final Query<Q> query;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FetchingState<T, Q> &&
        other.current == current &&
        other.metadata == metadata &&
        other.query == query;
  }

  @override
  int get hashCode => current.hashCode ^ metadata.hashCode ^ query.hashCode;

  @override
  String toString() => 'FetchingState(current: $current, metadata: $metadata, '
      'query: $query, metadata: $metadata)';
}

@immutable
final class ErrorState<T, Q> extends PageState<T, Q> {
  const ErrorState(this.current, this.metadata, this.cause, this.query);

  @override
  R visit<R>(PageStateVisitor<T, Q, R> visitor) =>
      visitor.failure(query, cause);

  @override
  PageState<T, Q> _fetching(Query<Q> query) => FetchingState(
        this.query == query ? current : null,
        this.query == query ? metadata : null,
        query,
      );

  @override
  PageState<T, Q> _append(
    Iterable<T> source,
    ElementComparisonStrategy<T> strategy,
    ShortCircuitStrategy<T> shortCircuit,
  ) {
    final result = _appendList(current, source, strategy, shortCircuit);
    return ErrorState(result, metadata, cause, query);
  }

  @override
  PageState<T, Q> _prepend(
    Iterable<T> source,
    ElementComparisonStrategy<T> strategy,
    ShortCircuitStrategy<T> shortCircuit,
  ) {
    final result = _prependList(current, source, strategy, shortCircuit);
    return ErrorState(result, metadata, cause, query);
  }

  @override
  PageState<T, Q> _replace(Transformation<T, T> map, Predicate<T> predicate) {
    return ErrorState(
      current?.let((e) => _replaceElement(e, map, predicate)),
      metadata,
      cause,
      query,
    );
  }

  @override
  PageState<T, Q> _remove(Predicate<T> predicate, [MetadataPatch<T>? patch]) {
    final current = this.current;
    if (current == null) {
      return FetchingState(current, metadata, query);
    } else {
      final (element, result) = _removeElement(current, predicate);
      return ErrorState(
        result,
        patch == null || element == null
            ? metadata
            : patch([element], metadata)?.build(),
        cause,
        query,
      );
    }
  }

  @override
  PageState<T, Q> _fetched(
    Query<Q> query,
    Iterable<T> elements,
    Map<String, Object?>? metadata,
    ElementComparisonStrategy<T> strategy,
    ShortCircuitStrategy<T> shortCircuit,
  ) {
    if (query == this.query) {
      return this;
    } else {
      return this.query.start <= query.start
          ? this
          : FetchedState(
              BuiltList.of(elements),
              metadata?.build(),
              query,
              hasMore: elements.length >= query.size,
            );
    }
  }

  @override
  final BuiltList<T>? current;
  @override
  final BuiltMap<String, Object?>? metadata;
  @override
  final Query<Q> query;
  final Object cause;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ErrorState<T, Q> &&
        other.current == current &&
        other.metadata == metadata &&
        other.query == query &&
        other.cause == cause;
  }

  @override
  int get hashCode =>
      current.hashCode ^ metadata.hashCode ^ query.hashCode ^ cause.hashCode;

  @override
  String toString() => 'ErrorState(current: $current, metadata: $metadata, '
      'query: $query, cause: $cause)';
}

@immutable
final class FetchedState<T, Q> extends PageState<T, Q> {
  const FetchedState(
    this.current,
    this.metadata,
    this.query, {
    required this.hasMore,
  });

  @override
  R visit<R>(PageStateVisitor<T, Q, R> visitor) {
    return visitor.fetched(query, current, hasMore: hasMore);
  }

  @override
  PageState<T, Q> _fetching(Query<Q> query) => FetchingState(
        query.prolongs(this.query) ? current : null,
        query.prolongs(this.query) ? metadata : null,
        query,
      );

  @override
  PageState<T, Q> _append(
    Iterable<T> source,
    ElementComparisonStrategy<T> strategy,
    ShortCircuitStrategy<T> shortCircuit,
  ) {
    final result = _appendList(current, source, strategy, shortCircuit);
    return FetchedState(result, metadata, query, hasMore: hasMore);
  }

  @override
  PageState<T, Q> _prepend(
    Iterable<T> source,
    ElementComparisonStrategy<T> strategy,
    ShortCircuitStrategy<T> shortCircuit,
  ) {
    final result = _prependList(current, source, strategy, shortCircuit);
    return FetchedState(result, metadata, query, hasMore: hasMore);
  }

  @override
  PageState<T, Q> _replace(Transformation<T, T> map, Predicate<T> predicate) {
    final replaced = _replaceElement(current, map, predicate);
    return FetchedState(replaced, metadata, query, hasMore: hasMore);
  }

  @override
  PageState<T, Q> _remove(Predicate<T> predicate, [MetadataPatch<T>? patch]) {
    final (element, result) = _removeElement(current, predicate);
    return FetchedState(
      result,
      patch == null || element == null
          ? metadata
          : patch([element], metadata)?.build(),
      query,
      hasMore: hasMore,
    );
  }

  @override
  PageState<T, Q> _fetched(
    Query<Q> query,
    Iterable<T> elements,
    Map<String, Object?>? metadata,
    ElementComparisonStrategy<T> strategy,
    ShortCircuitStrategy<T> shortCircuit,
  ) {
    if (query == this.query) {
      return this;
    } else {
      return this.query.start <= query.start
          ? this
          : FetchedState(
              BuiltList.of(elements),
              metadata?.build(),
              query,
              hasMore: elements.length >= query.size,
            );
    }
  }

  @override
  final BuiltList<T> current;
  @override
  final BuiltMap<String, Object?>? metadata;
  @override
  final Query<Q> query;
  final bool hasMore;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FetchedState<T, Q> &&
        other.current == current &&
        other.metadata == metadata &&
        other.query == query &&
        other.hasMore == hasMore;
  }

  @override
  int get hashCode =>
      current.hashCode ^ metadata.hashCode ^ query.hashCode ^ hasMore.hashCode;

  @override
  String toString() => 'FetchedState(current: $current, metadata: $metadata, '
      'query: $query, hasMore: $hasMore)';
}

class _PageEvent<T, Q> implements Event<PageState<T, Q>> {
  const _PageEvent(
    this._pageSize,
    this._gateway,
    this._strategy,
    this._shortCircuit,
  );

  @override
  Stream<PageState<T, Q>> fold(Producer<PageState<T, Q>> state) async* {
    final current = state();
    if (!current.visit(FetchedAndHasMore())) return;
    final query = current.visit(_ResolveNextQuery(_pageSize));
    yield* _QueryEvent<T, Q>(query, _gateway, _strategy, _shortCircuit)
        .fold(state);
  }

  final int _pageSize;
  final PagedGateway<T, Q> _gateway;
  final ElementComparisonStrategy<T> _strategy;
  final ShortCircuitStrategy<T> _shortCircuit;
}

class _RetryEvent<T, Q> implements Event<PageState<T, Q>> {
  const _RetryEvent(this._gateway, this._strategy, this._shortCircuit);

  @override
  Stream<PageState<T, Q>> fold(Producer<PageState<T, Q>> state) async* {
    final query = state().visit(_ResolveFailedQuery());
    yield* _QueryEvent(query, _gateway, _strategy, _shortCircuit).fold(state);
  }

  final PagedGateway<T, Q> _gateway;
  final ElementComparisonStrategy<T> _strategy;
  final ShortCircuitStrategy<T> _shortCircuit;
}

class _QueryEvent<T, Q> implements Event<PageState<T, Q>> {
  const _QueryEvent(
    this._query,
    this._gateway,
    this._strategy,
    this._shortCircuit,
  );

  @override
  Stream<PageState<T, Q>> fold(Producer<PageState<T, Q>> state) async* {
    yield state()._fetching(_query);
    try {
      final (elements, metadata) = await _gateway.get(_query);
      yield state()
          ._fetched(_query, elements, metadata, _strategy, _shortCircuit);
    } on Object catch (e) {
      yield state()._failure(_query, e);
    }
  }

  final Query<Q> _query;
  final PagedGateway<T, Q> _gateway;
  final ElementComparisonStrategy<T> _strategy;
  final ShortCircuitStrategy<T> _shortCircuit;
}

@immutable
class _ReplaceEvent<T, Q> implements Event<PageState<T, Q>> {
  const _ReplaceEvent(this._map, this._predicate);

  @override
  Stream<PageState<T, Q>> fold(Producer<PageState<T, Q>> state) async* {
    yield state()._replace(_map, _predicate);
  }

  final Transformation<T, T> _map;
  final Predicate<T> _predicate;
}

final class _ResolveFailedQuery<T, Q>
    extends AdHocPageStateVisitor<T, Q, Query<Q>> {
  _ResolveFailedQuery() : super(() => throw StateError('Unexpected state'));

  @override
  Query<Q> failure(Query<Q> query, Object cause) => query;
}

@immutable
class _AddEvent<T, Q> implements Event<PageState<T, Q>> {
  const _AddEvent(this._input, this._strategy, this._shortCircuit);

  @override
  Stream<PageState<T, Q>> fold(Producer<PageState<T, Q>> state) async* {
    yield state()._append(_input, _strategy, _shortCircuit);
  }

  final Iterable<T> _input;
  final ElementComparisonStrategy<T> _strategy;
  final ShortCircuitStrategy<T> _shortCircuit;
}

@immutable
class _PrependEvent<T, Q> implements Event<PageState<T, Q>> {
  const _PrependEvent(this._source, this._strategy, this._shortCircuit);

  @override
  Stream<PageState<T, Q>> fold(Producer<PageState<T, Q>> state) async* {
    yield state()._prepend(_source, _strategy, _shortCircuit);
  }

  final Iterable<T> _source;
  final ElementComparisonStrategy<T> _strategy;
  final ShortCircuitStrategy<T> _shortCircuit;
}

@immutable
class _RemoveEvent<T, Q> implements Event<PageState<T, Q>> {
  const _RemoveEvent(this._predicate, this._patch);

  @override
  Stream<PageState<T, Q>> fold(Producer<PageState<T, Q>> state) async* {
    yield state()._remove(_predicate, _patch);
  }

  final Predicate<T> _predicate;
  final MetadataPatch<T>? _patch;
}

extension _ListApplication<T> on ElementComparisonStrategy<T> {
  BuiltList<T> _prepend(
    BuiltList<T> source,
    Iterable<T> input,
    ShortCircuitStrategy<T> strategy,
  ) {
    if (input.isEmpty) return source;
    final element = input.last;
    final identityIndex = source.indexWhere((e) => isSameIdentity(e, element));
    final builtInput = BuiltList.of(input);
    if (identityIndex == -1) {
      return builtInput + source;
    } else {
      final head = <T>[];
      var shortCircuited = false;
      for (int i = identityIndex; i >= 0; i--) {
        final current = source[i];
        final update = builtInput[builtInput.length - 1 + i - identityIndex];
        if (isSameIdentity(current, update)) {
          head.insert(0, defineNewer(current, update));
        } else {
          final currentHead = source.sublist(0, i);
          final inputHead = builtInput
              .toList()
              .sublist(0, builtInput.length - 1 + i - identityIndex);
          final newHead = strategy.prepend(
            strategy: this,
            current: source,
            input: input,
            currentHead: currentHead,
            inputHead: inputHead,
          );
          head.insertAll(0, newHead);
          shortCircuited = true;
          break;
        }
      }
      if (!shortCircuited && builtInput.length > identityIndex + 1) {
        head.insertAll(
          0,
          builtInput.sublist(0, builtInput.length - head.length),
        );
      }
      final result = source.toList().sublist(identityIndex + 1)
        ..insertAll(0, head);
      return BuiltList.of(result);
    }
  }

  BuiltList<T> _append(
    BuiltList<T> source,
    Iterable<T> input,
    ShortCircuitStrategy<T> strategy,
  ) {
    if (input.isEmpty) return source;
    final element = input.first;
    final identityIndex = source.indexWhere((e) => isSameIdentity(e, element));
    final builtInput = BuiltList.of(input);
    final remainder = source.length - identityIndex;
    if (identityIndex == -1) {
      return source + builtInput;
    } else {
      final tail = <T>[];
      var shortCircuited = false;
      for (int i = 0; i < remainder; i++) {
        final current = source[identityIndex + i];
        final update = builtInput[i];
        if (isSameIdentity(current, update)) {
          tail.add(defineNewer(current, update));
        } else {
          final currentTail = source.sublist(identityIndex + i);
          final inputTail = builtInput.toList().sublist(i);
          final newTail = strategy.append(
            strategy: this,
            current: source,
            input: input,
            currentTail: currentTail,
            inputTail: inputTail,
          );
          tail.addAll(newTail);
          shortCircuited = true;
          break;
        }
      }
      if (!shortCircuited && builtInput.length > remainder) {
        tail.addAll(builtInput.sublist(remainder));
      }
      final result = source.toList().sublist(0, identityIndex)..addAll(tail);
      return BuiltList.of(result);
    }
  }
}

final class _ResolveNextQuery<T, Q>
    extends AdHocPageStateVisitor<T, Q, Query<Q>> {
  _ResolveNextQuery(this._pageSize)
      : super(() => throw StateError('Invalid state'));

  @override
  Query<Q> fetched(
    Query<Q> query,
    BuiltList<T> elements, {
    required bool hasMore,
  }) {
    assert(hasMore, 'Query does not have more elements.');
    return Query<Q>(
      value: query.value,
      start: elements.length,
      size: _pageSize,
    );
  }

  final int _pageSize;
}

final class FetchedAndHasMore<T, Q> extends AdHocPageStateVisitor<T, Q, bool> {
  FetchedAndHasMore() : super.value(false);

  @override
  bool fetched(
    Query<Q> query,
    BuiltList<T> elements, {
    required bool hasMore,
  }) {
    return hasMore;
  }
}
