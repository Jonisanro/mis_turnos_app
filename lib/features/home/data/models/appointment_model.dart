// lib/features/turnos/data/models/turno_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String clientName;
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
      id: map['id'],
      clientName: map['clientName'],
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      duration: map['duration'],
      deposit: map['deposit'] ?? 0,
      hasPaid: map['hasPaid'] ?? false,
      service: map['service'],
      status: map['status'] ?? 'none',
      comments: map['comments'] ?? '',
      owner: map['owner'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientName': clientName,
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
