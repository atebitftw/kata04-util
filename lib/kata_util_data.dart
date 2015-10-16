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

/// Analyzes data and provides a report.  Useful for spotting
/// potential problems with a data set or for understanding which
/// flags to give for queries.
String analyze(String rawData, {bool ignoreLast: false}){
  var skipCount = 0;

  if(rawData == null || rawData.isEmpty){
    return '(empty)';
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
void _whitespace(String char, int howMany){
  final sb = new StringBuffer();

  for (int i = 0; i < howMany; i++){
    sb.write(char);
  }

  return sb.toString();
}

void _warn(String message){
  print("WARNING: $message");
}