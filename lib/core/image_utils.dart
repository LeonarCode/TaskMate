import 'dart:convert';
import 'package:flutter/material.dart';

/// Resolves a photoUrl that may be either:
/// - A base64 data URL ("data:image/jpeg;base64,...")
/// - A remote http URL ("https://...")
/// - null (no photo set)
ImageProvider? resolvePhoto(String? photoUrl) {
  if (photoUrl == null || photoUrl.isEmpty) return null;
  if (photoUrl.startsWith('data:image')) {
    try {
      final base64Str = photoUrl.split(',').last;
      return MemoryImage(base64Decode(base64Str));
    } catch (_) {
      return null;
    }
  }
  return NetworkImage(photoUrl);
}
