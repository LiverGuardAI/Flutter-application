// 병원 일정 추가/수정 팝업
import 'package:flutter/material.dart';
import '../models/appointment.dart';

class AppointmentPopup extends StatefulWidget {
  final Appointment? initialAppointment;
  final DateTime? selectedDate;
  final Function(Appointment)? onSave;

  const AppointmentPopup({
    super.key,
    this.initialAppointment,
    this.selectedDate,
    this.onSave,
  });

  @override
  _AppointmentPopupState createState() => _AppointmentPopupState();
}

class _AppointmentPopupState extends State<AppointmentPopup> {
  final TextEditingController hospitalController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();

  DateTime? appointmentDate;
  String appointmentType = 'blood_test';
  String status = 'scheduled';
  bool reminderEnabled = true;

  final List<Map<String, String>> appointmentTypes = [
    {'value': 'blood_test', 'label': '혈액검사'},
    {'value': 'ct', 'label': 'CT 검사'},
    {'value': 'mri', 'label': 'MRI 검사'},
    {'value': 'ultrasound', 'label': '초음파 검사'},
    {'value': 'consultation', 'label': '진료 상담'},
    {'value': 'other', 'label': '기타'},
  ];

  final List<Map<String, String>> statusOptions = [
    {'value': 'scheduled', 'label': '예정'},
    {'value': 'completed', 'label': '완료'},
    {'value': 'cancelled', 'label': '취소'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialAppointment != null) {
      hospitalController.text = widget.initialAppointment!.hospital;
      timeController.text = widget.initialAppointment!.appointmentTime ?? '';
      detailsController.text = widget.initialAppointment!.details ?? '';
      appointmentDate = widget.initialAppointment!.appointmentDate;
      appointmentType = widget.initialAppointment!.appointmentType;
      status = widget.initialAppointment!.status;
      reminderEnabled = widget.initialAppointment!.reminderEnabled;
    } else {
      appointmentDate = widget.selectedDate ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    hospitalController.dispose();
    timeController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: appointmentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != appointmentDate) {
      setState(() {
        appointmentDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        timeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _saveAppointment() {
    if (hospitalController.text.isEmpty || appointmentDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('병원명과 날짜를 입력해주세요.')));
      return;
    }

    final appointment = Appointment(
      appointmentId: widget.initialAppointment?.appointmentId,
      appointmentDate: appointmentDate!,
      appointmentTime: timeController.text.isEmpty ? null : timeController.text,
      hospital: hospitalController.text,
      appointmentType: appointmentType,
      details: detailsController.text.isEmpty ? null : detailsController.text,
      status: status,
      reminderEnabled: reminderEnabled,
    );

    widget.onSave?.call(appointment);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 650),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.initialAppointment == null ? '일정 추가' : '일정 수정',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '병원명',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: hospitalController,
                      decoration: const InputDecoration(
                        hintText: '병원 이름을 입력하세요',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '검사 종류',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: appointmentType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: appointmentTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type['value'],
                              child: Text(type['label']!),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          appointmentType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '날짜',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              appointmentDate != null
                                  ? '${appointmentDate!.year}-${appointmentDate!.month.toString().padLeft(2, '0')}-${appointmentDate!.day.toString().padLeft(2, '0')}'
                                  : '날짜를 선택하세요',
                            ),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '시간 (선택)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectTime(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              timeController.text.isEmpty
                                  ? '시간을 선택하세요'
                                  : timeController.text,
                            ),
                            const Icon(Icons.access_time, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '상태',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: statusOptions
                          .map(
                            (s) => DropdownMenuItem(
                              value: s['value'],
                              child: Text(s['label']!),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          status = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '메모 (선택)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: detailsController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: '메모를 입력하세요',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: reminderEnabled,
                          onChanged: (value) {
                            setState(() {
                              reminderEnabled = value!;
                            });
                          },
                        ),
                        const Text('알림 설정'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.initialAppointment == null ? '추가' : '수정',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
