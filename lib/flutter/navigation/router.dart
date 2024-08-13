import 'package:flutter/widgets.dart';
import 'package:flutter_estd/ioc/widget.dart';
import 'package:flutter_estd/presentation/navigation/router.dart';

abstract interface class ApplicationRouterFactory {
  ApplicationRouter create(BuildContext context);

  static ApplicationRouter of(BuildContext context) {
    return ServiceLocatorWidget.shared<ApplicationRouterFactory>(context)
        .create(context);
  }
}
