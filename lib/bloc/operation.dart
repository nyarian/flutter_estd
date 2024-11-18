import 'package:flutter_estd/bloc/bloc.dart';
import 'package:flutter_estd/bloc/state.dart';
import 'package:flutter_estd/estd/functional/std.dart';
import 'package:meta/meta.dart';

class OperationBloc implements Bloc<OperationState> {
  OperationBloc()
      : _delegate = StreamTransformerBloc.ordered(
          initialState: const IdleState(),
        );

  void run(Operation operation) => _delegate.add(_Run(operation));

  void onErrorProcessed() => _delegate.add(const _RevertToIdle());

  void onSuccessProcessed() => _delegate.add(const _RevertToIdle());

  @override
  Stream<OperationState> state() => _delegate.state();

  @override
  OperationState currentState() => _delegate.currentState();

  @override
  void release() => _delegate.release();

  final MutableBloc<OperationState> _delegate;
}

abstract interface class Operation {
  Future<void> run();
}

@immutable
class LambdaOperation implements Operation {
  final Future<void> Function() function;

  const LambdaOperation(this.function);

  @override
  Future<void> run() => function();
}

sealed class OperationState {
  const OperationState();
  T visit<T>(OperationStateVisitor<T> visitor);
  OperationState _idle() => transitionError(IdleState);
  OperationState _processing() => transitionError(ProcessingState);
  OperationState _error(Object cause) => transitionError(ErrorState);
  OperationState _success() => transitionError(SuccessState);
}

@immutable
class IdleState extends OperationState {
  const IdleState();

  @override
  T visit<T>(OperationStateVisitor<T> visitor) => visitor.idle();

  @override
  OperationState _processing() => const ProcessingState();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IdleState;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'IdleState()';
}

@immutable
class ProcessingState extends OperationState {
  const ProcessingState();

  @override
  T visit<T>(OperationStateVisitor<T> visitor) => visitor.processing();

  @override
  OperationState _success() => const SuccessState();

  @override
  OperationState _error(Object cause) => ErrorState(cause);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ProcessingState;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'ProcessingState()';
}

@immutable
class SuccessState extends OperationState {
  const SuccessState();

  @override
  T visit<T>(OperationStateVisitor<T> visitor) => visitor.success();

  @override
  OperationState _idle() => const IdleState();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SuccessState;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'SuccessState()';
}

@immutable
class ErrorState extends OperationState {
  const ErrorState(this.cause);

  @override
  T visit<T>(OperationStateVisitor<T> visitor) => visitor.error(cause);

  @override
  OperationState _idle() => const IdleState();

  @override
  OperationState _processing() => const ProcessingState();

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

abstract interface class OperationStateVisitor<T> {
  T idle();
  T processing();
  T success();
  T error(Object cause);
}

class _Run implements Event<OperationState> {
  const _Run(this._operation);

  @override
  Stream<OperationState> fold(Producer<OperationState> currentState) async* {
    yield currentState()._processing();
    try {
      await _operation.run();
      yield currentState()._success();
    } on Object catch (e) {
      yield currentState()._error(e);
    }
  }

  final Operation _operation;
}

class _RevertToIdle implements Event<OperationState> {
  const _RevertToIdle();

  @override
  Stream<OperationState> fold(Producer<OperationState> currentState) async* {
    yield currentState()._idle();
  }
}
