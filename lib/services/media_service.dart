import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class SelectedPhoto {
  const SelectedPhoto(
    this.dataUri,
    this.aspectRatio, {
    this.bytes,
    this.mimeType = 'image/jpeg',
    this.filename = 'pin.jpg',
  });

  final String dataUri;
  final double aspectRatio;
  final Uint8List? bytes;
  final String mimeType;
  final String filename;

  bool get hasBytes => bytes != null && bytes!.isNotEmpty;
}

class MediaService {
  static final _picker = ImagePicker();
  static SelectedPhoto? recoveredPhoto;
  static const _maxBytes = 5 * 1024 * 1024;

  static Future<double> _ratio(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final ratio = frame.image.width / frame.image.height;
      frame.image.dispose();
      codec.dispose();
      return ratio.isFinite && ratio > 0 ? ratio : .75;
    } catch (_) {
      return .75;
    }
  }

  static Future<SelectedPhoto> _read(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > _maxBytes) {
      throw const FormatException(
        'Gambar terlalu besar. Pilih gambar di bawah 5 MB.',
      );
    }
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final ratio = frame.image.width / frame.image.height;
    frame.image.dispose();
    codec.dispose();

    final mime = file.mimeType ?? 'image/jpeg';
    final extension = mime.split('/').last;
    return SelectedPhoto(
      'data:$mime;base64,${base64Encode(bytes)}',
      ratio.isFinite && ratio > 0 ? ratio : .75,
      bytes: bytes,
      mimeType: mime,
      filename: 'pin.$extension',
    );
  }

  static Future<SelectedPhoto> fromAsset(String asset) async {
    final data = await rootBundle.load(asset);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final extension = asset.split('.').last.toLowerCase();
    final mime = extension == 'jpg' ? 'image/jpeg' : 'image/$extension';
    final ratio = await _ratio(bytes);
    return SelectedPhoto(
      'data:$mime;base64,${base64Encode(bytes)}',
      ratio,
      bytes: bytes,
      mimeType: mime,
      filename: 'pin.$extension',
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
