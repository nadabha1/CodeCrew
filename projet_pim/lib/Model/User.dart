class User {
  final String id;
  final String name;
  final String job;
  final String location;
  final String profileImage;
  final int followers;
  final int following;
  final int likes;

  User({
    required this.id,
    required this.name,
    required this.job,
    required this.location,
    required this.profileImage,
    required this.followers,
    required this.following,
    required this.likes,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      name: json['name'],
      job: json['job'],
      location: json['location'],
      profileImage: json['profileImage'],
      followers: json['followers'],
      following: json['following'],
      likes: json['likes'],
    );
  }
}
