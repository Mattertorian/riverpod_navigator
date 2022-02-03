import 'dart:convert';

const all = 0xffffff;
const l1 = 1;
const l2 = 2;
const l3 = 8; // async screen actions
const l4 = 16; // async screen actions with splash screen
const l5 = 32;
const l6 = 64;
const l7 = 128;
const l8 = 256;
const l9 = 512;
const l_async = l3 + l4;

const lessonMasks = <int>[0, l1, l2, l3, l4, l5, l6, l7, l8, l9];

String int2LessonId(int id) => id.toString().padLeft(2, '0');

String fileGen(
  bool isLesson,
  int id,
  // =true => dart only, =false => flutter only, null => single file for flutter and dart
  bool? lessonDartOnly,
  bool forDoc, {
  bool? screenSplitDartFlutterOnly, // =true => for splited example, null => single file for flutter and dart
}) {
  assert(screenSplitDartFlutterOnly != false);

  final lessonMask = lessonMasks[id];
  final lessonId = int2LessonId(id);

  String filter(int maskPlus, int? maskMinus, bool? forDart, String body) {
    final mask = maskPlus & ~(maskMinus ?? 0);
    if ((lessonMask & mask) == 0) return '';

    if (lessonDartOnly != null) {
      if (forDart != lessonDartOnly) return '';
    } else {
      if (forDart != null) return '';
    }
    return body;
  }

  String filterScreen(bool? forSplitDartFlutter, String body) {
    assert(forSplitDartFlutter != false);
    if (screenSplitDartFlutterOnly != null) {
      if (forSplitDartFlutter != screenSplitDartFlutterOnly) return '';
    } else {
      if (forSplitDartFlutter != null) return '';
    }
    return body;
  }

  String filter2(int maskPlus, int? maskMinus, bool filterDartOnly, String title, String subTitle, String body) {
    final mask = maskPlus & ~(maskMinus ?? 0);
    if ((lessonMask & mask) == 0) return '';

    if (lessonDartOnly != null) {
      if (filterDartOnly != lessonDartOnly) return '';
    }
    return title + subTitle + body;
  }

  String comment(String body) => LineSplitter().convert(body).map((l) => '/// $l').join('\n');

  String t(String title) => (title = title.trim()).isEmpty ? '' : '// *** $title\n\n';
  String st(String subTitle) => (subTitle = subTitle.trim()).isEmpty ? '' : '${comment(subTitle)}\n';
  String b(String body) => (body = body.trim()).isEmpty ? '' : '$body\n\n';

  String lessonGen() => filter(all, null, null, b('''
// ignore: unused_import
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:riverpod_navigator/riverpod_navigator.dart';

import 'screens.dart';

part 'lesson$lessonId.freezed.dart';
part 'lesson$lessonId.g.dart';
''')) + filter(all, null, true, b('''
// ignore: unused_import
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_navigator_dart/riverpod_navigator_dart.dart';

part 'dart_lesson$lessonId.freezed.dart';
part 'dart_lesson$lessonId.g.dart';
''')) + filter(all, null, false, b('''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:riverpod_navigator/riverpod_navigator.dart';

import 'dart_lesson$lessonId.dart';
import 'screens.dart';

part 'flutter_lesson$lessonId.g.dart';
''')) + filter2(all, l5, true, t('''
1. classes for typed path segments (TypedSegment)
'''), st('''
The Freezed package generates three immutable classes used for writing typed navigation path,
e.g TypedPath path = [HomeSegment (), BooksSegment () and BookSegment (id: 3)]
'''), b(''' 
@freezed
class AppSegments with _\$AppSegments, TypedSegment {
  AppSegments._();
  factory AppSegments.home() = HomeSegment;
  factory AppSegments.books() = BooksSegment;
  factory AppSegments.book({required int id}) = BookSegment;

  factory AppSegments.fromJson(Map<String, dynamic> json) => _\$AppSegmentsFromJson(json);
}

final Json2Segment json2AppSegments = (json, _) => AppSegments.fromJson(json);
''')) + filter2(l5, null, true, t('''
1. classes for typed path segments (TypedSegment)
'''), st('''
The Freezed package generates three immutable classes used for writing typed navigation path,
e.g TypedPath path = [HomeSegment (), BooksSegment () and BookSegment (id: 3)]
'''), b(''' 
@freezed
class AppSegments with _\$AppSegments, TypedSegment {
  AppSegments._();
  factory AppSegments.home() = HomeSegment;
  factory AppSegments.books() = BooksSegment;
  factory AppSegments.book({required int id}) = BookSegment;

  factory AppSegments.fromJson(Map<String, dynamic> json) => _\$AppSegmentsFromJson(json);
}

final Json2Segment json2AppSegments = (json, _) => AppSegments.fromJson(json);

@Freezed(unionKey: LoginSegments.jsonNameSpace)
class LoginSegments with _\$LoginSegments, TypedSegment {
  /// json serialization hack: must be at least two constructors
  factory LoginSegments() = _LoginSegments;
  LoginSegments._();
  factory LoginSegments.home({String? loggedUrl, String? canceledUrl}) = LoginHomeSegment;

  factory LoginSegments.fromJson(Map<String, dynamic> json) => _\$LoginSegmentsFromJson(json);
  static const String jsonNameSpace = '_login';
}

final Json2Segment json2LoginSegments = (json, _) => LoginSegments.fromJson(json);

/// mark screens which needs login: every 'id.isOdd' book needs it
bool needsLogin(TypedSegment segment) => segment is BookSegment && segment.id.isOdd;
''')) + filter2(l_async, null, true, t('''
1.1. async screen actions  
'''), st('''
'''), b(''' 
AsyncScreenActions? segment2AsyncScreenActions(TypedSegment segment) {
  // simulate helper
  Future<String> simulateAsyncResult(String title, int msec) async {
    await Future.delayed(Duration(milliseconds: msec));
    return title;
  }

  return (segment as AppSegments).maybeMap(
    book: (_) => AsyncScreenActions<BookSegment>(
      // for every Book screen: creating takes some time
      creating: (newSegment) async => simulateAsyncResult('Book creating async result after 1 sec', 1000),
      // for every Book screen with odd id: changing to another Book screen takes some time
      merging: (_, newSegment) async => newSegment.id.isOdd ? simulateAsyncResult('Book merging async result after 500 msec', 500) : null,
      // for every Book screen with even id: creating takes some time
      deactivating: (oldSegment) => oldSegment.id.isEven ? Future.delayed(Duration(milliseconds: 500)) : null,
    ),
    home: (_) => AsyncScreenActions<HomeSegment>(
        // Home screen takes some timefor creating
        creating: (_) async => simulateAsyncResult('Home creating async result after 1 sec', 1000)),
    orElse: () => null,
  );
}
''')) + filter2(all, l5, true, t('''
2. App-specific navigator with navigation aware actions (used in screens)  
'''), st('''
'''), b('''
const booksLen = 5;

class AppNavigator extends RiverpodNavigator {
  AppNavigator(Ref ref) : super(ref);

  void toHome() => navigate([HomeSegment()]);
  void toBooks() => navigate([HomeSegment(), BooksSegment()]);
  void toBook({required int id}) => navigate([HomeSegment(), BooksSegment(), BookSegment(id: id)]);
  void bookNextPrevButton({bool? isPrev}) {
    assert(actualTypedPath.last is BookSegment);
    var id = (actualTypedPath.last as BookSegment).id;
    if (isPrev == true)
      id = id == 0 ? booksLen - 1 : id - 1;
    else
      id = booksLen - 1 > id ? id + 1 : 0;
    toBook(id: id);
  }
}

/// provide a correctly typed navigator for tests
extension ReadNavigator on ProviderContainer {
  AppNavigator readNavigator() => read(riverpodNavigatorProvider) as AppNavigator;
}
''')) + filter2(l5, null, true, t('''
2. App-specific navigator with navigation aware actions (used in screens)  
'''), st('''
'''), b('''
const booksLen = 5;

class AppNavigator extends RiverpodNavigator {
  AppNavigator(Ref ref) : super(ref);

  /// Returns redirect path or null
  @override
  FutureOr<TypedPath?> appNavigationLogic(Ref ref, TypedPath oldPath, TypedPath newPath) {
    if (!ref.read(userIsLoggedProvider)) {
      final pathNeedsLogin = newPath.any((segment) => needsLogin(segment));

      // login needed => redirect to login page
      if (pathNeedsLogin) {
        final pathParser = ref.read(config4DartProvider).pathParser;
        // parametters for login screen
        final loggedUrl = pathParser.typedPath2Path(newPath);
        var canceledUrl = oldPath.isEmpty || oldPath.last is LoginHomeSegment ? '' : pathParser.typedPath2Path(oldPath);
        // chance to exit login loop
        if (loggedUrl == canceledUrl) canceledUrl = '';
        // redirect to login screen
        return [LoginHomeSegment(loggedUrl: loggedUrl, canceledUrl: canceledUrl)];
      }
    } else {
      // user logged and navigation to Login page => redirect to home
      if (newPath.isEmpty || newPath.last is LoginHomeSegment) return [HomeSegment()];
    }
    // login OK => no redirect
    return null;
  }

  void toHome() => navigate([HomeSegment()]);
  void toBooks() => navigate([HomeSegment(), BooksSegment()]);
  void toBook({required int id}) => navigate([HomeSegment(), BooksSegment(), BookSegment(id: id)]);
  void bookNextPrevButton({bool? isPrev}) {
    assert(actualTypedPath.last is BookSegment);
    var id = (actualTypedPath.last as BookSegment).id;
    if (isPrev == true)
      id = id == 0 ? booksLen - 1 : id - 1;
    else
      id = booksLen - 1 > id ? id + 1 : 0;
    toBook(id: id);
  }

  Future<void> globalLogoutButton() {
    // checking
    final isLogged = ref.read(userIsLoggedProvider.notifier);
    assert(isLogged.state); // is logged?
    // change login state
    isLogged.state = false;
    return Future.value();
  }

  Future<void> globalLoginButton() {
    // checking
    final isLogged = ref.read(userIsLoggedProvider.notifier);
    assert(!isLogged.state); // is logoff?
    // navigate to login page
    final segment = ref.read(config4DartProvider).pathParser.typedPath2Path(actualTypedPath);
    return navigate([LoginHomeSegment(loggedUrl: segment, canceledUrl: segment)]);
  }

  Future<void> loginPageCancel() => _loginPageButtons(true);
  Future<void> loginPageOK() => _loginPageButtons(false);

  Future<void> _loginPageButtons(bool cancel) async {
    assert(actualTypedPath.last is LoginHomeSegment);
    final loginHomeSegment = actualTypedPath.last as LoginHomeSegment;

    var newSegment = ref.read(config4DartProvider).pathParser
      .path2TypedPath(cancel ? loginHomeSegment.canceledUrl : loginHomeSegment.loggedUrl);
    if (newSegment.isEmpty) newSegment = [HomeSegment()];


    ref.read(typedPathProvider.notifier).state = newSegment;
    // login successfull => change login state
    if (!cancel) ref.read(userIsLoggedProvider.notifier).state = true;
  }
}

final userIsLoggedProvider = StateProvider<bool>((_) => false);

/// provide a correctly typed navigator for tests
extension ReadNavigator on ProviderContainer {
  AppNavigator readNavigator() => read(riverpodNavigatorProvider) as AppNavigator;
}
''')) + filter2(all, l4 + l5, true, t('''
3. Dart-part of app configuration
'''), st('''
'''), b('''
final config4DartCreator = () => Config4Dart(
      initPath: [HomeSegment()],
      json2Segment: json2AppSegments,
      riverpodNavigatorCreator: (ref) => AppNavigator(ref),
    );
''')) + filter2(l4, null, true, t('''
3. Dart-part of app configuration
'''), st('''
'''), b('''
final config4DartCreator = () => Config4Dart(
      json2Segment: json2AppSegments,
      initPath: [HomeSegment()],
      segment2AsyncScreenActions: segment2AsyncScreenActions,
      riverpodNavigatorCreator: (ref) => AppNavigator(ref),
    );
''')) + filter2(l5, null, true, t('''
3. Dart-part of app configuration
'''), st('''
'''), b('''
final config4DartCreator = () => Config4Dart(
      json2Segment: (json, unionKey) =>
          (unionKey == LoginSegments.jsonNameSpace ? json2LoginSegments : json2AppSegments)(json, unionKey),
      initPath: [HomeSegment()],
      riverpodNavigatorCreator: (ref) => AppNavigator(ref),
      getAllDependedStates: (ref) => [ref.watch(typedPathProvider), ref.watch(userIsLoggedProvider)],
    );
''')) + filter2(all, l4 + l5, false, t('''
4. Flutter-part of app configuration
'''), st('''
'''), b('''
final configCreator = (Config4Dart config4Dart) => Config(
      /// Which widget will be builded for which [TypedSegment].
      /// Used in [RiverpodRouterDelegate] to build pages from [TypedSegment]'s
      screenBuilder: screenBuilderAppSegments,
      config4Dart: config4Dart,
    );
''')) + filter2(l4, null, false, t('''
4. Flutter-part of app configuration  
'''), st('''
'''), b('''
final configCreator = (Config4Dart config4Dart) => Config(
      /// Which widget will be builded for which [TypedSegment].
      /// Used in [RiverpodRouterDelegate] to build pages from [TypedSegment]'s
      screenBuilder: screenBuilderAppSegments,
      splashBuilder: () => SplashScreen(),
      config4Dart: config4Dart,
    );
''')) + filter2(l5, null, false, t('''
4. Flutter-part of app configuration  
'''), st('''
'''), b('''
final configCreator = (Config4Dart config4Dart) => Config(
      /// Which widget will be builded for which [TypedSegment].
      /// Used in [RiverpodRouterDelegate] to build pages from [TypedSegment]'s
      screenBuilder: (segment) => segment is LoginSegments ? screenBuilderLoginSegments(segment) : screenBuilderAppSegments(segment),
      config4Dart: config4Dart,
    );
''')) + filter2(all, null, false, t('''
5. root widget for app  
'''), st('''
Using functional_widget package to be less verbose. Package generates "class BooksExampleApp extends ConsumerWidget...", see *.g.dart
'''), b('''
@cwidget
Widget booksExampleApp(WidgetRef ref) => MaterialApp.router(
      title: 'Books App',
      routerDelegate: ref.read(riverpodNavigatorProvider).routerDelegate as RiverpodRouterDelegate,
      routeInformationParser: RouteInformationParserImpl(ref),
    );
''')) + filter2(all, null, false, t('''
6. app entry point with ProviderScope  
'''), st('''
'''), b('''
void runMain() {
  final config = configCreator(config4DartCreator());
  runApp(ProviderScope(
    // initialize configs providers
    overrides: [
      config4DartProvider.overrideWithValue(config.config4Dart),
      configProvider.overrideWithValue(config),
    ],
    child: const BooksExampleApp(),
  ));
}
''')) + filter2(all, null, false, t('''
'''), st('''
'''), b('''
'''));

  String screenGen() => filterScreen(null, b('''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:riverpod_navigator/riverpod_navigator.dart';

import 'lesson$lessonId.dart';

part 'screens.g.dart';

final ScreenBuilder screenBuilderAppSegments = (segment) => (segment as AppSegments).map(
      home: (home) => HomeScreen(home),
      books: (books) => BooksScreen(books),
      book: (book) => BookScreen(book),
    );

// ************************************
// Using "functional_widget" package to be less verbose.
// ************************************

@swidget
Widget linkHelper({required String title, VoidCallback? onPressed}) => ElevatedButton(onPressed: onPressed, child: Text(title));
''')) + filterScreen(true, b('''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:riverpod_navigator/riverpod_navigator.dart';

import 'dart_lesson$lessonId.dart';

part 'screens.g.dart';

final ScreenBuilder screenBuilderAppSegments = (segment) => (segment as AppSegments).map(
      home: (home) => HomeScreen(home),
      books: (books) => BooksScreen(books),
      book: (book) => BookScreen(book),
    );

// ************************************
// Using "functional_widget" package to be less verbose.
// ************************************

@swidget
Widget linkHelper({required String title, VoidCallback? onPressed}) => ElevatedButton(onPressed: onPressed, child: Text(title));
''')) + filter(all, 0, null, b('''
@swidget
Widget homeScreen(HomeSegment segment) => PageHelper(
      title: 'Home Screen',
      buildChildren: (navigator) => [
        LinkHelper(title: 'Books Page', onPressed: navigator.toBooks),
      ],
    );

@swidget
Widget booksScreen(BooksSegment segment) => PageHelper(
      title: 'Books Screen',
      buildChildren: (navigator) =>
          [for (var id = 0; id < booksLen; id++) LinkHelper(title: 'Book Screen, id=\$id', onPressed: () => navigator.toBook(id: id))],
    );

@swidget
Widget bookScreen(BookSegment segment) => PageHelper(
      title: 'Book Screen, id=\${segment.id}',
      buildChildren: (navigator) => [
        LinkHelper(title: 'Next >>', onPressed: navigator.bookNextPrevButton),
        LinkHelper(title: '<< Prev', onPressed: () => navigator.bookNextPrevButton(isPrev: true)),
      ],
    );
''')) + filter(l4, 0, null, b('''
@swidget
Widget splashScreen() =>
    SizedBox.expand(child: Container(color: Colors.white, child: Center(child: Icon(Icons.circle_outlined, size: 150, color: Colors.deepPurple))));
''')) + filter(l5, 0, null, b('''
final ScreenBuilder screenBuilderLoginSegments = (segment) => (segment as LoginHomeSegment).map(
      (value) => throw UnimplementedError(),
      home: (loginHome) => LoginScreen(loginHome),
    );

@swidget
Widget loginScreen(LoginHomeSegment segment) => PageHelper(
      title: 'Login Page',
      isLoginPage: true,
      buildChildren: (navigator) => [
        ElevatedButton(onPressed: navigator.loginPageOK, child: Text('Login')),
      ],
    );
''')) + filter(all, l5, null, b('''
@cwidget
Widget pageHelper(WidgetRef ref, {required String title, required List<Widget> buildChildren(AppNavigator navigator)}) {
  final navigator = ref.read(riverpodNavigatorProvider) as AppNavigator;
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
          return res;
        })(),
      ),
    ),
  );
}
''')) + filter(l5, 0, null, b('''
@cwidget
Widget pageHelper(WidgetRef ref, {required String title, required List<Widget> buildChildren(AppNavigator navigator), bool? isLoginPage}) {
  final navigator = ref.read(riverpodNavigatorProvider) as AppNavigator;
  return Scaffold(
    appBar: AppBar(
      title: Text(title),
      leading: isLoginPage == true
          ? IconButton(
              onPressed: navigator.loginPageCancel,
              icon: Icon(Icons.cancel),
            )
          : null,
      actions: [
        if (isLoginPage != true)
          Consumer(builder: (_, ref, __) {
            final isLogged = ref.watch(userIsLoggedProvider);
            return ElevatedButton(
              onPressed: () => isLogged ? navigator.globalLogoutButton() : navigator.globalLoginButton(),
              child: Text(isLogged ? 'Logout' : 'Login'),
            );
          }),
      ],
    ),
    body: Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: (() {
          final res = <Widget>[SizedBox(height: 20)];
          for (final w in buildChildren(navigator)) res.addAll([w, SizedBox(height: 20)]);
          return res;
        })(),
      ),
    ),
  );
}'''));

  return isLesson ? lessonGen() : screenGen();
}
