class InventoryModel {
  final String id;
  final String organizationId;
  final String itemName;
  final int quantity;
  final String condition;
  final String location;

  InventoryModel({
    required this.id,
    required this.organizationId,
    required this.itemName,
    required this.quantity,
    required this.condition,
    required this.location,
  });

  InventoryModel copyWith({
    String? id,
    String? organizationId,
    String? itemName,
    int? quantity,
    String? condition,
    String? location,
  }) {
    return InventoryModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      condition: condition ?? this.condition,
      location: location ?? this.location,
    );
  }

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      itemName: json['itemName'] as String,
      quantity: json['quantity'] as int,
      condition: json['condition'] as String,
      location: json['location'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationId': organizationId,
      'itemName': itemName,
      'quantity': quantity,
      'condition': condition,
      'location': location,
    };
  }
}
