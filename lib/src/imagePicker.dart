import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flash/flash.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

class FireUploader {
  FireUploader({this.maxImagesCount = 10, this.path = '/', this.selectedAssets = const [], required this.context, this.showProgress = false});
  int maxImagesCount = 10;
  bool showProgress = false;
  String path = "";
  List<String> links = [];
  List<Asset> selectedAssets = [];
  BuildContext context;

  Future<bool> mostrarCargaDatos(BuildContext context, UploadTask task) async {
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
          behavior: FlashBehavior.floating,
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

  Future<String> subirDatos(
    File file,
  ) async {
    final Reference storageReference = FirebaseStorage.instance.ref(path);

    UploadTask uploadTask = storageReference.putFile(file);
    if (showProgress) {
      await mostrarCargaDatos(context, uploadTask);
    }

    TaskSnapshot storageTaskSnapshot = await uploadTask.whenComplete(() {});
    String link = await storageTaskSnapshot.ref.getDownloadURL();
    return link;
  }

  Future<String> subirDatosCrudo(
    List<int> data,
  ) async {
    final Reference storageReference = FirebaseStorage.instance.ref(path);

    UploadTask uploadTask = storageReference.putData(data as Uint8List);
    if (showProgress) {
      await mostrarCargaDatos(context, uploadTask);
    }
    TaskSnapshot storageTaskSnapshot = await uploadTask.whenComplete(() {});
    String link = await storageTaskSnapshot.ref.getDownloadURL();
    return link;
  }

  Future<List<String>> seleccionYSubir() async {
    //
    selectedAssets = await MultiImagePicker.pickImages(
      maxImages: maxImagesCount,
      enableCamera: true,
    );
    return (await subir());
  }

  Future<List<String>> subir() async {
    for (var imageFile in selectedAssets) {
      links.add((await postImage(imageFile)));
    }
    return links;
  }

//

  Future<String> postImage(Asset imageFile) async {
    var byteData = await imageFile.getByteData();
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference = FirebaseStorage.instance.ref(path + fileName);
    UploadTask uploadTask = reference.putData(byteData.buffer.asUint8List());
    if (showProgress) {
      await mostrarCargaDatos(context, uploadTask);
    }
    TaskSnapshot storageTaskSnapshot = await uploadTask.whenComplete(() {});
    String link = await storageTaskSnapshot.ref.getDownloadURL();
    return link;
  }

  Future<String> postImageFromUint8List(List<int> byteData) async {
    // var byteData = await imageFile.getByteData();
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference = FirebaseStorage.instance.ref(path + fileName);
    UploadTask uploadTask = reference.putData(byteData as Uint8List);
    if (showProgress) {
      await mostrarCargaDatos(context, uploadTask);
    }
    TaskSnapshot storageTaskSnapshot = await uploadTask.whenComplete(() {});
    String link = await storageTaskSnapshot.ref.getDownloadURL();
    return link;
  }
  //
}

class ProgressFromUploadTask extends StatefulWidget {
  UploadTask task;
  Function onDone;
  ProgressFromUploadTask({required this.task, required this.onDone});
  @override
  _ProgressFromUploadTaskState createState() => _ProgressFromUploadTaskState();
}

class _ProgressFromUploadTaskState extends State<ProgressFromUploadTask> {
  double value = 0;
  bool ended = false;

  StreamSubscription<TaskSnapshot>? streamSubscription;
  show() async {
    streamSubscription = widget.task.snapshotEvents.listen((event) {
      if (value == 1 && !ended) {
        widget.onDone();
        ended = true;
      }
      setState(() {
        value = event.bytesTransferred / event.totalBytes;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    if(streamSubscription!=null)streamSubscription!.cancel();
  }
  @override
  void initState() {
    super.initState();
    show();
  }

  @override
  Widget build(BuildContext context) {
    return ended?Row(
      children: const [
        Icon(Icons.done,size: 30,color: Colors.white,),
        Text("Done!",style: TextStyle(color: Colors.white,fontSize: 20),),
      ],
    ):LinearProgressIndicator(value: value);
  }
}
