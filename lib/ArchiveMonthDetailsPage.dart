import 'package:flutter/material.dart';
import 'package:scct_reserving_meeting_rooms/reusable%20components.dart';
import 'package:sqflite/sqflite.dart';

import 'DataBaseImplementation.dart';

class ArchiveMonthDetailsPage extends StatefulWidget {
  @override
  _ArchiveMonthDetailsPageState createState() => _ArchiveMonthDetailsPageState();
}

class _ArchiveMonthDetailsPageState extends State<ArchiveMonthDetailsPage> {
  late String _selectedMonth;
  late String _selectedRoom;
  late List<String> _months;
  List<String> _rooms = meetingRooms;
  List<Map<String, dynamic>> _reservations = [];

  @override
  void initState() {
    super.initState();
    _selectedMonth = '';
    _selectedRoom = _rooms.first;
    _months = [];
    _fetchMonths();
  }

  Future<void> _fetchMonths() async {
    final Database db = await initDatabase();
    final List<Map<String, dynamic>> monthsData = await db.rawQuery(
      'SELECT DISTINCT substr(date, 1, 7) AS month FROM reservations ORDER BY month ASC',
    );
    setState(() {
      _months = monthsData.map<String>((monthData) => monthData['month'] as String).toList();
      _selectedMonth = _months.isNotEmpty ? _months.first : '';
    });
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    final Database db = await initDatabase();
    final List<Map<String, dynamic>> reservations = await db.query(
      'reservations',
      where: 'date LIKE ? AND roomName = ?',
      whereArgs: ['${_selectedMonth}%', _selectedRoom],
    );
    setState(() {
      _reservations = reservations;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Row(
            children: [
              Text("Select Month: "),
              DropdownButton<String>(
                value: _selectedMonth,
                onChanged: (String? month) {
                  if (month != null) {
                    setState(() {
                      _selectedMonth = month;
                    });
                    _fetchReservations();
                  }
                },
                items: _months.map<DropdownMenuItem<String>>((String month) {
                  return DropdownMenuItem<String>(
                    value: month,
                    child: Text(month),
                  );
                }).toList(),
              ),
            ],
          ),
          Row(
            children: [
              Text("Select Room: "),
              DropdownButton<String>(
                value: _selectedRoom,
                onChanged: (String? room) {
                  if (room != null) {
                    setState(() {
                      _selectedRoom = room;
                    });
                    _fetchReservations();
                  }
                },
                items: _rooms.map<DropdownMenuItem<String>>((String room) {
                  return DropdownMenuItem<String>(
                    value: room,
                    child: Text(room),
                  );
                }).toList(),
              ),
            ],
          ),
          Expanded(
            child: _reservations.isEmpty
                ? Center(child: Text('No reservations'))
                : ListView.builder(
              itemCount: _reservations.length,
              itemBuilder: (context, index) {
                final reservation = _reservations[index];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Room: ${reservation['roomName']}'),
                              Text('Date: ${reservation['date']}'),
                              Text('Time: ${reservation['startTime']} to ${reservation['endTime']}'),
                              Text('Department: ${reservation['department']}'),
                            ],
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Name: ${reservation['name']}'),
                              Text('Purpose: ${reservation['purpose']}'),
                              Text('Pax: ${reservation['pax']}'),
                              Text('Comment: ${reservation['comment']}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

