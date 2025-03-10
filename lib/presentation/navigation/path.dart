// ignore_for_file: avoid_returning_this

import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:flutter_estd/estd/string.dart';
import 'package:meta/meta.dart';

@immutable
class URLPath {
  factory URLPath(String path) {
    try {
      final uri = Uri.parse('$_host$path');
      final qparamsSeparator = path.indexOf('?');
      final newPath =
          qparamsSeparator == -1 ? path : path.substring(0, qparamsSeparator);
      return URLPath._(newPath, uri.queryParametersAll);
    } on FormatException catch (e) {
      throw InvalidURLPathException(message: 'Invalid path: $path', cause: e);
    }
  }

  const URLPath._(this._path, this._queryParams);

  URLPath subpath(URLPath parent) {
    return URLPath(_path.removeBeginning(parent._path));
  }

  String unpreseparetedPath() => _path.removeBeginning(_separator);

  URLPath append(String subpath) {
    final prefix = _path == root._path ? _path : '$_path$_separator';
    return URLPath('$prefix$subpath').replaceQueryParamsAll(_queryParams);
  }

  URLPath appendVariable(
    String variable, [
    URLPathVariableNotation notation = const CurlyNotation(),
  ]) {
    return append(notation.notate(variable));
  }

  URLPath materialize(
    URLParametersValues parametersValues, [
    URLPathVariableNotation notation = const CurlyNotation(),
  ]) {
    var result = _path;
    for (final entry in parametersValues.asMap.entries) {
      final range = notation.find(result, entry.key);
      result = result.replaceRange(range.start, range.end, entry.value);
    }
    return URLPath(result);
  }

  URLPath renotate({
    required URLPathVariableNotation to,
    URLPathVariableNotation from = const CurlyNotation(),
  }) {
    return URLPath(
      _path.replaceAllMapped(
        from.asRegExp,
        (match) => to.notate(match.group(1)!),
      ),
    );
  }

  URLPath? parent() {
    final index = _path.lastIndexOf('/');
    if (index == 0) {
      return _path.length == 1 ? null : URLPath.root;
    } else {
      return URLPath(_path.substring(0, index));
    }
  }

  URLPath rootParent() {
    if (_path == root._path) {
      return URLPath(_path);
    } else {
      final index = _path.indexOf('/', 1);
      return index == -1 ? this : URLPath(_path.substring(0, index));
    }
  }

  URLPath replaceQueryParams(Map<String, String> params) {
    return URLPath._(_path, params.map((key, value) => MapEntry(key, [value])));
  }

  URLPath replaceQueryParamsAll(Map<String, List<String>> params) {
    return URLPath._(_path, Map.of(params));
  }

  List<String>? queryParam(String key) => _queryParams[key];

  Map<String, List<String>> get queryParams =>
      BuiltMap.of(_queryParams).toMap();

  String get asString {
    final path = Uri(
      scheme: 'https',
      host: 'sample.com',
      path: _path == root._path ? '' : _path,
      queryParameters: _queryParams.isEmpty ? null : _queryParams,
    ).toString().removeBeginning(_host);
    return path.isEmpty || path.startsWith('?') ? '/$path' : path;
  }

  String get path => _path;

  final String _path;
  final Map<String, List<String>> _queryParams;

  static final root = URLPath('/');
  static const _separator = '/';
  static const _host = 'https://sample.com';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is URLPath &&
        other._path == _path &&
        const MapEquality<String, List<String>>()
            .equals(_queryParams, other.queryParams);
  }

  @override
  int get hashCode => _path.hashCode & _queryParams.hashCode;

  @override
  String toString() => 'URLPath(_path: $_path, _queryParams: $_queryParams)';
}

@immutable
abstract class URLPathException implements Exception {
  final String? message;
  final Object? cause;

  const URLPathException({required this.message, required this.cause});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is URLPathException &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          cause == other.cause;

  @override
  int get hashCode => message.hashCode ^ cause.hashCode;

  @override
  String toString() {
    return message?.toString() ??
        (cause is Exception
            ? cause.toString()
            : "$runtimeType"
                "${message == null ? "" : "\nMessage: $message"}"
                "${cause == null ? "" : "\nCause: ${cause.toString()}"}");
  }
}

final class InvalidURLPathException extends URLPathException {
  const InvalidURLPathException({super.cause, super.message});
}

final class InvalidURLParameterException extends URLPathException {
  const InvalidURLParameterException({super.cause, super.message});
}

final class InvalidURLParameterValueException extends URLPathException {
  const InvalidURLParameterValueException({super.cause, super.message});
}

@immutable
class URLParametersValues {
  factory URLParametersValues(Map<String, String> source) {
    for (final entry in source.entries) {
      if (!_regex.hasMatch(entry.key)) {
        throw InvalidURLParameterException(
          message: "Parameter's name is invalid: ${entry.key}",
        );
      } else if (!_regex.hasMatch(entry.value)) {
        throw InvalidURLParameterValueException(
          message: "Parameter's ${entry.key} value is invalid: ${entry.value}",
        );
      }
    }
    return URLParametersValues._(BuiltMap.of(source));
  }

  const URLParametersValues._(this._map);

  BuiltMap<String, String> get asMap => _map;

  final BuiltMap<String, String> _map;

  static final _regex = RegExp(r'^[a-zA-Z0-9-_]+$');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is URLParametersValues && other._map == _map;
  }

  @override
  int get hashCode => _map.hashCode;

  @override
  String toString() => 'URLParametersValues(_map: $_map)';
}

abstract interface class URLPathVariableNotation {
  RegExp get asRegExp;

  PositiveIntRange find(String path, String variable);

  String notate(String variable);
}

@immutable
abstract class RegExpNotation implements URLPathVariableNotation {
  const RegExpNotation(this._builder);

  @override
  RegExp get asRegExp => _builder('([^/{}:]+)');

  @nonVirtual
  @override
  PositiveIntRange find(String path, String variable) {
    final match = _builder(variable).firstMatch(path);
    if (match == null) {
      throw NoPathVariableException(
        message: 'No path variable `$variable` found in path `$path`',
      );
    } else {
      return PositiveIntRange(match.start, match.end);
    }
  }

  final RegexpBuilder _builder;
}

class ColonNotation extends RegExpNotation implements URLPathVariableNotation {
  const ColonNotation() : super(_build);

  static RegExp _build(String variable) => RegExp(':$variable');

  @override
  String notate(String variable) => ':$variable';
}

class CurlyNotation extends RegExpNotation implements URLPathVariableNotation {
  const CurlyNotation() : super(_build);

  static RegExp _build(String variable) => RegExp('{$variable}');

  @override
  String notate(String variable) => '{$variable}';
}

typedef RegexpBuilder = RegExp Function(String variable);

final class NoPathVariableException extends URLPathException {
  const NoPathVariableException({super.cause, super.message});
}

@immutable
class PositiveIntRange {
  final int start;
  final int end;

  const PositiveIntRange(this.start, this.end)
      : assert(end >= start, "`end` can't be less than `start`: [$start:$end)"),
        assert(
          start >= 0 && end >= 0,
          "Can't have negative values: [$start:$end)",
        );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PositiveIntRange &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;

  @override
  String toString() => 'PositiveIntRange(start: $start, end: $end)';
}
