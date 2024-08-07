import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'AdminPage.dart';
import 'ReservationDetailsPage.dart';
import 'reusable components.dart';
import 'ReservedTimesPage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
//import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'dart:async';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

class RoomListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text('Meeting Rooms'),
        actions: [
          IconButton(
            icon: Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminPage()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[100], // Set background color
      body: Column(
        children: [
          for (int i = 0; i < meetingRooms.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: i >= 0 ? 10.0 : 0.0), // Add top padding for all items
                child: Container(
                  color: Colors.grey[100], // Set room entry background color
                  child: ListTile(
                    title: Text(
                      meetingRooms[i],
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.grey[100],
                            title: Text("Choose Action"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ListTile(
                                  title: Text("View Reserved Times"),
                                  onTap: () {
                                    Navigator.pop(context); // Close the dialog
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ReservedTimesPage(roomName: meetingRooms[i]),
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  title: Text("Reservation Details"),
                                  onTap: () {
                                    Navigator.pop(context); // Close the dialog
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ReservationDetailsPage(roomName: meetingRooms[i]),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
