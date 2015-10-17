part of kata.util.data;

/// Defines immutable information about a column in the raw text file.
class ColumnHeaderData
{
  final String name;
  final int start;
  final int end;
  final int index;

  ColumnHeaderData(this.name, this.index, this.start, this.end);

  ColumnHeaderData.anonymous(this.index, this.start, this.end) : this.name = '(anon)';

  // Parses raw header row into ColumnHeaderData objects.  Column header is assumed to be
  // well formed.  No sanity checks in this version.
  static List<ColumnHeaderData> _parseHeader(String headerRow){
    final headers = new List<ColumnHeaderData>();
    var cIndex = 0;

    // dart supports nested functions
    int nextIndexNoSpace(int ci){
      while (ci < headerRow.length){
        if (headerRow[ci] == ' '){
          ci++;
        }else{
          return ci;
        }
      }

      return ci;
    }

    int nextIndexSpace(int ci){
      while (ci < headerRow.length){
        if (headerRow[ci] != ' '){
          ci++;
        }else{
          return ci;
        }
      }

      return ci;
    }

    int nextColumn(int ci){
      if (headerRow[ci] == ' '){
        // anonymous column
        final n = nextIndexNoSpace(ci);
        headers.add(new ColumnHeaderData.anonymous(cIndex, ci, n - 1));
        return n;
      }else{
        // named column
        var n = nextIndexSpace(ci);
        n = nextIndexNoSpace(n);
        headers.add(new ColumnHeaderData(headerRow.substring(ci, n).trim(), cIndex, ci, n - 1));
        return (n == headerRow.length) ? -1 : n;
      }
    }

    var i = 0;
    var ni = 0;

    while(i != -1) {
      ni = nextColumn(i);
      i = ni;
      cIndex++;
    }

    return headers;

  }

  @override toString() => '${name}(${index})';
}