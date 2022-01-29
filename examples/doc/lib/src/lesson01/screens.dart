import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';

import 'lesson01.dart';

// flutter pub run build_runner watch
part 'screens.g.dart';

// ************************************
// Using "functional_widget" package to be less verbose.
// "@cwidget" means, that package generates e.g "class HomeScreen extends ConsumerWidget...", see *.g.dart
// ************************************
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
          [for (var id = 0; id < booksLen; id++) LinkHelper(title: 'Book, id=$id', onPressed: () => ref.readNavigator().toBook(id: id))],
    );

@cwidget
Widget bookScreen(WidgetRef ref, BookSegment segment) => PageHelper(
      title: 'Book Page, id=${segment.id}',
      buildChildren: () => [
        LinkHelper(title: 'Next >>', onPressed: ref.readNavigator().bookNextPrevButton),
        LinkHelper(title: '<< Prev', onPressed: () => ref.readNavigator().bookNextPrevButton(isPrev: true)),
      ],
    );

// "@swidget" means, that package generates e.g. "class LinkHelper extends StatelessWidget...", see *.g.dart

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
