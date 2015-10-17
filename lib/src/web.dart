part of kata.util.web;

/// Reads an html url into a string.
///
/// Returns null if the operation was not successful.
Future<String> getFileFromUri(String urlToFile) async {
  try {
    _l.fine("Attempting file download from: ${urlToFile}");
    return (await http.read(urlToFile));
  } on http.ClientException catch (e){
    return (await new Future.value(null));
  }
}
