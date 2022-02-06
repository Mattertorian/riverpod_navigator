// ignore: unused_import
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:riverpod_navigator/riverpod_navigator.dart';

import 'screens.dart';

part 'lesson04.freezed.dart';
part 'lesson04.g.dart';

// *************************************
// Example04
// - introduction route concept
// *************************************
//
// *** 1. classes for typed path segments (TypedSegment)

@freezed
class AppSegments with _$AppSegments, TypedSegment {
  AppSegments._();
  factory AppSegments.home() = HomeSegment;
  factory AppSegments.books() = BooksSegment;
  factory AppSegments.book({required int id}) = BookSegment;

  factory AppSegments.fromJson(Map<String, dynamic> json) => _$AppSegmentsFromJson(json);
}

@Freezed(unionKey: LoginSegments.jsonNameSpace)
class LoginSegments with _$LoginSegments, TypedSegment {
  /// json serialization hack: must be at least two constructors
  factory LoginSegments() = _LoginSegments;
  LoginSegments._();
  factory LoginSegments.home({String? loggedUrl, String? canceledUrl}) = LoginHomeSegment;

  factory LoginSegments.fromJson(Map<String, dynamic> json) => _$LoginSegmentsFromJson(json);
  static const String jsonNameSpace = '_login';
}

// *** 1.1.

abstract class AppRoute<T extends TypedSegment> extends TypedRoute<T> {
  bool needsLogin(T segment) => false;
}

class HomeRoute extends AppRoute<HomeSegment> {
  @override
  Widget screenBuilder(HomeSegment segment) => HomeScreen(segment);
  @override
  Future<void>? creating(HomeSegment newPath) => _simulateAsyncResult('Home creating async result after 1 sec', 1000);
}

class BooksRoute extends AppRoute<BooksSegment> {
  @override
  Widget screenBuilder(BooksSegment segment) => BooksScreen(segment);
}

class BookRoute extends AppRoute<BookSegment> {
  @override
  Widget screenBuilder(BookSegment segment) => BookScreen(segment);

  @override
  Future<void>? creating(BookSegment newPath) => _simulateAsyncResult('Book creating async result after 1 sec', 1000);
  @override
  Future<void>? merging(oldPath, BookSegment newPath) =>
      newPath.id.isOdd ? _simulateAsyncResult('Book merging async result after 500 msec', 500) : null;
  @override
  Future<void>? deactivating(BookSegment oldPath) => oldPath.id.isEven ? _simulateAsyncResult('', 500) : null;

  @override
  bool needsLogin(BookSegment segment) => segment.id.isOdd;
}

class LoginHomeRoute extends TypedRoute<LoginHomeSegment> {
  @override
  Widget screenBuilder(LoginHomeSegment segment) => LoginHomeScreen(segment);
}

class AppRouteGroup extends RouteGroup<AppSegments> {
  @override
  AppSegments json2Segment(JsonMap jsonMap) => AppSegments.fromJson(jsonMap);

  @override
  TypedRoute segment2Route(AppSegments segment) => segment.map(home: (_) => homeRoute, books: (_) => booksRoute, book: (_) => bookRoute);

  final homeRoute = HomeRoute();
  final booksRoute = BooksRoute();
  final bookRoute = BookRoute();
}

class LoginRouteGroup extends RouteGroup<LoginSegments> {
  @override
  LoginSegments json2Segment(JsonMap jsonMap) => LoginSegments.fromJson(jsonMap);

  @override
  TypedRoute segment2Route(LoginSegments segment) => segment.map((value) => throw UnimplementedError(), home: (_) => loginHomeRoute);

  final loginHomeRoute = LoginHomeRoute();
}

class AppRouter extends TypedRouter {
  AppRouter() : super([AppRouteGroup(), LoginRouteGroup()]);

  bool needsLogin() => false;
}

Future<String> _simulateAsyncResult(String title, int msec) async {
  await Future.delayed(Duration(milliseconds: msec));
  return title;
}

// *** 2. App-specific navigator with navigation aware actions (used in screens)

/// the navigation state also depends on the following [userIsLoggedProvider]
final userIsLoggedProvider = StateProvider<bool>((_) => false);

const booksLen = 5;

class AppNavigator extends RiverpodNavigator {
  AppNavigator(Ref ref)
      : super(
          ref,
          dependsOn: [userIsLoggedProvider],
          initPath: [HomeSegment()],
          router: AppRouter(), // <========================
        );

  /// mark screens which needs login: every 'id.isOdd' book needs it
  bool needsLogin(TypedSegment segment) => (router as AppRouter).needsLogin();

  @override
  FutureOr<void> appNavigationLogic(Ref ref, TypedPath currentPath) {
    final userIsLogged = ref.read(userIsLoggedProvider);
    final ongoingNotifier = ref.read(ongoingPathProvider.notifier);

    if (!userIsLogged) {
      final pathNeedsLogin = ongoingNotifier.state.any((segment) => needsLogin(segment));

      // login needed => redirect to login page
      if (pathNeedsLogin) {
        // parametters for login screen
        final loggedUrl = pathParser.typedPath2Path(ongoingNotifier.state);
        var canceledUrl = currentPath.isEmpty || currentPath.last is LoginHomeSegment ? '' : pathParser.typedPath2Path(currentPath);
        // chance to exit login loop
        if (loggedUrl == canceledUrl) canceledUrl = '';
        // redirect to login screen
        ongoingNotifier.state = [LoginHomeSegment(loggedUrl: loggedUrl, canceledUrl: canceledUrl)];
      }
    } else {
      // user logged and navigation to Login page => redirect to home
      if (ongoingNotifier.state.isEmpty || ongoingNotifier.state.last is LoginHomeSegment) ongoingNotifier.state = [HomeSegment()];
    }
    // here can be async action for <oldPath, ongoingNotifier.state> pair
    return null;
  }

  Future<void> toHome() => navigate([HomeSegment()]);
  Future<void> toBooks() => navigate([HomeSegment(), BooksSegment()]);
  Future<void> toBook({required int id}) => navigate([HomeSegment(), BooksSegment(), BookSegment(id: id)]);
  Future<void> bookNextPrevButton({bool? isPrev}) {
    assert(currentTypedPath.last is BookSegment);
    var id = (currentTypedPath.last as BookSegment).id;
    if (isPrev == true)
      id = id == 0 ? booksLen - 1 : id - 1;
    else
      id = booksLen - 1 > id ? id + 1 : 0;
    return toBook(id: id);
  }

  Future<void> globalLogoutButton() {
    final loginNotifier = ref.read(userIsLoggedProvider.notifier);
    // checking
    assert(loginNotifier.state); // is logged?
    // change login state
    loginNotifier.state = false;
    return navigationCompleted; // wait for the navigation to end
  }

  Future<void> globalLoginButton() {
    // checking
    assert(!ref.read(userIsLoggedProvider)); // is logoff?
    // navigate to login page
    final segment = pathParser.typedPath2Path(currentTypedPath);
    return navigate([LoginHomeSegment(loggedUrl: segment, canceledUrl: segment)]);
  }

  Future<void> loginPageCancel() => _loginPageButtons(true);
  Future<void> loginPageOK() => _loginPageButtons(false);

  Future<void> _loginPageButtons(bool cancel) async {
    assert(currentTypedPath.last is LoginHomeSegment);
    final loginHomeSegment = currentTypedPath.last as LoginHomeSegment;

    var newSegment = pathParser.path2TypedPath(cancel ? loginHomeSegment.canceledUrl : loginHomeSegment.loggedUrl);
    if (newSegment.isEmpty) newSegment = [HomeSegment()];

    // change both providers on which the navigation status depends
    ref.read(ongoingPathProvider.notifier).state = newSegment;
    if (!cancel) ref.read(userIsLoggedProvider.notifier).state = true;

    return navigationCompleted; // wait for the navigation to end
  }
}

// *** 3. Root widget and entry point (same for all examples)

// Root app widget
//
// To make it less verbose, we use the functional_widget package to generate widgets.
// See *.g.dart file for details.
@cwidget
Widget booksExampleApp(WidgetRef ref) {
  final navigator = ref.read(riverpodNavigatorProvider);
  return MaterialApp.router(
    title: 'Books App',
    routerDelegate: navigator.routerDelegate as RiverpodRouterDelegate,
    routeInformationParser: RouteInformationParserImpl(navigator.pathParser),
    debugShowCheckedModeBanner: false,
  );
}

/// app entry point with ProviderScope
void runMain() => runApp(
      ProviderScope(
        overrides: [
          riverpodNavigatorCreatorProvider.overrideWithValue(AppNavigator.new),
        ],
        child: const BooksExampleApp(),
      ),
    );
