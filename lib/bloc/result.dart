import 'package:flutter_estd/bloc/bloc.dart';
import 'package:flutter_estd/bloc/state.dart';
import 'package:flutter_estd/estd/functional/std.dart';
import 'package:meta/meta.dart';

class ResultBloc<T, R> implements Bloc<ResultState<T, R>> {
  ResultBloc()
      : _delegate = StreamTransformerBloc.ordered(
          initialState: IdleState<T, R>(),
        );

  void run(Supplier<R> supplier, [T? argument]) =>
      _delegate.add(_Run(argument, supplier));

  void onErrorProcessed() => _delegate.add(_RevertToIdle<T, R>());

  void onSuccessProcessed() => _delegate.add(_RevertToIdle<T, R>());

  @override
  Stream<ResultState<T, R>> state() => _delegate.state();

  @override
  ResultState<T, R> currentState() => _delegate.currentState();

  @override
  void release() => _delegate.release();

  final MutableBloc<ResultState<T, R>> _delegate;
}

abstract interface class Supplier<T> {
  Future<T> run();
}

@immutable
class LambdaSupplier<T> implements Supplier<T> {
  const LambdaSupplier(this._function);

  @override
  Future<T> run() => _function();

  final Future<T> Function() _function;
}

sealed class ResultState<T, R> {
  const ResultState();
  U visit<U>(OperationStateVisitor<T, R, U> visitor);
  ResultState<T, R> _idle() => transitionError(IdleState);
  ResultState<T, R> _processing(T? argument) =>
      transitionError(ProcessingState);
  ResultState<T, R> _error(Object cause) => transitionError(ErrorState);
  ResultState<T, R> _success(R result) => transitionError(SuccessState);
}

@immutable
class IdleState<T, R> extends ResultState<T, R> {
  const IdleState();

  @override
  U visit<U>(OperationStateVisitor<T, R, U> visitor) => visitor.idle();

  @override
  ResultState<T, R> _processing(T? argument) => ProcessingState<T, R>(argument);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IdleState;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'IdleState()';
}

@immutable
class ProcessingState<T, R> extends ResultState<T, R> {
  const ProcessingState([this.argument]);

  @override
  U visit<U>(OperationStateVisitor<T, R, U> visitor) =>
      visitor.processing(argument);

  @override
  ResultState<T, R> _success(R result) => SuccessState(result, argument);

  @override
  ResultState<T, R> _error(Object cause) => ErrorState(cause, argument);

  final T? argument;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProcessingState<T, R> && other.argument == argument;
  }

  @override
  int get hashCode => argument.hashCode;

  @override
  String toString() => 'ProcessingState(argument: $argument)';
}

@immutable
class SuccessState<T, R> extends ResultState<T, R> {
  const SuccessState(this.result, [this.argument]);

  @override
  U visit<U>(OperationStateVisitor<T, R, U> visitor) =>
      visitor.success(result, argument);

  @override
  ResultState<T, R> _idle() => IdleState<T, R>();

  @override
  ResultState<T, R> _processing(T? argument) => ProcessingState<T, R>(argument);

  final R result;
  final T? argument;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SuccessState<T, R> &&
        other.result == result &&
        other.argument == argument;
  }

  @override
  int get hashCode => result.hashCode ^ argument.hashCode;

  @override
  String toString() => 'SuccessState(result: $result, argument: $argument)';
}

@immutable
class ErrorState<T, R> extends ResultState<T, R> {
  const ErrorState(this.cause, [this.argument]);

  @override
  U visit<U>(OperationStateVisitor<T, R, U> visitor) =>
      visitor.error(cause, argument);

  @override
  ResultState<T, R> _idle() => IdleState<T, R>();

  @override
  ResultState<T, R> _processing(T? argument) => ProcessingState<T, R>(argument);

  final Object cause;
  final T? argument;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ErrorState &&
        other.cause == cause &&
        other.argument == argument;
  }

  @override
  int get hashCode => cause.hashCode ^ argument.hashCode;

  @override
  String toString() => 'ErrorState(cause: $cause, argument: $argument)';
}

abstract interface class OperationStateVisitor<T, R, U> {
  U idle();
  U processing([T? argument]);
  U success(R result, [T? argument]);
  U error(Object cause, [T? argument]);
}

class _Run<T, R> implements Event<ResultState<T, R>> {
  const _Run(this._argument, this._operation);

  @override
  Stream<ResultState<T, R>> fold(
    Producer<ResultState<T, R>> currentState,
  ) async* {
    yield currentState()._processing(_argument);
    try {
      yield currentState()._success(await _operation.run());
    } on Object catch (e) {
      yield currentState()._error(e);
    }
  }

  final T? _argument;
  final Supplier<R> _operation;
}

class _RevertToIdle<T, R> implements Event<ResultState<T, R>> {
  const _RevertToIdle();

  @override
  Stream<ResultState<T, R>> fold(
    Producer<ResultState<T, R>> currentState,
  ) async* {
    yield currentState()._idle();
  }
}
