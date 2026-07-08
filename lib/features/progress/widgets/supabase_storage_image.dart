import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Family provider to download and cache private Supabase Storage images.
final storageImageBytesProvider = FutureProvider.family<Uint8List, String>((ref, path) async {
  final supabase = Supabase.instance.client;
  return await supabase.storage.from('progress-photos').download(path);
});

class SupabaseStorageImage extends ConsumerWidget {
  final String storagePath;
  final double? width;
  final double? height;
  final BoxFit fit;

  const SupabaseStorageImage({
    super.key,
    required this.storagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytesAsync = ref.watch(storageImageBytesProvider(storagePath));

    return bytesAsync.when(
      data: (bytes) {
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
        );
      },
      loading: () => Container(
        width: width,
        height: height,
        color: Colors.grey[900]?.withValues(alpha: 0.12),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (err, stack) => Container(
        width: width,
        height: height,
        color: Colors.grey[900]?.withValues(alpha: 0.12),
        child: const Center(
          child: Icon(Icons.broken_image_rounded, color: Colors.grey),
        ),
      ),
    );
  }
}
