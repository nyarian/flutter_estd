import 'package:flutter/widgets.dart';
import 'package:flutter_estd/estd/resource.dart';
import 'package:flutter_estd/ioc/retained.dart';
import 'package:flutter_estd/ioc/service_locator.dart';

class ServiceLocatorWidget extends InheritedWidget {
  final ServiceLocator _locator;

  const ServiceLocatorWidget(
    this._locator, {
    required super.child,
    super.key,
  });

  static ServiceLocator of(BuildContext context) => (context
          .getElementForInheritedWidgetOfExactType<ServiceLocatorWidget>()!
          // ignore: avoid_as
          .widget as ServiceLocatorWidget)
      ._locator;

  static ServiceLocator observe(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ServiceLocatorWidget>()!
      ._locator;

  static ScopedService<T> get<T extends Object>(BuildContext context) {
    return of(context).get();
  }

  static T shared<T extends Object>(BuildContext context) {
    return of(context).shared();
  }

  static Retained<T> retained<T extends Resource>(BuildContext context) {
    return of(context).retained<T>();
  }

  static T owned<T extends Object>(BuildContext context) {
    return of(context).owned();
  }

  @override
  bool updateShouldNotify(ServiceLocatorWidget oldWidget) =>
      !identical(_locator, oldWidget._locator);
}
