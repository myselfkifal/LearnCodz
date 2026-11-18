import 'package:flutter/material.dart';

/// Optional lesson or question artwork. Text remains available offline.
class ContentPicture extends StatelessWidget {
  final String? url, description;
  final Widget fallback;
  const ContentPicture(
      {super.key,
      this.url,
      this.description,
      this.fallback = const SizedBox.shrink()});

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url ?? '');
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return fallback;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(uri.toString(),
          semanticLabel: description ?? 'Learning illustration',
          width: double.infinity,
          height: 190,
          fit: BoxFit.contain,
          frameBuilder: (context, child, frame, synchronous) =>
              synchronous || frame != null ? child : fallback,
          errorBuilder: (_, __, ___) => fallback),
    );
  }
}
