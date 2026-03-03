class Branch {
  final String id;
  final String name;
  final String googleSheetId;
  final String enquirySheetGid;
  final String bookingSheetGid;
  final String soldSheetGid;
  final String stockSheetGid;
  final String? apiKey; // Deprecated, using OAuth Service Account

  Branch({
    required this.id,
    required this.name,
    required this.googleSheetId,
    required this.enquirySheetGid,
    required this.bookingSheetGid,
    required this.soldSheetGid,
    required this.stockSheetGid,
    this.apiKey,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as String,
      name: json['name'] as String,
      googleSheetId: json['googleSheetId'] as String,
      enquirySheetGid: json['enquirySheetGid'] as String,
      bookingSheetGid: json['bookingSheetGid'] as String,
      soldSheetGid: json['soldSheetGid'] as String,
      stockSheetGid: json['stockSheetGid'] as String,
      apiKey: json['apiKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'googleSheetId': googleSheetId,
      'enquirySheetGid': enquirySheetGid,
      'bookingSheetGid': bookingSheetGid,
      'soldSheetGid': soldSheetGid,
      'stockSheetGid': stockSheetGid,
      'apiKey': apiKey,
    };
  }
}
