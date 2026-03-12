import 'dart:async';
import 'dart:html' as html;

Future<String?> pickImageAsDataUrlImpl() {
  final completer = Completer<String?>();
  final input = html.FileUploadInputElement()..accept = 'image/*';

  input.onChange.listen((_) {
    final file = input.files?.isNotEmpty == true ? input.files!.first : null;
    if (file == null) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final reader = html.FileReader();
    reader.onLoad.listen((_) {
      if (!completer.isCompleted) {
        completer.complete(reader.result as String?);
      }
    });
    reader.onError.listen((_) {
      if (!completer.isCompleted) completer.complete(null);
    });
    reader.readAsDataUrl(file);
  });

  input.click();
  return completer.future;
}
