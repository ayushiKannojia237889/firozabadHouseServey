import 'package:firozabadwastemng/sqliteFolder/sqlite_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SqliteService {
  Future<Database> initializeDB() async {
    String path = await getDatabasesPath();

    return openDatabase(
      join(path, 'database.db'),
      onCreate: (database, version) async {
        await database.execute(
            "CREATE TABLE form_data(id INTEGER PRIMARY KEY AUTOINCREMENT, "
                "tagged_location TEXT, "
                "user_houseNumber TEXT) "
        );
      },
      version: 1,
    );
  }

  Future<int> insertFormData(FormData data) async {
    final Database db = await initializeDB();
    final id = await db.insert('form_data', data.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    print("Inserted FormData: ${data.toMap()}"); // Debugging line

    return id;
  }

  Future<List<FormData>> getFormDataList() async {
    final db = await initializeDB();
    try {
      final List<Map<String, Object?>> queryResult = await db.query(
          'form_data',
          columns: [
            'id', 'tagged_location', 'user_houseNumber'
          ],
          orderBy: "id"
      );
      return queryResult.map((e) => FormData.fromMap(e)).toList();
    } catch (e) {
      print("Error fetching form data: $e");
      return [];
    }
  }

  Future<void> deleteFormDataByID(int id) async {
    final db = await initializeDB();
    try {
      await db.delete('form_data', where: "id = ?", whereArgs: [id]);
    } catch (err) {
      print("Something went wrong when deleting an item: $err");
    }
  }

  Future<void> deleteSurveyNumberData() async {
    final db = await initializeDB();
    try {
      await db.delete('form_data');
    } catch (err) {
      print("Something went wrong when deleting an item: $err");
    }
  }


  Future<int> getSurveyedHouseCount() async {
    final db = await initializeDB(); // Assuming you have a method to get the database

    // Query the database to count the number of rows in the FormData table
    var result = await db.rawQuery('SELECT COUNT(*) FROM form_data');

    // Return the count of the rows
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Clear all data from the form_data table
  Future<void> clearAllData() async {
    final db = await initializeDB();
    try {
      print("Attempting to clear all data from the database...");
      // Fetch current data before deletion
      final List<FormData> formDataList = await getFormDataList();
      print('Current form data count: ${formDataList.length}'); // Debugging line

      // Perform deletion
      await db.delete('form_data');
      print('All form data cleared from the database.');

      // Verify deletion
      final List<FormData> postClearData = await getFormDataList();
      print('Post-clear form data count: ${postClearData.length}'); // Debugging line
    } catch (e) {
      print('Error clearing all data: $e');
      throw Exception('Error clearing all data from SQLite');
    }
  }

  Future<bool> checkTaggedLocationExists(String taggedLocation) async {
    final db = await initializeDB();
    final List<Map<String, dynamic>> result = await db.query(
      'form_data', // Replace with your actual table name
      where: 'tagged_location = ?', // Replace with your column name for tagged_location
      whereArgs: [taggedLocation],
    );

    return result.isNotEmpty; // Returns true if the location exists, false otherwise
  }

  Future<List<FormData>> fetchAllLocations() async {
    final db = await initializeDB();
    final maps = await db.query('form_data'); // Use 'form_data' as the table name
    return List.generate(maps.length, (i) {
      return FormData.fromMap(maps[i]);
    });
  }

  //------------------------------ check house Number ------------------------------------------
  Future<bool> checkHouseNumberExists(String houseNumber) async {
    final db = await initializeDB();
    final result = await db.query(
      'form_data', // Your table name
      where: 'user_houseNumber = ?',
      whereArgs: [houseNumber],
    );

    return result.isNotEmpty; // Returns true if house number exists
  }




}

