class Appointment {
  final String id;
  final String clientName;
  final DateTime dateTime;
  final int duration;
  final bool hasPaid;
  final String service;
  final String status;
  final String comments;
  final String owner;
  final double deposit;

  Appointment(
      {required this.id,
      required this.clientName,
      required this.dateTime,
      required this.duration,
      required this.hasPaid,
      required this.service,
      required this.status,
      required this.comments,
      required this.owner,
      required this.deposit});
}
