import 'dart:async';

/// Basic middleware
typedef Middleware<T> = dynamic Function(
  T context,
  NextMiddleware next,
);

///Call the next middleware from the chain
typedef NextMiddleware = Future<dynamic> Function();

/// Asynchronous function for branch condition
typedef BranchMiddlewareConditionFunction<T> = FutureOr<bool> Function(
  T context,
);

///Check possible types for branch condition
void BranchMiddlewareCondition<T>(condition) {
  assert(
    condition is bool || condition is BranchMiddlewareConditionFunction<T>,
  );
}

///Asynchronous factory to create middleware
typedef LazyMiddlewareFactory<T> = FutureOr<Middleware<T>> Function(T context);

///Handler for catching errors in middleware chains
typedef CaughtMiddlewareHandler<T> = dynamic Function(
  T context,
  Exception error,
);
