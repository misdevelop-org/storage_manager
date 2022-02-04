
<img  src="https://firebasestorage.googleapis.com/v0/b/misdevelop.appspot.com/o/storage_manager%2FPackages%202.png?alt=media&token=99e4fe86-295a-49cb-9c17-2664d720118d"  alt="MIS Develop">  
  
## Features  
  
Storage Manager for online (FireStorage) and offline (Shared Preferences) purposes  
  
## Getting started  
  
Add this import line  
  
```dart  
import 'package:storage_manager/storage_manager.dart';  
```  
  
  
## Usage  
  
#### Upload an image to given path  
  
```dart  
  String url = await FireUploader(path:'/collectionName/Image.png').saveImage(file);  
```  
  
Or upload directly from bytes (Uint8List) to given path  
  
```dart  
  String url = await FireUploader(path:'/collectionName/Image.png').saveFileFromBytes(bytes);  
```  
  
#### Select images from gallery and upload them  
  
```dart  
  String url = await FireUploader(path:'/collectionName/Image.png').selectAndUpload();  
```  
  
#### Remove files from Storage Path  
  
```dart  
  bool success = await FireUploader.removeFileFromPath('/collectionName/Image.png');  
```  
  
or from Storage link  
  
```dart  
  bool success = await FireUploader.removeFileFromUrl(urlLink);  
```  
  
  
#### Save images, text and data to device persistor  
  
```dart  
  String localPath = await DataPersistor().saveImage('/collectionName/Image.png',bytes);  
```  
  
#### Get images, text and data to device persistor  
  
```dart  
  var imageBytes = await DataPersistor().getImage('/collectionName/Image.png');  
```  
  
#### Remove images, text and data to device persistor  
  
```dart  
  DataPersistor().removeImage('/collectionName/Image.png');  
```  
  
## Additional information  
  
This package assumes complete Firebase configuration with Storage and permissions.