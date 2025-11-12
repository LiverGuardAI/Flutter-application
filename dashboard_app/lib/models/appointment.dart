// 일정 관리 테이블 모델
import 'package:flutter/material.dart';

class Appointment {
  final int? appointmentId;
  final String? patientId;
  final DateTime appointmentDate;
  final String? appointmentTime;
  final String hospital;
  final String appointmentType;
  final String? details;
  final String status;
  final bool reminderEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Appointment({
    this.appointmentId,
    this.patientId,
    required this.appointmentDate,
    this.appointmentTime,
    required this.hospital,
    required this.appointmentType,
    this.details,
    this.status = 'scheduled',
    this.reminderEnabled = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      appointmentId: json['appointment_id'],
      patientId: json['patient_id'],
      appointmentDate: DateTime.parse(json['appointment_date']),
      appointmentTime: json['appointment_time'],
      hospital: json['hospital'],
      appointmentType: json['appointment_type'],
      details: json['details'],
      status: json['status'] ?? 'scheduled',
      reminderEnabled: json['reminder_enabled'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (appointmentId != null) 'appointment_id': appointmentId,
      'appointment_date':
          '${appointmentDate.year}-${appointmentDate.month.toString().padLeft(2, '0')}-${appointmentDate.day.toString().padLeft(2, '0')}',
      if (appointmentTime != null) 'appointment_time': appointmentTime,
      'hospital': hospital,
      'appointment_type': appointmentType,
      if (details != null) 'details': details,
      'status': status,
      'reminder_enabled': reminderEnabled,
    };
  }

  String getAppointmentTypeLabel() {
    switch (appointmentType) {
      case 'blood_test':
        return '혈액검사';
      case 'ct':
        return 'CT 검사';
      case 'mri':
        return 'MRI 검사';
      case 'ultrasound':
        return '초음파 검사';
      case 'consultation':
        return '진료 상담';
      case 'other':
        return '기타';
      default:
        return appointmentType;
    }
  }

  String getStatusLabel() {
    switch (status) {
      case 'scheduled':
        return '예정';
      case 'completed':
        return '완료';
      case 'cancelled':
        return '취소';
      default:
        return status;
    }
  }

  Color getStatusColor() {
    switch (status) {
      case 'scheduled':
        return const Color(0xFF5B9FED);
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  Color getTypeColor() {
    switch (appointmentType) {
      case 'blood_test':
        return const Color(0xFFE57373);
      case 'ct':
        return const Color(0xFF64B5F6);
      case 'mri':
        return const Color(0xFF81C784);
      case 'ultrasound':
        return const Color(0xFFFFD54F);
      case 'consultation':
        return const Color(0xFFBA68C8);
      case 'other':
        return const Color(0xFF90A4AE);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
