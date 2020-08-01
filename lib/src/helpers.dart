import 'types.dart';

Future<bool> wrapMiddlewareNextCall<T>(
  T context,
  Middleware<T> middleware,
) async {
  var called = false;

  await middleware(context, () async {
    if (called) {
      throw Exception('next() called multiple times');
    }

    called = true;
  });

  return called;
}

/// Noop for call `next()` in middleware
Future<void> noopNext() => Future.value();
