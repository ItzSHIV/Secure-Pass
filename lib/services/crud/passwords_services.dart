import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'crud_exceptions.dart';

class PasswordsService {
  Database? _db;

  Future<DatabasePassword> updatePassword({required DatabasePassword password, required String text}) async{
      final db = _getDatabaseOrThrow();

    await getPassword(id: password.id);

    final updatesCount = await db.update(passwordTable, {
      textColumn: text,
      isSynchedWithCloudColumn: 0,
    });

    if(updatesCount == 0){
      throw CouldNotUpdatePassword();
    } else{
      return await getPassword(id: password.id);
    }
  }

  Future<Iterable<DatabasePassword>> getAllPasswords({required int id}) async{
    final db = _getDatabaseOrThrow();
    final passwords = await db.query(passwordTable);

    return passwords.map((passwordRow) => DatabasePassword.fromRow(passwordRow));
  }

  Future<DatabasePassword> getPassword({required int id}) async{
    final db = _getDatabaseOrThrow();
    final password = await db.query(
      passwordTable, 
      limit: 1, 
      where: 'id = ?', 
      whereArgs: [id],
    );

    if(password.isEmpty){
      throw CouldNotFindPassword();
    } else{
      return DatabasePassword.fromRow(password.first);
    }
  }

  Future<int> deleteAllPasswords() async{
    final db = _getDatabaseOrThrow();
    return await db.delete(passwordTable);
  }

  Future<void> deletePassword({required int id}) async{
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      passwordTable, 
      where: 'id = ?', 
      whereArgs: [id],
    );
    if(deletedCount == 0){
      throw CouldNotDeletePassword();
    }
  }

  Future<DatabasePassword> createPassword({required DatabaseUser owner}) async{
    final db = _getDatabaseOrThrow();
    
    // making sure owner exists with the correct id
    final dbUser = await getUser(email: owner.email);
    if(dbUser != owner){
      throw CouldNotFindUser();
    } 

    const text = '';
    //create new password
    final passwordId = await db.insert(passwordTable, {
      userIdColumn : owner.id,
      textColumn : text,
      isSynchedWithCloudColumn : 1
    });

    final password = DatabasePassword(
      id: passwordId, 
      userId: owner.id, 
      text: text, 
      isSynchedWithCloud: true,
    );

    return password;
  }

  Future<DatabaseUser> getUser({required String email}) async{
    final db = _getDatabaseOrThrow();

    final results = await db.query(
      userTable, 
      limit: 1, 
      where: 'email = ?', 
      whereArgs: [email.toLowerCase()],
    );

    if(results.isEmpty){
      throw CouldNotFindUser();
    } else{
      return DatabaseUser.fromRow(results.first);
    }
  }

  Future<DatabaseUser> createUser({required String email}) async{
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable, 
      limit: 1, 
      where: 'email = ?', 
      whereArgs: [email.toLowerCase()],
    );
    if(results.isNotEmpty){
      throw UserAlreadyExists();
    }

    final userId = await db.insert(userTable, {
      emailColumn: email.toLowerCase()
      });

      return DatabaseUser(
        id: userId, 
        email: email,
      );
  }

  Future<void> deleteUser({required String email}) async{
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userTable, 
      where: 'email = ?', 
      whereArgs: [email.toLowerCase()],
    );
    if(deletedCount != 1){
      throw CouldNotDeleteUser();
    }
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if(db == null){
      throw DatabaseIsNotOpen();
    } else{
      return db;
    }
  }

  Future<void> close() async{
    final db = _db;
    if(db == null){
      throw DatabaseIsNotOpen();
    } else{
      await db.close();
      _db = null;
    }}

  Future<void> open() async{
    if(_db != null){
      throw DatabaseAlreadyOpenException();
    }
    try{
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;

      // create the user table
      await db.execute(createUserTable);
      // create the password table
      await db.execute(createPasswordTable);

    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectory();
    }}
}

@immutable
class DatabaseUser {
  final int id;
  final String email;
  const DatabaseUser({
    required this.id, 
    required this.email,
  });

  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int, 
        email = map[emailColumn] as String;

  @override
  String toString() => 'Person, ID =$id, email = $email';

  @override bool operator ==(covariant DatabaseUser other) => id == other.id;
  
  @override
  int get hashCode => id.hashCode;
}

class DatabasePassword{
  final int id;
  final int userId;
  final String text;
  final bool isSynchedWithCloud;

  DatabasePassword({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSynchedWithCloud,
  });

    DatabasePassword.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int, 
        userId = map[userIdColumn] as int,
        text = map[textColumn] as String,
        isSynchedWithCloud = (map[isSynchedWithCloudColumn] as int) == 1 ? true : false;

  @override
  String toString() => 'Password, ID = $id, userId = $userId, isSynchedWithCloud = $isSynchedWithCloud, text =$text';

  @override bool operator ==(covariant DatabasePassword other) => id == other.id;
  
  @override
  int get hashCode => id.hashCode;
}

const dbName = 'passwords.db';
const passwordTable = 'password';
const userTable = 'user';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'user_id';
const textColumn = 'text';
const isSynchedWithCloudColumn = 'is_synched_with_cloud';

const createUserTable = '''CREATE TABLE IF NOT EXISTS "user" (
  "id"	INTEGER NOT NULL,
  "email"	TEXT NOT NULL UNIQUE,
  PRIMARY KEY("id" AUTOINCREMENT)
);''';

const createPasswordTable = '''CREATE TABLE IF NOT EXISTS "password" (
  "id"	INTEGER NOT NULL,
  "user_id"	INTEGER NOT NULL,
  "text"	TEXT,
  "is_synced_with_server"	INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY("user_id") REFERENCES "user"("id"),
  PRIMARY KEY("id" AUTOINCREMENT)
); ''';