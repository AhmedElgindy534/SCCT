import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite;
import 'dart:async';
import 'ArchiveMonthDetailsPage.dart';
import 'ClearDataTab.dart';
import 'RoomReservationPage.dart';
//import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

class AdminTabPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Three tabs: Rooms, Archive Months, Clear Data
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: Text('Admin Page'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Rooms'),
              Tab(text: 'Archive Months'),
              Tab(text: 'Clear Data'),
            ],
            indicatorColor: Colors.black,
          ),
        ),
        backgroundColor: Colors.grey[100],
        body: TabBarView(
          children: [
            RoomList(),
            ArchiveMonthDetailsPage(),
            ClearDataTab(),
          ],
        ),
      ),
    );
  }
}
