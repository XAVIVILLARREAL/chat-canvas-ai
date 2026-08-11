import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:graph_core/graph_core.dart';
import 'package:webview_windows/webview_windows.dart';

/// Vista 3D del grafo (WebView2 + Three.js) para desktop Windows.
///
/// Sirve el HTML generado por graph_core desde un HttpServer local
/// (127.0.0.1, puerto efímero) con los assets Three.js del bundle —
/// sin CDN, funciona offline. En el resto de plataformas [supportsPlatform]
/// es false y [initState] notifica [onNativeError] (fallback 2D en la pantalla).
class ProjectGraph3DView extends StatefulWidget {
  final Graph graph;
  final Map<String, Offset2> positions;
  final Future<String> Function(String path) loadAsset;
  final VoidCallback? onLoaded;
  final VoidCallback? onNativeError;

  const ProjectGraph3DView({
    super.key,
    required this.graph,
    required this.positions,
    this.loadAsset = _defaultLoadAsset,
    this.onLoaded,
    this.onNativeError,
  });

  static bool get supportsPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  State<ProjectGraph3DView> createState() => _ProjectGraph3DViewState();

  static Future<String> _defaultLoadAsset(String path) async {
    final data = await rootBundle.load(path);
    return String.fromCharCodes(data.buffer.asUint8List());
  }
}

class _ProjectGraph3DViewState extends State<ProjectGraph3DView> {
  HttpServer? _server;
  WebviewController? _controller;

  @override
  void initState() {
    super.initState();
    if (!ProjectGraph3DView.supportsPlatform) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onNativeError?.call();
        widget.onLoaded?.call();
      });
      return;
    }
    _boot();
  }

  Future<void> _boot() async {
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server = server;
      server.listen(_handle);
      final controller = WebviewController();
      _controller = controller;
      await controller.initialize();
      controller.loadingState.listen((state) {
        if (state == LoadingState.navigationCompleted) {
          widget.onLoaded?.call();
        }
      });
      await controller.loadUrl('http://127.0.0.1:${server.port}/');
    } catch (_) {
      widget.onNativeError?.call();
    }
  }

  Future<void> _handle(HttpRequest request) async {
    final path = request.uri.path == '/' ? '/' : request.uri.path;
    try {
      switch (path) {
        case '/':
          request.response.headers.contentType = ContentType.html;
          request.response.write(
            buildGraph3dHtml(widget.graph, positions: widget.positions),
          );
        case '/three.min.js':
        case '/orbitcontrols.js':
          request.response.headers.contentType = ContentType('application', 'javascript');
          request.response.write(
            await widget.loadAsset('assets/graph3d/${path.substring(1)}'),
          );
        default:
          request.response.statusCode = HttpStatus.notFound;
      }
    } catch (_) {
      request.response.statusCode = HttpStatus.internalServerError;
    } finally {
      await request.response.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!ProjectGraph3DView.supportsPlatform) {
      return const SizedBox.shrink();
    }
    return controller == null
        ? const Center(child: CircularProgressIndicator())
        : Webview(controller);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _server?.close(force: true);
    super.dispose();
  }
}