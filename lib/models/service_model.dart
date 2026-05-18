class ServiceModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int duration;
  final String? categoryId;
  final String? categoryName;
  final String? image;
  final bool isVisible;

  const ServiceModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.duration,
    this.categoryId,
    this.categoryName,
    this.image,
    this.isVisible = true,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    return ServiceModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      categoryId: category is Map ? category['_id']?.toString() : category?.toString(),
      categoryName: category is Map ? category['name']?.toString() : null,
      image: json['image']?.toString(),
      isVisible: json['isVisible'] != false,
    );
  }
}
