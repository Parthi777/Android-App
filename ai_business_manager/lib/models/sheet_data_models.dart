DateTime _parseDateSafely(String value) {
  final date = DateTime.tryParse(value);
  if (date != null) return date;
  return DateTime.now(); // Fallback date if sheet format is not standard
}

double _parseDoubleSafely(String value) {
  final clean = value.replaceAll(RegExp(r'[^\\d.]'), '');
  return double.tryParse(clean) ?? 0.0;
}

// Base mixin to ensure standard Google Sheets conversion
mixin SheetDataMapper {
  List<Object?> toSheetRow();
}

// Model for Enquiry
class Enquiry implements SheetDataMapper {
  final String id;
  final DateTime date;
  final String executive;
  final String customerName;
  final String phone;
  final String modelInterested;
  final String source;
  final String status;

  // UI expects 'handledBy'
  String get handledBy => executive;

  Enquiry({
    required this.id,
    required this.date,
    required this.executive,
    required this.customerName,
    required this.phone,
    required this.modelInterested,
    required this.source,
    required this.status,
  });

  factory Enquiry.fromRow(List<dynamic> row) {
    return Enquiry(
      id: row.isNotEmpty ? row[0].toString() : '',
      date: row.length > 1
          ? _parseDateSafely(row[1].toString())
          : DateTime.now(),
      executive: row.length > 2 ? row[2].toString() : '',
      customerName: row.length > 3 ? row[3].toString() : '',
      phone: row.length > 4 ? row[4].toString() : '',
      modelInterested: row.length > 5 ? row[5].toString() : '',
      source: row.length > 6 ? row[6].toString() : '',
      status: row.length > 7 ? row[7].toString() : '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'executive': executive,
    'customerName': customerName,
    'phone': phone,
    'modelInterested': modelInterested,
    'source': source,
    'status': status,
  };

  factory Enquiry.fromJson(Map<String, dynamic> json) => Enquiry(
    id: json['id'] ?? '',
    date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    executive: json['executive'] ?? '',
    customerName: json['customerName'] ?? '',
    phone: json['phone'] ?? '',
    modelInterested: json['modelInterested'] ?? '',
    source: json['source'] ?? '',
    status: json['status'] ?? '',
  );

  @override
  List<Object?> toSheetRow() {
    return [
      id,
      date.toIso8601String(),
      executive,
      customerName,
      phone,
      modelInterested,
      source,
      status,
    ];
  }
}

// Model for Bookings
class Booking implements SheetDataMapper {
  final String bookingId;
  final DateTime bookingDate;
  final String executive;
  final String customerName;
  final String phone;
  final String vehicleModel;
  final double bookingAmount;
  final String paymentMode;
  final String status;

  Booking({
    required this.bookingId,
    required this.bookingDate,
    required this.executive,
    required this.customerName,
    required this.phone,
    required this.vehicleModel,
    required this.bookingAmount,
    required this.paymentMode,
    required this.status,
  });

  factory Booking.fromRow(List<dynamic> row) {
    return Booking(
      bookingId: row.isNotEmpty ? row[0].toString() : '',
      bookingDate: row.length > 1
          ? _parseDateSafely(row[1].toString())
          : DateTime.now(),
      executive: row.length > 2 ? row[2].toString() : '',
      customerName: row.length > 3 ? row[3].toString() : '',
      phone: row.length > 4 ? row[4].toString() : '',
      vehicleModel: row.length > 5 ? row[5].toString() : '',
      bookingAmount: row.length > 6
          ? _parseDoubleSafely(row[6].toString())
          : 0.0,
      paymentMode: row.length > 7 ? row[7].toString() : '',
      status: row.length > 8 ? row[8].toString() : '',
    );
  }

  Map<String, dynamic> toJson() => {
    'bookingId': bookingId,
    'bookingDate': bookingDate.toIso8601String(),
    'executive': executive,
    'customerName': customerName,
    'phone': phone,
    'vehicleModel': vehicleModel,
    'bookingAmount': bookingAmount,
    'paymentMode': paymentMode,
    'status': status,
  };

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    bookingId: json['bookingId'] ?? '',
    bookingDate: DateTime.tryParse(json['bookingDate'] ?? '') ?? DateTime.now(),
    executive: json['executive'] ?? '',
    customerName: json['customerName'] ?? '',
    phone: json['phone'] ?? '',
    vehicleModel: json['vehicleModel'] ?? '',
    bookingAmount: json['bookingAmount'] ?? 0.0,
    paymentMode: json['paymentMode'] ?? '',
    status: json['status'] ?? '',
  );

  @override
  List<Object?> toSheetRow() {
    return [
      bookingId,
      bookingDate.toIso8601String(),
      executive,
      customerName,
      phone,
      vehicleModel,
      bookingAmount,
      paymentMode,
      status,
    ];
  }
}

// Model for Sold Vehicles
class Sold implements SheetDataMapper {
  final DateTime saleDate;
  final String customerName;
  final String mobileNo;
  final String executiveName;
  final String vehicleModel;
  final String category;
  final String engineNo;
  final String frameNo;
  final double vehicleCost;
  final String exFittings;
  final String discountOperated;
  final String downpayment;
  final String cashHp;
  final String financierName;
  final String documentCharges;
  final String financeDd;
  final String customerBalance;
  final String exchangeVehicle;
  final String exchangeValue;
  final String exchangeVehicleSoldStatus;
  final String exchangeVehicleManufacturing;
  final String invoiceStatus;
  final String invoiceDate;
  final String rtoLocation;
  final String rto;
  final String registerationNo;

  // Fallbacks for UI compatibility
  String get saleId => frameNo;
  double get saleAmount => vehicleCost;

  Sold({
    required this.saleDate,
    required this.customerName,
    required this.mobileNo,
    required this.executiveName,
    required this.vehicleModel,
    required this.category,
    required this.engineNo,
    required this.frameNo,
    required this.vehicleCost,
    required this.exFittings,
    required this.discountOperated,
    required this.downpayment,
    required this.cashHp,
    required this.financierName,
    required this.documentCharges,
    required this.financeDd,
    required this.customerBalance,
    required this.exchangeVehicle,
    required this.exchangeValue,
    required this.exchangeVehicleSoldStatus,
    required this.exchangeVehicleManufacturing,
    required this.invoiceStatus,
    required this.invoiceDate,
    required this.rtoLocation,
    required this.rto,
    required this.registerationNo,
  });

  factory Sold.fromRow(List<dynamic> row) {
    return Sold(
      saleDate: row.isNotEmpty
          ? _parseDateSafely(row[0].toString())
          : DateTime.now(),
      customerName: row.length > 1 ? row[1].toString() : '',
      mobileNo: row.length > 2 ? row[2].toString() : '',
      executiveName: row.length > 3 ? row[3].toString() : '',
      vehicleModel: row.length > 4 ? row[4].toString() : '',
      category: row.length > 5 ? row[5].toString() : '',
      engineNo: row.length > 6 ? row[6].toString() : '',
      frameNo: row.length > 7 ? row[7].toString() : '',
      vehicleCost: row.length > 8 ? _parseDoubleSafely(row[8].toString()) : 0.0,
      exFittings: row.length > 9 ? row[9].toString() : '',
      discountOperated: row.length > 10 ? row[10].toString() : '',
      downpayment: row.length > 11 ? row[11].toString() : '',
      cashHp: row.length > 12 ? row[12].toString() : '',
      financierName: row.length > 13 ? row[13].toString() : '',
      documentCharges: row.length > 14 ? row[14].toString() : '',
      financeDd: row.length > 15 ? row[15].toString() : '',
      customerBalance: row.length > 16 ? row[16].toString() : '',
      exchangeVehicle: row.length > 17 ? row[17].toString() : '',
      exchangeValue: row.length > 18 ? row[18].toString() : '',
      exchangeVehicleSoldStatus: row.length > 19 ? row[19].toString() : '',
      exchangeVehicleManufacturing: row.length > 20 ? row[20].toString() : '',
      invoiceStatus: row.length > 21 ? row[21].toString() : '',
      invoiceDate: row.length > 22 ? row[22].toString() : '',
      rtoLocation: row.length > 23 ? row[23].toString() : '',
      rto: row.length > 24 ? row[24].toString() : '',
      registerationNo: row.length > 25 ? row[25].toString() : '',
    );
  }

  Map<String, dynamic> toJson() => {
    'saleDate': saleDate.toIso8601String(),
    'customerName': customerName,
    'mobileNo': mobileNo,
    'executiveName': executiveName,
    'vehicleModel': vehicleModel,
    'category': category,
    'engineNo': engineNo,
    'frameNo': frameNo,
    'vehicleCost': vehicleCost,
    'exFittings': exFittings,
    'discountOperated': discountOperated,
    'downpayment': downpayment,
    'cashHp': cashHp,
    'financierName': financierName,
    'documentCharges': documentCharges,
    'financeDd': financeDd,
    'customerBalance': customerBalance,
    'exchangeVehicle': exchangeVehicle,
    'exchangeValue': exchangeValue,
    'exchangeVehicleSoldStatus': exchangeVehicleSoldStatus,
    'exchangeVehicleManufacturing': exchangeVehicleManufacturing,
    'invoiceStatus': invoiceStatus,
    'invoiceDate': invoiceDate,
    'rtoLocation': rtoLocation,
    'rto': rto,
    'registerationNo': registerationNo,
  };

  factory Sold.fromJson(Map<String, dynamic> json) => Sold(
    saleDate: DateTime.tryParse(json['saleDate'] ?? '') ?? DateTime.now(),
    customerName: json['customerName'] ?? '',
    mobileNo: json['mobileNo'] ?? '',
    executiveName: json['executiveName'] ?? '',
    vehicleModel: json['vehicleModel'] ?? '',
    category: json['category'] ?? '',
    engineNo: json['engineNo'] ?? '',
    frameNo: json['frameNo'] ?? '',
    vehicleCost: json['vehicleCost'] ?? 0.0,
    exFittings: json['exFittings'] ?? '',
    discountOperated: json['discountOperated'] ?? '',
    downpayment: json['downpayment'] ?? '',
    cashHp: json['cashHp'] ?? '',
    financierName: json['financierName'] ?? '',
    documentCharges: json['documentCharges'] ?? '',
    financeDd: json['financeDd'] ?? '',
    customerBalance: json['customerBalance'] ?? '',
    exchangeVehicle: json['exchangeVehicle'] ?? '',
    exchangeValue: json['exchangeValue'] ?? '',
    exchangeVehicleSoldStatus: json['exchangeVehicleSoldStatus'] ?? '',
    exchangeVehicleManufacturing: json['exchangeVehicleManufacturing'] ?? '',
    invoiceStatus: json['invoiceStatus'] ?? '',
    invoiceDate: json['invoiceDate'] ?? '',
    rtoLocation: json['rtoLocation'] ?? '',
    rto: json['rto'] ?? '',
    registerationNo: json['registerationNo'] ?? '',
  );

  @override
  List<Object?> toSheetRow() {
    return [
      saleDate.toIso8601String(),
      customerName,
      mobileNo,
      executiveName,
      vehicleModel,
      category,
      engineNo,
      frameNo,
      vehicleCost,
      exFittings,
      discountOperated,
      downpayment,
      cashHp,
      financierName,
      documentCharges,
      financeDd,
      customerBalance,
      exchangeVehicle,
      exchangeValue,
      exchangeVehicleSoldStatus,
      exchangeVehicleManufacturing,
      invoiceStatus,
      invoiceDate,
      rtoLocation,
      rto,
      registerationNo,
    ];
  }
}

// Model for Stock items
class Stock implements SheetDataMapper {
  final String vehicleModel;
  final String color;
  final String frameNo;
  final String engineNo;
  final String quantity;
  final String tvsInvoiceDate;
  final String agingStockDays;
  final String dealerInvoiceStatus;
  final String pdiStatus;

  // UI Compatibility Setters
  String get chassisNumber => frameNo;
  String get engineNumber => engineNo;
  String get location => dealerInvoiceStatus;
  String get status => pdiStatus.isEmpty ? dealerInvoiceStatus : pdiStatus;
  int get daysInStock => int.tryParse(agingStockDays) ?? 0;

  Stock({
    required this.vehicleModel,
    required this.color,
    required this.frameNo,
    required this.engineNo,
    required this.quantity,
    required this.tvsInvoiceDate,
    required this.agingStockDays,
    required this.dealerInvoiceStatus,
    required this.pdiStatus,
  });

  factory Stock.fromRow(List<dynamic> row) {
    return Stock(
      vehicleModel: row.isNotEmpty ? row[0].toString() : '',
      color: row.length > 1 ? row[1].toString() : '',
      frameNo: row.length > 2 ? row[2].toString() : '',
      engineNo: row.length > 3 ? row[3].toString() : '',
      quantity: row.length > 4 ? row[4].toString() : '',
      tvsInvoiceDate: row.length > 5 ? row[5].toString() : '',
      agingStockDays: row.length > 6 ? row[6].toString() : '',
      dealerInvoiceStatus: row.length > 7 ? row[7].toString() : '',
      pdiStatus: row.length > 8 ? row[8].toString() : '',
    );
  }

  Map<String, dynamic> toJson() => {
    'vehicleModel': vehicleModel,
    'color': color,
    'frameNo': frameNo,
    'engineNo': engineNo,
    'quantity': quantity,
    'tvsInvoiceDate': tvsInvoiceDate,
    'agingStockDays': agingStockDays,
    'dealerInvoiceStatus': dealerInvoiceStatus,
    'pdiStatus': pdiStatus,
  };

  factory Stock.fromJson(Map<String, dynamic> json) => Stock(
    vehicleModel: json['vehicleModel'] ?? '',
    color: json['color'] ?? '',
    frameNo: json['frameNo'] ?? '',
    engineNo: json['engineNo'] ?? '',
    quantity: json['quantity'] ?? '',
    tvsInvoiceDate: json['tvsInvoiceDate'] ?? '',
    agingStockDays: json['agingStockDays'] ?? '',
    dealerInvoiceStatus: json['dealerInvoiceStatus'] ?? '',
    pdiStatus: json['pdiStatus'] ?? '',
  );

  @override
  List<Object?> toSheetRow() {
    return [
      vehicleModel,
      color,
      frameNo,
      engineNo,
      quantity,
      tvsInvoiceDate,
      agingStockDays,
      dealerInvoiceStatus,
      pdiStatus,
    ];
  }
}
