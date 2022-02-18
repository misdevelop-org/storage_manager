import 'dart:async';
// import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flash/flash.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Saves, gets and removes data online with FireStorage
///
/// Supports images from Asset file [saveImage]
/// Supports images, audios, videos and  files from bytes [saveFileFromBytes]
/// Supports files from File [saveFile]
///
/// - Facilitates Image selection from gallery and camera
/// - Facilitates upload progress indicator as Flash Bar
class FireUploader {
  FireUploader(
      {this.maxImagesCount = 10,
      this.path = '/',
      this.selectedAssets = const [],
      this.context,
      this.showProgress = false});

  ///MUST set the [context] if true
  bool showProgress = false;

  ///Restrict the gallery selection
  int maxImagesCount = 10;

  ///Final path where the files will be saved
  String path = "";

  ///Uploaded files links
  List<String> links = [];

  ///Selected assets from gallery
  ///
  /// Call [selectAssets] to populate it
  List<XFile>? selectedAssets = [];

  ///ONLY needed if [showProgress] is true
  BuildContext? context;

  Future<bool> showDataUploadProgress(
      BuildContext context, UploadTask task) async {
    bool successUpload = false;

    await showFlash(
      context: context,
      persistent: true,
      builder: (context, controller) {
        return Flash(
          barrierDismissible: true,
          backgroundColor: Colors.blue[800],
          controller: controller,
          position: FlashPosition.bottom,
          behavior: FlashBehavior.fixed,
          boxShadows: kElevationToShadow[4],
          horizontalDismissDirection: HorizontalDismissDirection.horizontal,
          child: FlashBar(
            icon: const Icon(Icons.upload_rounded),
            title: Text(
              "Uploading " + task.snapshot.ref.name,
              style: const TextStyle(color: Colors.white, fontSize: 25),
            ),
            content: ProgressFromUploadTask(
                task: task,
                onDone: () {
                  successUpload = true;
                  if (!controller.isDisposed) {
                    controller.dismiss();
                  }
                }),
          ),
        );
      },
    );

    return successUpload;
  }

  ///Select assets from gallery or camera and returns the uploaded file paths
  ///
  ///Select gallery as source by setting [isGallery] to true
  ///
  ///Select camera as source by setting [isGallery] to false
  ///
  ///Let the default showModalBottomSheet get the source from user by setting [isGallery] to null
  ///
  /// [isGallery] defaults to null
  Future<List<String>> selectAndUpload(
      {bool? isGallery, Color? backgroundColor = Colors.transparent}) async {
    if (await selectAssets(
        isGallery: isGallery, backgroundColor: backgroundColor)) {
      return (await uploadSelectedAssets());
    } else {
      return <String>[];
    }
  }

  ///Select assets from gallery or camera and stores the Assets in the variable [selectedAssets]
  ///Select gallery as source by setting [isGallery] to true
  ///Select camera as source by setting [isGallery] to false
  ///Let the default showModalBottomSheet get the source from user by setting [isGallery] to null
  ///
  /// [isGallery] defaults to null
  Future<bool> selectAssets(
      {bool? isGallery, Color? backgroundColor = Colors.transparent}) async {
    isGallery ??= await getSource(backgroundColor: backgroundColor);
    if (isGallery == null) {
      return false;
    }
    selectedAssets = (maxImagesCount > 1 && isGallery
        ? await ImagePicker().pickMultiImage()
        : [
            await ImagePicker().pickImage(
                source: isGallery ? ImageSource.gallery : ImageSource.camera)
          ].map((e) => e!).toList());
    return true;
  }

  ///Uploads the Assets in [selectedAssets]
  Future<List<String>> uploadSelectedAssets() async {
    for (var imageFile in selectedAssets!) {
      links.add((await saveImage(imageFile)));
    }
    return links;
  }

  ///Let the default showModalBottomSheet get the source from user
  Future<bool?> getSource({Color? backgroundColor = Colors.transparent}) async {
    return await showModalBottomSheet<bool?>(
      context: context!,
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

  ///Uploads the selected Asset and returns file link
  Future<String> saveImage(XFile imageFile) async {
    var byteData = await imageFile.readAsBytes();
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference = FirebaseStorage.instance.ref(path + fileName);
    UploadTask uploadTask = reference.putData(byteData.buffer.asUint8List());
    if (showProgress) {
      await showDataUploadProgress(context!, uploadTask);
    }
    TaskSnapshot storageTaskSnapshot = await uploadTask.whenComplete(() {});
    String link = await storageTaskSnapshot.ref.getDownloadURL();
    return link;
  }

  ///Uploads the selected bytes and returns file link
  ///
  /// Supports the extension format
  Future<String> saveFileFromBytes(List<int> byteData,
      {String? extensionFormat}) async {
    // var byteData = await imageFile.getByteData();
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference =
        FirebaseStorage.instance.ref(path + fileName + (extensionFormat ?? ""));
    UploadTask uploadTask = reference.putData(byteData as Uint8List);
    if (showProgress) {
      await showDataUploadProgress(context!, uploadTask);
    }
    TaskSnapshot storageTaskSnapshot = await uploadTask.whenComplete(() {});
    String link = await storageTaskSnapshot.ref.getDownloadURL();
    return link;
  }

  /// Removes the file from the given [path]
  Future<bool> removeFileFromPath(String path) async {
    try {
      await FirebaseStorage.instance.ref(path).delete();
    } catch (err, stack) {
      if (kDebugMode) {
        print(err);
        print(stack);
      }
      return false;
    }
    return true;
  }

  /// Removes the file from the given url link
  Future<bool> removeFileFromUrl(String urlPath) async {
    try {
      await FirebaseStorage.instance.refFromURL(urlPath).delete();
    } catch (err, stack) {
      if (kDebugMode) {
        print(err);
        print(stack);
      }
      return false;
    }
    return true;
  }
}

///Creates a Flash bar with a LinearProgress indicating the upload task
class ProgressFromUploadTask extends StatefulWidget {
  final UploadTask task;
  final Function onDone;
  const ProgressFromUploadTask(
      {Key? key, required this.task, required this.onDone})
      : super(key: key);
  @override
  _ProgressFromUploadTaskState createState() => _ProgressFromUploadTaskState();
}

class _ProgressFromUploadTaskState extends State<ProgressFromUploadTask> {
  double value = 0;
  bool ended = false;

  ///Shows the ProgressIndicator in the flash bar
  show() async {
    widget.task.snapshotEvents.listen(
      (event) {
        setState(() {
          value = event.bytesTransferred / event.totalBytes;
        });
        if (value == 1 && !ended) {
          widget.onDone();
          ended = true;
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    show();
  }

  @override
  Widget build(BuildContext context) {
    return ended
        ? Container(
            width: 100,
            height: 60,
            decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.done,
                  size: 30,
                  color: Colors.white,
                ),
                Text(
                  "Done!",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          )
        : LinearProgressIndicator(value: value);
  }
}
