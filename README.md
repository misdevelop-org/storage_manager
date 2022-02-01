
## Features

Storage Manager for online (FireStorage) and offline (Shared Preferences) purposes

## Getting started

Add this import line

```dart
import 'package:storage_manager/storage_manager.dart';
```


## Usage

Upload an image to given path

```dart
  String url = await FireUploader(path:'/collectionName/Image.png').postImage(file);
```

Or upload directly from bytes (Uint8List) to given path

```dart
  String url = await FireUploader(path:'/collectionName/Image.png').postImageFromUint8List(bytes);
```

Select images from gallery and upload them

```dart
  String url = await FireUploader(path:'/collectionName/Image.png',maxImagesCount: 5).selectAndUpload();
```


Save images, text and data to device persistor

```dart
  String localPath = await DataPersistor().saveImage('/collectionName/Image.png',bytes);
```

Get images, text and data to device persistor

```dart
  var imageBytes = await DataPersistor().getImage('/collectionName/Image.png');
```

Remove images, text and data to device persistor

```dart
  DataPersistor().removeImage('/collectionName/Image.png');
```


## Additional information

This package assumes complete Firebase configuration with Storage and permissions.