import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:storage_manager/storage_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Configure default firebase app

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Storage Manager Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const MyHomePage(title: 'Storage Manager Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> links = [];

  ///Final path where the files will be saved
  String path = "/images";

  ///MUST set the [context] if true
  bool showProgress = false;

  ///Selected assets from gallery
  /// Call [selectAssets] to populate it
  List<XFile>? selectedAssets = [];

  ///Restrict the gallery selection
  int maxImagesCount = 10;

  @override
  Widget build(BuildContext context) {
    // You can set the context here or on each method call
    StorageProvider.context = context;

    // You can set the ImageSource get function to have a custom implementation
    StorageProvider.getImageSource = () async {
      return await showDialog<ImageSource>(
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
      );
    };

    // You can set the upload progress dialog by utilizing the [UploadTask] stream
    // StorageProvider.customUploadProgressIndicator = (uploadTask) async {
    //   return await showDialog(
    //     context: context,
    //     barrierDismissible: true,
    //     builder: (context) {
    //       return StreamBuilder<TaskSnapshot>(
    //         stream: uploadTask.snapshotEvents,
    //         builder: (context, snapshot) {
    //           if (snapshot.hasData) {
    //             return AlertDialog(
    //                 title: const Text('Uploading...'),
    //                 content: ProgressFromUploadTask(
    //                   task: uploadTask,
    //                   onDone: () {
    //                     Navigator.pop(context);
    //                   },
    //                 ));
    //           } else {
    //             return const AlertDialog(
    //               title: Text('Waiting...'),
    //               content: LinearProgressIndicator(),
    //             );
    //           }
    //         },
    //       );
    //     },
    //   );
    // };
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          const Text("Selected files", style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
          ...selectedAssets
                  ?.map((e) => Card(
                        child: ListTile(
                          title: Text(e.path),
                          leading: Image.file(
                            File(e.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ))
                  .toList() ??
              [],
          const SizedBox(height: 20),
          const Divider(),
          const Text("Uploaded files links", style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
          ...links
              .map((e) => Card(
                    child: ListTile(title: Text(e)),
                  ))
              .toList()
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text("Select images", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await StorageProvider.selectAssets(backgroundColor: Colors.grey[900]!);
                setState(() {
                  selectedAssets = StorageProvider.selectedAssets;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text("Upload selected images", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await StorageProvider.uploadSelectedAssets(path);
                setState(() {
                  links = StorageProvider.links;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text("Select and upload images", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await StorageProvider.selectAndUpload(path);
                setState(() {
                  links = StorageProvider.links;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
