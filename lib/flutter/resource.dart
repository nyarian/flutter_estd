import 'package:flutter/widgets.dart';
import 'package:flutter_estd/estd/resource.dart';

extension ChangeNotifierResourceExtension on ChangeNotifier {
  Resource asResource() => ChangeNotifierResource(this);
}

@immutable
class ChangeNotifierResource implements Resource {
  const ChangeNotifierResource(this._notifier);

  final ChangeNotifier _notifier;

  @override
  void release() => _notifier.dispose();
}

extension AnimationListenerMixinResourceExtension
    on AnimationEagerListenerMixin {
  Resource asResource() => AnimationListenerMixinResource(this);
}

class AnimationListenerMixinResource implements Resource {
  const AnimationListenerMixinResource(this._animation);

  @override
  void release() => _animation.dispose();

  final AnimationEagerListenerMixin _animation;
}
