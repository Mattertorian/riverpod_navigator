// ignore: unused_import
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:riverpod_navigator/riverpod_navigator.dart';

import 'screens.dart';

part 'lesson02.freezed.dart';
part 'lesson02.g.dart';

// The mission:
// 
// - **string path:** ```stringPath = 'home/books/book;id=2';```
// - **string segment** (the string path consists of three string segments, delimited by slash): 'home', 'books', 'book;id=2'
// - **typed path**: ```typedPath = <TypedSegment>[HomeSegment(), BooksSegment(), BookSegment(id:2)];```
// - **typed segment** (the typed path consists of three instances of [TypedSegment]'s): [HomeSegment], [BooksSegment], [BookSegment]
// - **navigation stack** of Flutter Navigator 2.0: ```HomeScreen(HomeSegment())) => BooksScreen(BooksSegment()) => BookScreen(BookSegment(id:3))```
// 
// The mission of navigation is to keep **string path** <=> **typed path** <=> **navigation stack** always in a synchronous state.
// *************************************
// Example02
// - screens require some asynchronous actions (when creating, deactivating or merging)
// - extension of the Example01
// - the splash screen appears before the HomeScreen is displayed
// *************************************
 
// *** 1. classes for typed path segments (TypedSegment)

/// From the following definition, [Freezed](https://github.com/rrousselGit/freezed) generates three typed segment classes,
/// HomeSegment, BooksSegment and BookSegment.
/// 
/// See [Freezed](https://github.com/rrousselGit/freezed) for details.
@freezed
class AppSegments with _$AppSegments, TypedSegment {
  AppSegments._();
  factory AppSegments.home() = HomeSegment;
  factory AppSegments.books() = BooksSegment;
  factory AppSegments.book({required int id}) = BookSegment;

  factory AppSegments.fromJson(Map<String, dynamic> json) => _$AppSegmentsFromJson(json);
}

// *** 1.1. async screen actions

/// Each screen may require an asynchronous action during its creation, merging, or deactivating.
AsyncScreenActions? segment2AsyncScreenActions(TypedSegment segment) {
  /// helper for simulating asynchronous action
  Future<String> simulateAsyncResult(String title, int msec) async {
    await Future.delayed(Duration(milliseconds: msec));
    return title;
  }

  if (segment is! AppSegments) return null;

  return segment.maybeMap(
    book: (_) => AsyncScreenActions<BookSegment>(
      // for every Book screen: creating takes some time
      creating: (newSegment) => simulateAsyncResult('Book creating: async result after 700 msec', 700),
      // for every Book screen with odd id: changing to another Book screen takes some time
      merging: (_, newSegment) => newSegment.id.isOdd ? simulateAsyncResult('Book merging: async result after 500 msec', 500) : null,
      // for every Book screen with even id: deactivating takes some time
      deactivating: (oldSegment) => oldSegment.id.isEven ? Future.delayed(Duration(milliseconds: 500)) : null,
    ),
    home: (_) => AsyncScreenActions<HomeSegment>(
      creating: (_) async => simulateAsyncResult('Home creating: async result after 1000 msec', 1000),
    ),
    orElse: () => null,
  );
}

// *** 2. App-specific navigator.

/// - contains navigation-oriented actions with respect to navigation. The actions are then used in the screen widgets.
/// - configures various navigation properties
class AppNavigator extends RiverpodNavigator {
  AppNavigator(Ref ref)
      : super(
          ref,
          initPath: [HomeSegment()],
          json2Segment: (jsonMap, _) => AppSegments.fromJson(jsonMap),
          screenBuilder: appSegmentsScreenBuilder,
          splashBuilder: SplashScreen.new,
          segment2AsyncScreenActions: segment2AsyncScreenActions, // <============================
        );

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
}

// *** 3. Root widget and entry point (same for all examples)

/// Root app widget
/// 
/// To make it less verbose, we use the functional_widget package to generate widgets.
/// See *.g.dart file for details.
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

const booksLen = 5;

