
<img  src="https://firebasestorage.googleapis.com/v0/b/misdevelop.appspot.com/o/storage_manager%2Fstorage_manager_cover.png?alt=media&token=0c1161df-3c19-4f75-9b04-ddc9c0111826"  alt="MIS Develop Storage Manager package">  
  
## Features  
  
Storage Manager for online (FireStorage) and offline (Shared Preferences) purposes  
  
## Getting started  
  
Add this import line  
  
```dart  
import 'package:storage_manager/storage_manager.dart';  
```  

## Usage  

### Save (upload), get (download) and remove (delete) a file from storage

#### This package can save and get images, text and data to device local storage 
#### (shared_preferences) or Firebase Cloud Storage (firebase_storage) using the latest dependencies

#### Upload a file (image, string, json or bytes) to given a path
  
```dart  
  String url = await StorageProvider.save('collectionName/Image.png', image);  
```

#### Get a file (image, string, json or bytes) from given a path  
  
```dart  
  var file = await StorageProvider.get('collectionName/Image.png');  
```  

#### Get an image from given a path  
  
```dart  
  Uint8List? image = await StorageProvider.getImage('collectionName/Image.png');  
```

#### Get a video from given a path  
  
```dart  
  Uint8List? video = await StorageProvider.getVideo('collectionName/Video.mp4');  
```

#### Get a string from given a path  
  
```dart  
  String? text = await StorageProvider.getText('collectionName/text.txt');  
```

#### Remove files from storage or local path  
  
```dart  
  bool removed = await StorageProvider.remove('collectionName/Image.png');  
```

or from storage URL  
  
```dart  
  bool success = await StorageProvider.removeUrl('url');  
```  


#### Only the save method can save to local storage using the [toLocalStorage] parameter
#### the [value] parameter can be a [String], [Uint8List], [File], [JSON] or [XFile] (image_picker)
#### and the [fileName] parameter is the name of the file to be saved

```dart  
  StorageProvider.save('/images/[fileName]', image, toLocalStorage: true);  
```

#### You can also save and Image directly to local storage using:
    
    ```dart  
    StorageProvider.saveLocalImage('/images/[fileName]', image);  
    ```

#### or a Video directly to local storage using:
    
    ```dart  
    StorageProvider.saveLocalVideo('/videos/[fileName]', video);  
    ```

#### or a String directly to local storage using:
    
    ```dart
    StorageProvider.saveLocalText('/texts/[fileName]', text);  
    ```

#### or a JSON directly to local storage using:
    
    ```dart
    StorageProvider.saveLocalJson('/jsons/[fileName]', json);  
    ```

### Integrated image picker feature

#### Select images from gallery or camera

```dart  
   if(await StorageProvider.selectImages()){
        List<XFile> images =  StorageProvider.selectedAssets;
   }else{
        print('User cancelled selection');
   }
```
#### Upload selected images to given path

```dart  
    /// You can use the selectedAssets from the previous step or select new ones with image_picker
    List<XFile> images = StorageProvider.selectedAssets;
    List<String> urls = await StorageProvider.save('collectionName', images);  
```
#### Select images from gallery and upload them

```dart  
  String url = await StorageProvider.selectAndUpload();  
```  


## Additional information  
  
This package assumes complete Firebase configuration with Storage and permissions.