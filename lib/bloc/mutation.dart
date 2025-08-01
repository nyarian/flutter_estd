import 'package:flutter_estd/bloc/bloc.dart';
import 'package:flutter_estd/bloc/state.dart';
import 'package:flutter_estd/estd/functional/std.dart';
import 'package:meta/meta.dart';

class MutationBloc<T> implements Bloc<MutationState<T>> {
  MutationBloc(FetchGateway<T> gateway)
      : _delegate = StreamTransformerBloc.ordered(
          initialState: FetchingState(),
          initialEvent: _FetchEvent(gateway),
        );

  void fetch(FetchGateway<T> gateway) => _delegate.add(_FetchEvent(gateway));

  void mutate(MutateGateway<T> gateway) => _delegate.add(_MutateEvent(gateway));

  void patch(Transformation<T, T> patch) => _delegate.add(_PatchEvent(patch));

  void clearError({bool isSafe = false}) {
    _delegate.add(_ClearErrorEvent(isSafe: isSafe));
  }

  @override
  MutationState<T> currentState() => _delegate.currentState();

  @override
  Stream<MutationState<T>> state() => _delegate.state();

  @override
  void release() => _delegate.release();

  final MutableBloc<MutationState<T>> _delegate;
}

abstract interface class FetchGateway<T> {
  factory FetchGateway.run(Producer<Future<T>> producer) = LambdaFetchGateway;

  Future<T> fetch(T? current);
}

class LambdaFetchGateway<T> implements FetchGateway<T> {
  const LambdaFetchGateway(this._producer);

  @override
  Future<T> fetch(T? current) => _producer();

  final Producer<Future<T>> _producer;
}

abstract interface class MutateGateway<T> {
  factory MutateGateway.run(Transformation<T, Future<T>> producer) =
      LambdaMutateGateway;

  Future<T> mutate(T subject);
}

class LambdaMutateGateway<T> implements MutateGateway<T> {
  const LambdaMutateGateway(this._producer);

  @override
  Future<T> mutate(T subject) => _producer(subject);

  final Transformation<T, Future<T>> _producer;
}

sealed class MutationState<T> {
  R visit<R>(MutationStateVisitor<T, R> visitor);

  MutationState<T> _fetching() => transitionError(FetchingState);

  MutationState<T> _fetched(T result) => transitionError(FetchedState);

  MutationState<T> _fetchError(Object cause) =>
      transitionError(FetchErrorState);

  MutatingState<T> _mutating() => transitionError(MutatingState);

  MutationState<T> _mutated(T result) => transitionError(MutatedState);

  // This function is used to "seamlessly patch" an object which is useful
  // for certain scenarios, so returning `this` is a sensible default for most
  // states.
  // ignore: avoid_returning_this
  MutationState<T> _patch(Transformation<T, T> transformation) => this;

  // False lint positive: it is used in the override.
  // ignore: unused_element_parameter
  MutationState<T> _mutationError(Object cause, [T? partial]) =>
      transitionError(MutationErrorState);

  MutationState<T> _clearError({required bool isSafe}) =>
      transitionErrorMsg("Can't clear error for $this");

  T? get currentOrNull;
}

abstract interface class MutationStateVisitor<T, R> {
  R fetching(T? current);

  R fetched(T result);

  R fetchError(Object cause, T? current);

  R mutating(T current);

  R mutated(T result);

  R mutationError(Object cause, T current);
}

abstract base class AdHocMutationStateVisitor<T, R>
    implements MutationStateVisitor<T, R> {
  const AdHocMutationStateVisitor(this._stub);

  AdHocMutationStateVisitor.value(R value) : _stub = (() => value);

  @override
  R fetching(T? current) => _stub();

  @override
  R fetched(T result) => _stub();

  @override
  R fetchError(Object cause, T? current) => _stub();

  @override
  R mutating(T current) => _stub();

  @override
  R mutated(T result) => _stub();

  @override
  R mutationError(Object cause, T current) => _stub();

  final Producer<R> _stub;
}

final class PartialMutationException<T> implements Exception {
  const PartialMutationException(
    this.partialResult,
    this.cause, [
    this.message,
  ]);

  final T partialResult;
  final Object cause;
  final String? message;

  @override
  String toString() => 'PartialMutationException(partialResult: '
      '$partialResult, message: $message, cause: $cause)';
}

@immutable
class FetchingState<T> extends MutationState<T> {
  FetchingState([this.current]);

  @override
  R visit<R>(MutationStateVisitor<T, R> visitor) => visitor.fetching(current);

  @override
  MutationState<T> _fetching() => this;

  @override
  MutationState<T> _fetched(T result) => FetchedState(result);

  @override
  MutationState<T> _fetchError(Object cause) => FetchErrorState(current, cause);

  @override
  MutationState<T> _clearError({required bool isSafe}) {
    return isSafe ? this : super._clearError(isSafe: isSafe);
  }

  final T? current;
  @override
  T? get currentOrNull => current;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FetchingState<T> && other.current == current;
  }

  @override
  int get hashCode => current.hashCode;

  @override
  String toString() => 'FetchingState(_current: $current)';
}

@immutable
class FetchedState<T> extends MutationState<T> {
  FetchedState(this.result);

  @override
  R visit<R>(MutationStateVisitor<T, R> visitor) => visitor.fetched(result);

  @override
  MutationState<T> _fetching() => FetchingState(result);

  @override
  MutationState<T> _patch(Transformation<T, T> transformation) {
    return FetchedState(transformation(result));
  }

  @override
  MutatingState<T> _mutating() => MutatingState(result);

  @override
  MutationState<T> _clearError({required bool isSafe}) {
    return isSafe ? this : super._clearError(isSafe: isSafe);
  }

  final T result;
  @override
  T? get currentOrNull => result;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FetchedState<T> && other.result == result;
  }

  @override
  int get hashCode => result.hashCode;

  @override
  String toString() => 'FetchedState(result: $result)';
}

@immutable
class FetchErrorState<T> extends MutationState<T> {
  FetchErrorState(this.current, this.cause);

  @override
  MutationState<T> _fetching() => FetchingState(current);

  @override
  MutationState<T> _clearError({required bool isSafe}) {
    if (current == null) {
      if (isSafe) return this;
      throw StateError(
        "Can't clear an error for a state without the fallback: $this",
      );
    } else {
      return FetchedState(current!);
    }
  }

  @override
  R visit<R>(MutationStateVisitor<T, R> visitor) =>
      visitor.fetchError(cause, current);

  final T? current;
  final Object cause;
  @override
  T? get currentOrNull => current;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FetchErrorState<T> &&
        other.current == current &&
        other.cause == cause;
  }

  @override
  int get hashCode => current.hashCode ^ cause.hashCode;

  @override
  String toString() => 'FetchErrorState(current: $current, cause: $cause)';
}

@immutable
class MutatingState<T> extends MutationState<T> {
  MutatingState(this.current);

  @override
  R visit<R>(MutationStateVisitor<T, R> visitor) => visitor.mutating(current);

  @override
  MutationState<T> _mutated(T result) => MutatedState(result);

  @override
  MutationState<T> _patch(Transformation<T, T> transformation) {
    return MutatingState(transformation(current));
  }

  @override
  MutationState<T> _mutationError(Object cause, [T? partial]) =>
      MutationErrorState(partial ?? current, cause);

  @override
  MutationState<T> _clearError({required bool isSafe}) {
    return isSafe ? this : super._clearError(isSafe: isSafe);
  }

  final T current;
  @override
  T? get currentOrNull => current;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MutatingState<T> && other.current == current;
  }

  @override
  int get hashCode => current.hashCode;

  @override
  String toString() => 'MutatingState(current: $current)';
}

@immutable
class MutatedState<T> extends MutationState<T> {
  MutatedState(this.result);

  @override
  R visit<R>(MutationStateVisitor<T, R> visitor) => visitor.mutated(result);

  @override
  MutationState<T> _fetching() => FetchingState(result);

  @override
  MutatingState<T> _mutating() => MutatingState(result);

  @override
  MutationState<T> _patch(Transformation<T, T> transformation) {
    return MutatedState(transformation(result));
  }

  @override
  MutationState<T> _clearError({required bool isSafe}) {
    return isSafe ? this : super._clearError(isSafe: isSafe);
  }

  final T result;
  @override
  T? get currentOrNull => result;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MutatedState<T> && other.result == result;
  }

  @override
  int get hashCode => result.hashCode;

  @override
  String toString() => 'MutatedState(result: $result)';
}

@immutable
class MutationErrorState<T> extends MutationState<T> {
  MutationErrorState(this.current, this.cause);

  @override
  R visit<R>(MutationStateVisitor<T, R> visitor) =>
      visitor.mutationError(cause, current);

  @override
  MutationState<T> _patch(Transformation<T, T> transformation) {
    return MutationErrorState(transformation(current), cause);
  }

  @override
  MutationState<T> _clearError({required bool isSafe}) => MutatedState(current);

  final T current;
  final Object cause;
  @override
  T? get currentOrNull => current;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MutationErrorState<T> &&
        other.current == current &&
        other.cause == cause;
  }

  @override
  int get hashCode => current.hashCode ^ cause.hashCode;

  @override
  String toString() => 'MutationErrorState(current: $current, cause: $cause)';
}

@immutable
sealed class SimplifiedMutationState<T> {
  const SimplifiedMutationState();

  factory SimplifiedMutationState.from(MutationState<T> state) {
    return switch (state) {
      FetchingState<T>() => SimplifiedProcessingState<T>(null),
      MutatingState<T>(:var current) => SimplifiedProcessingState<T>(current),
      FetchErrorState<T>(:var cause) => SimplifiedErrorState<T>(cause, null),
      MutationErrorState<T>(:var cause, :var current) =>
        SimplifiedErrorState<T>(cause, current),
      FetchedState<T>(:var result) ||
      MutatedState<T>(:var result) =>
        SimplifiedResultState(result),
    };
  }

  R visit<R>(SimplifiedMutationStateVisitor<T, R> visitor);
}

@immutable
class SimplifiedProcessingState<T> implements SimplifiedMutationState<T> {
  const SimplifiedProcessingState(this.current);

  @override
  R visit<R>(SimplifiedMutationStateVisitor<T, R> visitor) {
    return visitor.processing(current);
  }

  final T? current;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SimplifiedProcessingState<T> && other.current == current;
  }

  @override
  int get hashCode => current.hashCode;

  @override
  String toString() => 'SimplifiedProcessingState(current: $current)';
}

@immutable
class SimplifiedErrorState<T> implements SimplifiedMutationState<T> {
  const SimplifiedErrorState(this.cause, this.current);

  @override
  R visit<R>(SimplifiedMutationStateVisitor<T, R> visitor) {
    return visitor.error(cause, current);
  }

  final Object cause;
  final T? current;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SimplifiedErrorState<T> &&
        other.cause == cause &&
        other.current == current;
  }

  @override
  int get hashCode => cause.hashCode ^ current.hashCode;

  @override
  String toString() => 'SimplifiedErrorState(cause: $cause, current: $current)';
}

@immutable
class SimplifiedResultState<T> implements SimplifiedMutationState<T> {
  const SimplifiedResultState(this.result);

  @override
  R visit<R>(SimplifiedMutationStateVisitor<T, R> visitor) {
    return visitor.result(result);
  }

  final T result;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SimplifiedResultState<T> && other.result == result;
  }

  @override
  int get hashCode => result.hashCode;

  @override
  String toString() => 'SimplifiedSuccessState(result: $result)';
}

extension StreamStateSimplificationExtension<T> on Stream<MutationState<T>> {
  Stream<SimplifiedMutationState<T>> simplified() {
    return map(SimplifiedMutationState.from);
  }
}

extension StateSimplificationExtension<T> on MutationState<T> {
  SimplifiedMutationState<T> toSimplified() {
    return SimplifiedMutationState.from(this);
  }
}

abstract interface class SimplifiedMutationStateVisitor<T, R> {
  R processing(T? current);

  R result(T result);

  R error(Object cause, T? current);
}

extension SimplifiedVisitorExtension<T> on MutationState<T> {
  R simpleVisit<R>(SimplifiedMutationStateVisitor<T, R> visitor) =>
      visit(_SimplifiedMutationStateVisitorAdapter(visitor));
}

class _SimplifiedMutationStateVisitorAdapter<T, R>
    implements MutationStateVisitor<T, R> {
  _SimplifiedMutationStateVisitorAdapter(this._delegate);

  @override
  R fetching(T? current) => _delegate.processing(current);

  @override
  R fetched(T result) => _delegate.result(result);

  @override
  R fetchError(Object cause, T? current) => _delegate.error(cause, current);

  @override
  R mutating(T current) => _delegate.processing(current);

  @override
  R mutated(T result) => _delegate.result(result);

  @override
  R mutationError(Object cause, T current) => _delegate.error(cause, current);

  final SimplifiedMutationStateVisitor<T, R> _delegate;
}

@immutable
class _FetchEvent<T> implements Event<MutationState<T>> {
  const _FetchEvent(this._gateway);

  @override
  Stream<MutationState<T>> fold(Producer<MutationState<T>> state) async* {
    yield state()._fetching();
    try {
      final result = await _gateway.fetch(switch (state()) {
        FetchingState(:var current) || FetchErrorState(:var current) => current,
        FetchedState(result: var current) ||
        MutatingState(:var current) ||
        MutatedState(result: var current) ||
        MutationErrorState(:var current) =>
          current,
      });
      yield state()._fetched(result);
    } on Object catch (e) {
      yield state()._fetchError(e);
    }
  }

  final FetchGateway<T> _gateway;
}

class _MutateEvent<T> implements Event<MutationState<T>> {
  const _MutateEvent(this._gateway);

  @override
  Stream<MutationState<T>> fold(Producer<MutationState<T>> state) async* {
    final updated = state()._mutating();
    yield updated;
    try {
      final mutated = await _gateway.mutate(updated.current);
      yield state()._mutated(mutated);
    } on PartialMutationException<T> catch (e) {
      yield state()._mutationError(e.cause, e.partialResult);
    } on Object catch (e) {
      yield state()._mutationError(e);
    }
  }

  final MutateGateway<T> _gateway;
}

class _PatchEvent<T> implements Event<MutationState<T>> {
  const _PatchEvent(this._transformation);

  @override
  Stream<MutationState<T>> fold(Producer<MutationState<T>> state) {
    return Stream.value(state()._patch(_transformation));
  }

  final Transformation<T, T> _transformation;
}

class _ClearErrorEvent<T> implements Event<MutationState<T>> {
  _ClearErrorEvent({required bool isSafe}) : _isSafe = isSafe;

  @override
  Stream<MutationState<T>> fold(Producer<MutationState<T>> state) async* {
    yield state()._clearError(isSafe: _isSafe);
  }

  final bool _isSafe;
}

final class IsMutated<T> extends AdHocMutationStateVisitor<T, bool> {
  IsMutated() : super.value(false);

  @override
  bool mutated(T result) => true;
}

final class MutatedResult<T> extends AdHocMutationStateVisitor<T, T?> {
  MutatedResult() : super.value(null);

  @override
  T? mutated(T result) => result;
}
