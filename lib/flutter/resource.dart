import 'package:flutter/foundation.dart';
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
