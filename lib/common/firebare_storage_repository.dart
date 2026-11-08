import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

Future<String> storeFileToFirebase(String ref, XFile file) async {
  try {
    final FirebaseStorage firebaseStorage = FirebaseStorage.instance;
    final bytes = await file.readAsBytes();
    final metadata = SettableMetadata(contentType: file.mimeType ?? 'image/jpeg');
    UploadTask uploadTask =
        firebaseStorage.ref().child(ref).putData(bytes, metadata);
    TaskSnapshot snap = await uploadTask;
    String downloadUrl = await snap.ref.getDownloadURL();
    return downloadUrl;
  } catch (_) {
    return file.path;
  }
}

Future<void> deleteFileStorage(String ref) async {
  try {
    final FirebaseStorage firebaseStorage = FirebaseStorage.instance;
    await firebaseStorage.ref().child(ref).delete();
  } catch (_) {}
}
