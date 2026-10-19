import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_state_views/prism_state_views.dart';

/// Screenshot generator — renders the four states in a 2×2 grid into
/// `doc/screenshot.png`.
/// Run with: `SCREENSHOTS=1 flutter test test/screenshot_test.dart`
/// Empty success builder used by the const state constructors.
Widget _emptySuccess(String data) => const SizedBox.shrink();

void main() {
  const key = ValueKey('screenshot');

  Future<void> loadFonts() async {
    var dir = Directory('test/fonts');
    if (!dir.existsSync()) {
      dir = Directory('../prism_markdown/test/fonts');
    }
    if (!dir.existsSync()) return;
    final families = <String, List<Uint8List>>{};
    for (final file in dir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.ttf'),
    )) {
      final name = file.uri.pathSegments.last.replaceAll('.ttf', '');
      final family = name.startsWith('RobotoMono')
          ? 'monospace'
          : name.substring(0, name.indexOf('-'));
      (families[family] ??= []).add(file.readAsBytesSync());
    }
    for (final entry in families.entries) {
      final loader = FontLoader(entry.key);
      for (final bytes in entry.value) {
        loader.addFont(Future.value(bytes.buffer.asByteData()));
      }
      await loader.load();
    }
    // Walk up from the test runner binary to find the Flutter SDK's icon
    // font — the exact depth varies between flutter/dart launch paths.
    var sdkDir = File(Platform.resolvedExecutable).parent;
    File? iconFont;
    for (var i = 0; i < 8; i++) {
      final candidate = File(
        '${sdkDir.path}/bin/cache/artifacts/material_fonts/'
        'MaterialIcons-Regular.otf',
      );
      if (candidate.existsSync()) {
        iconFont = candidate;
        break;
      }
      sdkDir = sdkDir.parent;
    }
    final resolved = iconFont;
    if (resolved != null) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(Future.value(resolved.readAsBytesSync().buffer.asByteData()));
      await loader.load();
    }
  }

  Widget card(String title, Widget child) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: child,
            ),
          ),
        ),
      ],
    );
  }

  testWidgets(
    'capture state views screenshot',
    (tester) async {
      await loadFonts();
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0B57D0),
            ),
          ),
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              appBar: AppBar(
                centerTitle: true,
                title: const Text('prism_state_views'),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: card(
                              'loading',
                              const PrismStateView<String>(
                                state: PrismViewState.loading(
                                  message: 'Fetching…',
                                ),
                                successBuilder: _emptySuccess,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: card(
                              'error',
                              PrismStateView<String>(
                                state: const PrismViewState.error(
                                  'Network unreachable',
                                ),
                                onRetry: () {},
                                successBuilder: (data) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: card(
                              'empty',
                              PrismStateView<String>(
                                state: const PrismViewState.empty(),
                                emptyMessage: 'No items yet',
                                emptyActionLabel: 'Add item',
                                onEmptyAction: () {},
                                successBuilder: (data) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: card(
                              'success',
                              PrismStateView<String>(
                                state: const PrismViewState.success(
                                  'Hello, Prism!',
                                ),
                                successBuilder: (data) => Center(
                                  child: Text(
                                    data,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      // The loading state's spinner never settles — pump fixed frames.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(key),
        );
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ImageByteFormat.png);
        final file = File('doc/screenshot.png');
        await file.create(recursive: true);
        await file.writeAsBytes(byteData!.buffer.asUint8List());
      });
    },
    skip: !Platform.environment.containsKey('SCREENSHOTS'),
  );
}
