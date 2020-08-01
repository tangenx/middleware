import 'package:middleware/middleware.dart';
import 'package:test/test.dart';

class Context {
  DateTime now;
}

final delayDuration = Duration(milliseconds: 1);

void main() {
  group('compose', () {
    test('should work', () async {
      final out = <int>[];

      final middleware = compose([
        (ctx, next) async {
          out.add(1);

          await Future.delayed(delayDuration);
          await next();
          await Future.delayed(delayDuration);

          out.add(6);
        },
        (ctx, next) async {
          out.add(2);

          await Future.delayed(delayDuration);
          await next();
          await Future.delayed(delayDuration);

          out.add(5);
        },
        (ctx, next) async {
          out.add(3);

          await Future.delayed(delayDuration);
          await next();
          await Future.delayed(delayDuration);

          out.add(4);
        }
      ]);

      await middleware(out, noopNext);

      expect(out, equals([1, 2, 3, 4, 5, 6]));
    });

    test('should keep the context', () async {
      final context = {};

      final middleware = compose([
        (ctx, next) async {
          await next();

          expect(ctx, equals(context));
        },
        (ctx, next) async {
          await next();

          expect(ctx, equals(context));
        },
        (ctx, next) async {
          await next();

          expect(ctx, equals(context));
        }
      ]);

      await middleware(context, noopNext);
    });

    test('should work with 0 middleware', () async {
      final middleware = compose<Object>([]);

      await middleware({}, noopNext);
    });

    test('should reject on errors in middleware', () async {
      final context = Context();

      final middleware = compose<Context>([
        (ctx, next) async {
          ctx.now = DateTime.now();

          await next();
        },
        (ctx, next) async {
          throw Exception();
        }
      ]);

      try {
        await middleware(context, noopNext);
      } catch (e) {
        expect(e, isA<Exception>());

        return;
      }
    });

    test('should throw if next() is called multiple times', () async {
      final middleware = compose([
        (ctx, next) async {
          await next();
        },
        (ctx, next) async {
          await next();
          await next();
        },
        (ctx, next) async {
          await next();
        }
      ]);

      try {
        await middleware({}, noopNext);
      } catch (e) {
        expect(e.toString(), contains('multiple times'));

        return;
      }
    });
  });
}
