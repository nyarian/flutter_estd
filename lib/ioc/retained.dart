import 'package:flutter_estd/estd/resource.dart';
import 'package:flutter_estd/ioc/service_locator.dart';

class Retained<T extends Resource> implements Resource {
  Retained(this._locator);

  T retain() {
    final result = _dependency ?? _locator.owned<T>();
    _dependency ??= result;
    _retainers++;
    return result;
  }

  @override
  void release() {
    _retainers--;
    assert(_retainers > -1, '`release()` was called with no subscribers.');
    if (_retainers == 0) {
      _dependency!.release();
      _dependency = null;
    }
  }

  final ServiceLocator _locator;
  var _retainers = 0;
  T? _dependency;
}

extension FluentRetained<T extends Resource> on Retained<T> {
  T releasedBy(CompositeResource resource) {
    final dependency = retain();
    resource.add(this);
    return dependency;
  }
}
