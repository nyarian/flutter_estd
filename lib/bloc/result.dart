import 'package:flutter_estd/bloc/bloc.dart';
import 'package:flutter_estd/bloc/state.dart';
import 'package:flutter_estd/estd/functional/std.dart';
import 'package:meta/meta.dart';

class ResultBloc<T> implements Bloc<ResultState<T>> {
  ResultBloc()
      : _delegate = StreamTransformerBloc.ordered(
          initialState: IdleState<T>(),
        );

  void run(Supplier<T> supplier) => _delegate.add(_Run(supplier));

  void onErrorProcessed() => _delegate.add(_RevertToIdle<T>());

  void onSuccessProcessed() => _delegate.add(_RevertToIdle<T>());

  @override
  Stream<ResultState<T>> state() => _delegate.state();

  @override
  ResultState<T> currentState() => _delegate.currentState();

  @override
  void release() => _delegate.release();

  final MutableBloc<ResultState<T>> _delegate;
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

sealed class ResultState<T> {
  const ResultState();
  R visit<R>(OperationStateVisitor<T, R> visitor);
  ResultState<T> _idle() => transitionError(IdleState);
  ResultState<T> _processing() => transitionError(ProcessingState);
  ResultState<T> _error(Object cause) => transitionError(ErrorState);
  ResultState<T> _success(T result) => transitionError(SuccessState);
}

@immutable
class IdleState<T> extends ResultState<T> {
  const IdleState();

  @override
  R visit<R>(OperationStateVisitor<T, R> visitor) => visitor.idle();

  @override
  ResultState<T> _processing() => ProcessingState<T>();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IdleState;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'IdleState()';
}

@immutable
class ProcessingState<T> extends ResultState<T> {
  const ProcessingState();

  @override
  R visit<R>(OperationStateVisitor<T, R> visitor) => visitor.processing();

  @override
  ResultState<T> _success(T result) => SuccessState(result);

  @override
  ResultState<T> _error(Object cause) => ErrorState(cause);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ProcessingState;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'ProcessingState()';
}

@immutable
class SuccessState<T> extends ResultState<T> {
  const SuccessState(this.result);

  @override
  R visit<R>(OperationStateVisitor<T, R> visitor) => visitor.success(result);

  @override
  ResultState<T> _idle() => IdleState<T>();

  @override
  ResultState<T> _processing() => ProcessingState<T>();

  final T result;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SuccessState<T> && other.result == result;
  }

  @override
  int get hashCode => result.hashCode;

  @override
  String toString() => 'SuccessState(result: $result)';
}

@immutable
class ErrorState<T> extends ResultState<T> {
  const ErrorState(this.cause);

  @override
  R visit<R>(OperationStateVisitor<T, R> visitor) => visitor.error(cause);

  @override
  ResultState<T> _idle() => IdleState<T>();

  @override
  ResultState<T> _processing() => ProcessingState<T>();

  final Object cause;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ErrorState && other.cause == cause;
  }

  @override
  int get hashCode => cause.hashCode;

  @override
  String toString() => 'ErrorState(cause: $cause)';
}

abstract interface class OperationStateVisitor<T, R> {
  R idle();
  R processing();
  R success(T result);
  R error(Object cause);
}

class _Run<T> implements Event<ResultState<T>> {
  const _Run(this._operation);

  @override
  Stream<ResultState<T>> fold(
    Producer<ResultState<T>> currentState,
  ) async* {
    yield currentState()._processing();
    try {
      yield currentState()._success(await _operation.run());
    } on Object catch (e) {
      yield currentState()._error(e);
    }
  }

  final Supplier<T> _operation;
}

class _RevertToIdle<T> implements Event<ResultState<T>> {
  const _RevertToIdle();

  @override
  Stream<ResultState<T>> fold(
    Producer<ResultState<T>> currentState,
  ) async* {
    yield currentState()._idle();
  }
}
