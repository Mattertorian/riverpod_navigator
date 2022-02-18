# Riverpod navigation

### Simple but powerfull Flutter navigation with [riverpod](https://riverpod.dev/), [freezed](https://github.com/rrousselGit/freezed) and Navigator 2.0 that solves the following:

- **Strictly typed navigation:** <br>
you can use ```navigate([HomeSegment(),BookSegment(id: 2)]);``` instead of ```navigate('home/book;id:2');``` in your code.
- **asynchronous navigation**<br>
is the case when changing the navigation state requires asynchronous actions (such as loading or saving data from the Internet)
- **multiple providers**<br>
is the case when the navigation state depends on multiple providers
- **easier coding:** <br>
the problem of navigation is reduced to manipulation an immutable collection.
- **better separation of concerns: UI x Model** (thanks to [riverpod](https://riverpod.dev/) :+1:):<br>
navigation logic can be developed and tested without typing a single flutter widget.
- **nested navigation**<br>
just use the nested riverpod ```ProviderScope()```

#### Packages

Most of the code is in the *[riverpod_navigator_core](https://github.com/PavelPZ/riverpod_navigator/tree/main/packages/riverpod_navigator_core)* dart library independent of Flutter.
*[riverpod_navigator](https://github.com/PavelPZ/riverpod_navigator/tree/main/packages/riverpod_navigator)* addresses the connection to Flutter Navigator 2.0.

## Terminology used

Take a look at the following terms related to url path ```home/book;id=2```

- **string-path:** ```final stringPath = 'home/book;id=2';```
- **string-segment** - the string-path consists of two slash-delimited string-segments: ```home``` and ```book;id=2```
- **typed-segment** - the typed-segment (aka ```class TypedSegment {}``` ) defines string-segment: ```HomeSegment()``` and ```BookSegment(id:2)``` in this case
- **typed-path**: typed-path (aka ```typedef TypedPath = List<TypedSegment>```) : ```[HomeSegment(), BookSegment(id:2)];```
- Flutter Navigator 2.0 **navigation-stack** is specified by TypedPath, where each TypedPath's TypedSegment instance corresponds to a screen and page instance<br>
  ```[MaterialPage (child: HomeScreen(HomeSegment())), MaterialPage (child: BookScreen(BookSegment(id:2)))]```.

## Navigator Data Flow Diagram:

<p align="center">
<img src="https://github.com/PavelPZ/riverpod_navigator/blob/main/packages/riverpod_navigator_core/README.png" alt="riverpod_navigator_core" />
</p>

As you can see, changing the **Input state** starts the async calculation.
The result of the calculations is **Output state** in navigationStackProvider and possibly app specific **Side effects**.
Connecting *navigationStackProvider* to Flutter Navigator 2.0 is then easy.

The appLogic procedure returns the future with the new navigationStack and its signature is as follows:

```dart
FutureOr<TypedPath> appNavigationLogic(TypedPath oldNavigationStack, TypedPath ongoingPath)
```

## Simple example

### Step1 - imutable classes for typed-segment

We use [freezed-package](https://github.com/rrousselGit/freezed) to generate immutable TypedSegment descendant classes.

It's a good idea to be familiar with the freezed-package (including support for JSON serialization).

From the following SegmentGrp class declaration, the freezed generates two classes: *HomeSegment* and *PageSegment*.

```dart
@freezed
class Segments with _$Segments, TypedSegment {
  Segments._();
  factory Segments.home() = HomeSegment;
  factory Segments.page({required String title}) = PageSegment;

  factory Segments.fromJson(Map<String, dynamic> json) => _$SegmentsFromJson(json);
}```

### Step2 - navigator parameterization

Extends the RNavigator class as follows.

```dart
class AppNavigator extends RNavigator {
  AppNavigator(Ref ref)
      : super(
          ref,
          [
            RRoutes<Segments>(Segments.fromJson, [ // json deserialize HomeSegment or PageSegment
              RRoute<HomeSegment>(HomeScreen.new), // build a HomeScreen for HomeSegment
              RRoute<PageSegment>(PageScreen.new), // build a PageScreen for PageSegment
            ])
          ],
        );

  //******* app specific actions, used:
  // - in screen e.g. in button onClick
  // - in dart test during development or testing

  /// navigate to page
  Future toPage(String title) => navigate([HomeSegment(), PageSegment(title: title)]);

  /// navigate to home
  Future toHome() => navigate([HomeSegment()]);
}
```

### useful extension for screen code

```dart
extension WidgetRefApp on WidgetRef {
  AppNavigator get navigator => read(riverpodNavigatorProvider) as AppNavigator;
}
```

use:

```dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
...
    ElevatedButton(onPressed: () => ref.navigator.toPage('Page title')
```

### useful extension for testing 

```dart 
extension WidgetRefApp on WidgetRef {
  AppNavigator get navigator => read(riverpodNavigatorProvider) as AppNavigator;
}
```

use:

```dart
void main() {
  test('navigation test', () async {
    final container = ProviderContainer();
    await container.navigator.toPage('Page');
    await container.pump();
    // dump navigationStackProvider state
    expect(container.navigator.debugNavigationStack2String, 'home/page;title=Page');
...
```

### Step3 - use the RNavigator in MaterialApp.router

If you are familiar with the Flutter Navigator 2.0 and the riverpod, the following code is clear:

```dart
class App extends ConsumerWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigator = ref.navigator;
    return MaterialApp.router(
      title: 'Riverpod Navigator Example',
      routerDelegate: navigator.routerDelegate,
      routeInformationParser: navigator.routeInformationParser,
    );
  }
}
```

### Step4 - runApp

```dart
void main() => runApp(
      ProviderScope(
        overrides: RNavigatorCore.providerOverrides([HomeSegment()], AppNavigator.new),
        child: const App(),
      ),
    );
```

### Step5 - widgets for screens

```dart 
class HomeScreen extends ConsumerWidget {
  const HomeScreen(this.segment, {Key? key}) : super(key: key);

  final HomeSegment segment;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                // following navigation create navigation stack [HomeScreen(HomeSegment()) => PageScreen(PageSegment(title: 'Page title'))].
                onPressed: () => ref.navigator.toPage('Page'),
                child: const Text('Go to page'),
              ),
            ],
          ),
        ),
      );
}

class PageScreen extends ConsumerWidget {
  const PageScreen(this.segment, {Key? key}) : super(key: key);

  final PageSegment segment;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: Text(segment.title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                // following navigation create navigation stack "HomeScreen(HomeSegment())".
                onPressed: () => ref.navigator.toHome(),
                child: const Text('Go to home'),
              ),
            ],
          ),
        ),
      );
}
```

#### Code of the example

The full code is available here:
[simple.dart](https://github.com/PavelPZ/riverpod_navigator/blob/main/examples/doc/lib/src/simple.dart).

## Other features doc and samples 

Note: *The following examples are prepared using a **functional_widget package** that simplifies writing widgets.
The use of functional_widget is not mandatory*

- [Async navigation and splash screen](https://github.com/PavelPZ/riverpod_navigator/blob/main/features/async_navigation_splash_screen.md)
- [Login flow](https://github.com/PavelPZ/riverpod_navigator/blob/main/features/login_flow.md)
- [Testing](https://github.com/PavelPZ/riverpod_navigator/blob/main/features/testing.md)
- [More TypedSegment roots](https://github.com/PavelPZ/riverpod_navigator/blob/main/features/more_typedSegment_roots.md)
- [Nested navigation](https://github.com/PavelPZ/riverpod_navigator/blob/main/features/nested_navigation.md)

## See [What's under the hood](https://github.com/PavelPZ/riverpod_navigator/blob/main/under_the_hood.md) for riverpod_navigation principle

## Installation of examples

After clonning repository, go to ```examples\doc``` subdirectory and execute:

- ```flutter create .```
- ```flutter pub get```

## Comparison with go_router

This chapter is inspired by this riverpod issue: [Examples of go_router using riverpod](https://github.com/rrousselGit/river_pod/issues/1122).

| example | go_router | code lines | riverpod_navigator | code lines |
| --- | --- | --- | --- | --- |
| main | [source code](https://github.com/csells/go_router/blob/main/go_router/example/lib/main.dart) | 70 | [source code](https://github.com/PavelPZ/riverpod_navigator/blob/main/examples/go_router/lib/main.dart) | 84  |
| redirection | [source code](https://github.com/csells/go_router/blob/main/go_router/example/lib/redirection.dart) | 167 | [source code](https://github.com/PavelPZ/riverpod_navigator/blob/main/examples/go_router/lib/redirection.dart) | 149 |

If you are interested in preparing another go_router example, I will try to do it.

## Roadmap

I prepared this package for my new project. Its further development depends on whether it will be used by the community.

- proofreading because my English is not good. Community help is warmly welcomed.
- BlockGUI widget (block the GUI while asynchronous navigation is waiting to complete)
- parameterization allowing  cupertino
