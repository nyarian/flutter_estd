import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:flutter_estd/bloc_page.dart';
import 'package:flutter_estd/estd/query.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

import 'commons.dart';

void main() {
  PagedBloc<_Element, String> createTestSubject({
    PagedGateway<_Element, String> gateway = const _ContinuousElementGateway(),
    Query<String> firstQuery = const Query.of(''),
    int pageSize = Query.defaultSize,
    ElementComparisonStrategy<_Element> strategy =
        const NaturalComparisonStrategy(),
    ShortCircuitStrategy<_Element> shortCircuit =
        const LatestShortCircuitStrategy(),
    Page<_Element>? initialData,
  }) {
    return PagedBloc(
      gateway,
      firstQuery,
      initialData: initialData,
      pageSize: pageSize,
      strategy: strategy,
      shortCircuit: shortCircuit,
    );
  }

  group(
    'initialization: ',
    () {
      test(
        'initial payload gets propagated',
        () {
          final initial =
              BuiltList.of(List.generate(20, (i) => _Element('$i')));
          final subject = createTestSubject(initialData: (initial, null));
          expect(
            subject.state(),
            emitsThrough(
              predicate<FetchedState<_Element, String>>(
                (e) => e.current == initial,
              ),
            ),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'starts with the fetching state in the absence of initial payload',
        () {
          final subject = createTestSubject();
          expect(
            subject.currentState(),
            const FetchingState<_Element, String>(null, null, Query.of('')),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );
    },
  );

  group(
    'fetch: ',
    () {
      test(
        'fetched list is published',
        () async {
          final (expected, _) = await const _ContinuousElementGateway()
              .get(const Query(value: ''));
          final subject = createTestSubject();
          expect(
            subject.state(),
            emitsThrough(predicate<FetchedState<_Element, String>>(
                (e) => e.current == BuiltList.of(expected))),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'metadata is published',
        () async {
          const given = {'1': 1};
          final (_, _) = await const _ContinuousElementGateway(metadata: given)
              .get(const Query(value: ''));
          final subject = createTestSubject(
            gateway: const _ContinuousElementGateway(metadata: given),
          );
          expect(
            subject.state(),
            emitsThrough(predicate<FetchedState<_Element, String>>(
                (e) => e.metadata == BuiltMap.of(given))),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'fetch error is published',
        () async {
          final expected = Exception('expected cause');
          final subject = createTestSubject(
            gateway: _DelegatingElementGateway((_) async => throw expected),
          );
          expect(
            subject.state(),
            emitsThrough(predicate<ErrorState<_Element, String>>((e) =>
                e.current == null &&
                e.cause.toString() == expected.toString())),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'fetch error is recovered from with retrying',
        () async {
          final (expected, _) = await const _ContinuousElementGateway()
              .get(const Query(value: ''));

          final subject = createTestSubject(
            gateway: _IncrementalDelegatingElementGateway((count, query) {
              return switch (count) {
                0 => throw Exception(),
                _ => const _ContinuousElementGateway().get(query),
              };
            }),
          );
          await _ErrorFixture(subject).prepare();
          subject.retry();

          expect(
            subject.state(),
            emitsThrough(predicate<FetchedState<_Element, String>>(
                (e) => e.current == BuiltList.of(expected))),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );
    },
  );

  group(
    'paging: ',
    () {
      test(
        'triggers the fetching state with the last snapshotted list',
        () async {
          final (expected, _) = await const _ContinuousElementGateway()
              .get(const Query(value: ''));

          final subject = createTestSubject();
          await _PagedFixture(subject).prepare();

          expect(
            subject.state(),
            emitsThrough(predicate<FetchingState<_Element, String>>(
                (e) => e.current == BuiltList.of(expected))),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'triggers the fetching state with the next query',
        () async {
          const expected = Query.of('', start: Query.defaultSize);

          final subject = createTestSubject();
          await _PagedFixture(subject).prepare();

          expect(
            subject.state(),
            emitsThrough(predicate<FetchingState<_Element, String>>(
                (e) => e.query == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'retains metadata for the fetching state with the next query',
        () async {
          const expected = {'1': 1};

          final subject = createTestSubject(
              gateway: const _ContinuousElementGateway(metadata: expected));
          await _PagedFixture(subject).prepare();

          expect(
            subject.state(),
            emitsThrough(predicate<FetchingState<_Element, String>>(
                (e) => e.metadata == BuiltMap.of(expected))),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'error retains the previous page state',
        () async {
          final (expected, _) = await const _ContinuousElementGateway()
              .get(const Query(value: ''));

          final subject = createTestSubject(
            gateway: _IncrementalDelegatingElementGateway((count, query) {
              return switch (count) {
                0 => const _ContinuousElementGateway().get(query),
                _ => throw Exception(),
              };
            }),
          );
          await _PagedFixture(subject).prepare();

          expect(
            subject.state(),
            emitsThrough(predicate<ErrorState<_Element, String>>(
                (e) => e.current == BuiltList.of(expected))),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'error retains the previous metadata',
        () async {
          const expected = {'1': 1};

          final subject = createTestSubject(
            gateway: _IncrementalDelegatingElementGateway((count, query) {
              return switch (count) {
                0 => const _ContinuousElementGateway(metadata: expected)
                    .get(query),
                _ => throw Exception(),
              };
            }),
          );
          await _PagedFixture(subject).prepare();

          expect(
            subject.state(),
            emitsThrough(predicate<ErrorState<_Element, String>>(
                (e) => e.metadata == BuiltMap.of(expected))),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'appends the next page to the current page',
        () async {
          final (expected, _) = await const _ContinuousElementGateway()
              .get(const Query(value: '', size: 40));

          final subject = createTestSubject();
          await _PagedFixture(subject).prepare();

          expect(
            subject.state(),
            emitsThrough(predicate<FetchedState<_Element, String>>(
                (e) => e.current == BuiltList.of(expected))),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'updates metadata on next page',
        () async {
          const expected = {'2': 2};

          final subject = createTestSubject(
            gateway: _IncrementalDelegatingElementGateway((count, query) {
              return switch (count) {
                0 => const _ContinuousElementGateway().get(query),
                _ => const _ContinuousElementGateway(metadata: expected)
                    .get(query),
              };
            }),
          );
          await _PagedFixture(subject).prepare();

          expect(
            subject.state(),
            emitsThrough(predicate<FetchedState<_Element, String>>(
                (e) => e.metadata == BuiltMap.of(expected))),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'appends the next page to the current page on paging error retry',
        () async {
          final (expected, _) = await const _ContinuousElementGateway()
              .get(const Query(value: '', size: 40));

          final subject = createTestSubject(
            gateway: _IncrementalDelegatingElementGateway((count, query) {
              return switch (count) {
                1 => throw Exception(),
                _ => const _ContinuousElementGateway().get(query),
              };
            }),
          );
          await Fixture.sequence(
              [_PagedFixture(subject), _ErrorFixture(subject)]);
          subject.retry();

          expect(
            subject.state(),
            emitsThrough(predicate<FetchedState<_Element, String>>(
                (e) => e.current == BuiltList.of(expected))),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'append accounts for duplicates caused by a linear page shift',
        () async {
          final (expected, _) = await const _ContinuousElementGateway()
              .get(const Query(value: '', size: 30));

          final subject = createTestSubject(
            gateway: _IncrementalDelegatingElementGateway((count, query) {
              return switch (count) {
                0 => const _ContinuousElementGateway().get(query),
                1 => const _ContinuousElementGateway().get(query.shift(-10)),
                _ => throw StateError('Expected only 2 calls'),
              };
            }),
          );
          await _PagedFixture(subject).prepare();

          expect(
            subject.state(),
            emitsThrough(predicate<FetchedState<_Element, String>>(
                (e) => e.current == BuiltList.of(expected))),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'append short circuits if tails differ identity-wise (latest)',
        () async {
          final expected = BuiltList.of([
            ...(await const _ContinuousElementGateway()
                    .get(const Query(value: '', size: 10)))
                .$1,
            ...(await const _ContinuousElementGateway(multiplier: 2)
                    .get(const Query(value: '', start: 10)))
                .$1,
          ]);

          final subject = createTestSubject(
            gateway: _IncrementalDelegatingElementGateway((count, query) {
              return switch (count) {
                0 => const _ContinuousElementGateway().get(query),
                1 => const _ContinuousElementGateway(multiplier: 2)
                    .get(query.shift(-10)),
                _ => throw StateError('Expected only 2 calls'),
              };
            }),
          );
          await _PagedFixture(subject).prepare();

          expect(
            subject.state(),
            emitsThrough(predicate<FetchedState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'append short circuits if tails differ identity-wise (retaining)',
        () async {
          final expected = BuiltList.of([
            ...(await const _ContinuousElementGateway()
                    .get(const Query(value: '')))
                .$1,
            ...(await const _ContinuousElementGateway(multiplier: 2)
                    .get(const Query(value: '', start: 20, size: 15)))
                .$1,
          ]);

          final subject = createTestSubject(
            gateway: _IncrementalDelegatingElementGateway((count, query) {
              return switch (count) {
                0 => const _ContinuousElementGateway().get(query),
                1 => const _ContinuousElementGateway(multiplier: 2)
                    .get(query.shift(-10)),
                _ => throw StateError('Expected only 2 calls'),
              };
            }),
            shortCircuit: const RetainingShortCircuitStrategy(),
          );
          await _PagedFixture(subject).prepare();

          expect(
            subject.state(),
            emitsThrough(predicate<FetchedState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );
    },
  );

  group(
    'replace: ',
    () {
      test(
        'changes a single matched element',
        () async {
          const given = _Element('#20');
          final expected = BuiltList.of(
              (await const _ContinuousElementGateway().get(const Query.of('')))
                  .$1
                  .toList()
                ..[0] = given);

          final subject = createTestSubject();
          await _FetchedFixture(subject).prepare();
          subject.replaceSingle(given, (e) => e.name == '#0');

          expect(
            subject.state(),
            emitsThrough(predicate<FetchedState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'changes a single matched element for error state',
        () async {
          const given = _Element('#20');
          final expected = BuiltList.of(
              (await const _ContinuousElementGateway().get(const Query.of('')))
                  .$1
                  .toList()
                ..[0] = given);

          final subject = createTestSubject(
            initialData:
                await const _ContinuousElementGateway().get(const Query.of('')),
            gateway: const _ErrorElementGateway(),
          );
          await _PagedFixture(subject).prepare();
          subject.replaceSingle(given, (e) => e.name == '#0');

          expect(
            subject.state(),
            emitsThrough(predicate<ErrorState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'changes a single matched element for fetching state',
        () async {
          const given = _Element('#20');
          final expected = BuiltList.of(
              (await const _ContinuousElementGateway().get(const Query.of('')))
                  .$1
                  .toList()
                ..[0] = given);

          final subject = createTestSubject(
            initialData:
                await const _ContinuousElementGateway().get(const Query.of('')),
            gateway: const _NonReturningElementGateway(),
          );
          await _PagedFixture(subject).prepare();
          subject.replaceSingle(given, (e) => e.name == '#0');

          expect(
            subject.state(),
            emitsThrough(predicate<FetchingState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );
    },
  );

  group(
    'append: ',
    () {
      test(
        'adds a single element',
        () async {
          const given = _Element('#20');
          final expected = BuiltList.of(
              (await const _ContinuousElementGateway().get(const Query.of('')))
                  .$1
                  .toList()
                ..add(given));

          final subject = createTestSubject();
          await _FetchedFixture(subject).prepare();
          subject.append(given);

          expect(
            subject.state(),
            emitsThrough(predicate<FetchedState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'adds a single element for error state',
        () async {
          const given = _Element('#20');
          final expected = BuiltList.of(
              (await const _ContinuousElementGateway().get(const Query.of('')))
                  .$1
                  .toList()
                ..add(given));

          final subject = createTestSubject(
            initialData:
                await const _ContinuousElementGateway().get(const Query.of('')),
            gateway: const _ErrorElementGateway(),
          );
          await _PagedFixture(subject).prepare();
          subject.append(given);

          expect(
            subject.state(),
            emitsThrough(predicate<ErrorState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'adds a single element for fetching state',
        () async {
          const given = _Element('#20');
          final expected = BuiltList.of(
              (await const _ContinuousElementGateway().get(const Query.of('')))
                  .$1
                  .toList()
                ..add(given));

          final subject = createTestSubject(
            initialData:
                await const _ContinuousElementGateway().get(const Query.of('')),
            gateway: const _NonReturningElementGateway(),
          );
          await _PagedFixture(subject).prepare();
          subject.append(given);

          expect(
            subject.state(),
            emitsThrough(predicate<FetchingState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'no change if the element is a duplicate of any existing',
        () async {
          final (given, _) =
              await const _ContinuousElementGateway().get(const Query.of(''));
          final expected = BuiltList.of(given);

          final subject = createTestSubject();
          await _FetchedFixture(subject).prepare();
          given.forEach(subject.append);

          expect(
            subject.state(),
            emitsThrough(predicate<FetchedState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );
    },
  );

  group(
    'appendAll: ',
    () {
      test(
        'adds the elements',
        () async {
          const given = [_Element('#20'), _Element('#21')];
          final expected = BuiltList.of(
              (await const _ContinuousElementGateway().get(const Query.of('')))
                  .$1
                  .toList()
                ..addAll(given));

          final subject = createTestSubject();
          await _FetchedFixture(subject).prepare();
          subject.appendAll(given);

          expect(
            subject.state(),
            emitsThrough(predicate<FetchedState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'adds the elements for error state',
        () async {
          const given = [_Element('#20'), _Element('#21')];
          final expected = BuiltList.of(
              (await const _ContinuousElementGateway().get(const Query.of('')))
                  .$1
                  .toList()
                ..addAll(given));

          final subject = createTestSubject(
            initialData:
                await const _ContinuousElementGateway().get(const Query.of('')),
            gateway: const _ErrorElementGateway(),
          );
          await _PagedFixture(subject).prepare();
          subject.appendAll(given);

          expect(
            subject.state(),
            emitsThrough(predicate<ErrorState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'adds the elements for fetching state',
        () async {
          const given = [_Element('#20'), _Element('#21')];
          final expected = BuiltList.of(
              (await const _ContinuousElementGateway().get(const Query.of('')))
                  .$1
                  .toList()
                ..addAll(given));

          final subject = createTestSubject(
            initialData:
                await const _ContinuousElementGateway().get(const Query.of('')),
            gateway: const _NonReturningElementGateway(),
          );
          await _PagedFixture(subject).prepare();
          subject.appendAll(given);

          expect(
            subject.state(),
            emitsThrough(predicate<FetchingState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'no change if the element is a duplicate of any existing',
        () async {
          final (given, _) =
              await const _ContinuousElementGateway().get(const Query.of(''));
          final expected = BuiltList.of(given);

          final subject = createTestSubject();
          await _FetchedFixture(subject).prepare();
          subject.appendAll(given);

          expect(
            subject.state(),
            emitsThrough(predicate<FetchedState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'appends the cutoff non-duplicate tail',
        () async {
          const given = [
            _Element('#18'),
            _Element('#19'),
            _Element('#20'),
            _Element('#21'),
          ];
          final expected =
              BuiltList.of(List.generate(22, (i) => _Element('#$i')));

          final subject = createTestSubject();
          await _FetchedFixture(subject).prepare();
          subject.appendAll(given);

          expect(
            subject.state(),
            emitsThrough(predicate<FetchedState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );
    },
  );

  group(
    'prepend: ',
    () {
      test(
        'adds a single element',
        () async {
          const given = _Element('#-1');
          final expected = BuiltList.of(
              (await const _ContinuousElementGateway().get(const Query.of('')))
                  .$1
                  .toList()
                ..insert(0, given));

          final subject = createTestSubject();
          await _FetchedFixture(subject).prepare();
          subject.prepend(given);

          expect(
            subject.state(),
            emitsThrough(predicate<FetchedState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'adds a single element for error state',
        () async {
          const given = _Element('#-1');
          final expected = BuiltList.of(
              (await const _ContinuousElementGateway().get(const Query.of('')))
                  .$1
                  .toList()
                ..insert(0, given));

          final subject = createTestSubject(
            initialData:
                await const _ContinuousElementGateway().get(const Query.of('')),
            gateway: const _ErrorElementGateway(),
          );
          await _PagedFixture(subject).prepare();
          subject.prepend(given);

          expect(
            subject.state(),
            emitsThrough(predicate<ErrorState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'adds a single element for fetching state',
        () async {
          const given = _Element('#-1');
          final expected = BuiltList.of(
              (await const _ContinuousElementGateway().get(const Query.of('')))
                  .$1
                  .toList()
                ..insert(0, given));

          final subject = createTestSubject(
            initialData:
                await const _ContinuousElementGateway().get(const Query.of('')),
            gateway: const _NonReturningElementGateway(),
          );
          await _PagedFixture(subject).prepare();
          subject.prepend(given);

          expect(
            subject.state(),
            emitsThrough(predicate<FetchingState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'no change if the element is a duplicate of any existing',
        () async {
          final (given, _) =
              await const _ContinuousElementGateway().get(const Query.of(''));
          final expected = BuiltList.of(given);

          final subject = createTestSubject();
          await _FetchedFixture(subject).prepare();
          given.forEach(subject.prepend);

          expect(
            subject.state(),
            emitsThrough(predicate<FetchedState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );
    },
  );

  group(
    'prependAll: ',
    () {
      test(
        'adds the elements',
        () async {
          const given = [_Element('#-2'), _Element('#-1')];
          final expected = BuiltList.of(
              (await const _ContinuousElementGateway().get(const Query.of('')))
                  .$1
                  .toList()
                ..insertAll(0, given));

          final subject = createTestSubject();
          await _FetchedFixture(subject).prepare();
          subject.prependAll(given);

          expect(
            subject.state(),
            emitsThrough(predicate<FetchedState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'adds the elements for error state',
        () async {
          const given = [_Element('#-2'), _Element('#-1')];
          final expected = BuiltList.of(
              (await const _ContinuousElementGateway().get(const Query.of('')))
                  .$1
                  .toList()
                ..insertAll(0, given));

          final subject = createTestSubject(
            initialData:
                await const _ContinuousElementGateway().get(const Query.of('')),
            gateway: const _ErrorElementGateway(),
          );
          await _PagedFixture(subject).prepare();
          subject.prependAll(given);

          expect(
            subject.state(),
            emitsThrough(predicate<ErrorState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'adds the elements for fetching state',
        () async {
          const given = [_Element('#-2'), _Element('#-1')];
          final expected = BuiltList.of(
              (await const _ContinuousElementGateway().get(const Query.of('')))
                  .$1
                  .toList()
                ..insertAll(0, given));

          final subject = createTestSubject(
            initialData:
                await const _ContinuousElementGateway().get(const Query.of('')),
            gateway: const _NonReturningElementGateway(),
          );
          await _PagedFixture(subject).prepare();
          subject.prependAll(given);

          expect(
            subject.state(),
            emitsThrough(predicate<FetchingState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'no change if the element is a duplicate of any existing',
        () async {
          final (given, _) =
              await const _ContinuousElementGateway().get(const Query.of(''));
          final expected = BuiltList.of(given);

          final subject = createTestSubject();
          await _FetchedFixture(subject).prepare();
          subject.prependAll(given);

          expect(
            subject.state(),
            emitsThrough(predicate<FetchedState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'prepends the cutoff non-duplicate tail',
        () async {
          const given = [
            _Element('#-2'),
            _Element('#-1'),
            _Element('#0'),
            _Element('#1'),
          ];
          final expected =
              BuiltList.of(List.generate(22, (i) => _Element('#${i - 2}')));

          final subject = createTestSubject();
          await _FetchedFixture(subject).prepare();
          subject.prependAll(given);

          expect(
            subject.state(),
            emitsThrough(predicate<FetchedState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );

      test(
        'prepends the cutoff non-duplicate tail, case 2',
        () async {
          const given = [
            _Element('#-5'),
            _Element('#-4'),
            _Element('#-3'),
            _Element('#-2'),
            _Element('#-1'),
            _Element('#0'),
            _Element('#1'),
            _Element('#2'),
            _Element('#3'),
          ];
          final expected =
              BuiltList.of(List.generate(25, (i) => _Element('#${i - 5}')));

          final subject = createTestSubject();
          await _FetchedFixture(subject).prepare();
          subject.prependAll(given);

          expect(
            subject.state(),
            emitsThrough(predicate<FetchedState<_Element, String>>(
                (e) => e.current == expected)),
          );
        },
        timeout: const Timeout(Duration(seconds: 1)),
      );
    },
  );
}

@immutable
class _Element {
  const _Element(this.name);

  final String name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _Element && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'PagedSubject(name: $name)';
}

class _ContinuousElementGateway implements PagedGateway<_Element, String> {
  const _ContinuousElementGateway({int multiplier = 1, this.metadata})
      : _multiplier = multiplier;

  @override
  Future<Page<_Element>> get(Query<String> query) async {
    return (
      List.generate(
        query.size,
        (i) => _Element('#${query.start + i * _multiplier}'),
      ),
      metadata,
    );
  }

  final int _multiplier;
  final Map<String, Object?>? metadata;
}

class _ErrorElementGateway implements PagedGateway<_Element, String> {
  const _ErrorElementGateway();

  @override
  Future<Page<_Element>> get(Query<String> query) async {
    return throw Exception();
  }
}

class _NonReturningElementGateway implements PagedGateway<_Element, String> {
  const _NonReturningElementGateway();

  @override
  Future<Page<_Element>> get(Query<String> query) async {
    return Completer<Page<_Element>>().future;
  }
}

class _DelegatingElementGateway implements PagedGateway<_Element, String> {
  const _DelegatingElementGateway(this._delegate);

  @override
  Future<Page<_Element>> get(Query<String> query) async {
    return _delegate(query);
  }

  final Future<Page<_Element>> Function(Query<String> query) _delegate;
}

class _IncrementalDelegatingElementGateway
    implements PagedGateway<_Element, String> {
  _IncrementalDelegatingElementGateway(this._delegate);

  @override
  Future<Page<_Element>> get(Query<String> query) async {
    return _delegate(_count++, query);
  }

  var _count = 0;
  final Future<Page<_Element>> Function(int, Query<String> query) _delegate;
}

class _FetchedFixture implements Fixture {
  const _FetchedFixture(this._subject);

  @override
  Future<void> prepare() async {
    await _subject
        .state()
        .firstWhere((e) => switch (e) { FetchedState() => true, _ => false });
  }

  final PagedBloc<dynamic, dynamic> _subject;
}

class _ErrorFixture implements Fixture {
  const _ErrorFixture(this._subject);

  @override
  Future<void> prepare() async {
    await _subject
        .state()
        .firstWhere((e) => switch (e) { ErrorState() => true, _ => false });
  }

  final PagedBloc<dynamic, dynamic> _subject;
}

class _PagedFixture implements Fixture {
  const _PagedFixture(this._subject);

  @override
  Future<void> prepare() async {
    await _FetchedFixture(_subject).prepare();
    _subject.page();
  }

  final PagedBloc<dynamic, dynamic> _subject;
}
