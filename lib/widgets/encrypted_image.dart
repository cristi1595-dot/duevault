import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/encryption_service.dart';

class EncryptedImage extends StatefulWidget {
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;
  final int? cacheWidth;
  final int? cacheHeight;

  const EncryptedImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  State<EncryptedImage> createState() => _EncryptedImageState();
}

class _EncryptedImageState extends State<EncryptedImage> {
  Future<Uint8List?>? _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = EncryptionService.decryptFileToMemory(widget.path);
  }

  @override
  void didUpdateWidget(EncryptedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      setState(() {
        _imageFuture = EncryptionService.decryptFileToMemory(widget.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return widget.errorWidget ??
              const Center(child: Icon(Icons.error_outline));
        }

        return Image.memory(
          snapshot.data!,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          cacheWidth: widget.cacheWidth,
          cacheHeight: widget.cacheHeight,
          errorBuilder: (context, error, stackTrace) {
            return widget.errorWidget ??
                const Center(child: Icon(Icons.error_outline));
          },
        );
      },
    );
  }
}
