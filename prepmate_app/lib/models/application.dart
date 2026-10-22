class Application {
  final String id;
  final String company;
  final String role;
  final String interviewDate; // yyyy-MM-dd
  final num preparationHours;
  final String experience;
  final String status;
  final String jd;
  final String createdAt;

  const Application({
    required this.id,
    required this.company,
    required this.role,
    required this.interviewDate,
    required this.preparationHours,
    required this.experience,
    required this.status,
    required this.jd,
    this.createdAt = '',
  });

  factory Application.fromJson(Map<String, dynamic> json) => Application(
    id: (json['id'] ?? '').toString(),
    company: (json['company'] ?? '').toString(),
    role: (json['role'] ?? '').toString(),
    interviewDate: (json['interviewDate'] ?? '').toString(),
    preparationHours: json['preparationHours'] is num
        ? json['preparationHours'] as num
        : num.tryParse((json['preparationHours'] ?? '').toString()) ?? 0,
    experience: (json['experience'] ?? '').toString(),
    status: (json['status'] ?? '').toString(),
    jd: (json['jd'] ?? '').toString(),
    createdAt: (json['createdAt'] ?? '').toString(),
  );

  /// The fields the API accepts when creating or updating.
  Map<String, dynamic> toJson() => {
    'company': company,
    'role': role,
    'interviewDate': interviewDate,
    'preparationHours': preparationHours,
    'experience': experience,
    'status': status,
    'jd': jd,
  };
}

class AppUser {
  final String id;
  final String name;
  final String email;

  const AppUser({required this.id, required this.name, required this.email});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: (json['id'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
  );
}
