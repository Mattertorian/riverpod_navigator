import 'package:doc/async.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_navigator_core/riverpod_navigator_core.dart';
import 'package:test/test.dart';

ProviderContainer createContainer() {
  final res = ProviderContainer(overrides: providerOverrides([HomeSegment()], AppNavigator.new));
  addTearDown(res.dispose);
  return res;
}

void main() {
  test('navigation test', () async {
    final container = createContainer();
    final start = DateTime.now();
    final navigator = container.read(navigatorProvider) as AppNavigator;

    Future navigTest(Future action(), String expected) async {
      await action();
      print('${DateTime.now().difference(start).inMilliseconds} msec ($expected)');
      await container.pump();
      expect(navigator.navigationStack2Url, expected);
    }

    await navigTest(
      navigator.toHome().onPressed,
      'home',
    );

    await navigTest(
      navigator.toBook(id: 1).onPressed,
      'home/page;id=1',
    );

    await navigTest(
      navigator.popPath().onPressed,
      'home',
    );

    await navigTest(
      navigator.pushPath(BookSegment(id: 2)).onPressed,
      'home/page;id=2',
    );

    await navigTest(
      navigator.replaceLastPath((_) => BookSegment(id: 3)).onPressed,
      'home/page;id=3',
    );

    await navigTest(
      navigator.toNextBook().onPressed,
      'home/page;id=4',
    );

    return;
  });
}
