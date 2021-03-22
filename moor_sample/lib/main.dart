import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/moor_database.dart';
import 'ui/home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider(
      // create: (_) => AppDatabase(),
      create: (_) => AppDatabase().taskDao, // daoクラスを使用する場合
      child: MaterialApp(
        title: 'Material App',
        home: HomePage(),
      ),
    );
  }
}
