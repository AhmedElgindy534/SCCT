import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
//import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'dart:async';
import 'DataBaseImplementation.dart';
import 'reusable components.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

class ReservationDetailsPage extends StatefulWidget {
  final String roomName;

  ReservationDetailsPage({required this.roomName});

  @override
  _ReservationDetailsPageState createState() => _ReservationDetailsPageState();
}

class _ReservationDetailsPageState extends State<ReservationDetailsPage> {
  late TextEditingController _nameController;
  late TextEditingController _purposeController;
  late TextEditingController _paxController;
  late TextEditingController _commentController; // Add comment controller
  late String _selectedDepartment;
  late DateTime _selectedDate;
  late TimeOfDay _selectedStartTime;
  late TimeOfDay _selectedEndTime;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _purposeController = TextEditingController();
    _paxController = TextEditingController();
    _commentController = TextEditingController(); // Initialize comment controller
    _selectedDate = DateTime.now();
    _selectedStartTime = _getDefaultStartTime(); // Set default start time
    _selectedEndTime = _getDefaultEndTime(_selectedStartTime); // End time 30 minutes after start time
    _selectedDepartment = departments[0]; // Set the default department
  }

  TimeOfDay _getDefaultStartTime() {
    final now = TimeOfDay.now();
    int hour = now.hour;
    int minute = now.minute;

    // Round up the hour and minute to the nearest half-hour mark
    if (minute >= 30) {
      hour++; // Move to the next hour
      minute = 0; // Reset minutes to 0
    } else {
      minute = 30; // Set minutes to 30
    }

    // Ensure the default start time is within the allowed reservation hours (9:00 AM to 5:00 PM)
    if (hour < 9) {
      hour = 9; // Set to 9:00 AM if the current hour is before 9
      minute = 0; // Reset minutes to 0
    } else if (hour >= 17) {
      hour = 17; // Set to 5:00 PM if the current hour is after or equal to 5
      minute = 0; // Reset minutes to 0
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  TimeOfDay _getDefaultEndTime(TimeOfDay startTime) {
    int newHour = startTime.hour;
    int newMinute = (startTime.minute + 30) % 60;
    if (startTime.minute + 30 >= 60) {
      newHour++;
    }

    if (newHour >= 24) {
      newHour = newHour - 24;
    }

    return TimeOfDay(hour: newHour, minute: newMinute);
  }


  @override
  void dispose() {
    _nameController.dispose();
    _purposeController.dispose();
    _paxController.dispose();
    _commentController.dispose(); // Dispose of comment controller
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final int hour = timeOfDay.hour;
    final int hourOfPeriod = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final String minute = timeOfDay.minute.toString().padLeft(2, '0');
    final String period = (timeOfDay.hour >= 12) ? 'PM' : 'AM';
    return '$hourOfPeriod:$minute $period';
  }


  String _formatTimeForDatabase(TimeOfDay timeOfDay) {
    final int hour = timeOfDay.hour;
    final int formattedHour = hourOf24HourFormat(hour, timeOfDay.period == DayPeriod.pm);
    final String minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$formattedHour:$minute';
  }

  TimeOfDay _convertTimeFromDatabase(String timeString) {
    final List<String> parts = timeString.split(':');
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);
    final bool isPM = hour >= 12;
    final int formattedHour = hourOf12HourFormat(hour);
    return TimeOfDay(hour: formattedHour, minute: minute);
  }
  final currentTime = TimeOfDay.now();
  int hourOf12HourFormat(int hour) {
    return hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
  }

  int hourOf24HourFormat(int hour, bool isPM) {
    return isPM ? (hour == 12 ? 12 : hour + 12) : (hour == 12 ? 0 : hour);
  }
  Future<void> _confirmBooking(context) async {
    String name = _nameController.text.trim();
    String purpose = _purposeController.text.trim();
    int pax = int.tryParse(_paxController.text.trim()) ?? 0; // Parse pax as integer
    String comment = _commentController.text.trim(); // Get comment text

    // Get the current time
    final currentTime = TimeOfDay.now();

    // Convert the selected start time to TimeOfDay
    TimeOfDay selectedStartTime = TimeOfDay(hour: _selectedStartTime.hour, minute: _selectedStartTime.minute);

    if (name.isEmpty || purpose.isEmpty || comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill in all fields')));
      return;
    }

    // Check if the selected date is today or later
    if (_selectedDate.isAfter(DateTime.now().subtract(Duration(days: 1)))) {
      // Allow choosing a start time between 9 am and 5 pm
      if (selectedStartTime.hour < 9 || selectedStartTime.hour >= 17) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid Start Time. Please choose a time between 9 am and 5 pm.')));
        return;
      }
    } else {
      // Check if the selected start time is before the current time
      if (selectedStartTime.hour < currentTime.hour ||
          (selectedStartTime.hour == currentTime.hour && selectedStartTime.minute < currentTime.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid Start Time. Please choose a time after the current time.')));
        return;
      }
    }

    if (_isValidTime(_selectedStartTime) && _isValidTime(_selectedEndTime)) {
      if (_selectedStartTime.hour > _selectedEndTime.hour || (_selectedStartTime.hour == _selectedEndTime.hour && _selectedStartTime.minute >= _selectedEndTime.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('End time cannot be before start time')));
        return;
      }
      // Check if the selected time slot is already booked
      bool isAlreadyBooked = await isTimeSlotBooked(widget.roomName, _selectedDate, _selectedStartTime, _selectedEndTime);
      if (isAlreadyBooked) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Room is already booked at this time')));
      } else {
        await saveReservation(widget.roomName, name, _selectedDate, _selectedStartTime, _selectedEndTime, comment, purpose, pax, _selectedDepartment);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Booked successfully')));
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid Time. Please select from 9:00 AM to 5:00 PM .')
          ));
    }
  }

  // Function to check if the selected time slot is already booked
  Future<bool> isTimeSlotBooked(String roomName, DateTime date, TimeOfDay startTime, TimeOfDay endTime) async {
    final Database db = await initDatabase();
    final String startDateString = DateFormat('yyyy-MM-dd').format(date);
    final String startTimeString = _formatTimeForDatabase(startTime);
    final String endTimeString = _formatTimeForDatabase(endTime);

    List<Map<String, dynamic>> reservations = await db.rawQuery(
      'SELECT * FROM reservations WHERE roomName = ? AND date = ? AND ((startTime < ? AND endTime > ?) OR (startTime < ? AND endTime > ?) OR (startTime >= ? AND endTime <= ?))',
      [roomName, startDateString, endTimeString, startTimeString, startTimeString, endTimeString, startTimeString, endTimeString],
    );

    return reservations.isNotEmpty;
  }


  bool _isValidTime(TimeOfDay time) {
    final start = TimeOfDay(hour: 9, minute: 0);
    final end = TimeOfDay(hour: 17, minute: 0);
    return time.hour >= start.hour && time.hour <= end.hour;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reservation Details'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Room: ${widget.roomName}'),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _purposeController,
              decoration: InputDecoration(labelText: 'Purpose'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Pax: '),
                IconButton(
                  onPressed: () {
                    int currentValue = int.tryParse(_paxController.text) ?? 0;
                    setState(() {
                      _paxController.text = (currentValue - 1).clamp(0, 999).toString();
                    });
                  },
                  icon: Icon(Icons.remove),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _paxController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Adjust padding for better appearance
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    int currentValue = int.tryParse(_paxController.text) ?? 0;
                    setState(() {
                      _paxController.text = (currentValue + 1).clamp(0, 999).toString();
                    });
                  },
                  icon: Icon(Icons.add),
                ),
              ],
            ),
            TextField( // Add TextField for comment
              controller: _commentController,
              decoration: InputDecoration(labelText: 'Comment'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedDepartment,
              items: departments.map((String department) {
                return DropdownMenuItem<String>(
                  value: department,
                  child: Text(department),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDepartment = newValue ?? departments[0];
                });
              },
              decoration: InputDecoration(labelText: 'Department'),
            ),
            TextButton(
              onPressed: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null && pickedDate != _selectedDate) {
                  setState(() {
                    _selectedDate = pickedDate;
                  });
                }
              },
              child: Text('Select Date'),
            ),
            Text('Date: ${_selectedDate.toString().substring(0, 10)}'),
            TextButton(
              onPressed: () async {
                final TimeOfDay? pickedStartTime = await showTimePicker(
                  context: context,
                  initialTime: _selectedStartTime,
                  initialEntryMode: TimePickerEntryMode.input,
                  builder: (BuildContext context, Widget? child) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                      child: child!,
                    );
                  },
                );
                if (pickedStartTime != null) {
                  setState(() {
                    final minute = pickedStartTime.minute < 30 ? 0 : 30;
                    _selectedStartTime = TimeOfDay(hour: pickedStartTime.hour, minute: minute);
                    _selectedEndTime = _selectedStartTime.replacing(
                      hour: _selectedStartTime.hour + 1,
                      minute: _selectedStartTime.minute,
                    );
                  });
                }
              },
              child: Text('Select Start Time'),
            ),
            Text('Start Time: ${_formatTimeOfDay(_selectedStartTime)}'),
            TextButton(
              onPressed: () async {
                final TimeOfDay? pickedEndTime = await showTimePicker(
                  context: context,
                  initialTime: _selectedEndTime,
                  initialEntryMode: TimePickerEntryMode.input,
                  builder: (BuildContext context, Widget? child) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                      child: child!,
                    );
                  },
                );
                if (pickedEndTime != null) {
                  setState(() {
                    final minute = pickedEndTime.minute < 30 ? 0 : 30;
                    _selectedEndTime = TimeOfDay(hour: pickedEndTime.hour, minute: minute);
                  });
                }
              },
              child: Text('Select End Time'),
            ),
            Text('End Time: ${_formatTimeOfDay(_selectedEndTime)}'),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => _confirmBooking(context),
              child: Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}