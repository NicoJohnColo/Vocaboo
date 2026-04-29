class LearnerModel {
  final int? id;
  final String name;
  final int age;
  final String pin;
  final String languagePreference;

  LearnerModel({
    this.id,
    required this.name,
    required this.age,
    required this.pin,
    required this.languagePreference,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'pin': pin,
      'languagePreference': languagePreference,
    };
  }

  factory LearnerModel.fromJson(Map<String, dynamic> json) {
    return LearnerModel(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      pin: json['pin'],
      languagePreference: json['languagePreference'],
    );
  }
}
