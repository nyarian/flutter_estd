abstract interface class Fixture {
  Future<void> prepare();

  static Future<void> sequence(Iterable<Fixture> fixtures) async {
    await for (final fixture in Stream.fromIterable(fixtures)) {
      await fixture.prepare();
    }
  }
}
