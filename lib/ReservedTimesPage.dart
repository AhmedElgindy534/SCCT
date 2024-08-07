import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'DataBaseImplementation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
//import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'dart:async';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

class ReservedTimesPage extends StatelessWidget {
  final String roomName;

  ReservedTimesPage({required this.roomName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text('Reserved Times for $roomName'),
      ),
      backgroundColor: Colors.grey[100],
      body: FutureBuilder(
        future: getReservedTimes(roomName),
        builder: (context, AsyncSnapshot<List<String>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<String> reservedTimes = snapshot.data ?? [];
            return ListView.builder(
              itemCount: reservedTimes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(reservedTimes[index]),
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<List<String>> getReservedTimes(String roomName) async {
    final Database db = await initDatabase();
    final String currentDate = _formatDate(DateTime.now());
    final String nextDate = _formatDate(DateTime.now().add(Duration(days: 1)));

    List<Map<String, dynamic>> reservations = await db.rawQuery(
      'SELECT startTime, endTime, date FROM reservations WHERE roomName = ? AND (date = ? OR date = ?) ORDER BY date ASC, startTime ASC',
      [roomName, currentDate, nextDate],
    );

    List<String> reservedTimeSlots = [];
    for (var reservation in reservations) {
      String startTime = _formatTimeFromString(reservation['startTime']);
      String endTime = _formatTimeFromString(reservation['endTime']);
      String date = _formatDate(DateTime.parse(reservation['date']));
      reservedTimeSlots.add('$date - $startTime to $endTime');
    }

    return reservedTimeSlots;
  }


  String _formatTimeFromString(String timeString) {
    final List<String> parts = timeString.split(':');
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);
    final String period = hour >= 12 ? 'PM' : 'AM';
    final int displayHour = hour > 12 ? hour - 12 : hour;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}