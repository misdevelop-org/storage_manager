/*
 * Copyright (c) 2019 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../src/Repository.dart';

class DataPersistor implements Repository {
  @override
  Future<String> saveImage(String path, Uint8List image) async {
    final base64Image = const Base64Encoder().convert(image);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(path, base64Image);
    return path;
  }

  @override
  Future<bool> saveObject(String path, Map<String, dynamic> object) async {
    final prefs = await SharedPreferences.getInstance();
    final string = const JsonEncoder().convert(object);

    return await prefs.setString(path, string);
  }

  @override
  void saveString(String path, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(path, value);
  }

  @override
  Future<Uint8List> getImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final base64Image = prefs.getString(path);
    if (base64Image != null) return const Base64Decoder().convert(base64Image);
    return [] as Uint8List;
  }

  @override
  Future<Map<String, dynamic>> getObject(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final objectString = prefs.getString(path);
    if (objectString != null) return const JsonDecoder().convert(objectString) as Map<String, dynamic>;
    return {};
  }

  @override
  Future<String> getString(String path) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(path) ?? '';
  }

  @override
  Future<void> removeImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(path);
  }

  @override
  Future<void> removeObject(String path) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(path);
  }

  @override
  Future<void> removeString(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(path);
  }
}
