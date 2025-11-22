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
    // Handle both string and integer IDs
    // Support both 'id' and 'category_id' field names
    String id;
    final idField = json['category_id'] ?? json['id'];
    if (idField is String) {
      id = idField;
    } else if (idField is int) {
      id = idField.toString();
    } else {
      id = idField.toString();
    }

    // Support both 'name' and 'category_name' field names
    final name = (json['category_name'] ?? json['name']) as String;
    
    // Support both 'slug' and 'category_code' field names
    final slug = (json['category_code'] ?? json['slug']) as String;
    
    // Support both 'icon' and 'icon_class' field names
    final icon = json['icon_class'] as String? ?? json['icon'] as String?;
    
    // Get image
    final image = json['image'] as String?;

    return VendorCategoryModel(
      id: id,
      name: name,
      slug: slug,
      icon: icon,
      image: image,
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

