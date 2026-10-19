import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prism_state_views/prism_state_views.dart';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'prism_state_views demo',
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  var _state = const PrismViewState<List<String>>.empty();

  Future<void> _cycle() async {
    setState(() => _state = const PrismViewState.loading(message: 'Fetching…'));
    await Future<void>.delayed(const Duration(seconds: 1));
    setState(() {
      _state = const PrismViewState.error('Network unreachable');
    });
    await Future<void>.delayed(const Duration(seconds: 1));
    setState(() {
      _state = const PrismViewState.success(['Ada', 'Grace', 'Linus']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('prism_state_views demo')),
      floatingActionButton: FloatingActionButton(
        onPressed: _cycle,
        child: const Icon(Icons.play_arrow),
      ),
      body: PrismStateView<List<String>>(
        state: _state,
        onRetry: _cycle,
        emptyMessage: 'Tap play to load',
        successBuilder: (names) => ListView(
          children: [for (final n in names) ListTile(title: Text(n))],
        ),
      ),
    );
  }
}
