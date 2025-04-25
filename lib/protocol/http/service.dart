class HttpServiceUri {
  const HttpServiceUri({
    required String domain,
    required String prefix,
    required Scheme scheme,
  })  : _domain = domain,
        _prefix = prefix,
        _scheme = scheme;

  factory HttpServiceUri.from(String uri) {
    final result = _regex.firstMatch(uri);
    if (result == null) throw InvalidServiceUriException(message: uri);
    return HttpServiceUri(
      scheme: result.group(1) == 'http' ? Scheme.http : Scheme.https,
      domain: result.group(2)!,
      prefix: result.group(4) ?? '',
    );
  }

  Uri build(
    String endpoint, [
    Map<String, dynamic>? queryParameters,
  ]) {
    final path = '$_prefix/$endpoint';
    if (_scheme == Scheme.http) {
      return Uri.http(_domain, path, queryParameters);
    } else {
      return Uri.https(_domain, path, queryParameters);
    }
  }

  final String _domain;
  final String _prefix;
  final Scheme _scheme;

  static final _regex =
      RegExp('(https|http)://([a-z0-9.-]+(:[0-9]+)?)/([a-z0-9-_/]+)?');
}

enum Scheme { http, https }

final class InvalidServiceUriException implements Exception {
  const InvalidServiceUriException({this.message, this.cause});

  final String? message;
  final String? cause;

  @override
  String toString() =>
      'InvalidServiceUriException(message: $message, cause: $cause)';
}
