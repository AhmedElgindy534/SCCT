import 'dart:async';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
//import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'RoomListPage.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

class OpeningPhotoPage extends StatefulWidget {
  @override
  _OpeningPhotoPageState createState() => _OpeningPhotoPageState();
}

class _OpeningPhotoPageState extends State<OpeningPhotoPage> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2), () {
      // After 5 seconds, navigate to the RoomListPage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => RoomListPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'images/Scct2.jpg',
          fit: BoxFit.cover, // Fit the image to the screen
          width: double.infinity,
          height: double.infinity,
        ), // Load the opening photo from assets
      ),
    );
  }
}