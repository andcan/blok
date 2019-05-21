import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

/// Takes a [Stream] of [Actions]s as input
/// and transforms them into a [Stream] of [State]s as output.
abstract class Bloc<State, Action> {
  final PublishSubject<Action> _actionsSubject = PublishSubject<Action>();

  BehaviorSubject<State> _stateSubject;

  Bloc() {
    assert(null != initialState, 'initialState should not be null');
    _stateSubject = BehaviorSubject<State>.seeded(initialState);
    transform(_actionsSubject.stream).handleError(onError)
        .where((nextState) => currentState != nextState)
        .forEach(_stateSubject.add);
  }

  @protected
  @visibleForTesting
  Sink<Action> get actions => _actionsSubject.sink;

  /// Returns the current [State] of the [Bloc].
  State get currentState => _stateSubject.value;

  /// Returns the [State] before any [Action]s have been `dispatched`.
  State get initialState;

  /// Returns [Stream] of [State]s.
  /// Consumed by the presentation layer.
  @protected
  @visibleForTesting
  ValueObservable<State> get state => _stateSubject.stream;

  /// Closes the [Action] and [State] [Stream]s.
  /// This method should be called when a [Bloc] is no longer needed.
  /// Once `dispose` is called, actions that are `dispatched` will not be
  /// processed and will result in an error being passed to `onError`.
  @mustCallSuper
  void dispose() {
    _actionsSubject.close();
    _stateSubject.close();
  }

  /// Called whenever an [Exception] is thrown within `map`.
  /// By default all exceptions will be ignored and [Bloc] functionality will be unaffected.
  /// The stacktrace argument may be `null` if the state stream received an error without a [StackTrace].
  /// A great spot to handle exceptions at the individual [Bloc] level.
  void onError(Object error, StackTrace stacktrace) => null;

  /// Transforms the `Observable<Action>` into a `Stream<State>`.
  Stream<State> transform(Observable<Action> actions);
}
