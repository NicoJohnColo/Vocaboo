class ClassModel {
  final String classId;
  final String name;
  final String? gradeLevel;
  final String classCode;
  final String teacherName;
  final String? teacherSchool;
  final int studentCount;
  final DateTime? enrolledAt;
  final int totalLessons;

  ClassModel({
    required this.classId,
    required this.name,
    this.gradeLevel,
    required this.classCode,
    required this.teacherName,
    this.teacherSchool,
    required this.studentCount,
    this.enrolledAt,
    this.totalLessons = 0,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      classId: json['classId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      gradeLevel: json['gradeLevel']?.toString(),
      classCode: json['classCode']?.toString() ?? '',
      teacherName: json['teacherName']?.toString() ?? 'Teacher',
      teacherSchool: json['teacherSchool']?.toString(),
      studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
      enrolledAt: json['enrolledAt'] != null ? DateTime.tryParse(json['enrolledAt'].toString()) : null,
      totalLessons: (json['totalLessons'] as num?)?.toInt() ?? 0,
    );
  }
}

class ClassInvitationModel {
  final String invitationId;
  final String classId;
  final String className;
  final String? gradeLevel;
  final String classCode;
  final String teacherName;
  final String? teacherSchool;
  final DateTime? sentAt;
  final String status;

  ClassInvitationModel({
    required this.invitationId,
    required this.classId,
    required this.className,
    this.gradeLevel,
    required this.classCode,
    required this.teacherName,
    this.teacherSchool,
    this.sentAt,
    required this.status,
  });

  factory ClassInvitationModel.fromJson(Map<String, dynamic> json) {
    return ClassInvitationModel(
      invitationId: json['invitationId']?.toString() ?? '',
      classId: json['classId']?.toString() ?? '',
      className: json['className']?.toString() ?? '',
      gradeLevel: json['gradeLevel']?.toString(),
      classCode: json['classCode']?.toString() ?? '',
      teacherName: json['teacherName']?.toString() ?? 'Teacher',
      teacherSchool: json['teacherSchool']?.toString(),
      sentAt: json['sentAt'] != null ? DateTime.tryParse(json['sentAt'].toString()) : null,
      status: json['status']?.toString() ?? 'PENDING',
    );
  }
}
