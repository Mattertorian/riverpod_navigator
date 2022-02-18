import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:riverpod_navigator/riverpod_navigator.dart';
import 'package:riverpod_navigator_core/riverpod_navigator_core.dart';

part 'async.g.dart';
part 'async.freezed.dart';

void main() => runApp(
      ProviderScope(
        overrides: RNavigatorCore.providerOverrides([HomeSegment()], AppNavigator.new),
        child: const App(),
      ),
    );

@Freezed(maybeWhen: false, maybeMap: false)
class Segments with _$Segments, TypedSegment {
  Segments._();
  factory Segments.home() = HomeSegment;
  factory Segments.page({required int id}) = PageSegment;

  factory Segments.fromJson(Map<String, dynamic> json) => _$SegmentsFromJson(json);
}

extension WidgetRefApp on WidgetRef {
  AppNavigator get navigator => read(riverpodNavigatorProvider) as AppNavigator;
}

extension ProviderContainerApp on ProviderContainer {
  AppNavigator get navigator => read(riverpodNavigatorProvider) as AppNavigator;
}

class AppNavigator extends RNavigator {
  AppNavigator(Ref ref)
      : super(
          ref,
          [
            RRoutes<Segments>(Segments.fromJson, [
              RRoute<HomeSegment>(
                HomeScreen.new,
                opening: (newSegment) => simulateAsyncResult('Home.creating', 2000),
              ),
              RRoute<PageSegment>(
                PageScreen.new,
                opening: (newSegment) => simulateAsyncResult('Page.creating', 400),
                replacing: (oldSegment, newSegment) => simulateAsyncResult('Page.merging', 200),
                closing: null,
              ),
            ])
          ],
          splashBuilder: () => SplashScreen(),
        );

  /// navigate to page
  Future toPage({required int id}) => navigate([HomeSegment(), PageSegment(id: id)]);

  /// navigate to next page
  Future toNextPage() => replaceLast<PageSegment, PageSegment>((old) => PageSegment(id: old.id + 1));

  /// navigate to home
  Future toHome() => navigate([HomeSegment()]);
}

@cwidget
Widget app(WidgetRef ref) => MaterialApp.router(
      title: 'Riverpod Navigator Example',
      routerDelegate: ref.navigator.routerDelegate,
      routeInformationParser: ref.navigator.routeInformationParser,
      debugShowCheckedModeBanner: false,
    );

// simulates an action such as loading external data or saving to external storage
Future<String> simulateAsyncResult(String asyncResult, int msec) async {
  await Future.delayed(Duration(milliseconds: msec));
  return '$asyncResult: async result after $msec msec';
}

@cwidget
Widget homeScreen(WidgetRef ref, HomeSegment segment) => PageHelper<AppNavigator>(
      segment: segment,
      title: 'Home',
      buildChildren: (navigator) => [
        ElevatedButton(
          onPressed: () => navigator.navigate([HomeSegment(), PageSegment(id: 1)]),
          child: const Text('Go to page'),
        ),
      ],
    );

@cwidget
Widget pageScreen(WidgetRef ref, PageSegment segment) => PageHelper<AppNavigator>(
      segment: segment,
      title: 'Page ${segment.id}',
      buildChildren: (navigator) => [
        ElevatedButton(
          onPressed: () => navigator.navigate([HomeSegment()]),
          child: const Text('Go to home'),
        ),
      ],
    );

@cwidget
Widget pageHelper<N extends RNavigator>(
  WidgetRef ref, {
  required TypedSegment segment,
  required String title,
  required List<Widget> buildChildren(N navigator),
}) {
  final navigator = ref.navigator as N;
  return Scaffold(
    appBar: AppBar(
      title: Text(title),
    ),
    body: Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: (() {
          final res = <Widget>[SizedBox(height: 20)];
          for (final w in buildChildren(navigator)) res.addAll([w, SizedBox(height: 20)]);
          res.addAll([SizedBox(height: 20), Text('Dump actual typed-path: "${navigator.debugSegmentSubpath(segment)}"')]);
          if (segment.asyncActionResult != null) res.addAll([SizedBox(height: 20), Text('Async result: "${segment.asyncActionResult}"')]);
          return res;
        })(),
      ),
    ),
  );
}

@swidget
Widget splashScreen() =>
    SizedBox.expand(child: Container(color: Colors.white, child: Center(child: Icon(Icons.hourglass_full, size: 150, color: Colors.deepPurple))));
