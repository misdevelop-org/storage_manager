<img src="https://firebasestorage.googleapis.com/v0/b/misdevelop.appspot.com/o/storage_manager%2Fstorage_manager_cover.png?alt=media&token=0c1161df-3c19-4f75-9b04-ddc9c0111826" alt="Storage Manager by MIS Develop">

# storage_manager

[![pub package](https://img.shields.io/pub/v/storage_manager.svg)](https://pub.dev/packages/storage_manager)

`storage_manager` gives one static API, `StorageProvider`, for two kinds of storage:

- **Firebase Cloud Storage** (`firebase_storage`): upload, download, list and delete files.
- **Local storage** (`shared_preferences`): keep strings, bytes (images, videos, audio) and JSON on the device.

It also includes an image/video picker (gallery or camera) and an upload progress dialog. You can replace both
with your own UI.

## Features

- Upload a `String`, `Uint8List`, `List<int>` or JSON map and get its download URL back.
- Download a file as bytes, as UTF-8 text or as decoded JSON.
- Pick one or more images, or a video, then upload them in a single call.
- Show an optional upload progress dialog, or plug in your own.
- Use the same `save` / `get` / `remove` calls for local storage.

## Compatibility

| storage_manager | firebase_storage | Dart / Flutter |
|---|---|---|
| 0.7.x | 12.x and 13.x | Dart ≥ 3.6, Flutter ≥ 3.27 |
| 0.6.x | 12.x | Dart ≥ 3.4, Flutter ≥ 3.27 |

The supported platforms are Android, iOS, macOS and Web, which are the platforms `firebase_storage` and
`image_picker` support.

## Getting started

1. Configure Firebase in your app, for example with the [FlutterFire CLI](https://firebase.flutter.dev/docs/overview/):

   ```shell
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

2. Add the package:

   ```shell
   flutter pub add storage_manager
   ```

3. Import it:

   ```dart
   import 'package:storage_manager/storage_manager.dart';
   ```

`image_picker` needs camera and photo permissions on iOS and macOS. See the
[image_picker setup](https://pub.dev/packages/image_picker#installation).

## Usage

### Upload to Cloud Storage

For remote uploads, `path` is a **folder prefix**. The file is stored at `path + fileName + extensionFormat`, and
`fileName` defaults to the current timestamp. Each call returns the download URL.

```dart
// Text, bytes or a JSON map (maps are uploaded as JSON text).
final url = await StorageProvider.save('notes/', 'Hello', fileName: 'greeting', extensionFormat: '.txt');
final jsonUrl = await StorageProvider.save('configs/', {'theme': 'dark'}, extensionFormat: '.json');
final bytesUrl = await StorageProvider.save('files/', bytes, extensionFormat: '.pdf');

// An XFile from image_picker. It is stored as `<original-name>-<timestamp><extension>`.
final imageUrl = await StorageProvider.saveImage(xFile, 'users/42/avatars/'); // default '.png'
final videoUrl = await StorageProvider.saveVideo(xFile, 'users/42/videos/'); // default '.mp4'
final fileUrl = await StorageProvider.saveBytes(xFile, 'uploads/', extensionFormat: '.bin');
```

### Download from Cloud Storage

```dart
final Uint8List? image = await StorageProvider.getImage('users/42/avatars/me.png');
final Uint8List? video = await StorageProvider.getVideo('users/42/videos/clip.mp4');
final String? text = await StorageProvider.getString('notes/greeting.txt');
final Map<String, dynamic>? json = await StorageProvider.getJson('configs/app.json');

// Generic form; `type` picks the decoder (string by default).
final dynamic value = await StorageProvider.get('configs/app.json', type: StorageType.json);
```

### Remove

```dart
await StorageProvider.remove('notes/greeting.txt');
await StorageProvider.removeUrl(downloadUrl);
await StorageProvider.remove('local-key', isLocal: true);
```

### Local storage

For local storage, `path` is the key the value is stored under.

```dart
await StorageProvider.save('profile', {'name': 'Ana'}, toLocalStorage: true);
await StorageProvider.saveLocalString('token', 'abc');
await StorageProvider.saveLocalImage('avatar', imageBytes);
await StorageProvider.saveLocalVideo('intro', videoBytes);
await StorageProvider.saveLocalJson('settings', {'sound': true});

final String? token = await StorageProvider.getLocalString('token');
final Uint8List? avatar = await StorageProvider.getLocalImage('avatar');
final Map<String, dynamic>? settings = await StorageProvider.getLocalJson('settings');
```

Bytes are stored as base64 strings in SharedPreferences. That is fine for small files; for large media, use files
or a database.

### Pick and upload images or videos

```dart
// 1. Pick. With no `source`, a bottom sheet asks for camera or gallery, so `context` is required.
if (await StorageProvider.selectAssets(context: context, maxImagesCount: 5)) {
  final List<XFile>? picked = StorageProvider.selectedAssets;

  // 2. Upload what was picked and get the download URLs back.
  final List<String> urls = await StorageProvider.uploadSelectedAssets('products/123/');
}

// Or do both in one call:
final List<String> urls = await StorageProvider.selectAndUpload(
  'products/123/',
  source: ImageSource.gallery,
  context: context,
  showProgress: true,
);

// Upload specific files instead of the picked ones:
final List<String> videoUrls = await StorageProvider.uploadSelectedAssets(
  'clips/',
  selectedImages: [videoFile],
  isVideo: true,
);
```

`selectAssets` returns `false` when the user cancels. If `maxImagesCount` is greater than 1 and the source is the
gallery, the user can select several images.

## Customization

Set the context, the progress behaviour, the source picker and the progress dialog once, for example in your root
widget:

```dart
StorageProvider.configure(
  context: context,
  showProgress: true,
  getImageSource: () => showDialog<ImageSource>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Select image source'),
      children: [
        ListTile(
          leading: const Icon(Icons.camera_alt),
          title: const Text('Camera'),
          onTap: () => Navigator.pop(context, ImageSource.camera),
        ),
        ListTile(
          leading: const Icon(Icons.photo),
          title: const Text('Gallery'),
          onTap: () => Navigator.pop(context, ImageSource.gallery),
        ),
      ],
    ),
  ),
  showDataUploadProgress: (uploadTask) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Uploading...'),
      content: ProgressFromUploadTask(task: uploadTask, onDone: () => Navigator.pop(context)),
    ),
  ),
);
```

Each setting can also be changed on its own with `StorageProvider.context`, `StorageProvider.showProgress`,
`StorageProvider.getImageSource` and `StorageProvider.customUploadProgressIndicator`.

For lower-level access, use `FireUploader` (Cloud Storage) and `DataPersistor` (SharedPreferences) directly.

## Web: CORS for downloads and images

In the browser, `getImage` / `getString` / `getJson` (which download bytes) and `Image.network` on Storage URLs
need your bucket to allow your app's origin. Create a `cors.json` file:

```json
[
  {
    "origin": ["https://your-app.web.app", "http://localhost:8080"],
    "method": ["GET"],
    "maxAgeSeconds": 3600
  }
]
```

Then apply it to the bucket:

```shell
gcloud storage buckets update gs://YOUR_BUCKET --cors-file=cors.json
```

## Additional information

- This package assumes Firebase is initialized and that your Storage security rules allow the paths you use.
- Example app: [`example/`](https://github.com/misdevelop-org/storage_manager/tree/main/example)
- Issues and contributions: [GitHub](https://github.com/misdevelop-org/storage_manager/issues)
