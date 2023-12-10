import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:storage_manager/storage_manager.dart';

class StorageProvider {
  ///List of links from uploaded files
  static List<String> links = [];

  ///Final path where the files will be saved
  static List<XFile>? selectedAssets = [];

  BuildContext? _context;

  ///Shows upload progress indicator and MUST set the [context]
  bool _showProgress = false;

  /// Gets the image source from user
  Future<ImageSource?> Function()? _getImageSource;

  /// Shows the upload progress indicator
  Future<void> Function(UploadTask uploadTask)? _showDataUploadProgress;

  ///Get object from storage or local
  static Future<dynamic> get(String path,
      {bool isLocal = false, StorageType type = StorageType.string}) async {
    switch (type) {
      case StorageType.image:
        getImage(path, isLocal: isLocal);
      case StorageType.video:
        getVideo(path, isLocal: isLocal);
      case StorageType.string:
        getString(path, isLocal: isLocal);
      case StorageType.json:
        getJson(path, isLocal: isLocal);
    }
  }

  /// Get image from local storage
  static Future<Uint8List?> getLocalImage(String path) async {
    return DataPersistor().getImage(path);
  }

  /// Get video from local storage
  static Future<Uint8List?> getLocalVideo(String path) async {
    return DataPersistor().getBytes(path);
  }

  /// Get string from local storage
  static Future<String?> getLocalString(String path) async {
    return DataPersistor().getString(path);
  }

  /// Get json from local storage
  static Future<Map<String, dynamic>?> getLocalJson(String path) async {
    return DataPersistor().getObject(path);
  }

  /// Get image from storage or local
  static Future<Uint8List?> getImage(String path,
      {bool isLocal = false}) async {
    if (isLocal) {
      return getLocalImage(path);
    } else {
      return await FireUploader().getObject(path);
    }
  }

  /// Get video from storage or local
  static Future<Uint8List?> getVideo(String path,
      {bool isLocal = false}) async {
    if (isLocal) {
      return getLocalVideo(path);
    } else {
      return await FireUploader().getObject(path);
    }
  }

  /// Get string from storage or local
  static Future<String?> getString(String path, {bool isLocal = false}) async {
    if (isLocal) {
      return getLocalString(path);
    } else {
      return await FireUploader().getObject(path) as String;
    }
  }

  /// Get json from storage or local
  static Future<Map<String, dynamic>?> getJson(String path,
      {bool isLocal = false}) async {
    if (isLocal) {
      return getLocalJson(path);
    } else {
      return jsonDecode(await FireUploader().getObject(path) as String);
    }
  }

  ///### Save an object to database
  ///* if [toLocalStorage] is true, it will save to local storage
  ///* if [toLocalStorage] is false, it will save to firebase storage
  /// Default extension format is json
  static Future<String> save(String path, dynamic value,
      {String? extensionFormat,
      String? fileName,
      bool showProgress = false,
      BuildContext? context,
      bool toLocalStorage = false}) async {
    if (toLocalStorage) {
      switch (value.runtimeType) {
        case String:
          DataPersistor().saveString(path, value as String);
          return path;
        case Uint8List:
          DataPersistor().saveImage(path, value as Uint8List);
          return path;
        case const (List<int>):
          DataPersistor().saveImage(path, value as Uint8List);
          return path;
        default:
          DataPersistor().saveObject(path, value);
          return path;
      }
    }
    if (value is Map<String, dynamic>) {
      return await FireUploader().saveObject(path, jsonEncode(value),
          extensionFormat: extensionFormat,
          fileName: fileName,
          showProgress: showProgress,
          context: context);
    }
    return await FireUploader().saveObject(path, value,
        extensionFormat: extensionFormat,
        fileName: fileName,
        showProgress: showProgress,
        context: context);
  }

  ///### Saves the image to local storage
  /// Default extension format is png
  static Future<String> saveLocalImage(String path, Uint8List imageBytes,
          {String? extensionFormat = '.png'}) async =>
      DataPersistor().saveImage(path, imageBytes);

  ///### Saves the video to local storage
  /// Default extension format is mp4
  static Future<String> saveLocalVideo(String path, Uint8List videoBytes,
          {String? extensionFormat = '.mp4'}) async =>
      DataPersistor().saveImage(path, videoBytes);

  ///### Saves the string to local storage
  /// Default extension format is txt
  static Future<void> saveLocalString(String path, String value,
          {String? extensionFormat = '.txt'}) async =>
      DataPersistor().saveString(path, value);

  ///### Saves the json to local storage
  /// Default extension format is json
  static Future<void> saveLocalJson(String path, Map<String, dynamic> value,
          {String? extensionFormat = '.json'}) async =>
      DataPersistor().saveObject(path, value);

  ///### Uploads the selected image as XFile and returns a link
  /// Default extension format is png
  static Future<String> saveImage(XFile imageFile, String path,
          {String? extensionFormat = '.png'}) async =>
      saveBytes(imageFile, path, extensionFormat: extensionFormat);

  ///### Uploads the selected video as XFile and returns a link
  /// Default extension format is mp4
  static Future<String> saveVideo(XFile videoFile, String path,
          {String? extensionFormat = '.mp4'}) async =>
      saveBytes(videoFile, path, extensionFormat: extensionFormat);

  ///### Uploads the selected Asset as XFile and returns file link
  /// Supports the extension format, if not set, will be set to application/octet-stream (bytes)
  static Future<String> saveBytes(XFile imageFile, String path,
      {String? extensionFormat}) async {
    var byteData = await imageFile.readAsBytes();
    final name = imageFile.name.split('.').first;
    String fileName =
        '$name-${DateTime.now().millisecondsSinceEpoch.toString()}';
    Reference reference =
        FirebaseStorage.instance.ref(path + fileName + (extensionFormat ?? ""));
    UploadTask uploadTask = reference.putData(byteData.buffer.asUint8List());
    if (instance._showProgress) {
      if (instance._context == null) {
        throw Exception("Must set context if showProgress is true");
      }
      if (instance._showDataUploadProgress != null) {
        await instance._showDataUploadProgress!(uploadTask);
      } else {
        await FireUploader()
            .showDataUploadProgress(instance._context!, uploadTask);
      }
    }
    TaskSnapshot storageTaskSnapshot = await uploadTask.whenComplete(() {});
    String link = await storageTaskSnapshot.ref.getDownloadURL();
    return link;
  }

  ///Let the default [showModalBottomSheet] get the source from user.
  ///
  /// Context is required and can be set using [set context] or passing directly to the function.
  static Future<ImageSource?> getSource({
    Color? backgroundColor = Colors.transparent,
    BuildContext? context,
  }) async {
    if (instance._context == null && context == null) {
      throw Exception("You must set context to get source");
    }
    return await showModalBottomSheet<ImageSource?>(
      context: instance._context ?? context!,
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
                    Navigator.of(context).pop(ImageSource.camera);
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
                    Navigator.of(context).pop(ImageSource.gallery);
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
  static Future<void> remove(String path, {bool isLocal = false}) async {
    if (isLocal) {
      DataPersistor().removeObject(path);
    } else {
      await FireUploader().removeObject(path);
    }
  }

  ///Remove object from url (only storage in firebase)
  static Future<void> removeUrl(String url) async {
    await FireUploader().removeObjectFromUrl(url);
  }

  ///## Select assets from gallery or camera and stores them in the variable [selectedAssets].
  ///* Select gallery or camera as [source] by using [ImageSource].
  ///* Let the default [showModalBottomSheet] get the source from user by setting [source] to null.
  ///* You can set [showProgress] to show upload progress indicator.
  ///
  ///## You must set the [context] if [source] is null or [showProgress] is true.
  ///* When context is required, can be set using [StorageProvider.context] or passing directly to the function.
  ///
  ///## Customization
  ///* You can set the ImageSource get function to have a custom implementation
  ///* You can set the upload progress indicator to have a custom implementation
  static Future<List<String>> selectAndUpload(
    String path, {
    ImageSource? source,
    bool isVideo = false,
    Color? backgroundColor = Colors.transparent,
    int maxImagesCount = 10,
    BuildContext? context,
    String? extensionFormat,
    bool showProgress = false,
  }) async {
    instance._context = context ?? instance._context;
    instance._showProgress = showProgress;
    if (await selectAssets(
        source: source,
        isVideo: isVideo,
        backgroundColor: backgroundColor,
        maxImagesCount: maxImagesCount)) {
      return (await uploadSelectedAssets(path,
          isVideo: isVideo,
          extensionFormat: extensionFormat,
          showProgress: showProgress,
          context: context));
    } else {
      return <String>[];
    }
  }

  ///## Select assets from gallery or camera and stores them in the variable [selectedAssets].
  ///* Select gallery or camera as [source] by using [ImageSource].
  ///* Let the default [showModalBottomSheet] get the source from user by setting [source] to null.
  ///
  ///## You must set the [context] if [source] is null.
  ///* When context is required, can be set using [StorageProvider.context] or passing directly to the function.
  ///
  ///## Customization
  ///* You can set the ImageSource get function to have a custom implementation
  static Future<bool> selectAssets({
    bool isVideo = false,
    ImageSource? source,
    BuildContext? context,
    Color? backgroundColor = Colors.transparent,
    int maxImagesCount = 10,
  }) async {
    instance._context = context ?? instance._context;
    if (source == null) {
      ImageSource? selectedSource = instance._getImageSource != null
          ? await instance._getImageSource!()
          : await getSource(backgroundColor: backgroundColor);
      if (selectedSource != null) {
        source = selectedSource;
      } else {
        return false;
      }
    }
    try {
      selectedAssets = (isVideo
          ? [(await ImagePicker().pickVideo(source: source))!]
          : maxImagesCount > 1 && source == ImageSource.gallery
              ? await ImagePicker().pickMultiImage()
              : [(await ImagePicker().pickImage(source: source))!]);
    } catch (e) {
      if (kDebugMode) print(e.toString());
      selectedAssets = [];
    }
    return selectedAssets!.isNotEmpty;
  }

  ///## Upload the [selectedAssets] to the given [path].
  ///* You can set [showProgress] to show upload progress indicator.
  ///
  ///## You must set the [context] if [showProgress] is true.
  ///* When context is required, can be set using [StorageProvider.context] or passing directly to the function.
  ///
  ///## Customization
  ///* You can set the upload progress indicator to have a custom implementation
  static Future<List<String>> uploadSelectedAssets(String path,
      {List<XFile>? selectedImages,
      BuildContext? context,
      String? extensionFormat,
      bool isVideo = false,
      bool showProgress = false}) async {
    instance._context = context ?? instance._context;
    instance._showProgress = showProgress;
    if (selectedImages != null) links = <String>[];
    for (var imageFile in selectedImages ?? selectedAssets!) {
      links.add((isVideo
          ? await saveVideo(imageFile, path,
              extensionFormat: extensionFormat ?? '.mp4')
          : await saveImage(imageFile, path,
              extensionFormat: extensionFormat ?? '.png')));
    }
    selectedAssets?.clear();
    return links;
  }

  static set context(BuildContext? context) => instance._context = context;

  ///Shows upload progress indicator and MUST set the [context]
  static set showProgress(bool showProgress) =>
      instance._showProgress = showProgress;

  /// You can set the ImageSource get function to have a custom implementation
  static set getImageSource(Future<ImageSource?> Function()? getImageSource) =>
      instance._getImageSource = getImageSource;

  /// You can set the upload progress indicator to have a custom implementation
  static set customUploadProgressIndicator(
          Future<void> Function(UploadTask uploadTask)?
              showDataUploadProgress) =>
      instance._showDataUploadProgress = showDataUploadProgress;

  static void configure({
    BuildContext? context,
    bool showProgress = false,
    Future<ImageSource?> Function()? getImageSource,
    Future<void> Function(UploadTask uploadTask)? showDataUploadProgress,
  }) {
    instance._context = context;
    instance._getImageSource = getImageSource;
    instance._showDataUploadProgress = showDataUploadProgress;
    instance._showProgress = showProgress;
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
  video(Uint8List),
  string(String),
  json(Map<String, dynamic>);

  final Type type;
  const StorageType(this.type);
}
