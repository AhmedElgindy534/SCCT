import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
//import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
//import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'dart:async';
import 'DataBaseImplementation.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;


class ClearDataTab extends StatefulWidget {
  @override
  _ClearDataTabState createState() => _ClearDataTabState();
}

class _ClearDataTabState extends State<ClearDataTab> {
  late DateTime _startDate = DateTime.now();
  late DateTime _endDate = DateTime.now();

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Select Date Range to Clear Data:',
            style: TextStyle(color: Colors.black),
          ),
          SizedBox(height: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () async {
                  final DateTime? pickedStartDate = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedStartDate != null) {
                    setState(() {
                      _startDate = pickedStartDate;
                    });
                  }
                },
                child: Text('Start Date: ${DateFormat('yyyy-MM-dd').format(_startDate)}',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final DateTime? pickedEndDate = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedEndDate != null) {
                    setState(() {
                      _endDate = pickedEndDate;
                    });
                  }
                },
                child: Text('End Date: ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _clearData(_startDate, _endDate);
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.grey), // Change this color to the desired background color
            ),
            child: Text('Clear Data',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _clearData(DateTime startDate, DateTime endDate) async {
    // Perform the deletion operation based on the selected date range
    final Database db = await initDatabase();
    await db.delete(
      'reservations',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [_formatDate(startDate), _formatDate(endDate)],
    );
    ScaffoldMessenger.of(context as BuildContext).showSnackBar(SnackBar(content: Text('Data cleared successfully')));
  }
}