import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';

class CustomCalendarView extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime)? onDateSelected;
  final List<Appointment> appointments;

  const CustomCalendarView({
    Key? key,
    this.selectedDate,
    this.onDateSelected,
    this.appointments = const [],
  }) : super(key: key);

  @override
  _CustomCalendarViewState createState() => _CustomCalendarViewState();
}

class _CustomCalendarViewState extends State<CustomCalendarView> {
  List<DateTime> dateList = <DateTime>[];
  DateTime currentMonthDate = DateTime.now();
  DateTime? selectedDate;

  @override
  void initState() {
    setListOfDate(currentMonthDate);
    if (widget.selectedDate != null) {
      selectedDate = widget.selectedDate;
    }
    super.initState();
  }

  void setListOfDate(DateTime monthDate) {
    dateList.clear();
    final DateTime newDate = DateTime(monthDate.year, monthDate.month, 0);
    int previousMothDay = 0;
    if (newDate.weekday < 7) {
      previousMothDay = newDate.weekday;
      for (int i = 1; i <= previousMothDay; i++) {
        dateList.add(newDate.subtract(Duration(days: previousMothDay - i)));
      }
    }
    for (int i = 0; i < (42 - previousMothDay); i++) {
      dateList.add(newDate.add(Duration(days: i + 1)));
    }
  }

  bool hasAppointmentOnDate(DateTime date) {
    return widget.appointments.any((appointment) =>
        appointment.appointmentDate.year == date.year &&
        appointment.appointmentDate.month == date.month &&
        appointment.appointmentDate.day == date.day);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 12, bottom: 8),
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      currentMonthDate = DateTime(
                          currentMonthDate.year, currentMonthDate.month, 0);
                      setListOfDate(currentMonthDate);
                    });
                  },
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      DateFormat('yyyy년 M월').format(currentMonthDate),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      currentMonthDate = DateTime(
                          currentMonthDate.year, currentMonthDate.month + 2, 0);
                      setListOfDate(currentMonthDate);
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 8, bottom: 8),
            child: Row(
              children: getDaysNameUI(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 8, bottom: 8),
            child: Column(
              children: getDaysNoUI(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> getDaysNameUI() {
    final List<String> weekDays = ['일', '월', '화', '수', '목', '금', '토'];
    final List<Widget> listUI = <Widget>[];
    for (int i = 0; i < 7; i++) {
      listUI.add(
        Expanded(
          child: Center(
            child: Text(
              weekDays[i],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: i == 0
                    ? Colors.red.shade400
                    : i == 6
                        ? Colors.blue.shade400
                        : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      );
    }
    return listUI;
  }

  List<Widget> getDaysNoUI() {
    final List<Widget> noList = <Widget>[];
    int count = 0;
    for (int i = 0; i < dateList.length / 7; i++) {
      final List<Widget> listUI = <Widget>[];
      for (int i = 0; i < 7; i++) {
        final DateTime date = dateList[count];
        final bool isCurrentMonth = currentMonthDate.month == date.month;
        final bool isSelected = selectedDate != null &&
            selectedDate!.year == date.year &&
            selectedDate!.month == date.month &&
            selectedDate!.day == date.day;
        final bool isToday = DateTime.now().year == date.year &&
            DateTime.now().month == date.month &&
            DateTime.now().day == date.day;
        final bool hasAppointment = hasAppointmentOnDate(date);

        listUI.add(
          Expanded(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                margin: const EdgeInsets.all(2),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(32.0),
                    onTap: () {
                      if (isCurrentMonth) {
                        setState(() {
                          selectedDate = date;
                        });
                        widget.onDateSelected?.call(date);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue
                            : isToday
                                ? Colors.blue.shade50
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : isToday
                                        ? Colors.blue
                                        : isCurrentMonth
                                            ? Colors.black87
                                            : Colors.grey.shade400,
                                fontSize: 14,
                                fontWeight: isSelected || isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (hasAppointment && !isSelected)
                            Positioned(
                              bottom: 6,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? Colors.blue
                                        : Colors.red.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        count += 1;
      }
      noList.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: listUI,
      ));
    }
    return noList;
  }
}
