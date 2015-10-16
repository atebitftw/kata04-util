part of kata.util.data;

/**
 * Represents semi-normalized row of data, but has no opinion about the type of each data element.
 * Attempts to align data to columnar boundaries when possible.
 */
class RowData
{
  String rawRow;
  final int rowIndex;
  final Map<int, String> elements = new Map<int, String>();
  bool _skipped = false;
  String _skipReason = '';

  bool get skipped => _skipped;
  String get skipReason => _skipReason;


  RowData(this.rawRow, this.rowIndex, List<ColumnHeaderData> columns){
    _parseRow(columns);
  }

  RowData.skip(this.rawRow, this.rowIndex, String reason){
    _skipped = true;
    _skipReason = reason;
  }

  void _parseRow(List<ColumnHeaderData> columns){
    var corruptElement = 0;
    if (rawRow == null || rawRow.trim().isEmpty){
      _skipReason = "Skipping row $rowIndex because it is empty or null.";
      _skipped = true;
      return;
    }

    int adjust = 0;

    //pad the row if it's shorter than the last column boundary
    if (columns.last.end >= rawRow.length){
      rawRow += _whitespace(' ', columns.last.end + 1 - rawRow.length);
    }

    for (final chd in columns){

      // skip if row has no data in the range of the column.
      if (chd.start < 0 || chd.end < 0 || chd.start > rawRow.length || chd.end > rawRow.length){
        _warn("No data found for column ${chd.name} (index ${chd.index}) because row ${rowIndex} has no data "
          "within column boundary");
        continue;
      }

      // detect column misalignment, try to compensate... the assumption is that the last char in the column boundary
      // should be whitespace, if not then the next column is probably misaligned.
      if (columns.last != chd && rawRow[chd.end] != ' '){

        while(rawRow[chd.end + adjust] != ' '){
          adjust--;
          if (chd.end + adjust < chd.start){
            //exceeded the starting boundary of this column so...
            //bail out and warn again that adjustment failed.
            adjust = 0;
            _warn("In row ${rowIndex}, Detected but unable to align data that exceeds column boundary for"
            " column ${chd.name}.  Data may be corrupt at this column.");
            corruptElement++;
            elements[chd.index] = rawRow.substring(chd.start, chd.end + 1).trim();
            break;
          }
        }

        if (adjust == 0){
          // bailing out because nothing adjustment was not successful.
          continue;
        }

        elements[chd.index] = rawRow.substring(chd.start, chd.end + 1 + adjust).trim();
        continue;
      }
      //print("${rawRow[chd.start]}-${rawRow[chd.end]}");
      elements[chd.index] = rawRow.substring(chd.start + adjust, chd.end + 1).trim();
      if (adjust != 0) adjust = 0;
    }

    // TODO This 50% threshold could (and should) easily be turned into a configurable.
    if (corruptElement / columns.length > .5){
      _skipped = true;
      _skipReason = "Skipping row $rowIndex because majority of elements appear misaligned.";
    }
  }

  @override
  String toString(){
    final sb = new StringBuffer();
    sb.write("row ${rowIndex}: ");
    elements.forEach((k, v){
      sb.write("(${k})${v}, ");
    });
    return sb.toString();
  }

}