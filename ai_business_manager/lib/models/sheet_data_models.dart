// Base mixin to ensure standard Google Sheets conversion
mixin SheetDataMapper {
  List<Object?> toSheetRow();
}

// Model for Enquiry
class Enquiry implements SheetDataMapper {
  final String id;
  final String customerName;
  final String phone;
  final String modelInterested;
  final String status;
  final DateTime date;
  final String handledBy;

  Enquiry({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.modelInterested,
    required this.status,
    required this.date,
    required this.handledBy,
  });

  factory Enquiry.fromRow(List<dynamic> row) {
    return Enquiry(
      id: row.isNotEmpty ? row[0].toString() : '',
      customerName: row.length > 1 ? row[1].toString() : '',
      phone: row.length > 2 ? row[2].toString() : '',
      modelInterested: row.length > 3 ? row[3].toString() : '',
      status: row.length > 4 ? row[4].toString() : 'New',
      date: row.length > 5
          ? DateTime.tryParse(row[5].toString()) ?? DateTime.now()
          : DateTime.now(),
      handledBy: row.length > 6 ? row[6].toString() : '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerName': customerName,
    'phone': phone,
    'modelInterested': modelInterested,
    'status': status,
    'date': date.toIso8601String(),
    'handledBy': handledBy,
  };

  factory Enquiry.fromJson(Map<String, dynamic> json) => Enquiry(
    id: json['id'],
    customerName: json['customerName'],
    phone: json['phone'],
    modelInterested: json['modelInterested'],
    status: json['status'],
    date: DateTime.parse(json['date']),
    handledBy: json['handledBy'],
  );

  @override
  List<Object?> toSheetRow() {
    return [
      id,
      customerName,
      phone,
      modelInterested,
      status,
      date.toIso8601String(),
      handledBy,
    ];
  }
}

// Model for Bookings
class Booking implements SheetDataMapper {
  final String bookingId;
  final String customerName;
  final String vehicleModel;
  final double bookingAmount;
  final DateTime bookingDate;

  Booking({
    required this.bookingId,
    required this.customerName,
    required this.vehicleModel,
    required this.bookingAmount,
    required this.bookingDate,
  });

  factory Booking.fromRow(List<dynamic> row) {
    return Booking(
      bookingId: row.isNotEmpty ? row[0].toString() : '',
      customerName: row.length > 1 ? row[1].toString() : '',
      vehicleModel: row.length > 2 ? row[2].toString() : '',
      bookingAmount: row.length > 3
          ? double.tryParse(row[3].toString()) ?? 0.0
          : 0.0,
      bookingDate: row.length > 4
          ? DateTime.tryParse(row[4].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'bookingId': bookingId,
    'customerName': customerName,
    'vehicleModel': vehicleModel,
    'bookingAmount': bookingAmount,
    'bookingDate': bookingDate.toIso8601String(),
  };

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    bookingId: json['bookingId'],
    customerName: json['customerName'],
    vehicleModel: json['vehicleModel'],
    bookingAmount: json['bookingAmount'],
    bookingDate: DateTime.parse(json['bookingDate']),
  );

  @override
  List<Object?> toSheetRow() {
    return [
      bookingId,
      customerName,
      vehicleModel,
      bookingAmount,
      bookingDate.toIso8601String(),
    ];
  }
}

// Model for Sold Vehicles
class Sold implements SheetDataMapper {
  final String saleId;
  final String customerName;
  final String vehicleModel;
  final double saleAmount;
  final DateTime saleDate;

  Sold({
    required this.saleId,
    required this.customerName,
    required this.vehicleModel,
    required this.saleAmount,
    required this.saleDate,
  });

  factory Sold.fromRow(List<dynamic> row) {
    return Sold(
      saleId: row.isNotEmpty ? row[0].toString() : '',
      customerName: row.length > 1 ? row[1].toString() : '',
      vehicleModel: row.length > 2 ? row[2].toString() : '',
      saleAmount: row.length > 3
          ? double.tryParse(row[3].toString()) ?? 0.0
          : 0.0,
      saleDate: row.length > 4
          ? DateTime.tryParse(row[4].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'saleId': saleId,
    'customerName': customerName,
    'vehicleModel': vehicleModel,
    'saleAmount': saleAmount,
    'saleDate': saleDate.toIso8601String(),
  };

  factory Sold.fromJson(Map<String, dynamic> json) => Sold(
    saleId: json['saleId'],
    customerName: json['customerName'],
    vehicleModel: json['vehicleModel'],
    saleAmount: json['saleAmount'],
    saleDate: DateTime.parse(json['saleDate']),
  );

  @override
  List<Object?> toSheetRow() {
    return [
      saleId,
      customerName,
      vehicleModel,
      saleAmount,
      saleDate.toIso8601String(),
    ];
  }
}

// Model for Stock items
class Stock implements SheetDataMapper {
  final String vehicleModel;
  final String color;
  final String chassisNumber;
  final String engineNumber;
  final String location;
  final String status; // e.g., Available, Blocked, In Transit
  final int daysInStock;

  Stock({
    required this.vehicleModel,
    required this.color,
    required this.chassisNumber,
    required this.engineNumber,
    required this.location,
    required this.status,
    required this.daysInStock,
  });

  factory Stock.fromRow(List<dynamic> row) {
    return Stock(
      vehicleModel: row.isNotEmpty ? row[0].toString() : '',
      color: row.length > 1 ? row[1].toString() : '',
      chassisNumber: row.length > 2 ? row[2].toString() : '',
      engineNumber: row.length > 3 ? row[3].toString() : '',
      location: row.length > 4 ? row[4].toString() : '',
      status: row.length > 5 ? row[5].toString() : '',
      daysInStock: row.length > 6 ? int.tryParse(row[6].toString()) ?? 0 : 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'vehicleModel': vehicleModel,
    'color': color,
    'chassisNumber': chassisNumber,
    'engineNumber': engineNumber,
    'location': location,
    'status': status,
    'daysInStock': daysInStock,
  };

  factory Stock.fromJson(Map<String, dynamic> json) => Stock(
    vehicleModel: json['vehicleModel'],
    color: json['color'],
    chassisNumber: json['chassisNumber'],
    engineNumber: json['engineNumber'],
    location: json['location'],
    status: json['status'],
    daysInStock: json['daysInStock'],
  );

  @override
  List<Object?> toSheetRow() {
    return [
      vehicleModel,
      color,
      chassisNumber,
      engineNumber,
      location,
      status,
      daysInStock,
    ];
  }
}
