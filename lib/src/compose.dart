import 'dart:async';
import 'types.dart';

Middleware<T> compose<T>(List<Middleware<T>> middlewares) {
  return (T context, NextMiddleware next) {
    var lastIndex = -1;

    Future<dynamic> nextDispatch(int index) {
      if (index <= lastIndex) {
        return Future.error(Exception('next() called multiple times'));
      }

      lastIndex = index;

      final middleware =
          middlewares.length != index ? middlewares[index] : next;

      if (middleware == null) {
        return Future.value();
      }

      try {
        return Future.value(
          middleware is Middleware<T>
              ? middleware(context, () {
                  return nextDispatch(index + 1);
                })
              : middleware(),
        );
      } catch (e) {
        return Future.error(e);
      }
    }

    return nextDispatch(0);
  };
}
