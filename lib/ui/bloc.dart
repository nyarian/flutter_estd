import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_estd/bloc/bloc.dart';

typedef BlocBuilderChild<T> = Widget Function(BuildContext context, T state);

class BlocBuilder<T> extends StatelessWidget {
  final Bloc<T> bloc;
  final BlocBuilderChild<T> builder;

  const BlocBuilder({required this.bloc, required this.builder, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      initialData: bloc.currentState(),
      stream: bloc.state(),
      builder: (ctx, snapshot) => builder(ctx, snapshot.data!),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('bloc', bloc))
      ..add(DiagnosticsProperty('builder', builder));
  }
}
