part of kata.util.web;

/// Reads an html url into a string.
///
/// Returns null if the operation was not successful.
Future<String> getFileFromUri(String urlToFile) async {
  try {
    return (await http.read(urlToFile));
  } on http.ClientException catch (e){
    return (await new Future.value(null));
  }
}

/// Prints an html escaped (safer) version of the string.
void prints(String toPrint) =>  print(new HtmlEscape().convert(toPrint));
