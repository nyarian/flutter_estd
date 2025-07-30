import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_estd/bloc/bloc.dart';
import 'package:flutter_estd/bloc_fetch.dart' as fetch;
import 'package:flutter_estd/bloc_mutation.dart' as mutation;

typedef BlocStateBuilder<T> = Widget Function(BuildContext context, T result);

class BlocBuilder<T> extends StatelessWidget {
  final Bloc<T> bloc;
  final BlocStateBuilder<T> builder;

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

typedef MutationBlocErrorBuilder<T> = Widget Function(
  BuildContext context,
  T? current,
  Object cause,
);

class MutationBlocBuilder<T> extends StatelessWidget {
  final Bloc<mutation.MutationState<T>> bloc;
  final BlocStateBuilder<T> builder;
  final WidgetBuilder processingBuilder;
  final MutationBlocErrorBuilder<T> errorBuilder;
  final bool suppressError;
  final bool suppressProcessing;

  const MutationBlocBuilder({
    required this.bloc,
    required this.builder,
    required this.processingBuilder,
    required this.errorBuilder,
    this.suppressError = false,
    this.suppressProcessing = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: bloc,
      builder: (context, state) {
        return switch (state) {
          mutation.FetchingState() => processingBuilder(context),
          mutation.MutatingState(:var current) when suppressProcessing =>
            builder(context, current),
          mutation.MutatingState() => processingBuilder(context),
          mutation.FetchErrorState(:var cause) =>
            errorBuilder(context, null, cause),
          mutation.MutationErrorState(:var current) when suppressError =>
            builder(context, current),
          mutation.MutationErrorState(:var cause, :var current) =>
            errorBuilder(context, current, cause),
          mutation.MutatedState(:var result) ||
          mutation.FetchedState(:var result) =>
            builder(context, result),
        };
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('bloc', bloc))
      ..add(DiagnosticsProperty('suppressError', suppressError))
      ..add(DiagnosticsProperty('suppressProcessing', suppressProcessing))
      ..add(ObjectFlagProperty.has('builder', builder))
      ..add(ObjectFlagProperty.has('processingBuilder', processingBuilder))
      ..add(ObjectFlagProperty.has('errorBuilder', errorBuilder));
  }
}

typedef GatewayFetchBlocErrorBuilder<T> = Widget Function(
  BuildContext context,
  Object cause,
);

class GatewayFetchBlocBuilder<T> extends StatelessWidget {
  final Bloc<fetch.GatewayFetchState<T>> bloc;
  final BlocStateBuilder<T> builder;
  final WidgetBuilder processingBuilder;
  final GatewayFetchBlocErrorBuilder<T> errorBuilder;

  const GatewayFetchBlocBuilder({
    required this.bloc,
    required this.builder,
    required this.processingBuilder,
    required this.errorBuilder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: bloc,
      builder: (context, state) {
        return switch (state) {
          fetch.FetchingState() => processingBuilder(context),
          fetch.ErrorState(:var cause) => errorBuilder(context, cause),
          fetch.SuccessState(:var result) => builder(context, result),
        };
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('bloc', bloc))
      ..add(ObjectFlagProperty.has('builder', builder))
      ..add(ObjectFlagProperty.has('processingBuilder', processingBuilder))
      ..add(ObjectFlagProperty.has('errorBuilder', errorBuilder));
  }
}
