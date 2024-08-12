import 'package:built_collection/built_collection.dart';
import 'package:flutter_estd/bloc/bloc.dart';
import 'package:flutter_estd/bloc/state.dart';
import 'package:flutter_estd/estd/functional/std.dart';
import 'package:flutter_estd/estd/query.dart';

class PagedBloc<T, Q> implements Bloc<PageState<T, Q>> {
  PagedBloc(
    this._gateway,
    Query<Q> firstQuery, {
    bool prefetch = true,
  }) : _delegate = StreamTransformerBloc.electLast(
          initialState: prefetch
              ? FetchingState(firstQuery)
              : FetchedState(BuiltList(), firstQuery),
          initialEvent: prefetch ? _QueryEvent(firstQuery, _gateway) : null,
        );

  void query(Query<Q> query) => _delegate.add(_QueryEvent(query, _gateway));

  void retry() => _delegate.add(_RetryEvent(_gateway));

  void page() {
    if (currentState().visit(HasMore())) _delegate.add(_PageEvent(_gateway));
  }

  void replace(T element, Predicate<T> predicate) {
    if (currentState().visit(IsIdleFetched())) {
      _delegate.add(_ReplaceEvent(element, predicate));
    }
  }

  @override
  PageState<T, Q> currentState() => _delegate.currentState();

  @override
  Stream<PageState<T, Q>> state() => _delegate.state();

  @override
  void release() => _delegate.release();

  final MutableBloc<PageState<T, Q>> _delegate;
  final PagedGateway<T, Q> _gateway;
}

abstract interface class PagedGateway<T, Q> {
  Future<BuiltList<T>> get(Query<Q> query);
}

sealed class PageState<T, Q> {
  const PageState();

  R visit<R>(PageStateVisitor<T, Q, R> visitor);

  PageState<T, Q> _fetching(Query<Q> query) =>
      transitionErrorMsg("Can't transit to fetching state from $this");

  PageState<T, Q> _fetched(BuiltList<T> entities) =>
      transitionErrorMsg("Can't transit to fetched state from $this");

  PageState<T, Q> _failure(Object cause) =>
      transitionErrorMsg("Can't transit to failure state from $this");
}

abstract interface class PageStateVisitor<T, Q, R> {
  R fetching(Query<Q> query);

  R failure(Query<Q> query, Object cause);

  R fetched(
    Query<Q> query,
    BuiltList<T> entities, {
    required bool hasMore,
  });

  R additiveFetching(Query<Q> query, BuiltList<T> current);

  R additiveFetchFailure(
    Query<Q> query,
    BuiltList<T> current,
    Object cause,
  );
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
    BuiltList<T> entities, {
    required bool hasMore,
  }) =>
      _stub();

  @override
  R additiveFetching(Query<Q> query, BuiltList<T> current) => _stub();

  @override
  R additiveFetchFailure(
    Query<Q> query,
    BuiltList<T> current,
    Object cause,
  ) =>
      _stub();

  final Producer<R> _stub;
}

final class FetchingState<T, Q> extends PageState<T, Q> {
  const FetchingState(this.query);

  @override
  R visit<R>(PageStateVisitor<T, Q, R> visitor) => visitor.fetching(query);

  @override
  PageState<T, Q> _fetching(Query<Q> query) => FetchingState(query);

  @override
  PageState<T, Q> _fetched(BuiltList<T> entities) =>
      FetchedState(entities, query);

  @override
  PageState<T, Q> _failure(Object cause) => ErrorState(cause, query);

  final Query<Q> query;
}

final class ErrorState<T, Q> extends PageState<T, Q> {
  const ErrorState(this.cause, this.query);

  @override
  R visit<R>(PageStateVisitor<T, Q, R> visitor) =>
      visitor.failure(query, cause);

  @override
  PageState<T, Q> _fetching(Query<Q> query) => FetchingState(query);

  final Query<Q> query;
  final Object cause;
}

final class FetchedState<T, Q> extends PageState<T, Q> {
  const FetchedState(this.entities, this.query);

  @override
  R visit<R>(PageStateVisitor<T, Q, R> visitor) =>
      visitor.fetched(query, entities, hasMore: hasMore);

  @override
  PageState<T, Q> _fetching(Query<Q> query) => query.isNextPageFor(this.query)
      ? AdditiveFetchingState(entities, query)
      : FetchingState(query);

  final BuiltList<T> entities;
  final Query<Q> query;
  bool get hasMore => query.start + query.size == entities.length;
}

final class AdditiveFetchingState<T, Q> extends PageState<T, Q> {
  const AdditiveFetchingState(this.entities, this.query);

  @override
  R visit<R>(PageStateVisitor<T, Q, R> visitor) =>
      visitor.additiveFetching(query, entities);

  @override
  PageState<T, Q> _fetching(Query<Q> query) => FetchingState(query);

  @override
  PageState<T, Q> _fetched(BuiltList<T> entities) =>
      FetchedState(this.entities + entities, query);

  @override
  PageState<T, Q> _failure(Object cause) =>
      AdditiveFetchErrorState(entities, cause, query);

  final BuiltList<T> entities;
  final Query<Q> query;
}

final class AdditiveFetchErrorState<T, Q> extends PageState<T, Q> {
  const AdditiveFetchErrorState(this.entities, this.cause, this.query);

  @override
  R visit<R>(PageStateVisitor<T, Q, R> visitor) =>
      visitor.additiveFetchFailure(query, entities, cause);

  @override
  PageState<T, Q> _fetching(Query<Q> query) {
    if (query == this.query) {
      return AdditiveFetchingState(entities, query);
    } else {
      return FetchingState(query);
    }
  }

  final BuiltList<T> entities;
  final Object cause;
  final Query<Q> query;
}

class _PageEvent<T, Q> implements Event<PageState<T, Q>> {
  const _PageEvent(this._gateway);

  @override
  Stream<PageState<T, Q>> fold(Producer<PageState<T, Q>> state) async* {
    final current = state();
    final query = current.visit(_ResolveNextQuery());
    yield* _QueryEvent<T, Q>(query, _gateway).fold(state);
  }

  final PagedGateway<T, Q> _gateway;
}

class _RetryEvent<T, Q> implements Event<PageState<T, Q>> {
  const _RetryEvent(this._gateway);

  @override
  Stream<PageState<T, Q>> fold(Producer<PageState<T, Q>> state) async* {
    final query = state().visit(_ResolveFailedQuery());
    yield* _QueryEvent(query, _gateway).fold(state);
  }

  final PagedGateway<T, Q> _gateway;
}

class _QueryEvent<T, Q> implements Event<PageState<T, Q>> {
  const _QueryEvent(this._query, this._gateway);

  @override
  Stream<PageState<T, Q>> fold(Producer<PageState<T, Q>> state) async* {
    yield state()._fetching(_query);
    try {
      final entities = await _gateway.get(_query);
      yield state()._fetched(entities);
    } on Object catch (e) {
      yield state()._failure(e);
    }
  }

  final Query<Q> _query;
  final PagedGateway<T, Q> _gateway;
}

class _ReplaceEvent<T, Q> implements Event<PageState<T, Q>> {
  const _ReplaceEvent(this._element, this._predicate);

  @override
  Stream<PageState<T, Q>> fold(Producer<PageState<T, Q>> state) async* {
    // Decided not to add the method to the interface, as it's a completely
    // state-transitional one without the thing
    final result = switch (state()) {
      FetchedState(entities: var _entities, query: var _query) =>
        FetchedState(_replace(_entities), _query),
      AdditiveFetchErrorState(
        entities: var _entities,
        cause: var _cause,
        query: var _query
      ) =>
        AdditiveFetchErrorState(_replace(_entities), _cause, _query),
      _ => null,
    };
    if (result != null) yield result;
  }

  BuiltList<T> _replace(BuiltList<T> source) {
    final index = source.indexWhere(_predicate);
    if (index == -1) {
      return source;
    } else {
      return BuiltList(source.toList()..[index] = _element);
    }
  }

  final T _element;
  final Predicate<T> _predicate;
}

final class _ResolveFailedQuery<T, Q>
    extends AdHocPageStateVisitor<T, Q, Query<Q>> {
  _ResolveFailedQuery() : super(() => throw StateError('Unexpected state'));

  @override
  Query<Q> failure(Query<Q> query, Object cause) => query;

  @override
  Query<Q> additiveFetchFailure(
    Query<Q> query,
    BuiltList<T> current,
    Object cause,
  ) {
    return query;
  }
}

final class _ResolveNextQuery<T, Q>
    extends AdHocPageStateVisitor<T, Q, Query<Q>> {
  _ResolveNextQuery() : super(() => throw StateError('Invalid state'));

  @override
  Query<Q> fetched(
    Query<Q> query,
    BuiltList<T> entities, {
    required bool hasMore,
  }) {
    assert(hasMore, "Query does not have more elements.");
    return Query<Q>(value: query.value, start: entities.length);
  }
}

final class HasMore<T, Q> extends AdHocPageStateVisitor<T, Q, bool> {
  HasMore() : super.value(false);

  @override
  bool fetched(
    Query<Q> query,
    BuiltList<T> entities, {
    required bool hasMore,
  }) {
    return hasMore;
  }
}

final class IsIdleFetched<T, Q> extends AdHocPageStateVisitor<T, Q, bool> {
  IsIdleFetched() : super.value(false);

  @override
  bool fetched(Query<Q> query, BuiltList<T> entities, {required bool hasMore}) {
    return true;
  }

  @override
  bool additiveFetchFailure(
    Query<Q> query,
    BuiltList<T> current,
    Object cause,
  ) {
    return true;
  }
}
