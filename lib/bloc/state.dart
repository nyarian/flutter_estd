final class StateTransitionError extends Error {
  final String message;

  StateTransitionError(Type from, Type to)
      : message = 'Unexpected state transition from "$from" to "$to".';

  StateTransitionError.message(this.message);

  @override
  String toString() => 'StateTransitionError(message: $message)';
}

extension StateTransitionErrorExtension on Object {
  T transitionError<T>(Type to) => throw StateTransitionError(runtimeType, to);

  T transitionErrorMsg<T>(String message) =>
      throw StateTransitionError.message(message);
}
