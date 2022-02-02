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

  ///Select assets from gallery and returns the uploaded file paths
  Future<List<String>> selectAndUpload() async {
    await selectAssets();
    return (await uploadSelectedAssets());
  }

  ///Select assets from gallery and stores the Assets in the variable [selectedAssets]
  Future<void> selectAssets() async {
    selectedAssets = (maxImagesCount > 1
            ? await ImagePicker().pickMultiImage()
            : [await ImagePicker().pickImage(source: ImageSource.gallery)])
        as List<XFile>?;
  }

  ///Uploads the Assets in [selectedAssets]
  Future<List<String>> uploadSelectedAssets() async {
    for (var imageFile in selectedAssets!) {
      links.add((await saveImage(imageFile)));
    }
    return links;
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

  StreamSubscription<TaskSnapshot>? streamSubscription;

  ///Shows the ProgressIndicator in the flash bar
  show() async {
    streamSubscription = widget.task.snapshotEvents.listen((event) {
      setState(() {
        value = event.bytesTransferred / event.totalBytes;
      });
      if (value == 1 && !ended) {
        streamSubscription!.cancel();
        widget.onDone();
        ended = true;
      }
    });
  }

  @override
  void dispose() {
    if (streamSubscription != null) streamSubscription!.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    show();
  }

  @override
  Widget build(BuildContext context) {
    return ended
        ? Row(
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
          )
        : LinearProgressIndicator(value: value);
  }
}
