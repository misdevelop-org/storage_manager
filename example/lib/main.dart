import 'dart:typed_data';

import 'package:example/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:storage_manager/storage_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Configure default firebase app
  Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
  String path = "/images/";

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
    StorageProvider.getImageSource = () async => await showDialog<ImageSource>(
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
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            runSpacing: 20,
            children: [
              SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    const Text("Selected files",
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center),
                    ...selectedAssets
                            ?.map((e) => Card(
                                  child: ListTile(
                                    title: Text(e.path),
                                    subtitle: SizedBox(
                                      width: 400,
                                      height: 400,
                                      child: FutureBuilder(
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return const CircularProgressIndicator();
                                          }
                                          return Image.memory(
                                            snapshot.data as Uint8List,
                                            fit: BoxFit.contain,
                                          );
                                        },
                                        future: e.readAsBytes(),
                                      ),
                                    ),
                                  ),
                                ))
                            .toList() ??
                        [],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    const Text("Uploaded files links",
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center),
                    ...links
                        .map((e) => Card(
                              child: ListTile(
                                title: Text(e),
                                subtitle: Image.network(
                                  e,
                                  // imageUrl: e,
                                  width: 400,
                                  height: 400,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ))
                        .toList(),
                    const SizedBox(height: 20),
                  ],
                ),
              )
            ],
          ),
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
              child: const Text("Select images",
                  style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await StorageProvider.selectAssets(
                    backgroundColor: Colors.grey[900]!);
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
              child: const Text("Upload selected images",
                  style: TextStyle(color: Colors.white)),
              onPressed: () async {
                // You can set the [links] variable directly
                links = await StorageProvider.uploadSelectedAssets(path,
                    context: context, showProgress: true);
                setState(() {});
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text("Select and upload images",
                  style: TextStyle(color: Colors.white)),
              onPressed: () async {
                //Or you can use the provider's stored value
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
