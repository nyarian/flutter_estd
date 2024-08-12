import 'dart:async';

import 'package:flutter_estd/estd/functional/std.dart';
import 'package:flutter_estd/estd/resource.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

abstract interface class Bloc<S> implements Resource {
  S currentState();

  Stream<S> state();
}

abstract base class ForwardingBloc<S> implements Bloc<S> {
  // Not const by design, because BLoCs are mutable, even if all references
  // inside the implementer are final!
  ForwardingBloc(this._delegate);

  @override
  Stream<S> state() => _delegate.state();

  @override
  S currentState() => _delegate.currentState();

  @override
  void release() => _delegate.release();

  final Bloc<S> _delegate;
}

abstract interface class MutableBloc<S> implements Bloc<S> {
  void add(Event<S> event);
}

abstract interface class ErrorProneState<S extends ErrorProneState<S>> {
  Object? get error;

  S clearError();
}

extension ErrorProneStateErrorCheck on ErrorProneState {
  bool get hasError => error != null;
}

abstract interface class Event<S> {
  Stream<S> fold(Producer<S> state);
}

// No `const` constructors for generic types!
@immutable
class ErrorProcessedEvent<S extends ErrorProneState<S>> implements Event<S> {
  @override
  Stream<S> fold(Producer<S> currentState) =>
      Stream.value(currentState().clearError());
}

class StreamTransformerBloc<S> implements MutableBloc<S> {
  StreamTransformerBloc(
    TransformerFactory<Event<S>, S> factory, {
    required S initialState,
    Event<S>? initialEvent,
    Transformation<Stream<Event<S>>, Stream<Event<S>>>? eventTransformer,
    Transformation<Stream<S>, Stream<S>>? stateTransformer,
  }) {
    _stateSubject.add(initialState);
    if (initialEvent != null) add(initialEvent);
    var events = _eventSC.stream;
    if (eventTransformer != null) {
      events = eventTransformer(events);
    }
    var states = events.transform(factory.transform(_fold));
    if (stateTransformer != null) {
      states = stateTransformer(states);
    }
    _subscription = states.listen(_stateSubject.add)
      ..onError(_stateSubject.addError);
  }

  StreamTransformerBloc.electLast({
    required S initialState,
    Event<S>? initialEvent,
    Transformation<Stream<Event<S>>, Stream<Event<S>>>? eventTransformer,
    Transformation<Stream<S>, Stream<S>>? stateTransformer,
  }) : this(
          SwitchMapTransformerFactory(),
          initialState: initialState,
          initialEvent: initialEvent,
          eventTransformer: eventTransformer,
          stateTransformer: stateTransformer,
        );

  StreamTransformerBloc.mix({
    required S initialState,
    Event<S>? initialEvent,
    Transformation<Stream<Event<S>>, Stream<Event<S>>>? eventTransformer,
    Transformation<Stream<S>, Stream<S>>? stateTransformer,
  }) : this(
          FlatMapTransformerFactory(),
          initialState: initialState,
          initialEvent: initialEvent,
          eventTransformer: eventTransformer,
          stateTransformer: stateTransformer,
        );

  StreamTransformerBloc.ordered({
    required S initialState,
    Event<S>? initialEvent,
    Transformation<Stream<Event<S>>, Stream<Event<S>>>? eventTransformer,
    Transformation<Stream<S>, Stream<S>>? stateTransformer,
  }) : this(
          ConcatMapTransformerFactory(),
          initialState: initialState,
          initialEvent: initialEvent,
          eventTransformer: eventTransformer,
          stateTransformer: stateTransformer,
        );

  Stream<S> _fold(Event<S> event) => event.fold(currentState);

  @override
  void add(Event<S> event) => _eventSC.add(event);

  @override
  S currentState() => _stateSubject.value!;

  @override
  Stream<S> state() => _stateSubject;

  @override
  void release() {
    _subscription.cancel();
    _stateSubject.close();
    _eventSC.close();
  }

  final _stateSubject = BehaviorSubject<S>();
  final _eventSC = StreamController<Event<S>>();
  late final StreamSubscription<void> _subscription;
}

abstract interface class TransformerFactory<T, S> {
  StreamTransformer<T, S> transform(Stream<S> Function(T) map);
}

class SwitchMapTransformerFactory<T, S> implements TransformerFactory<T, S> {
  @override
  StreamTransformer<T, S> transform(Stream<S> Function(T) map) =>
      SwitchMapStreamTransformer(map);
}

class FlatMapTransformerFactory<T, S> implements TransformerFactory<T, S> {
  @override
  StreamTransformer<T, S> transform(Stream<S> Function(T) map) =>
      FlatMapStreamTransformer(map);
}

class ConcatMapTransformerFactory<T, S> implements TransformerFactory<T, S> {
  @override
  StreamTransformer<T, S> transform(Stream<S> Function(T) map) =>
      _AsyncExpandTransformer(map);
}

class _AsyncExpandTransformer<T, S> extends StreamTransformerBase<T, S> {
  _AsyncExpandTransformer(this.map);

  @override
  Stream<S> bind(Stream<T> stream) => stream.asyncExpand(map);

  final Stream<S> Function(T event) map;
}
