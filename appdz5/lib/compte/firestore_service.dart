import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot snapshot =
      await _firestore.collection('User').doc(userId).get();
      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.id, snapshot.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print("Erreur lors de la récupération : $e");
    }
    return null;
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('User').doc(userId).update(data);
  }
}
