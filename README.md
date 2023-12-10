
<img  src="https://firebasestorage.googleapis.com/v0/b/misdevelop.appspot.com/o/storage_manager%2Fstorage_manager_cover.png?alt=media&token=0c1161df-3c19-4f75-9b04-ddc9c0111826"  alt="MIS Develop Storage Manager package">  

## Features

Storage Manager for online `FirebaseStorage` and offline `Shared Preferences` purposes

## Getting started

Add this import line

```dart
import 'package:storage_manager/storage_manager.dart';  
```  

## Usage

##### This package can save and get images, videos, text (plain or json) and data (bytes) to device local storage `shared_preferences` or Firebase Cloud Storage `firebase_storage` using the latest dependencies

## Get methods

#### Get a file (image, string, video, json or bytes) from given path

```dart
  final file = await StorageProvider.get('/collectionName/fileName.png');  
```  

#### Get an image from given path

```dart
  Uint8List? image = await StorageProvider.getImage('/collectionName/fileName.png');  
```

#### Get a video from given path

```dart
  Uint8List? video = await StorageProvider.getVideo('/collectionName/fileName.mp4');  
```

#### Get a string from given path

```dart
  String? text = await StorageProvider.getString('/collectionName/fileName.txt');  
```

#### Get a json from given path

```dart
  Map<String,dynamic>? json = await StorageProvider.getJson('/collectionName/fileName.json');  
```

#### To get an image from local storage use:

```dart
   Uint8List? image = await StorageProvider.getLocalImage('/collectionName/fileName.png');  
``` 

#### To get a video from local storage use:

```dart
  Uint8List? video = await StorageProvider.getLocalVideo('/collectionName/fileName.mp4');  
```

#### To get a string from local storage use:

```dart
  String? text = await StorageProvider.getLocalString('/collectionName/fileName.txt');  
```

#### To get a JSON from local storage use:

```dart
  Map<String,dynamic>? json = await StorageProvider.getLocalJson('/collectionName/fileName.json');  
```

## Remove methods

#### Remove files from storage or local path

```dart
  bool success = await StorageProvider.remove('/collectionName/fileName.png');  
```

or from storage URL

```dart
  bool success = await StorageProvider.removeUrl('url');  
```  

## Upload methods
* Only the save method can save to local storage using the `toLocalStorage` parameter with a dynamic `value`
* The `value` parameter can be a `String`, `Uint8List`, `File`, `JSON` or `XFile` from the image picker
* The `fileName` parameter is the name of the file to be saved

```dart
  StorageProvider.save('/images/image.png', value, toLocalStorage: true);  
```

#### Upload a dynamic file (image, video, string, json or bytes) to given path

```dart
  String url = await StorageProvider.save('/collectionName/fileName.png', image);
```

#### Upload an image to given path

```dart
  String url = await StorageProvider.saveImage('/collectionName/fileName.png', image);  
```

#### Upload a video to given path

```dart
  String url = await StorageProvider.saveVideo('/collectionName/fileName.mp4', video);  
```

#### Upload a JSON to given path

```dart
  String url = await StorageProvider.saveBytes('/collectionName/fileName.json', json);  
```

### You can also save and image directly to local storage using:

```dart
  String url = await StorageProvider.saveLocalImage('/collectionName/fileName', image);  
```

#### or a Video directly to local storage using:

```dart
  String url = await StorageProvider.saveLocalVideo('/collectionName/fileName', video);  
```

#### or a String directly to local storage using:

```dart
  String url = await StorageProvider.saveLocalString('/collectionName/fileName', text);  
```

#### or a JSON directly to local storage using:

```dart
  String url = await StorageProvider.saveLocalJson('/collectionName/fileName', json);  
```

## Integrated image picker feature

#### Select images from gallery or camera

```dart
   if(await StorageProvider.selectImages()){
        List<XFile> images =  StorageProvider.selectedAssets;
   }else{
        print('User cancelled selection');
   }
```
#### Upload selected images to given path
######  You can use the selectedAssets from the previous step or select new ones with `image_picker`
```dart
    List<XFile> images = StorageProvider.selectedAssets;
    List<String> urls = await StorageProvider.save('/collectionName/', images);  
```
#### Select images from gallery and upload them

```dart
  String url = await StorageProvider.selectAndUpload();  
```  
## Customizations

#### You can customize the image picker `getSource` function and the `showDataUploadProgress` function

```dart
StorageProvider.configure(
  context: context,
  showProgress: true,
  getImageSource: () async => await showDialog<ImageSource>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Select image source"),
        children: [
          ListTile(
            title: const Text("Camera"),
            leading: const Icon(Icons.camera_alt),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            title: const Text("Gallery"),
            leading: const Icon(Icons.photo),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
  ),
  showDataUploadProgress: (uploadTask) async {
    return await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StreamBuilder<TaskSnapshot>(
          stream: uploadTask.snapshotEvents,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return AlertDialog(
                title: const Text('Uploading...'),
                content: ProgressFromUploadTask(
                  task: uploadTask,
                  onDone: () {
                    Navigator.pop(context);
                  },
                ),
              );
            } else {
              return const AlertDialog(
                title: Text('Waiting...'),
                content: LinearProgressIndicator(),
              );
            }
          },
        );
      },
    );
  },
);
```

## Rendering images from storage

* Flutter web requires an additional script to be added to the index.html file if you want to use Image.network()
  Include this script in the bottom of your `body` inside the index.html:

```html
<script type="text/javascript">
    window.flutterWebRenderer = "html";
</script>
```

## Additional information

This package assumes complete Firebase configuration with Storage and permissions.
We recommend flutterfire to configure your project. For more information visit: https://firebase.flutter.dev/docs/overview/
```shell
    dart pub global activate flutterfire_cli
    flutterfire configure
```
