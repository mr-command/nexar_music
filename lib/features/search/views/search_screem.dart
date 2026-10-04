import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexar_app/sections/homescreen_header.dart';
import 'package:nexar_app/services/providers.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(designProvider);

    return Container(
      child: Text("Hello from Search Screen"),
    );

  }
}