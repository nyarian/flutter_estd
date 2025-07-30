import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef StateRetainingWidgetBuilder<T> =
    Widget Function(BuildContext context, T state, ValueSetter<T> setter);

class StateRetainingWidget<T> extends StatefulWidget {
  const StateRetainingWidget({
    required this.state,
    required this.builder,
    this.overrideState = false,
    super.key,
  });

  final StateRetainingWidgetBuilder<T> builder;
  final T state;
  final bool overrideState;

  @override
  State<StateRetainingWidget<T>> createState() =>
      _StateRetainingWidgetState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty.has('builder', builder))
      ..add(DiagnosticsProperty('state', state))
      ..add(DiagnosticsProperty('overrideState', overrideState));
  }
}

class _StateRetainingWidgetState<T> extends State<StateRetainingWidget<T>> {
  late final ValueNotifier<T> _state;

  @override
  void initState() {
    super.initState();
    _state = ValueNotifier(widget.state);
  }

  @override
  void didUpdateWidget(covariant StateRetainingWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.overrideState) {
      _state.value = widget.state;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _state,
      builder: (context, state, child) {
        return widget.builder(context, state, (e) => _state.value = e);
      },
    );
  }
}
