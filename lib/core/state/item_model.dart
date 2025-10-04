class ItemModel {
  final String name;
  final String? category;
  final String? finish;
  final String width;
  final String length;
  final String height;
  final int count;
  final String unit;

  ItemModel({
    required this.name,
    this.category,
    this.finish,
    this.width = '',
    this.length = '',
    this.height = '',
    this.count = 1,
    this.unit = 'in',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'finish': finish,
        'width': width,
        'length': length,
        'height': height,
        'count': count,
        'unit': unit,
      };

  factory ItemModel.fromJson(Map<String, dynamic> json) => ItemModel(
        name: json['name'] as String? ?? '',
        category: json['category'] as String?,
        finish: json['finish'] as String?,
        width: json['width'] as String? ?? '',
        length: json['length'] as String? ?? '',
        height: json['height'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 1,
        unit: json['unit'] as String? ?? 'in',
      );
}
