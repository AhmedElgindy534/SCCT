import 'dart:io';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:excel_dart/excel_dart.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';



Future<Database> initDatabase() async {
  databaseFactory = databaseFactoryFfi;
  // Open the database
  return openDatabase(
    join(await getDatabasesPath(), 'reservation_database.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE reservations(id INTEGER PRIMARY KEY, roomName TEXT, name TEXT, date TEXT, startTime TEXT, endTime TEXT, comment TEXT, purpose TEXT, pax INTEGER, department TEXT)',
      );
    },
    version: 1,
  );
}

Future<void> saveReservation(String roomName, String name, DateTime date,
    TimeOfDay startTime, TimeOfDay endTime, String comment, String purpose,
    int pax, String department) async {
  final Database db = await initDatabase();
  await db.insert(
    'reservations',
    {
      'roomName': roomName,
      'name': name,
      'date': _formatDate(date),
      'startTime': _formatTimeOfDay(startTime),
      'endTime': _formatTimeOfDay(endTime),
      'comment': comment,
      'purpose': purpose,
      'pax': pax,
      'department': department,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  // Load existing Excel file
  String desktopPath = (await getApplicationDocumentsDirectory()).path;
  var excelFile = File('$desktopPath/reservations.xlsx');
  Excel? excel;
  if (excelFile.existsSync()) {
    excel = Excel.decodeBytes(excelFile.readAsBytesSync());
  } else {
    excel = Excel.createExcel();
  }

  // Get the first sheet
  var sheet = excel['Sheet1'];

  // Add reservation data to the sheet
  sheet.appendRow([roomName, name, _formatDate(date), _formatTimeOfDay(startTime), _formatTimeOfDay(endTime), comment, purpose, pax, department]);

  // Save Excel file
  var encodedExcel = await excel.encode();
  if (encodedExcel != null) {
    await excelFile.writeAsBytes(encodedExcel);
  } else {
    // Handle null case if necessary
  }
}

String _formatDate(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

String _formatTimeOfDay(TimeOfDay timeOfDay) {
  return '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}';
}
