class UserModel {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String username;
  final String emploi;
  final String sexe;

  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.username,
    required this.emploi,
    required this.sexe,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      emploi: data['emploi'].toString(),
      sexe: data['sexe'].toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'username': username,
      'emploi': emploi,
      'sexe': sexe,
    };
  }
}
