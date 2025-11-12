import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../api/appointment_api.dart';
import '../widgets/custom_calendar.dart';
import '../widgets/appointment_popup.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<Appointment> appointments = [];
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      isLoading = true;
    });

    final data = await AppointmentApi.getAppointments();
    setState(() {
      appointments = data;
      isLoading = false;
    });
  }

  List<Appointment> _getAppointmentsForSelectedDate() {
    return appointments.where((appointment) {
      return appointment.appointmentDate.year == selectedDate.year &&
          appointment.appointmentDate.month == selectedDate.month &&
          appointment.appointmentDate.day == selectedDate.day;
    }).toList();
  }

  void _showAppointmentPopup({Appointment? appointment}) {
    showDialog(
      context: context,
      builder: (context) => AppointmentPopup(
        initialAppointment: appointment,
        selectedDate: selectedDate,
        onSave: (newAppointment) async {
          // ✅ await 전에 ScaffoldMessenger 미리 가져오기
          final messenger = ScaffoldMessenger.of(context);

          if (appointment == null) {
            // 새 일정 추가
            final result =
                await AppointmentApi.createAppointment(newAppointment);
            if (!mounted) return;

            messenger.showSnackBar(
              SnackBar(content: Text(result['message'])),
            );
            if (result['success'] == true) {
              _loadAppointments();
            }
          } else {
            // 기존 일정 수정
            final result = await AppointmentApi.updateAppointment(
                appointment.appointmentId!, newAppointment);
            if (!mounted) return;

            messenger.showSnackBar(
              SnackBar(content: Text(result['message'])),
            );
            if (result['success'] == true) {
              _loadAppointments();
            }
          }
        },
      ),
    );
  }

  void _deleteAppointment(Appointment appointment) async {
    // ✅ 모든 await 전에 ScaffoldMessenger 미리 가져오기
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 삭제'),
        content: const Text('이 일정을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result =
          await AppointmentApi.deleteAppointment(appointment.appointmentId!);
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      if (result['success'] == true) {
        _loadAppointments();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateAppointments = _getAppointmentsForSelectedDate();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAppointments,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 달력
                      CustomCalendarView(
                        selectedDate: selectedDate,
                        appointments: appointments,
                        onDateSelected: (date) {
                          setState(() {
                            selectedDate = date;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      // 선택된 날짜 표시
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('yyyy년 M월 d일 (E)', 'ko_KR')
                                .format(selectedDate),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showAppointmentPopup(),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('일정 추가',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 일정 목록
                      if (selectedDateAppointments.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(Icons.event_busy,
                                    size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  '이 날짜에 등록된 일정이 없습니다.',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...selectedDateAppointments.map((appointment) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () =>
                                  _showAppointmentPopup(appointment: appointment),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: appointment.getTypeColor(),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            appointment.getAppointmentTypeLabel(),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: appointment.getStatusColor(),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            appointment.getStatusLabel(),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.red),
                                          onPressed: () =>
                                              _deleteAppointment(appointment),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.local_hospital,
                                            size: 20, color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Text(
                                          appointment.hospital,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (appointment.appointmentTime != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time,
                                              size: 20, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text(
                                            appointment.appointmentTime!,
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade700),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (appointment.details != null &&
                                        appointment.details!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.note,
                                              size: 20, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              appointment.details!,
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (appointment.reminderEnabled) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.notifications_active,
                                              size: 18,
                                              color: Colors.orange.shade400),
                                          const SizedBox(width: 8),
                                          Text(
                                            '알림 설정됨',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
