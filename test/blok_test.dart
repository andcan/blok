import 'package:blok/blok.dart';
import 'package:test/test.dart';

void main() {
  test('state is updated', () async {
    final bloc = IncrementBloc();

    expect(bloc.state.value, equals(0));

    expect(bloc.state, emitsInOrder([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]));

    for (int i = 0; i < 10; i++) {
      bloc.actions.add(null);
    }
  });

  test('cannot add actions after dispose', () {
    final bloc = IncrementBloc();
    bloc.dispose();

    expect(() {
      bloc.actions.add(null);
    }, throwsStateError);
  });

  test('cannot create a bloc with null initial state', () {
    expect(
        () => NullInitialStateBloc(), throwsA(TypeMatcher<AssertionError>()));
  });
}

class IncrementBloc extends Bloc<int, void> {
  @override
  int get initialState => 0;

  @override
  Stream<int> map(void action) async* {
    yield currentState + 1;
  }
}

class NullInitialStateBloc extends Bloc<void, void> {
  @override
  void get initialState => null;

  @override
  Stream<void> map(void action) async* {}
}
