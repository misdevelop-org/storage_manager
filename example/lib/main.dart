import 'package:flutter/material.dart';
import 'package:storage_manager/storage_manager.dart';

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
        primarySwatch: Colors.blue,
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
          color: Colors.blue,
          child: TextButton(
            child: const Text("Select and upload images"),
            onPressed: () async => links =
                await FireUploader(context: context, path: 'test/images/')
                    .selectAndUpload(),
          ),
        ));
  }
}
