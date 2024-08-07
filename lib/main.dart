import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'DataBaseImplementation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel_dart/excel_dart.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:file_picker/file_picker.dart' as file_picker;
//import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'dart:async';
import 'OpeningPhotoPage.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main()  {

  sqfliteFfiInit();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Room Reservation App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: OpeningPhotoPage(),
    );
  }
}


