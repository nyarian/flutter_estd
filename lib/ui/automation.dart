import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_estd/application/automation/automation.dart';
import 'package:flutter_estd/estd/resource.dart';

class AutomationScopingWidget extends StatefulWidget {
  final Iterable<Automation> automations;
  final Widget child;

  const AutomationScopingWidget({
    required this.automations,
    required this.child,
    super.key,
  });

  @override
  State<AutomationScopingWidget> createState() =>
      AutomationScopingWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty('automations', automations));
  }
}

class AutomationScopingWidgetState extends State<AutomationScopingWidget> {
  final _resource = CompositeResource();

  @override
  void initState() {
    super.initState();
    _runAutomations();
  }

  Future<void> _runAutomations() async {
    final resources = await Future.wait(widget.automations.map((e) => e.run()));
    if (mounted) {
      _resource.addAll(resources);
    } else {
      CompositeResource.of(resources).release();
    }
  }

  @override
  void dispose() {
    _resource.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
