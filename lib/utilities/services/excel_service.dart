import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

String? lastPickedName;

class ExcelService {
  static bool looksLikeCsv(Uint8List bytes) {
    try {
      final end = bytes.length < 2048 ? bytes.length : 2048;
      final sample = utf8.decode(bytes.sublist(0, end), allowMalformed: true);
      return sample.contains(',') || sample.contains(';');
    } catch (_) {
      return false;
    }
  }

  static Future<List<List<String>>> safeTryExcelElseCsv(Uint8List bytes) async {
    try {
      return await parseExcel(bytes);
    } catch (_) {
      return await parseCsv(bytes);
    }
  }

  // -------- Parsing helpers --------

  static Future<List<List<String>>> parseExcel(Uint8List bytes) async {
    final excel = Excel.decodeBytes(bytes);
    for (final name in excel.tables.keys) {
      final sheet = excel.tables[name];
      if (sheet == null || sheet.maxColumns == 0 || sheet.maxRows == 0) {
        continue;
      }
      final List<List<String>> grid = <List<String>>[];
      for (final row in sheet.rows) {
        grid.add(
          row.map((cell) {
            final v = cell?.value;
            return v?.toString() ?? '';
          }).toList(),
        );
      }
      return grid;
    }
    return const <List<String>>[];
  }

  static Future<List<List<String>>> parseCsv(Uint8List bytes) async {
    String text;
    try {
      text = utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      text = const Latin1Decoder().convert(bytes);
    }
    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(text);
    return rows
        .map<List<String>>((r) => r.map((e) => (e ?? '').toString()).toList())
        .toList();
  }

  static Future<Uint8List?> pickFileBytes() async {
    // Works on Web, iOS, Android, Desktop with the same code path.
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true, // required for Web to get bytes in-memory
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
    );
    if (res == null || res.files.isEmpty) return null;

    final file = res.files.single;
    lastPickedName = file.name;
    return file.bytes; // On web, this is populated when withData: true
  }
}
