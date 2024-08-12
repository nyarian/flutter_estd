typedef Producer<T> = T Function();

typedef Consumer<T> = void Function(T);

typedef Transformation<T, R> = R Function(T);

typedef Predicate<T> = bool Function(T);

T identity<T>(T e) => e;

T Function(Object) returns<T>(T o) => (_) => o;

// ignore: only_throw_errors
T rethrows<T>(Object e) => throw e;

void emptyAction() {}

bool Function(T) equalTo<T>(T element) => (e) => e == element;
