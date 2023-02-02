import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:storage_manager/src/repository.dart';

/// Saves, gets and removes data online with FireStorage
///
/// Supports images from Asset file [saveImage]
/// Supports images, audios, videos and  files from bytes [saveFileFromBytes]
/// Supports files from File [saveFile]
///
/// - Facilitates Image selection from gallery and camera
/// - Facilitates upload progress indicator as Flash Bar
class FireUploader implements Repository {
  ///Uploads the selected bytes and returns file link
  /// Supports the extension format
  ///
  /// * [bool] __showProgress__: if true, shows upload progress indicator and MUST set the [context]
  ///
  /// * [BuildContext] context: if [showProgress] is true, MUST set the [context]
  @override
  Future<String> saveObject(String path, byteData,
      {String? extensionFormat, String? fileName, bool showProgress = false, BuildContext? context}) async {
    String fileNameAux = fileName ?? DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference = FirebaseStorage.instance.ref(path + fileNameAux + (extensionFormat ?? ""));
    UploadTask? uploadTask;
    switch (byteData.runtimeType) {
      case String:
        uploadTask = reference.putString(byteData as String);
        break;
      case Uint8List:
        uploadTask = reference.putData(byteData as Uint8List);
        break;
      case File:
        uploadTask = reference.putFile(byteData as File);
        break;
      default:
        uploadTask = reference.putData(byteData as Uint8List);
    }
    if (showProgress) {
      if (context != null) {
        await showDataUploadProgress(context, uploadTask);
      } else {
        if (kDebugMode) {
          throw 'Must set context if show progress is true';
        }
      }
    }
    return await getDownloadUrl(uploadTask);
  }

  Future<String> getDownloadUrl(UploadTask uploadTask) async {
    TaskSnapshot storageTaskSnapshot = await uploadTask.whenComplete(() {});
    return await storageTaskSnapshot.ref.getDownloadURL();
  }

  @override
  Future<Uint8List?> getObject(String path) async => await referenceFromPath(path).getData();

  Reference referenceFromPath(String path) => FirebaseStorage.instance.ref(path);

  Future<List<String>?> getObjectsFromPath(String path) async {
    final objList = await FirebaseStorage.instance.ref(path).listAll();
    return objList.items.map((obj) => obj.fullPath).toList();
  }

  /// Removes the file from the given [path]
  @override
  Future<bool> removeObject(String path) async {
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

  showDataUploadProgress(BuildContext buildContext, UploadTask uploadTask) {
    return showDialog(
      context: buildContext,
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
                  ));
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
  }
}

///Creates a Flash bar with a LinearProgress indicating the upload task
class ProgressFromUploadTask extends StatefulWidget {
  final UploadTask task;
  final Function onDone;
  const ProgressFromUploadTask({Key? key, required this.task, required this.onDone}) : super(key: key);
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
            decoration: BoxDecoration(color: Colors.green[700], borderRadius: BorderRadius.circular(20)),
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
