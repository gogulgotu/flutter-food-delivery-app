/// Vendor Category Model
class VendorCategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? icon;
  final String? image;

  VendorCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.image,
  });

  factory VendorCategoryModel.fromJson(Map<String, dynamic> json) {
    return VendorCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      icon: json['icon'] as String?,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      if (icon != null) 'icon': icon,
      if (image != null) 'image': image,
    };
  }
}

