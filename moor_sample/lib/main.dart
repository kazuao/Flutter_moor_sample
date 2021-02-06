import 'package:flutter/material.dart';
import 'package:moor_sample/data/moor_database.dart';
import 'package:provider/provider.dart';

import 'ui/home_page.dart';
import 'data/moor_database.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider(
      builder: (_) => AppDatabase(),
      child: MaterialApp(
        title: 'Material App',
        home: HomePage(),
      ),
    );
  }
}
