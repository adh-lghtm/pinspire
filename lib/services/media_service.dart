import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class SelectedPhoto {
  const SelectedPhoto(this.dataUri, this.aspectRatio);
  final String dataUri;
  final double aspectRatio;
}

class MediaService {
  static final _picker = ImagePicker();
  static SelectedPhoto? recoveredPhoto;
  static Future<SelectedPhoto> _read(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > 400 * 1024) {
      throw const FormatException(
        'Gambar terlalu besar untuk demo lokal. Pilih gambar di bawah 400 KB atau gunakan URL.',
      );
    }
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final ratio = frame.image.width / frame.image.height;
    frame.image.dispose();
    codec.dispose();
    return SelectedPhoto(
      'data:image/${file.mimeType?.split('/').last ?? 'jpeg'};base64,${base64Encode(bytes)}',
      ratio,
    );
  }

  static Future<SelectedPhoto?> pickPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1400,
      imageQuality: 75,
      requestFullMetadata: false,
    );
    return file == null ? null : _read(file);
  }

  static Future<void> recoverLostPhoto() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final result = await _picker.retrieveLostData();
      if (result.files?.isNotEmpty ?? false) {
        recoveredPhoto = await _read(result.files!.first);
      }
    } catch (_) {
      /* Pemulihan gagal tidak boleh menghalangi aplikasi dibuka. */
    }
  }
}
