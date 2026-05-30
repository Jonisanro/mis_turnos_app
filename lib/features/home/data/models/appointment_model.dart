// lib/features/turnos/data/models/turno_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String clientName;
  final String phone;
  final DateTime dateTime;
  final int duration;
  final bool hasPaid;
  final double deposit;
  final String service;
  final String status;
  final String comments;
  final String owner;

  AppointmentModel({
    required this.id,
    required this.clientName,
    this.phone = '',
    required this.dateTime,
    required this.duration,
    required this.deposit,
    required this.hasPaid,
    required this.service,
    required this.status,
    required this.comments,
    required this.owner,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      // Campos críticos con fallback seguro para evitar NPE con docs malformados.
      id: map['id'] as String? ?? '',
      clientName: map['clientName'] as String? ?? 'Sin nombre',
      phone: map['phone'] as String? ?? '',
      dateTime: map['dateTime'] != null
          ? (map['dateTime'] as Timestamp).toDate()
          : DateTime.now(),
      duration: map['duration'] as int? ?? 0,
      deposit: (map['deposit'] as num?)?.toDouble() ?? 0,
      hasPaid: map['hasPaid'] as bool? ?? false,
      service: map['service'] as String? ?? '',
      status: map['status'] as String? ?? 'pendiente',
      comments: map['comments'] as String? ?? '',
      owner: map['owner'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientName': clientName,
      'phone': phone,
      'dateTime': dateTime,
      'duration': duration,
      'deposit': deposit,
      'hasPaid': hasPaid,
      'service': service,
      'status': status,
      'comments': comments,
      'owner': owner,
    };
  }
}
