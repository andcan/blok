import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

/// Takes a [Stream] of [Actions]s as input
/// and transforms them into a [Stream] of [State]s as output.
abstract class Bloc<State, Action> {
  final PublishSubject<Action> _actionsSubject = PublishSubject<Action>();

  BehaviorSubject<State> _stateSubject;

  /// Returns [Stream] of [State]s.
  /// Consumed by the presentation layer.
  ValueObservable<State> get state => _stateSubject.stream;

  /// Returns the [State] before any [Action]s have been `dispatched`.
  State get initialState;

  /// Returns the current [State] of the [Bloc].
  State get currentState => _stateSubject.value;

  Bloc() {
    assert(null != initialState, 'initialState should not be null');
    _stateSubject = BehaviorSubject<State>.seeded(initialState);
    transform(
            _actionsSubject,
            (Action action) =>
                Observable<State>(map(action)).handleError(onError))
        .where((nextState) => currentState != nextState)
        .forEach(_stateSubject.add);
  }

  Sink<Action> get actions => _actionsSubject.sink;

  /// Called whenever an [Exception] is thrown within `map`.
  /// By default all exceptions will be ignored and [Bloc] functionality will be unaffected.
  /// The stacktrace argument may be `null` if the state stream received an error without a [StackTrace].
  /// A great spot to handle exceptions at the individual [Bloc] level.
  void onError(Object error, StackTrace stacktrace) => null;

  /// Closes the [Action] and [State] [Stream]s.
  /// This method should be called when a [Bloc] is no longer needed.
  /// Once `dispose` is called, actions that are `dispatched` will not be
  /// processed and will result in an error being passed to `onError`.
  @mustCallSuper
  void dispose() {
    _actionsSubject.close();
    _stateSubject.close();
  }

  /// Transforms the `Stream<Action>` along with a `next` function into a `Stream<State>`.
  /// Actions that should be processed by `map` need to be passed to `next`.
  /// By default `asyncExpand` is used to ensure all actions are processed in the order
  /// in which they are received. You can override `transform` for advanced usage
  /// in order to manipulate the frequency and specificity with which `map`
  /// is called as well as which actions are processed.
  ///
  /// For example, if you only want `map` to be called on the most recent
  /// action you can use `switchMap` instead of `asyncExpand`.
  ///
  /// ```dart
  /// @override
  /// Stream<State> transform(actions, next) {
  ///   return (actions as Observable<Action>).switchMap(next);
  /// }
  /// ```
  ///
  /// Alternatively, if you only want `map` to be called for distinct actions:
  ///
  /// ```dart
  /// @override
  /// Observable<State> transform(actions, next) {
  ///   return super.transform(
  ///     (actions as Observable<Action>).distinct(),
  ///     next,
  ///   );
  /// }
  /// ```
  Observable<State> transform(
    Observable<Action> actions,
    Observable<State> next(Action event)
  ) =>
      actions.asyncExpand(next);

  /// Takes the incoming `action` as the argument.
  /// `map` is called whenever an [Action] is added by the presentation layer.
  /// `map` must convert that [Action] into a new [State]
  /// and return the new [State] in the form of a [Stream] which is consumed by the presentation layer.
  Stream<State> map(Action action);
}
