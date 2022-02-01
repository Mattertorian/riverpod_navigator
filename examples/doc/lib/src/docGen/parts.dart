class Part {
  Part(this.title, this.subTitle, this.body);
  final String title;
  final String subTitle;
  final String body;
  String tempId = ''; // e.g. '2' or '3.1'
  String tempBody = ''; // e.g. body, created v GenFile without '@'
}

String lessonHeader(String lessonId) => '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:riverpod_navigator/riverpod_navigator.dart';

import 'screens.dart';

part 'lesson$lessonId.freezed.dart';
part 'lesson$lessonId.g.dart';
''';

String dartLessonHeader(String lessonId) => '''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_navigator/riverpod_navigator.dart';

part 'dart-lesson$lessonId.freezed.dart';
part 'dart-lesson$lessonId.g.dart';
''';

String flutterLessonHeader(String lessonId) => '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:riverpod_navigator/riverpod_navigator.dart';

import 'dart-lesson$lessonId.dart';
import 'screens.dart';

part 'flutter-lesson$lessonId.g.dart';
''';

String screensHeader(String lessonId) => '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';

import 'lesson$lessonId.dart';

part 'screens.g.dart';

// ************************************
// Using "functional_widget" package to be less verbose.
// ************************************
''';

String dartFlutterScreensHeader(String lessonId) => '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:riverpod_navigator/riverpod_navigator.dart';

import 'dart-lesson$lessonId.dart';

// flutter pub run build_runner watch
part 'screens.g.dart';
''';

var parts = <String, Part>{
  'l1': Part('''
classes for typed path segments (TypedSegment)
''', '''
The Freezed package generates three immutable classes used for writing typed navigation path,
e.g TypedPath path = [HomeSegment (), BooksSegment () and BookSegment (id: 3)]
''', ''' 
@freezed
class AppSegments with _\$AppSegments, TypedSegment {
  AppSegments._();
  factory AppSegments.home() = HomeSegment;
  factory AppSegments.books() = BooksSegment;
  factory AppSegments.book({required int id}) = BookSegment;

  factory AppSegments.fromJson(Map<String, dynamic> json) => _\$AppSegmentsFromJson(json);
}
'''),
  'l1-3': Part('''
async screen actions  
''', '''
''', ''' 
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
'''),
  'l2': Part('''
Dart-part of app configuration  
''', '''
''', ''' 
final config4DartCreator = () => Config4Dart(
      initPath: [HomeSegment()],
      json2Segment: (json, _) => AppSegments.fromJson(json),
      riverpodNavigatorCreator: (ref) => AppNavigator(ref),
      routerDelegateCreator: (ref) => RiverpodRouterDelegate(ref),
    );
'''),
  'l2-3': Part('''
Configure dart-part of app  
''', '''
''', ''' 
final config4DartCreator = () => Config4Dart(
      json2Segment: (json, _) => AppSegments.fromJson(json),
      initPath: [HomeSegment()],
      segment2AsyncScreenActions: segment2AsyncScreenActions,
      riverpodNavigatorCreator: (ref) => AppNavigator(ref),
      routerDelegateCreator: (ref) => RiverpodRouterDelegate(ref),
    );
'''),
  'l3': Part('''
app-specific navigator with navigation aware actions (used in screens)  
''', '''
''', ''' 
const booksLen = 5;

class AppNavigator extends RiverpodNavigator {
  AppNavigator(Ref ref) : super(ref);

  void toHome() => navigate([HomeSegment()]);
  void toBooks() => navigate([HomeSegment(), BooksSegment()]);
  void toBook({required int id}) => navigate([HomeSegment(), BooksSegment(), BookSegment(id: id)]);
  void bookNextPrevButton({bool? isPrev}) {
    assert(getActualTypedPath().last is BookSegment);
    var id = (getActualTypedPath().last as BookSegment).id;
    if (isPrev == true)
      id = id == 0 ? booksLen - 1 : id - 1;
    else
      id = booksLen - 1 > id ? id + 1 : 0;
    toBook(id: id);
  }
}
'''),
  'l4': Part('''
Flutter-part of app configuration  
''', '''
''', ''' 
final configCreator = (Config4Dart config4Dart) => Config(
      /// Which widget will be builded for which [TypedSegment].
      /// Used in [RiverpodRouterDelegate] to build pages from [TypedSegment]'s
      screenBuilder: (segment) => (segment as AppSegments).map(
        home: (home) => HomeScreen(home),
        books: (books) => BooksScreen(books),
        book: (book) => BookScreen(book),
      ),
      config4Dart: config4Dart,
    );
'''),
  'l4-31': Part('''
Flutter-part of app configuration  
''', '''
''', ''' 
final configCreator = (Config4Dart config4Dart) => Config(
      /// Which widget will be builded for which [TypedSegment].
      /// Used in [RiverpodRouterDelegate] to build pages from [TypedSegment]'s
      screenBuilder: (segment) => (segment as AppSegments).map(
        home: (home) => HomeScreen(home),
        books: (books) => BooksScreen(books),
        book: (book) => BookScreen(book),
      ),
      splashBuilder: () => SplashScreen(),
      config4Dart: config4Dart,
    );'''),
  'l5': Part('''
root widget for app  
''', '''
Using functional_widget package to be less verbose. Package generates "class BooksExampleApp extends ConsumerWidget...", see *.g.dart
''', ''' 
@cwidget
Widget booksExampleApp(WidgetRef ref) => MaterialApp.router(
      title: 'Books App',
      routerDelegate: ref.read(routerDelegateProvider) as RiverpodRouterDelegate,
      routeInformationParser: RouteInformationParserImpl(ref),
    );
'''),
  'l6': Part('''
app entry point with ProviderScope  
''', '''
''', ''' 
void main() {
  runApp(ProviderScope(
    // initialize configs providers
    overrides: [
      config4DartProvider.overrideWithValue(config4DartCreator()),
      configProvider.overrideWithValue(configCreator(config4DartCreator())),
    ],
    child: const BooksExampleApp(),
  ));
'''),
  's1': Part('''
"@cwidget" means, that package generates "class XXX extends ConsumerWidget...", see *.g.dart  
''', '''
''', ''' 
@cwidget
Widget homeScreen(WidgetRef ref, HomeSegment segment) => PageHelper(
      title: 'Home Page',
      buildChildren: () => [
        LinkHelper(title: 'Books Page', onPressed: ref.readNavigator().toBooks),
      ],
    );

@cwidget
Widget booksScreen(WidgetRef ref, BooksSegment segment) => PageHelper(
      title: 'Books Page',
      buildChildren: () =>
          [for (var id = 0; id < booksLen; id++) LinkHelper(title: 'Book, id=\$id', onPressed: () => ref.readNavigator().toBook(id: id))],
    );

@cwidget
Widget bookScreen(WidgetRef ref, BookSegment segment) => PageHelper(
      title: 'Book Page, id=\${segment.id}',
      buildChildren: () => [
        LinkHelper(title: 'Next >>', onPressed: ref.readNavigator().bookNextPrevButton),
        LinkHelper(title: '<< Prev', onPressed: () => ref.readNavigator().bookNextPrevButton(isPrev: true)),
      ],
    );
'''),
  's1-31': Part('''
''', '''
''', ''' 
@swidget
Widget splashScreen() =>
    SizedBox.expand(child: Container(color: Colors.white, child: Center(child: Icon(Icons.circle_outlined, size: 150, color: Colors.deepPurple))));
'''),
  's2': Part('''
''', '''
''', ''' 
@swidget
Widget linkHelper({required String title, VoidCallback? onPressed}) => ElevatedButton(onPressed: onPressed, child: Text(title));

@swidget
Widget pageHelper({required String title, required List<Widget> buildChildren()}) => Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: (() {
            final res = <Widget>[SizedBox(height: 20)];
            for (final w in buildChildren()) res.addAll([w, SizedBox(height: 20)]);
            return res;
          })(),
        ),
      ),
    );
'''),
  '': Part('''
''', '''
''', ''' 
'''),
};
