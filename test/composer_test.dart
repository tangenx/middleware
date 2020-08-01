import 'package:middleware/middleware.dart';
import 'package:test/test.dart';

class Context {
  DateTime now;
}

class AnotherContext {
  String test = 'test';
}

class CloneContext {
  CloneContext(this.value);

  bool baseBalue;
  String value;
}

final delayDuration = Duration(milliseconds: 1);

void main() {
  group('Composer', () {
    test('should work', () async {
      final out = <int>[];

      final composer = Composer();

      composer.use((context, next) async {
        out.add(1);

        await Future.delayed(delayDuration);
        await next();
        await Future.delayed(delayDuration);

        out.add(6);
      });

      composer.use((context, next) async {
        out.add(2);

        await Future.delayed(delayDuration);
        await next();
        await Future.delayed(delayDuration);

        out.add(5);
      });

      composer.use((context, next) async {
        out.add(3);

        await Future.delayed(delayDuration);
        await next();
        await Future.delayed(delayDuration);

        out.add(4);
      });

      final middleware = composer.composeMiddlewares();

      await middleware(out, noopNext);

      expect(out, equals([1, 2, 3, 4, 5, 6]));
    });

    test('should keep the context', () async {
      final context = {};

      final composer = Composer();

      composer.use((context, next) async {
        await next();

        expect(context, equals(context));
      });

      composer.use((context, next) async {
        await next();

        expect(context, equals(context));
      });

      composer.use((context, next) async {
        await next();

        expect(context, equals(context));
      });

      final middleware = composer.composeMiddlewares();

      await middleware(context, noopNext);
    });

    test('should work with 0 middleware', () async {
      final middleware = (Composer()).composeMiddlewares();

      await middleware({}, noopNext);
    });

    test('should reject on errors in middleware', () async {
      final context = Context();

      final composer = Composer<Context>();

      composer.use((context, next) async {
        context.now = DateTime.now();

        await next();
      });

      composer.use((context, next) async {
        throw Exception();
      });

      final middleware = composer.composeMiddlewares();

      try {
        await middleware(context, noopNext);
      } catch (e) {
        expect(e, isA<Exception>());

        return;
      }
    });

    test('should be cloned', () async {
      final baseComposer = Composer<CloneContext>();

      baseComposer.use((context, next) {
        context.baseBalue = true;

        return next();
      });

      final firstComposer = baseComposer.clone().use((context, next) {
        context.value = 'first';

        return next();
      });

      final secondComposer = baseComposer.clone().use((context, next) {
        context.value = 'second';

        return next();
      });

      final baseContext = CloneContext('default');
      final firstContext = CloneContext('default');
      final secondContext = CloneContext('default');

      await baseComposer.composeMiddlewares()(baseContext, noopNext);
      await firstComposer.composeMiddlewares()(firstContext, noopNext);
      await secondComposer.composeMiddlewares()(secondContext, noopNext);

      expect(baseContext.value, equals('default'));
      expect(baseContext.baseBalue, equals(true));

      expect(firstContext.value, equals('first'));
      expect(firstContext.baseBalue, equals(true));

      expect(secondContext.value, equals('second'));
      expect(secondContext.baseBalue, equals(true));
    });

    test('should correctly display the number of middleware', () {
      final composer = Composer();

      expect(composer.length, equals(0));

      composer.tap((context, next) {});

      expect(composer.length, equals(1));

      composer.tap((context, next) {});

      expect(composer.length, equals(2));
    });

    test('should create new instance of the Composer class', () {
      final composer = Composer.builder<AnotherContext>();

      composer.use((context, next) {
        if (context.test == 'test') {
          // ...
        }
      });

      expect(composer.length, equals(1));
      expect(composer, isA<Composer>());
    });

    test('should throw if next() is called multiple times', () async {
      final composer = Composer();

      composer.use((context, next) async {
        await next();
      });

      composer.use((context, next) async {
        await next();
        await next();
      });

      composer.use((context, next) async {
        await next();
      });

      final middleware = composer.composeMiddlewares();

      try {
        await middleware({}, noopNext);
      } catch (e) {
        expect(e.toString(), contains('multiple times'));
      }
    });
  });
}
