class ParentescoModel {
  final String label;
  final String value;

  ParentescoModel({required this.label, required this.value});

  factory ParentescoModel.fromJson(Map<String, dynamic> json) {
    return ParentescoModel(
      label: json['label'] ?? '',
      value: json['value'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'label': label, 'value': value};
  }
}
