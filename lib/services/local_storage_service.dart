import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/app_models.dart';

class LocalStorageService {
  static const _fileName = 'sdd_music_simple.json';

  Future<StoredState> load() async {
    try {
      final file = await _stateFile();
      if (!await file.exists()) {
        return const StoredState();
      }

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        return const StoredState();
      }
      return StoredState.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      return const StoredState();
    } on FileSystemException {
      return const StoredState();
    }
  }

  Future<void> save(StoredState state) async {
    final file = await _stateFile();
    await file.parent.create(recursive: true);
    final temporaryFile = File('${file.path}.tmp');
    await temporaryFile.writeAsString(jsonEncode(state.toJson()));
    if (await file.exists()) {
      await file.delete();
    }
    await temporaryFile.rename(file.path);
  }

  Future<File> _stateFile() async {
    Directory documentsDirectory;
    try {
      documentsDirectory = await getApplicationDocumentsDirectory();
    } on Object {
      // Permite que los tests sin plugins registrados sigan usando el flujo de UI.
      documentsDirectory = Directory.systemTemp;
    }
    return File(p.join(documentsDirectory.path, _fileName));
  }
}
