// import 'dart:async';

// import 'package:flutter/foundation.dart';
// import 'package:secure_pass/extensions/list/filter.dart';
// import 'package:secure_pass/services/crud/crud_exceptions.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' show join;

// class PasswordsService {
//   Database? _db;

//   List<DatabasePassword> _passwords = [];

//   DatabaseUser? _user;

//   static final PasswordsService _shared = PasswordsService._sharedInstance();
//   PasswordsService._sharedInstance() {
//     _passwordsStreamController = StreamController<List<DatabasePassword>>.broadcast(
//       onListen: () {
//         _passwordsStreamController.sink.add(_passwords);
//       },
//     );
//   }
//   factory PasswordsService() => _shared;

//   late final StreamController<List<DatabasePassword>> _passwordsStreamController;

//   Stream<List<DatabasePassword>> get allPasswords =>
//       _passwordsStreamController.stream.filter((password) {
//         final currentUser = _user;
//         if (currentUser != null) {
//           return password.userId == currentUser.id;
//         } else {
//           throw UserShouldBeSetBeforeReadingAllPasswords();
//         }
//       });

//   Future<DatabaseUser> getOrCreateUser({
//     required String email,
//     bool setAsCurrentUser = true,
//   }) async {
//     try {
//       final user = await getUser(email: email);
//       if (setAsCurrentUser) {
//         _user = user;
//       }
//       return user;
//     } on CouldNotFindUser {
//       final createdUser = await createUser(email: email);
//       if (setAsCurrentUser) {
//         _user = createdUser;
//       }
//       return createdUser;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<void> _cachePasswords() async {
//     final allPasswords = await getAllPasswords();
//     _passwords = allPasswords.toList();
//     _passwordsStreamController.add(_passwords);
//   }

//   Future<DatabasePassword> updatePassword({
//     required DatabasePassword password,
//     required String text,
//   }) async {
//     await _ensureDbIsOpen();
//     final db = _getDatabaseOrThrow();

//     // make sure password exists
//     await getPassword(id: password.id);

//     // update DB
//     final updatesCount = await db.update(
//       passwordTable,
//       {
//         textColumn: text,
//         isSyncedWithCloudColumn: 0,
//       },
//       where: 'id = ?',
//       whereArgs: [password.id],
//     );

//     if (updatesCount == 0) {
//       throw CouldNotUpdatePassword();
//     } else {
//       final updatedPassword = await getPassword(id: password.id);
//       _passwords.removeWhere((password) => password.id == updatedPassword.id);
//       _passwords.add(updatedPassword);
//       _passwordsStreamController.add(_passwords);
//       return updatedPassword;
//     }
//   }

//   Future<Iterable<DatabasePassword>> getAllPasswords() async {
//     await _ensureDbIsOpen();
//     final db = _getDatabaseOrThrow();
//     final passwords = await db.query(passwordTable);

//     return passwords.map((passwordRow) => DatabasePassword.fromRow(passwordRow));
//   }

//   Future<DatabasePassword> getPassword({required int id}) async {
//     await _ensureDbIsOpen();
//     final db = _getDatabaseOrThrow();
//     final passwords = await db.query(
//       passwordTable,
//       limit: 1,
//       where: 'id = ?',
//       whereArgs: [id],
//     );

//     if (passwords.isEmpty) {
//       throw CouldNotFindPassword();
//     } else {
//       final password = DatabasePassword.fromRow(passwords.first);
//       _passwords.removeWhere((password) => password.id == id);
//       _passwords.add(password);
//       _passwordsStreamController.add(_passwords);
//       return password;
//     }
//   }

//   Future<int> deleteAllPasswords() async {
//     await _ensureDbIsOpen();
//     final db = _getDatabaseOrThrow();
//     final numberOfDeletions = await db.delete(passwordTable);
//     _passwords = [];
//     _passwordsStreamController.add(_passwords);
//     return numberOfDeletions;
//   }

//   Future<void> deletePassword({required int id}) async {
//     await _ensureDbIsOpen();
//     final db = _getDatabaseOrThrow();
//     final deletedCount = await db.delete(
//       passwordTable,
//       where: 'id = ?',
//       whereArgs: [id],
//     );
//     if (deletedCount == 0) {
//       throw CouldNotDeletePassword();
//     } else {
//       _passwords.removeWhere((password) => password.id == id);
//       _passwordsStreamController.add(_passwords);
//     }
//   }

//   Future<DatabasePassword> createPassword({required DatabaseUser owner}) async {
//     await _ensureDbIsOpen();
//     final db = _getDatabaseOrThrow();

//     // make sure owner exists in the database with the correct id
//     final dbUser = await getUser(email: owner.email);
//     if (dbUser != owner) {
//       throw CouldNotFindUser();
//     }

//     const text = '';
//     // create the password
//     final passwordId = await db.insert(passwordTable, {
//       userIdColumn: owner.id,
//       textColumn: text,
//       isSyncedWithCloudColumn: 1,
//     });

//     final password = DatabasePassword(
//       id: passwordId,
//       userId: owner.id,
//       text: text,
//       isSyncedWithCloud: true,
//     );

//     _passwords.add(password);
//     _passwordsStreamController.add(_passwords);

//     return password;
//   }

//   Future<DatabaseUser> getUser({required String email}) async {
//     await _ensureDbIsOpen();
//     final db = _getDatabaseOrThrow();

//     final results = await db.query(
//       userTable,
//       limit: 1,
//       where: 'email = ?',
//       whereArgs: [email.toLowerCase()],
//     );

//     if (results.isEmpty) {
//       throw CouldNotFindUser();
//     } else {
//       return DatabaseUser.fromRow(results.first);
//     }
//   }

//   Future<DatabaseUser> createUser({required String email}) async {
//     await _ensureDbIsOpen();
//     final db = _getDatabaseOrThrow();
//     final results = await db.query(
//       userTable,
//       limit: 1,
//       where: 'email = ?',
//       whereArgs: [email.toLowerCase()],
//     );
//     if (results.isNotEmpty) {
//       throw UserAlreadyExists();
//     }

//     final userId = await db.insert(userTable, {
//       emailColumn: email.toLowerCase(),
//     });

//     return DatabaseUser(
//       id: userId,
//       email: email,
//     );
//   }

//   Future<void> deleteUser({required String email}) async {
//     await _ensureDbIsOpen();
//     final db = _getDatabaseOrThrow();
//     final deletedCount = await db.delete(
//       userTable,
//       where: 'email = ?',
//       whereArgs: [email.toLowerCase()],
//     );
//     if (deletedCount != 1) {
//       throw CouldNotDeleteUser();
//     }
//   }

//   Database _getDatabaseOrThrow() {
//     final db = _db;
//     if (db == null) {
//       throw DatabaseIsNotOpen();
//     } else {
//       return db;
//     }
//   }

//   Future<void> close() async {
//     final db = _db;
//     if (db == null) {
//       throw DatabaseIsNotOpen();
//     } else {
//       await db.close();
//       _db = null;
//     }
//   }

//   Future<void> _ensureDbIsOpen() async {
//     try {
//       await open();
//     } on DatabaseAlreadyOpenException {
//       // empty
//     }
//   }

//   Future<void> open() async {
//     if (_db != null) {
//       throw DatabaseAlreadyOpenException();
//     }
//     try {
//       final docsPath = await getApplicationDocumentsDirectory();
//       final dbPath = join(docsPath.path, dbName);
//       final db = await openDatabase(dbPath);
//       _db = db;
//       // create the user table
//       await db.execute(createUserTable);
//       // create password table
//       await db.execute(createPasswordTable);
//       await _cachePasswords();
//     } on MissingPlatformDirectoryException {
//       throw UnableToGetDocumentsDirectory();
//     }
//   }
// }

// @immutable
// class DatabaseUser {
//   final int id;
//   final String email;
//   const DatabaseUser({
//     required this.id,
//     required this.email,
//   });

//   DatabaseUser.fromRow(Map<String, Object?> map)
//       : id = map[idColumn] as int,
//         email = map[emailColumn] as String;

//   @override
//   String toString() => 'Person, ID = $id, email = $email';

//   @override
//   bool operator ==(covariant DatabaseUser other) => id == other.id;

//   @override
//   int get hashCode => id.hashCode;
// }

// class DatabasePassword {
//   final int id;
//   final int userId;
//   final String text;
//   final bool isSyncedWithCloud;

//   DatabasePassword({
//     required this.id,
//     required this.userId,
//     required this.text,
//     required this.isSyncedWithCloud,
//   });

//   DatabasePassword.fromRow(Map<String, Object?> map)
//       : id = map[idColumn] as int,
//         userId = map[userIdColumn] as int,
//         text = map[textColumn] as String,
//         isSyncedWithCloud =
//             (map[isSyncedWithCloudColumn] as int) == 1 ? true : false;

//   @override
//   String toString() =>
//       'Password, ID = $id, userId = $userId, isSyncedWithCloud = $isSyncedWithCloud, text = $text';

//   @override
//   bool operator ==(covariant DatabasePassword other) => id == other.id;

//   @override
//   int get hashCode => id.hashCode;
// }

// const dbName = 'passwords.db';
// const passwordTable = 'password';
// const userTable = 'user';
// const idColumn = 'id';
// const emailColumn = 'email';
// const userIdColumn = 'user_id';
// const textColumn = 'text';
// const isSyncedWithCloudColumn = 'is_synced_with_cloud';
// const createUserTable = '''CREATE TABLE IF NOT EXISTS "user" (
//         "id"	INTEGER NOT NULL,
//         "email"	TEXT NOT NULL UNIQUE,
//         PRIMARY KEY("id" AUTOINCREMENT)
//       );''';
// const createPasswordTable = '''CREATE TABLE IF NOT EXISTS "password" (
//         "id"	INTEGER NOT NULL,
//         "user_id"	INTEGER NOT NULL,
//         "text"	TEXT,
//         "is_synced_with_cloud"	INTEGER NOT NULL DEFAULT 0,
//         FOREIGN KEY("user_id") REFERENCES "user"("id"),
//         PRIMARY KEY("id" AUTOINCREMENT)
//       );''';