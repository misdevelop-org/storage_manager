import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:storage_manager/storage_manager.dart';

class StorageProvider {
  List<String> links = [];

  BuildContext? _context;
  bool _showProgress = false;

  ///Selected assets from gallery
  /// Call [selectAssets] to populate it
  List<XFile>? selectedAssets = [];

  /// Save an object to database, if [saveToLocal] is true, it will save to local storage
  Future<String> save(String path, dynamic value,
      {String? extensionFormat,
      String? fileName,
      bool showProgress = false,
      BuildContext? context,
      bool saveToLocal = false}) async {
    if (saveToLocal) {
      switch (value.runtimeType) {
        case String:
          DataPersistor().saveString(path, value as String);
          return path;
        case Uint8List:
          DataPersistor().saveImage(path, value as Uint8List);
          return path;
        case List<int>:
          DataPersistor().saveImage(path, value as Uint8List);
          return path;
        default:
          DataPersistor().saveObject(path, value);
          return path;
      }
    }
    if (value is Map<String, dynamic>) {
      return await FireUploader().saveObject(path, jsonEncode(value),
          extensionFormat: extensionFormat, fileName: fileName, showProgress: showProgress, context: context);
    }

    return await FireUploader().saveObject(path, value,
        extensionFormat: extensionFormat, fileName: fileName, showProgress: showProgress, context: context);
  }

  ///Uploads the selected Asset and returns file link
  Future<String> saveImage(XFile imageFile, String path) async {
    var byteData = await imageFile.readAsBytes();
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference = FirebaseStorage.instance.ref(path + fileName);
    UploadTask uploadTask = reference.putData(byteData.buffer.asUint8List());
    if (_showProgress) {
      if (_context == null) {
        throw Exception("Must set context if showProgress is true");
      }
      await FireUploader().showDataUploadProgress(_context!, uploadTask);
    }
    TaskSnapshot storageTaskSnapshot = await uploadTask.whenComplete(() {});
    String link = await storageTaskSnapshot.ref.getDownloadURL();
    return link;
  }

  ///Let the default showModalBottomSheet get the source from user
  Future<bool?> getSource({
    Color? backgroundColor = Colors.transparent,
  }) async {
    if (_context == null) {
      throw Exception("Must set context to get source");
    }
    return await showModalBottomSheet<bool?>(
      context: _context!,
      backgroundColor: backgroundColor,
      builder: (BuildContext context) {
        double size = 80;
        double iconSize = 30;
        return SizedBox(
          height: 160 + MediaQuery.of(context).viewPadding.bottom,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                height: size,
                width: 150,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                              height: size,
                              width: size,
                              decoration: BoxDecoration(
                                color: Colors.lightBlue[700],
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.camera,
                                  size: iconSize,
                                  color: Colors.white,
                                ),
                              )),
                        ),
                        const Text(
                          "Camera",
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        )
                      ],
                    ),
                  ),
                ),
              ), //Camera
              SizedBox(
                height: size,
                width: 150,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                              height: size,
                              width: size,
                              decoration: BoxDecoration(
                                color: Colors.blue[900],
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.photo,
                                  size: iconSize,
                                  color: Colors.white,
                                ),
                              )),
                        ),
                        const Text(
                          "Gallery",
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        )
                      ],
                    ),
                  ),
                ),
              ), //Gallery
            ],
          ),
        );
      },
    );
  }

  ///Remove object from storage
  Future<void> remove(String path, {bool isLocal = false}) async {
    if (isLocal) {
      DataPersistor().removeObject(path);
    } else {
      await FireUploader().removeObject(path);
    }
  }

  ///Remove object from url (only storage in firebase)
  Future<void> removeUrl(String url) async {
    await FireUploader().removeObjectFromUrl(url);
  }

  ///Get object from storage or local
  Future<dynamic> get(String path, {bool isLocal = false, StorageType type = StorageType.string}) async {
    switch (type) {
      case StorageType.image:
        if (isLocal) {
          return DataPersistor().getImage(path);
        } else {
          return await FireUploader().getObject(path) as Uint8List;
        }
      case StorageType.string:
        if (isLocal) {
          return DataPersistor().getString(path);
        } else {
          return await FireUploader().getObject(path) as String;
        }
      case StorageType.json:
        if (isLocal) {
          return DataPersistor().getObject(path);
        } else {
          return jsonDecode(await FireUploader().getObject(path) as String);
        }
    }
  }

  ///Select assets from gallery or camera and returns the uploaded file paths
  ///Select gallery as source by setting [isGallery] to true
  ///Select camera as source by setting [isGallery] to false
  ///Let the default showModalBottomSheet get the source from user by setting [isGallery] to null
  /// [isGallery] defaults to null
  Future<List<String>> selectAndUpload(String path,
      {bool? isGallery,
      Color? backgroundColor = Colors.transparent,
      int maxImagesCount = 10,
      BuildContext? context,
      bool showProgress = false}) async {
    _context = context ?? _context;
    _showProgress = showProgress;
    if (await selectAssets(isGallery: isGallery, backgroundColor: backgroundColor, maxImagesCount: maxImagesCount)) {
      return (await uploadSelectedAssets(path, showProgress: showProgress, context: context));
    } else {
      return <String>[];
    }
  }

  ///Select assets from gallery or camera and stores the Assets in the variable [selectedAssets]
  ///Select gallery as source by setting [isGallery] to true
  ///Select camera as source by setting [isGallery] to false
  ///Let the default showModalBottomSheet get the source from user by setting [isGallery] to null
  /// [isGallery] defaults to null
  Future<bool> selectAssets(
      {bool? isGallery,
      BuildContext? context,
      Color? backgroundColor = Colors.transparent,
      int maxImagesCount = 10}) async {
    _context = context ?? _context;
    isGallery ??= await getSource(backgroundColor: backgroundColor);
    if (isGallery == null) {
      return false;
    }
    selectedAssets = (maxImagesCount > 1 && isGallery
        ? await ImagePicker().pickMultiImage()
        : [await ImagePicker().pickImage(source: isGallery ? ImageSource.gallery : ImageSource.camera)]
            .map((e) => e!)
            .toList());
    return true;
  }

  ///Uploads the Assets in [selectedAssets]
  Future<List<String>> uploadSelectedAssets(String path,
      {List<XFile>? selectedImages, BuildContext? context, bool showProgress = false}) async {
    _context = context ?? _context;
    _showProgress = showProgress;
    for (var imageFile in selectedImages ?? selectedAssets!) {
      links.add((await saveImage(imageFile, path)));
    }
    return links;
  }

  static final StorageProvider instance = StorageProvider._internal();
  static StorageProvider get i => instance;
  StorageProvider._internal();

  factory StorageProvider() {
    return instance;
  }
}

enum StorageType {
  image(Uint8List),
  string(String),
  json(Map<String, dynamic>);

  final Type type;
  const StorageType(this.type);
}
