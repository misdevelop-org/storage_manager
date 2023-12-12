library storage_manager;

import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storage_manager/src/repository.dart';

part 'src/blocs/storage_provider.dart';
part 'src/device_persistor.dart';
part 'src/firestorage.dart';
