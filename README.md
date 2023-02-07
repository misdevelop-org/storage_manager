
<img  src="https://firebasestorage.googleapis.com/v0/b/misdevelop.appspot.com/o/storage_manager%2Fstorage_manager_cover.png?alt=media&token=0c1161df-3c19-4f75-9b04-ddc9c0111826"  alt="MIS Develop">  
  
## Features  
  
Storage Manager for online (FireStorage) and offline (Shared Preferences) purposes  
  
## Getting started  
  
Add this import line  
  
```dart  
import 'package:storage_manager/storage_manager.dart';  
```  

## Usage  

### Save (upload), get (download) and remove (delete) 
  
#### Upload an Object (image, string, json or bytes) to given path  
  
```dart  
  String url = await StorageProvider.i.save('collectionName/Image.png', image);  
```

#### Get images, text and data to device persistor

```dart  
  var imageBytes = await StorageProvider.i.get('collectionName/Image.png');  
```  

#### Remove files from storage or local path  
  
```dart  
  bool removed = await StorageProvider.i.remove('collectionName/Image.png');  
```

or from storage URL  
  
```dart  
  bool success = await StorageProvider.i.removeUrl('url');  
```  
  
  
  
### Integrated image picker feature

#### Select images from gallery or camera

```dart  
   if(await StorageProvider.i.selectImages()){
        List<XFile> images =  StorageProvider.i.selectedAssets;
   }else{
        print('User cancelled selection');
   }
```
#### Upload selected images to given path

```dart  
    /// You can use the selectedAssets from the previous step or select new ones with image_picker
    List<XFile> images = StorageProvider.i.selectedAssets;
    List<String> urls = await StorageProvider.i.save('collectionName', images);  
```
#### Select images from gallery and upload them

```dart  
  String url = await StorageProvider.i.selectAndUpload();  
```  


## Additional information  
  
This package assumes complete Firebase configuration with Storage and permissions.