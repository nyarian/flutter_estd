import 'package:built_collection/built_collection.dart';
import 'package:flutter_estd/estd/resource.dart';

abstract interface class Automation {
  Future<Resource> run();
}

class AutomationSet {
  const AutomationSet({
    required this.applicationWide,
    required this.session,
  });

  AutomationSet merge(AutomationSet other) {
    return AutomationSet(
      applicationWide: applicationWide + other.applicationWide,
      session: session + other.session,
    );
  }

  final BuiltList<Automation> applicationWide;
  final BuiltList<Automation> session;
}
