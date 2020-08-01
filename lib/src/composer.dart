import 'snippets.dart';
import 'types.dart';
import 'compose.dart';

///A simple middleware compose builder
class Composer<T extends Object> {
  List<Middleware<T>> _middlewares = [];

  ///Invokes a new instance of the Composer class
  static Composer<Context> builder<Context extends Object>() {
    return Composer<Context>();
  }

  ///The number of middleware installed in Composer
  int get length {
    return _middlewares.length;
  }

  ///Clones a composer object
  Composer<T> clone() {
    var composer = Composer<T>();

    composer._middlewares = [..._middlewares];

    return composer;
  }

  ///Adds middleware to the chain
  Composer<T> use(Middleware<T> middleware) {
    _middlewares.add(middleware);

    return this;
  }

  ///Lazily asynchronously gets middleware
  Composer<T> lazy(LazyMiddlewareFactory<T> middlewareFactory) {
    return use(
      getLazyMiddleware<T>(middlewareFactory),
    );
  }

  ///Runs the middleware and force call `next()`
  Composer<T> tap(Middleware<T> middleware) {
    return use(
      getTapMiddleware<T>(middleware),
    );
  }

  ///Runs the middleware at the next event loop and force call `next()`
  Composer<T> fork(Middleware<T> middleware) {
    return use(
      getForkMiddleware<T>(middleware),
    );
  }

  ///By condition splits the middleware
  Composer<T> branch(
    condition,
    Middleware<T> trueMiddleware,
    Middleware<T> falseMiddleware,
  ) {
    return use(
      getBranchMiddleware<T>(
        condition,
        trueMiddleware,
        falseMiddleware,
      ),
    );
  }

  ///Conditionally runs optional middleware or skips middleware
  Composer<T> optional(
    condition,
    Middleware<T> optionalMiddleware,
  ) {
    return use(
      getOptionalMiddleware<T>(
        condition,
        optionalMiddleware,
      ),
    );
  }

  ///Conditionally runs middleware or stops the chain
  Composer<T> filter(
    condition,
    Middleware<T> filterMiddleware,
  ) {
    return use(
      getFilterMiddleware<T>(
        condition,
        filterMiddleware,
      ),
    );
  }

  ///Runs the second middleware before the main
  Composer<T> before(
    Middleware<T> beforeMiddleware,
    Middleware<T> middleware,
  ) {
    return use(
      getBeforeMiddleware<T>(
        beforeMiddleware,
        middleware,
      ),
    );
  }

  ///Runs the second middleware after the main
  Composer<T> after(
    Middleware<T> middleware,
    Middleware<T> afterMiddleware,
  ) {
    return use(
      getAfterMiddleware<T>(
        middleware,
        afterMiddleware,
      ),
    );
  }

  ///Runs middleware before and after the main
  Composer<T> enforce(
    Middleware<T> beforeMiddleware,
    Middleware<T> middleware,
    Middleware<T> afterMiddleware,
  ) {
    return use(
      getEnforceMiddleware<T>(
        beforeMiddleware,
        middleware,
        afterMiddleware,
      ),
    );
  }

  ///Catches errors in the middleware chain
  Composer<T> caught(CaughtMiddlewareHandler<T> errorHandler) {
    return use(
      getCaughtMiddleware<T>(errorHandler),
    );
  }

  ///Concurrently launches middleware, the chain will continue if `next()` is called in all middlewares
  Composer<T> concurrency(List<Middleware<T>> middlewares) {
    return use(
      getConcurrencyMiddleware<T>(middlewares),
    );
  }

  ///Compose middleware handlers into a single handler
  Middleware<T> composeMiddlewares() {
    return compose<T>([..._middlewares]);
  }
}
