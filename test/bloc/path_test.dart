import 'package:flutter_estd/presentation/navigation/path.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('renotate', () {
    test(
      'from colon to curly works for single parameter',
      () {
        final path = URLPath('/users/:id');
        final renotated = path.renotate(
          from: const ColonNotation(),
          to: const CurlyNotation(),
        );
        expect(URLPath('/users/{id}'), renotated);
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );
    test(
      'from colon to curly works for double parameter',
      () {
        final path = URLPath('/users/:id/friends/:fid');
        final renotated = path.renotate(
          from: const ColonNotation(),
          to: const CurlyNotation(),
        );
        expect(URLPath('/users/{id}/friends/{fid}'), renotated);
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );
    test(
      'API-built from curly to colon works for single parameter',
      () {
        final path = URLPath.root.append('users').appendVariable('id');
        final renotated = path.renotate(
          to: const ColonNotation(),
        );
        expect(URLPath('/users/:id'), renotated);
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );
    test(
      'API-built from curly to colon works for two parameters',
      () {
        final path = URLPath.root
            .append('users')
            .appendVariable('id')
            .append('friends')
            .appendVariable('fid');
        final renotated = path.renotate(
          to: const ColonNotation(),
        );
        expect(URLPath('/users/:id/friends/:fid'), renotated);
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );
  });
}
