// Copyright (c) 2015, John Evans <prujohn@gmail.com>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Common data utilities for the Kata project.
///
/// Provides functions for semi-structured columnar data
library kata.util.data;

import 'package:logging/logging.dart';

part 'src/column_header_data.dart';
part 'src/row_data.dart';

final Logger _l = new Logger("kata.util.data");

const NO_DATA_FOUND = 'No data found';
const NOT_ENOUGH_DATA = 'Only found header row or not enough data to analyze.';
const DATA_FORMATTING_ERROR = '[Strict Mode] Query failed because a problem was found in the data or data formatting.';
const EXPECTED_2_COLUMNS = 'Query expects exactly 2 columns to be provided.';
const INVALID_QUERY_NAME = 'Query name not recognized.';

// pre-defined queries...
const SMALLEST_SPREAD = "smallest_spread";

/// Performs a predefined query and returns a JSON format result.
///
/// If there is an error during processing, the JSON result will contain the error message in the format:
///
///     {error: error_message}
Map query(String data, String queryName, List<String> cols, List<String> display,
          {bool coerce: false, bool ignoreLast: false, bool strict: false}){

  if (coerce && strict){
    _l.warning("coerce && strict flags are both true.  Setting coerce to false.");
    coerce = false;
  }

  _l.fine('query flags: coerce: ${coerce}, ignoreLast; ${ignoreLast}, strict: ${strict}');

  var skipCount = 0;

  if(data == null || data.isEmpty){
    return _error(NO_DATA_FOUND);
  }

  final rows = data.split('\n');

  if (rows.length < 2){
    return _error(NOT_ENOUGH_DATA);
  }

  final columnHeaders = ColumnHeaderData._parseHeader(rows[0]);
  _l.fine("Parsed ${columnHeaders.length} columns from header");

  _l.fine("Removing column header from raw data list");
  rows.remove(rows.first);

  if (ignoreLast){
    _l.fine("Removing last row from raw data list");
    rows.removeLast();
  }

  final rowData = new List<RowData>();

  var index = 0;
  for(String rawRow in rows){
    final row = new RowData(rawRow, index++, columnHeaders);

    if (strict && row.skipped){
      return _error("$DATA_FORMATTING_ERROR Reason: ${row.skipReason}");
    }

    if (row.skipped){
      _l.info("Skipping row ${row.rowIndex} because ${row.skipReason}");
    }else{
      rowData.add(row);
    }
  }

  if (rowData.length < rows.length){
    _l.warning("Skipped ${rows.length - rowData.length} row(s).");
  }

  _l.fine("Parsed ${rowData.length} rows of raw data into RowData objects.");

  switch(queryName){
    case SMALLEST_SPREAD:
      return _smallest_spread_query(columnHeaders, rowData, cols, display, coerce, strict);
    default:
      return _error(INVALID_QUERY_NAME);
  }

  return {};

}

Map _smallest_spread_query(List<ColumnHeaderData> columnData, List<RowData> rows, List<String> cols, List<String> disp,
                           bool coerce, bool strict){

  // some of this work might be factored out if more queries were added, but since we are only supporting one query
  // at the moment...

  if (cols.length != 2){
    return _error(EXPECTED_2_COLUMNS);
  }

  final c1 = _getColumn(columnData, cols[0]);
  final c2 = _getColumn(columnData, cols[1]);

  if (c1 == null){
    return _error("Column '${cols[0]}' not found by name or index.");
  }

  if (c2 == null){
    return _error("Column '${cols[1]}' not found by name or index.");
  }

  _l.fine("Found columns ${c1} and ${c2}");

  RowData winner;

  for(final row in rows){

    final num1 = _asNum(row.elements[c1.index], coerce);
    if (num1 == null){
      return _error("Unable to convert element ${row.elements[c1.index]} into a numeric at row ${row.rowIndex}, column ${c1}");
      
    }

    final num2 = _asNum(row.elements[c2.index], coerce);
    if (num2 == null){
      return _error("Unable to convert element ${row.elements[c2.index]} into a numeric at row ${row.rowIndex}, column ${c2}");
    }

    row._rowResult = (num1 - num2).abs();

    if (winner == null){
      winner = row;
      continue;
    }else{
      if (row._rowResult < winner._rowResult){
        winner = row;
      }
    }

  }
  
  Map results = {};
  
  var sb = new StringBuffer();
  if (disp.isEmpty){
    results['result'] = winner._rowResult;
  }else{

    for(final d in disp){
      final c = _getColumn(columnData, d);
      if (c == null){
        return _error("Display column '${d}' not found by name or index.");
      }
      results[c.toString()] = winner.elements[c.index];

    }
    results['result'] = winner._rowResult;

  }
  
  return results;
}


// return -1 if cannot convert the data element to an integer. Attempts to coerce dirty data by stripping non-numeric
// values
num _asNum(String data, bool coerce){
  return num.parse(data.trim(), (String s){
    if (!coerce){
      return null;
    }

    _l.warning("Attempting coerce of invalid numeric '${s}'. Non-numeric information will be stripped.");
    var sb = new StringBuffer();

    //strip out non-numerics
    for(int j = 0; j < s.length; j++) {
      if (_isNumeric(s[j])) {
        if (j > 0 && s[j] == '-') continue;
        sb.write(s[j]);
      }
    }
    //check once more in case multiple invalid characters slipped in.
    final candidate = sb.toString();
    return num.parse(candidate, (_) => null);
  });
}

// might be improved with regex
bool _isNumeric(String s) => (s.codeUnitAt(0) ^ 0x30) <= 9 || s == '.' || s == '-';

// Attempts to find the column by name, if not, then tries to convert the given name to an integer and query
// the column by index #.  Returns null otherwise.
ColumnHeaderData _getColumn(List<ColumnHeaderData> columnData, String columnName){
  ColumnHeaderData chd;

  try {
    chd = columnData.firstWhere((e) => e.name == columnName);
  } on StateError catch(e) {
    var i = int.parse(columnName, onError: (_) => -1);
    if (i < 0 || i > columnData.length - 1) {
      return null;
    }

    chd = columnData.firstWhere((e) => e.index == i, orElse: () => null);
  }

  return chd;
}



/// Analyzes data and provides a report.  Useful for spotting
/// potential problems with a data set or for understanding which
/// flags to give for queries.
String analyze(String rawData, {bool ignoreLast: false}){
  var skipCount = 0;

  if(rawData == null || rawData.isEmpty){
    return '(no data found)';
  }

  final rows = rawData.split('\n');

  if (rows.length < 2){
    return 'Only found header row or not enough data to analyze.';
  }

  final sb = new StringBuffer();

  sb.writeln(_whitespace('-', 45));

  final rowCount = rows.length - 1;

  sb.writeln("Processing Column Header...");
  final columnHeaders = ColumnHeaderData._parseHeader(rows[0]);
  sb.writeln("Found ${columnHeaders.length} columns.");

  sb.writeln();

  // parse the rows for warnings
  sb.writeln("Processing Rows...");
  sb.writeln("Found $rowCount rows (not including header).");
  for(var i = 1, until = rows.length - 1 - (ignoreLast ? 1 : 0); i < until; i++){
    var rd = new RowData(rows[i], i, columnHeaders);

    if (rd.skipped){
      sb.writeln(rd.skipReason);
      skipCount++;
    }
  }

  if (ignoreLast){
    skipCount++;
    sb.writeln("Skipping last row (${rows.length - 1}) because ignore requested.");
  }

  if (skipCount > 0) {
    sb.writeln("Skipped ${skipCount} row(s).");
  }
  sb.writeln(_whitespace('-', 45));
  return sb.toString();
}

// would likely have this utility in a more global library
String _whitespace(String char, int howMany){
  final sb = new StringBuffer();

  for (int i = 0; i < howMany; i++){
    sb.write(char);
  }

  return sb.toString();
}

Map _error(String message) => {'error': '${message}'};