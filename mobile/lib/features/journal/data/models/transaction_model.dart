import 'dart:convert';

import '../../domain/entities/transaction.dart';

/// Data model for LaundryTransaction with JSON/Map serialization.
class TransactionModel extends LaundryTransaction {
  /// Creates a new TransactionModel.
  const TransactionModel({
    required super.itemId, required super.itemName, required super.quantity, required super.rate, super.id,
    super.status = TransactionStatus.sent,
    super.memberId,
    super.memberName,
    super.notes,
    super.sentAt,
    super.returnedAt,
    super.createdAt,
    super.services = const [],
    super.serviceCharges = const {},
  });

  /// Creates a TransactionModel from a Map (database row).
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      itemId: map['item_id'] as int,
      itemName: map['item_name'] as String,
      quantity: map['quantity'] as int,
      rate: (map['rate'] as num).toDouble(),
      status: _parseStatus(map['status'] as String?),
      memberId: map['member_id'] as int?,
      memberName: map['member_name'] as String?,
      notes: map['notes'] as String?,
      sentAt: map['sent_at'] != null
          ? DateTime.parse(map['sent_at'] as String)
          : null,
      returnedAt: map['returned_at'] != null
          ? DateTime.parse(map['returned_at'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      services: _parseServices(map['services'] as String?),
      serviceCharges: _parseServiceCharges(map['service_charges'] as String?),
    );
  }

  /// Creates a TransactionModel from a domain entity.
  factory TransactionModel.fromEntity(LaundryTransaction transaction) {
    return TransactionModel(
      id: transaction.id,
      itemId: transaction.itemId,
      itemName: transaction.itemName,
      quantity: transaction.quantity,
      rate: transaction.rate,
      status: transaction.status,
      memberId: transaction.memberId,
      memberName: transaction.memberName,
      notes: transaction.notes,
      sentAt: transaction.sentAt,
      returnedAt: transaction.returnedAt,
      createdAt: transaction.createdAt,
      services: transaction.services,
      serviceCharges: transaction.serviceCharges,
    );
  }

  /// Parses a status string to TransactionStatus enum.
  static TransactionStatus _parseStatus(String? status) {
    switch (status) {
      case 'sent':
        return TransactionStatus.sent;
      case 'inProgress':
        return TransactionStatus.inProgress;
      case 'returned':
        return TransactionStatus.returned;
      case 'cancelled':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.sent;
    }
  }

  /// Converts TransactionStatus to string for storage.
  static String _statusToString(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.sent:
        return 'sent';
      case TransactionStatus.inProgress:
        return 'inProgress';
      case TransactionStatus.returned:
        return 'returned';
      case TransactionStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Parses services from JSON string.
  static List<String> _parseServices(String? servicesJson) {
    if (servicesJson == null || servicesJson.isEmpty || servicesJson == '[]') {
      return [];
    }
    try {
      final decoded = jsonDecode(servicesJson);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Parses service charges from JSON string.
  static Map<String, double> _parseServiceCharges(String? chargesJson) {
    if (chargesJson == null || chargesJson.isEmpty || chargesJson == '{}') {
      return {};
    }
    try {
      final decoded = jsonDecode(chargesJson);
      if (decoded is Map) {
        return decoded.map((key, value) =>
            MapEntry(key.toString(), (value as num).toDouble()));
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  /// Converts services list to JSON string.
  static String _servicesToString(List<String> services) {
    return jsonEncode(services);
  }

  /// Converts service charges map to JSON string.
  static String _serviceChargesToString(Map<String, double> charges) {
    return jsonEncode(charges);
  }

  /// Converts this model to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'item_id': itemId,
      'item_name': itemName,
      'quantity': quantity,
      'rate': rate,
      'price_at_time': rate, // Capture rate at time of transaction
      'status': _statusToString(status),
      'member_id': memberId,
      'member_name': memberName,
      'notes': notes,
      'sent_at': sentAt?.toIso8601String(),
      'returned_at': returnedAt?.toIso8601String(),
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'services': _servicesToString(services),
      'service_charges': _serviceChargesToString(serviceCharges),
    };
  }

  /// Converts this model to a Map for insertion (without id).
  Map<String, dynamic> toInsertMap() {
    final now = DateTime.now();
    return {
      'item_id': itemId,
      'item_name': itemName,
      'quantity': quantity,
      'rate': rate,
      'price_at_time': rate, // Capture rate at time of transaction
      'status': _statusToString(status),
      'member_id': memberId,
      'member_name': memberName,
      'notes': notes,
      'sent_at': (sentAt ?? now).toIso8601String(),
      'returned_at': returnedAt?.toIso8601String(),
      'created_at': now.toIso8601String(),
      'services': _servicesToString(services),
      'service_charges': _serviceChargesToString(serviceCharges),
    };
  }

  /// Converts this model to a Map for update.
  Map<String, dynamic> toUpdateMap() {
    return {
      'item_id': itemId,
      'item_name': itemName,
      'quantity': quantity,
      'rate': rate,
      'status': _statusToString(status),
      'member_id': memberId,
      'member_name': memberName,
      'notes': notes,
      'sent_at': sentAt?.toIso8601String(),
      'returned_at': returnedAt?.toIso8601String(),
      'services': _servicesToString(services),
      'service_charges': _serviceChargesToString(serviceCharges),
    };
  }

  /// Converts this model to a domain entity.
  LaundryTransaction toEntity() {
    return LaundryTransaction(
      id: id,
      itemId: itemId,
      itemName: itemName,
      quantity: quantity,
      rate: rate,
      status: status,
      memberId: memberId,
      memberName: memberName,
      notes: notes,
      sentAt: sentAt,
      returnedAt: returnedAt,
      createdAt: createdAt,
      services: services,
      serviceCharges: serviceCharges,
    );
  }
}
