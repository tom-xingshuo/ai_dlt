import 'package:flutter/material.dart';

import 'ui/core/widgets.dart';
import 'ui/features/shrink/views/shrink_view.dart';

void main() {
  runApp(const DltShrinkApp());
}

class DltShrinkApp extends StatelessWidget {
  const DltShrinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '大乐透前区缩水工具',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryGreen),
        scaffoldBackgroundColor: kPageBg,
        fontFamily: 'Microsoft YaHei UI',
      ),
      home: const ShrinkView(),
    );
  }
}
