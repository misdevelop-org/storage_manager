part of '../storage_manager.dart';

/// Saves, gets and removes data locally with SharedPreferences.
///
/// * Text and raw data as [String] ([saveString])
/// * Images, videos, audios and raw bytes as base64 ([saveImage])
/// * Objects in JSON format ([saveObject])
class DataPersistor implements Repository {
  /// Saves images, videos, audios and raw bytes as a base64 string.
  Future<String> saveImage(String path, Uint8List image) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(path, base64Encode(image));
    return path;
  }

  /// Saves an object in JSON format as `Map<String, dynamic>`.
  @override
  Future<bool> saveObject(String path, dynamic object) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(path, jsonEncode(object as Map<String, dynamic>));
  }

  /// Saves text and raw data as [String].
  Future<void> saveString(String path, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(path, value);
  }

  /// Gets media bytes stored at [path].
  Future<Uint8List> getImage(String path) async => getBytes(path);

  /// Gets bytes stored at [path], or an empty list when nothing is stored.
  Future<Uint8List> getBytes(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final base64Data = prefs.getString(path);
    if (base64Data != null) return base64Decode(base64Data);
    return Uint8List(0);
  }

  /// Gets the JSON object stored at [path], or an empty map when nothing is stored.
  @override
  Future<Map<String, dynamic>> getObject(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final objectString = prefs.getString(path);
    if (objectString != null) return jsonDecode(objectString) as Map<String, dynamic>;
    return <String, dynamic>{};
  }

  /// Gets the text stored at [path], or an empty string when nothing is stored.
  Future<String> getString(String path) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(path) ?? '';
  }

  /// Removes the value stored at [path].
  @override
  Future<void> removeObject(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(path);
  }
}
