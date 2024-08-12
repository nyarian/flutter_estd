import 'package:meta/meta.dart';

@immutable
class Nothing {
  const Nothing();

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Nothing;

  @override
  String toString() => 'Nothing{}';
}
