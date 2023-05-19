import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';

class ImageUtils {
  static Future<File?> pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  static Future<List<File>?> pickMultipleImagesFromGallery() async {
    try {
      List<Asset> resultList = await MultiImagePicker.pickImages(
        maxImages: 5,
      );
      // Convert Asset to File
      List<File> files = [];
      for (Asset asset in resultList) {
        final byteData = await asset.getByteData();
        final buffer = byteData.buffer;
        final tempFile = File(
            "${(await getTemporaryDirectory()).path}/${asset.name}");
        final file = await tempFile.writeAsBytes(
            buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        files.add(file);
      }
      return files;
    } catch (e) {
      print(e);
      return null;
    }
  }

  //static Future<File?> takePhoto() async {
  static Future<File?> takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  static Future<String?> uploadImageToFirebase(File imageFile, String storageUrl) async {
    try {
      // Create a StorageReference to the specified URL
      final storageReference = FirebaseStorage.instance.refFromURL(storageUrl);

      // Create a unique filename for the image
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final uploadReference = storageReference.child('images/$fileName');

      // Upload the image to Firebase Storage
      final uploadTask = uploadReference.putFile(imageFile);
      await uploadTask.whenComplete(() {});

      // Get the download URL of the uploaded image
      final url = await uploadReference.getDownloadURL();
      return url;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<List?> showImageSourceDialog(BuildContext context, {int maxImages = 1}) async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(maxImages > 1 ? 'Select Images' : 'Select Image'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              GestureDetector(
                child: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context, ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16.0),
              GestureDetector(
                child: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context, ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      if (source == ImageSource.gallery) {
        if (maxImages == 1) {
          final File? image = await pickImageFromGallery();
          if (image != null) {
            return [image];
          }
        } else {
          return await pickMultipleImagesFromGallery();
        }
      } else if (source == ImageSource.camera) {
        if (maxImages == 1) {
          final File? image = await takePhoto();
          if (image != null) {
            return [image];
          }
        } else {
          final images = [];
          for (int i = 0; i < maxImages; i++) {
            final image = await takePhoto();
            if (image != null) {
              images.add(image);
            }
          }
          return images;
        }
      }
    }

    return null;

  }

}
