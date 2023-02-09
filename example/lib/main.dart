import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
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
  String path = "";

  ///MUST set the [context] if true
  bool showProgress = false;

  ///Selected assets from gallery
  /// Call [selectAssets] to populate it
  List<XFile>? selectedAssets = [];

  ///Restrict the gallery selection
  int maxImagesCount = 10;

  ///Uploads the selected Asset and returns file link
  Future<String> saveImage(XFile imageFile) async {
    var byteData = await imageFile.readAsBytes();
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference = FirebaseStorage.instance.ref(path + fileName);
    UploadTask uploadTask = reference.putData(byteData.buffer.asUint8List());
    // if (showProgress) {
    //   await showDataUploadProgress(context!, uploadTask);
    // }
    TaskSnapshot storageTaskSnapshot = await uploadTask.whenComplete(() {});
    String link = await storageTaskSnapshot.ref.getDownloadURL();
    return link;
  }

  ///Let the default showModalBottomSheet get the source from user
  Future<bool?> getSource({Color? backgroundColor = Colors.transparent}) async {
    return await showModalBottomSheet<bool?>(
      context: context,
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

  ///Select assets from gallery or camera and returns the uploaded file paths
  ///Select gallery as source by setting [isGallery] to true
  ///Select camera as source by setting [isGallery] to false
  ///Let the default showModalBottomSheet get the source from user by setting [isGallery] to null
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        children: links
            .map((e) => Card(
                  child: ListTile(title: Text(e)),
                ))
            .toList(),
      ),
      floatingActionButton: Card(
        color: Colors.purple[900],
        child: TextButton(
          child: const Text("Select and upload images"),
          onPressed: () {}
          // () async => links = await FireUploader(context: context, path: 'test/images/').selectAndUpload()
          ,
        ),
      ),
    );
  }
}
