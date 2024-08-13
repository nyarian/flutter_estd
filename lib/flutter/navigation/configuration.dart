import 'package:flutter/widgets.dart';

abstract interface class RouterConfiguration {
  RouteInformationProvider get routeInformationProvider;
  RouteInformationParser<Object> get routeInformationParser;
  RouterDelegate<Object> get routerDelegate;
  RouterConfig<Object> get routerConfig;
}
