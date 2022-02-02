import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../src/repository.dart';

///Saves, gets and removes data locally
///
/// Supports text and raw data (saveString)
/// Supports images, audios and raw bytes (saveImage)
/// Supports objects in JSON format (saveObject)
class DataPersistor implements Repository {
  /// Supports images,videos, audios and raw bytes
  @override
  Future<String> saveImage(String path, Uint8List image) async {
    final base64Image = const Base64Encoder().convert(image);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(path, base64Image);
    return path;
  }

  /// Supports objects in JSON format as Map<String, dynamic>
  @override
  Future<bool> saveObject(String path, Map<String, dynamic> object) async {
    final prefs = await SharedPreferences.getInstance();
    final string = const JsonEncoder().convert(object);

    return await prefs.setString(path, string);
  }

  /// Supports text and raw data as String
  @override
  void saveString(String path, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(path, value);
  }

  /// Gets media bytes with given [path] as String
  @override
  Future<Uint8List> getImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final base64Image = prefs.getString(path);
    if (base64Image != null) return const Base64Decoder().convert(base64Image);
    return Uint8List(0);
  }

  /// Gets json object with given [path] as String
  @override
  Future<Map<String, dynamic>> getObject(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final objectString = prefs.getString(path);
    if (objectString != null) {
      return const JsonDecoder().convert(objectString) as Map<String, dynamic>;
    }
    return <String, dynamic>{};
  }

  /// Gets text with given [path] as String
  @override
  Future<String> getString(String path) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(path) ?? '';
  }

  /// Removes media bytes with given [path] as String
  @override
  Future<void> removeImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(path);
  }

  /// Removes json object with given [path] as String
  @override
  Future<void> removeObject(String path) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(path);
  }

  /// Removes text with given [path] as String
  @override
  Future<void> removeString(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(path);
  }
}
