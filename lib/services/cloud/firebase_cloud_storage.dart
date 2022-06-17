import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secure_pass/services/cloud/cloud_password.dart';
import 'package:secure_pass/services/cloud/cloud_storage_constants.dart';
import 'package:secure_pass/services/cloud/cloud_storage_exceptions.dart';

class FirebaseCloudStorage {
  final passwords = FirebaseFirestore.instance.collection('passwords');

  Future<void> deletePassword({required String documentId}) async {
    try {
      await passwords.doc(documentId).delete();
    } catch (e) {
      throw CouldNotDeletePasswordException();
    }
  }

  Future<void> updatePassword({
    required String documentId,
    required String text,
  }) async {
    try {
      await passwords.doc(documentId).update({textFieldName: text});
    } catch (e) {
      throw CouldNotUpdatePasswordException();
    }
  }

  Stream<Iterable<CloudPassword>> allPasswords({required String ownerUserId}) {
    final allPasswords = passwords
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .snapshots()
        .map((event) => event.docs.map((doc) => CloudPassword.fromSnapshot(doc)));
    return allPasswords;
  }

  Future<CloudPassword> createNewPassword({required String ownerUserId}) async {
    final document = await passwords.add({
      ownerUserIdFieldName: ownerUserId,
      textFieldName: '',
    });
    final fetchedPassword = await document.get();
    return CloudPassword(
      documentId: fetchedPassword.id,
      ownerUserId: ownerUserId,
      text: '',
    );
  }

  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage._sharedInstance();
  FirebaseCloudStorage._sharedInstance();
  factory FirebaseCloudStorage() => _shared;
}