import 'dart:html' as html;

void descargarPdfWeb(List<int> bytes, String nombre) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute("download", nombre)
    ..click();

  html.Url.revokeObjectUrl(url);
}