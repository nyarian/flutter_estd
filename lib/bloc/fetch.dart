import 'package:flutter_estd/bloc/bloc.dart';
import 'package:flutter_estd/estd/functional/std.dart';
import 'package:flutter_estd/estd/resource.dart';
import 'package:meta/meta.dart';

class GatewayFetchBloc<T> implements Bloc<GatewayFetchState<T>>, Resource {
  GatewayFetchBloc(Gateway<T> gateway)
      : _delegate = StreamTransformerBloc.electLast(
          initialState: FetchingState(),
          initialEvent: _Fetch(gateway),
        ),
        _gateway = gateway;

  void fetch() => _delegate.add(_Fetch(_gateway));

  @override
  GatewayFetchState<T> currentState() => _delegate.currentState();

  @override
  Stream<GatewayFetchState<T>> state() => _delegate.state();

  @override
  void release() => _delegate.release();

  final Gateway<T> _gateway;
  final MutableBloc<GatewayFetchState<T>> _delegate;
}

@immutable
sealed class GatewayFetchState<T> {
  const GatewayFetchState();
  R visit<R>(GatewayFetchStateVisitor<T, R> visitor);
  GatewayFetchState<T> _fetching() => FetchingState();
  GatewayFetchState<T> _error(Object cause) => ErrorState(cause);
  GatewayFetchState<T> _success(T result) => SuccessState(result);
}

abstract interface class GatewayFetchStateVisitor<T, R> {
  R fetching();
  R error(Object cause);
  R success(T result);
}

@immutable
class FetchingState<T> extends GatewayFetchState<T> {
  @override
  R visit<R>(GatewayFetchStateVisitor<T, R> visitor) => visitor.fetching();

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is FetchingState<T>;
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'FetchingState()';
}

@immutable
class ErrorState<T> extends GatewayFetchState<T> {
  const ErrorState(this.cause);

  @override
  R visit<R>(GatewayFetchStateVisitor<T, R> visitor) => visitor.error(cause);

  final Object cause;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ErrorState<T> && other.cause == cause;
  }

  @override
  int get hashCode => cause.hashCode;

  @override
  String toString() => 'ErrorState(cause: $cause)';
}

@immutable
class SuccessState<T> extends GatewayFetchState<T> {
  const SuccessState(this.result);

  @override
  R visit<R>(GatewayFetchStateVisitor<T, R> visitor) => visitor.success(result);

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

abstract interface class Gateway<T> {
  Future<T> resolve();
}

class LambdaGateway<T> implements Gateway<T> {
  const LambdaGateway(this._delegate);

  @override
  Future<T> resolve() => _delegate();

  final Future<T> Function() _delegate;
}

@immutable
class _Fetch<T> implements Event<GatewayFetchState<T>> {
  const _Fetch(this._gateway);

  @override
  Stream<GatewayFetchState<T>> fold(
    Producer<GatewayFetchState<T>> currentState,
  ) async* {
    yield currentState()._fetching();
    try {
      final result = await _gateway.resolve();
      yield currentState()._success(result);
    } on Object catch (e) {
      yield currentState()._error(e);
    }
  }

  final Gateway<T> _gateway;
}
