part of '../storage_manager.dart';

/// Saves, gets and removes data online with Firebase Cloud Storage.
///
/// * Uploads a [String], [Uint8List] or `List<int>` ([saveObject])
/// * Downloads bytes ([getObject]) and lists a folder ([getObjectsFromPath])
/// * Removes files by path ([removeObject]) or download URL ([removeObjectFromUrl])
/// * Optionally shows an upload progress dialog ([showDataUploadProgress])
class FireUploader implements Repository {
  /// Uploads [byteData] to `path + fileName + extensionFormat` and returns its download URL.
  ///
  /// * [byteData] must be a [String], [Uint8List] or `List<int>`.
  /// * [fileName] defaults to the current timestamp in milliseconds.
  /// * [extensionFormat] (e.g. `.png`) is appended to the file name when set.
  /// * When [showProgress] is true, [context] MUST be set.
  @override
  Future<String> saveObject(
    String path,
    dynamic byteData, {
    String? extensionFormat,
    String? fileName,
    bool showProgress = false,
    BuildContext? context,
  }) async {
    final name = fileName ?? DateTime.now().millisecondsSinceEpoch.toString();
    final reference = FirebaseStorage.instance.ref(path + name + (extensionFormat ?? ''));
    final UploadTask uploadTask = switch (byteData) {
      String text => reference.putString(text),
      Uint8List bytes => reference.putData(bytes),
      List<int> bytes => reference.putData(Uint8List.fromList(bytes)),
      _ => throw ArgumentError.value(byteData, 'byteData', 'Must be a String, Uint8List or List<int>'),
    };
    if (showProgress) {
      if (context != null) {
        await showDataUploadProgress(context, uploadTask);
      } else if (kDebugMode) {
        throw ArgumentError('Must set context if showProgress is true');
      }
    }
    return getDownloadUrl(uploadTask);
  }

  /// Waits for [uploadTask] to finish and returns the uploaded file's download URL.
  Future<String> getDownloadUrl(UploadTask uploadTask) async {
    final snapshot = await uploadTask;
    return snapshot.ref.getDownloadURL();
  }

  /// Downloads the bytes of the file at [path].
  @override
  Future<Uint8List?> getObject(String path) => referenceFromPath(path).getData();

  /// Returns the Storage [Reference] for [path].
  Reference referenceFromPath(String path) => FirebaseStorage.instance.ref(path);

  /// Lists the full paths of the files directly under [path].
  Future<List<String>?> getObjectsFromPath(String path) async {
    final result = await FirebaseStorage.instance.ref(path).listAll();
    return result.items.map((item) => item.fullPath).toList();
  }

  /// Removes the file at [path]. Returns false when the deletion fails.
  @override
  Future<bool> removeObject(String path) => _delete(() => FirebaseStorage.instance.ref(path).delete());

  /// Removes the file behind the download [url]. Returns false when the deletion fails.
  Future<bool> removeObjectFromUrl(String url) => _delete(() => FirebaseStorage.instance.refFromURL(url).delete());

  Future<bool> _delete(Future<void> Function() delete) async {
    try {
      await delete();
      return true;
    } catch (err, stack) {
      debugPrint('$err\n$stack');
      return false;
    }
  }

  /// Shows a dialog with the progress of [uploadTask] that closes itself when the upload succeeds.
  Future<void> showDataUploadProgress(BuildContext buildContext, UploadTask uploadTask) {
    return showDialog<void>(
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
                  onDone: () => Navigator.pop(context),
                ),
              );
            }
            return const AlertDialog(
              title: Text('Waiting...'),
              content: LinearProgressIndicator(),
            );
          },
        );
      },
    );
  }
}

/// A [LinearProgressIndicator] that follows [task] and calls [onDone] once it succeeds.
class ProgressFromUploadTask extends StatefulWidget {
  /// The upload to follow.
  final UploadTask task;

  /// Called once when the upload succeeds.
  final VoidCallback onDone;

  const ProgressFromUploadTask({super.key, required this.task, required this.onDone});

  @override
  State<ProgressFromUploadTask> createState() => _ProgressFromUploadTaskState();
}

class _ProgressFromUploadTaskState extends State<ProgressFromUploadTask> {
  StreamSubscription<TaskSnapshot>? _subscription;
  double value = 0;
  bool ended = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.task.snapshotEvents.listen((event) {
      if (event.totalBytes > 0 && mounted) {
        setState(() => value = event.bytesTransferred / event.totalBytes);
      }
      if (event.state == TaskState.success && !ended) {
        ended = true;
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ended) return LinearProgressIndicator(value: value);
    return Container(
      width: 100,
      height: 60,
      decoration: BoxDecoration(color: Colors.green[700], borderRadius: BorderRadius.circular(20)),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.done, size: 30, color: Colors.white),
          Text('Done!', style: TextStyle(color: Colors.white, fontSize: 20)),
        ],
      ),
    );
  }
}
