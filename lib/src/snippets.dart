import 'helpers.dart';
import 'types.dart';
import 'dart:async';

///Call `next()` in middleware
Future<dynamic> skipMiddleware<T>(T context, FutureOr<void> Function() next) {
  return next();
}

///Does not call `next()` in middleware
Future<void> stopMiddleware<T>(T context, FutureOr<void> Function() next) {
  return Future.value();
}

///Lazily asynchronously gets middleware
///
///Example:
///
///```dart
///getLazyMiddleware((context) async {
///   Future<Function> route = await getSomeRoute(context.path);
///
///   return route;
///});
///```
Middleware<T> getLazyMiddleware<T>(LazyMiddlewareFactory<T> middlewareFactory) {
  Middleware<T> middleware;

  return (T context, FutureOr<void> Function() next) async {
    middleware ??= await middlewareFactory(context);

    return middleware(context, next);
  };
}

///Runs the middleware and force call `next()`
///
///Example:
///
///```dart
///getTapMiddleware((context) => print('Context: $context'));
///```
Middleware<T> getTapMiddleware<T>(Middleware<T> middleware) {
  return (T context, FutureOr<void> Function() next) async {
    await middleware(context, noopNext);

    return next();
  };
}

///Runs the middleware at the next event loop and force call `next()`
///
///Example:
///
///```dart
///getForkMiddleware((context) => statisticsMiddlewares(context).catchError(print));
///```
Middleware<T> getForkMiddleware<T>(Middleware<T> middleware) {
  return (T context, FutureOr<void> Function() next) {
    Future.sync(middleware(context, noopNext));

    return next();
  };
}

///By condition splits the middleware
///
///Example:
///
///```dart
///getBranchMiddleware(
///   (context) => context.type == 'json',
///   myBodyParser.json(),
///   myBodyParser.urlencoded(),
///);
///```
///
///Static condition
///
///```dart
///getBranchMiddleware(
///   String.fromEnvironment('SOME_VAR') == 'SOME_VALUE',
///   logger.loggedContextToFile(),
///   logger.loggedContextToConsole(),
///);
///```
Middleware<T> getBranchMiddleware<T>(
  condition,
  Middleware<T> trueMiddleware,
  Middleware<T> falseMiddleware,
) {
  BranchMiddlewareCondition(condition);

  if (condition is! Function) {
    return condition ? trueMiddleware : falseMiddleware;
  }

  return (T context, FutureOr<void> Function() next) async {
    await condition(context)
        ? trueMiddleware(context, next)
        : falseMiddleware(context, next);
  };
}

///Conditionally runs optional middleware or skips middleware
///
///Example:
///
///```dart
///getOptionalMiddleware(
///   (context) => context.user.isAdmin,
///   addFieldsForAdmin,
///);
///```
Middleware<T> getOptionalMiddleware<T>(
  condition,
  Middleware<T> optionalMiddleware,
) {
  BranchMiddlewareCondition(condition);

  return getBranchMiddleware(
    condition,
    optionalMiddleware,
    skipMiddleware,
  );
}

///Conditionally runs middleware or stops the chain
///
///Example:
///
///```dart
///getFilterMiddleware(
///   (context) => context.authorized,
///   middlewareForAuthorized,
///);
///```
Middleware<T> getFilterMiddleware<T>(
  condition,
  Middleware<T> filterMiddleware,
) {
  BranchMiddlewareCondition(condition);

  return getBranchMiddleware(
    condition,
    filterMiddleware,
    stopMiddleware,
  );
}

///Runs the second middleware before the main
///
///Example:
///
///```dart
///getBeforeMiddleware(
///   myMockMiddleware,
///   outputUserData,
///);
///```
Middleware<T> getBeforeMiddleware<T>(
  Middleware<T> beforeMiddleware,
  Middleware<T> middleware,
) {
  return (T context, FutureOr<void> Function() next) async {
    var called = await wrapMiddlewareNextCall(context, beforeMiddleware);

    if (called) {
      return middleware(context, next);
    }
  };
}

///Runs the second middleware after the main
///
///Example:
///
///```dart
///getAfterMiddleware(
///   sendSecureData,
///   clearSecurityData,
///);
///```
Middleware<T> getAfterMiddleware<T>(
  Middleware<T> middleware,
  Middleware<T> afterMiddleware,
) {
  return (T context, FutureOr<void> Function() next) async {
    var called = await wrapMiddlewareNextCall(context, middleware);

    if (called) {
      return afterMiddleware(context, next);
    }
  };
}

///Runs middleware before and after the main
///
///Example:
///
///```dart
///getEnforceMiddleware(
///   prepareData,
///   sendData,
///   clearData
///);
///```
Middleware<T> getEnforceMiddleware<T>(
  Middleware<T> beforeMiddleware,
  Middleware<T> middleware,
  Middleware<T> afterMiddleware,
) {
  return (T context, FutureOr<void> Function() next) async {
    var beforeCalled = await wrapMiddlewareNextCall(context, beforeMiddleware);

    if (!beforeCalled) {
      return;
    }

    var middlewareCalled = await wrapMiddlewareNextCall(context, middleware);

    if (!middlewareCalled) {
      return;
    }

    return afterMiddleware(context, next);
  };
}

///Catches errors in the middleware chain
///
///Example:
///
///```dart
///getCaughtMiddleware((context, error) {
///   if (error is HttpException) {
///     return context.send('Sorry, network issues 😔');
///   }
///
///   throw error;
///});
///```
///
///Without a snippet, it would look like this:
///
///```dart
///(context, next) async {
///   try {
///     await next();
///   } catch (e) {
///     if (e is HttpException) {
///       return context.send('Sorry, network issues 😔');
///     }
///
///     rethrow e;
///   }
///}
///```
Middleware<T> getCaughtMiddleware<T>(
  CaughtMiddlewareHandler<T> errorHandler,
) {
  return (T context, FutureOr<void> Function() next) async {
    try {
      await next();
    } catch (e) {
      return errorHandler(context, e);
    }
  };
}

///Concurrently launches middleware, the chain will continue if `next()` is called in all middlewares.
///
///**Warning: Error interrupts all others**
///
///Example:
///
///```dart
///getConcurrencyMiddleware([
///   initializeUser,
///   initializeSession,
///   initializeDatabase,
///]);
///```
Middleware<T> getConcurrencyMiddleware<T>(List<Middleware<T>> middlewares) {
  return (T context, FutureOr<void> Function() next) async {
    var concurrencies = await Future.wait(
      middlewares
          .map((middleware) => wrapMiddlewareNextCall(context, middleware)),
    );

    if (concurrencies.every((element) => element is bool)) {
      return next();
    }
  };
}
