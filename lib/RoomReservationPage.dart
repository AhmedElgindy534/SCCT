import 'dart:io';
import 'package:excel_dart/excel_dart.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'DataBaseImplementation.dart';
import 'reusable components.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
//import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

class RoomReservationsPage extends StatelessWidget {
  final String roomName;

  RoomReservationsPage({required this.roomName});

  String _formatTime12Hour(String timeString) {
    final List<String> parts = timeString.split(':');
    int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);
    final String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour); // Convert hour to 12-hour format
    return '$hour:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reservations for $roomName'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () async {
              List<Map<String, dynamic>> reservations =
              await getReservations(roomName);
              saveExcelFile(context, reservations);
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: getReservations(roomName),
        builder:
            (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<Map<String, dynamic>> reservations = snapshot.data ?? [];
            return ListView.builder(
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> reservation = reservations[index];
                return Container(
                  margin: EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text('Name: ${reservation['name']}'),
                                  Text(
                                      'Comment: ${reservation['comment']}'),
                                  Text('Date: ${reservation['date']}'),
                                  Text(
                                      'Time: From ${_formatTime12Hour(reservation['startTime'])} To ${_formatTime12Hour(reservation['endTime'])}'),
                                ],
                              ),
                            ),
                            VerticalDivider(),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Purpose: ${reservation['purpose']}'),
                                  Text(
                                      'Dep: ${reservation['department']}'),
                                  Text('Pax: ${reservation['pax']}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getReservations(
      String roomName) async {
    final Database db = await initDatabase();
    return await db.query('reservations',
        where: 'roomName = ?', whereArgs: [roomName]);
  }

  Future<void> saveExcelFile(
      BuildContext context, List<Map<String, dynamic>> reservations) async {
    // Create Excel workbook
    var excel = Excel.createExcel();

    // Add worksheet
    var sheet = excel['Sheet1'];

    // Write header row to the worksheet
    sheet.appendRow([
      'Room Name',
      'Name',
      'Date',
      'Start Time',
      'End Time',
      'Comment',
      'Purpose',
      'Pax',
      'Department'
    ]);

    // Write reservation data to the worksheet
    for (var reservation in reservations) {
      sheet.appendRow([
        reservation['roomName'],
        reservation['name'],
        reservation['date'],
        reservation['startTime'],
        reservation['endTime'],
        reservation['comment'],
        reservation['purpose'],
        reservation['pax'],
        reservation['department']
      ]);
    }

    // Encode the entire workbook
    var excelData = excel.encode();

    // Get the selected directory path
    String? savePath = await _getSavePath(context);

    if (savePath != null) {
      try {
        // Generate a default file name
        String fileName = 'reservations.xlsx';

        // Construct the full file path
        String filePath = '$savePath/$fileName';

        print('File path: $filePath');

        // Check if excelData is not null
        if (excelData != null) {
          try {
            // Write the encoded Excel data to the file path
            await File(filePath).writeAsBytes(excelData);
            print('File saved successfully');

            // Show a snackbar to indicate successful saving
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Excel file saved at: $filePath')),
            );
          } catch (e, stackTrace) {
            // Handle any errors that might occur during file saving
            print('Error saving Excel file: $e');
            print('Stack trace: $stackTrace');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving Excel file')),
            );
          }
        } else {
          print('Error: excelData is null');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving Excel file')),
          );
        }
      } catch (e) {
        // Handle any other errors that might occur
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving Excel file')),
        );
      }
    } else {
      // Show a snackbar if no directory was selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No directory selected')),
      );
    }
  }


  Future<String?> _getSavePath(BuildContext context) async {
    try {
      // Open a file picker dialog to let the user choose the directory
      String? directoryPath = await FilePicker.platform.getDirectoryPath();
      if (directoryPath != null) {
        // Return the selected directory path
        return directoryPath;
      } else {
        // Handle the case where no directory was selected
        return null;
      }
    } catch (e) {
      // Handle any errors that might occur
      print('Error getting save path: $e');
      return null;
    }
  }
}
class RoomList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: meetingRooms.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(meetingRooms[index]),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RoomReservationsPage(roomName: meetingRooms[index]),
              ),
            );
          },
        );
      },
    );
  }
}