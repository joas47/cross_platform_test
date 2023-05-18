import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

class DatabaseHandler {
  static Future<void> getOwnerProfileData() async {
    final firestoreInstance = FirebaseFirestore.instance;
    final usersCollectionRef = firestoreInstance.collection('users');

    final userUid = FirebaseAuth.instance.currentUser?.uid;

    final userDocumentRef = usersCollectionRef.doc(userUid);

    final userData = await userDocumentRef.get();
  }

  static Future<bool> doesCurrentUserHaveProfile() {
    final firestoreInstance = FirebaseFirestore.instance;
    final usersCollectionRef = firestoreInstance.collection('users');
    final userUid = FirebaseAuth.instance.currentUser?.uid;
    final userDocumentRef = usersCollectionRef.doc(userUid);
    return userDocumentRef.get().then((value) => value.exists);
  }

  static Future<bool> doesCurrentUserHaveDogProfile() async {
    final firestoreInstance = FirebaseFirestore.instance;
    final usersCollectionRef = firestoreInstance.collection('users');

    final userUid = FirebaseAuth.instance.currentUser?.uid;

    final userDocumentRef = usersCollectionRef.doc(userUid);

    final userSnapshot = await userDocumentRef.get();

    if (userSnapshot.exists) {
      final data = userSnapshot.data();
      if (data != null && data.containsKey('dogs')) {
        return true;
      }
    }
    return false;
  }

  static Future<void> addFriend(String friendUid) async {
    final firestoreInstance = FirebaseFirestore.instance;
    final usersCollectionRef = firestoreInstance.collection('users');

    final User? currentUser = FirebaseAuth.instance.currentUser;
    late final userUid = currentUser?.uid;

    // Create a batch write operation
    final batch = firestoreInstance.batch();

    // Add the dog reference to the owner's array of dogs in the 'emails' collection
    final userDocumentRef = usersCollectionRef.doc(userUid);
    batch.update(userDocumentRef, {
      'friends': FieldValue.arrayUnion([friendUid]),
      'friendrequests': FieldValue.arrayRemove([friendUid])
    });

    final friendDocumentRef = usersCollectionRef.doc(friendUid);
    batch.update(friendDocumentRef, {
      'friends': FieldValue.arrayUnion([userUid]),
      'friendrequests': FieldValue.arrayRemove([userUid])
    });

    // Commit the batch write operation
    await batch.commit();
  }

  static Future<void> removeFriend(String friendUid) async {
    final firestoreInstance = FirebaseFirestore.instance;
    final usersCollectionRef = firestoreInstance.collection('users');

    final User? currentUser = FirebaseAuth.instance.currentUser;
    final userUid = currentUser?.uid;

    // Create a batch write operation
    final batch = firestoreInstance.batch();

    // Remove the friendUid from the owner's 'friends' array in the 'users' collection
    final userDocumentRef = usersCollectionRef.doc(userUid);
    batch.update(userDocumentRef, {
      'friends': FieldValue.arrayRemove([friendUid])
    });

    final friendDocumentRef = usersCollectionRef.doc(friendUid);
    batch.update(friendDocumentRef, {
      'friends': FieldValue.arrayRemove([userUid])
    });

    // Commit the batch write operation
    await batch.commit();
  }

  static Future<void> sendFriendRequest(String friendUid) async {
    final firestoreInstance = FirebaseFirestore.instance;
    final usersCollectionRef = firestoreInstance.collection('users');

    final User? currentUser = FirebaseAuth.instance.currentUser;
    late final userUid = currentUser?.uid;

    // Create a batch write operation
    final batch = firestoreInstance.batch();

    final userDocumentRef = usersCollectionRef.doc(friendUid);
    batch.update(userDocumentRef, {
      'friendrequests': FieldValue.arrayUnion([userUid])
    });

    // Commit the batch write operation
    await batch.commit();
  }

  static Future<void> addUserToDatabase(String fName, String lName,
      String gender, int age, String bio, String? profilePic) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    late final userUid = currentUser?.uid;
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    final userDocumentRef = users.doc(userUid);
    await userDocumentRef.set({
      'name': fName,
      'gender': gender,
      'age': age,
      'surname': lName,
      'about': bio,
      'picture': profilePic
    });
  }

  //DatabaseHandler.addParksToDatabase(_lat, _long, _currentAddress, _bio, _locationPic);

  static Future<void> addParksToDatabase(double lat, double long, String currentAddress, String bio, String? locationPic) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    late final userUid = currentUser?.uid;
    CollectionReference userparks = FirebaseFirestore.instance.collection('user-parks');

    await userparks.add({
      'uid': userUid,
      'latitude': lat,
      'logitude': long,
      'address': currentAddress,
      'about': bio,
      'picture': locationPic
    });
  }


  static Future<void> updateUser(String fName, String lName, String gender,
      int age, String bio, String? profilePic, String dogRef) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    late final userUid = currentUser?.uid;
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    final userDocumentRef = users.doc(userUid);
    await userDocumentRef.set({
      'name': fName,
      'gender': gender,
      'age': age,
      'surname': lName,
      'about': bio,
      'picture': profilePic,
      'dogs': dogRef
    });
  }

  static Future<void> removeUserFromDatabase(String userId) async {
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    users.doc(userId).delete();
  }

  static Future<void> removeOwnerFromDatabase(String emailDocumentId) async {
    // Get a reference to the Firestore instance
    final firestoreInstance = FirebaseFirestore.instance;

    // Define a list to store the references of the dog documents to be removed
    final List<DocumentReference> dogReferencesToRemove = [];

    // Create a batch write operation
    final batch = firestoreInstance.batch();

    // Get a reference to the email document to be removed
    final emailDocumentRef =
    firestoreInstance.collection('emails').doc(emailDocumentId);

    // Retrieve the array field 'dogs' from the email document
    final emailDocumentSnapshot = await emailDocumentRef.get();
    final dogReferences = emailDocumentSnapshot.get('dogs');

    // Iterate through the 'dogs' array and add the corresponding document references to the list
    for (final dogReference in dogReferences) {
      final dogDocumentRef = dogReference as DocumentReference;
      dogReferencesToRemove.add(dogDocumentRef);
    }

    // Remove the email document from the 'emails' collection
    batch.delete(emailDocumentRef);

    // Remove the corresponding dog documents from the 'Dogs' collection
    for (final dogRefToRemove in dogReferencesToRemove) {
      batch.delete(dogRefToRemove);
    }

    // Commit the batch write operation
    await batch.commit();
  }

  static Future<void> addDogToDatabase(String name, String breed, int age, String gender, bool isCastrated, String activity, String size, String biography, String? profilePic) async {
    final firestoreInstance = FirebaseFirestore.instance;
    final dogsCollectionRef = firestoreInstance.collection('Dogs');
    final usersCollectionRef = firestoreInstance.collection('users');

    final User? currentUser = FirebaseAuth.instance.currentUser;
    late final userUid = currentUser?.uid;

    // Create a batch write operation
    final batch = firestoreInstance.batch();

    // Add the dog document to the 'Dogs' collection
    final dogDocumentRef = dogsCollectionRef.doc();
    batch.set(dogDocumentRef, {
      'Name': name,
      'Breed': breed,
      'Age': age,
      'Gender': gender,
      'Is castrated': isCastrated,
      'Activity Level': activity,
      'Size': size,
      'Biography': biography,
      'owner': usersCollectionRef.doc(userUid),
      'picture': profilePic,
    });

    // Add the dog reference to the owner's array of dogs in the 'emails' collection
    final userDocumentRef = usersCollectionRef.doc(userUid);
    batch.update(userDocumentRef, {
      //'dogs': FieldValue.arrayUnion([dogDocumentRef])
      'dogs': dogDocumentRef.id
    });

    // Commit the batch write operation
    await batch.commit();
  }

  static Future<void> updateDog(String name,
      String breed,
      String gender,
      int age,
      String bio,
      String? profilePic,
      String size,
      bool isCastrated,
      String activity,
      String? dogRef) async {
    final firestoreInstance = FirebaseFirestore.instance;
    final dogsCollectionRef = firestoreInstance.collection('Dogs');
    final usersCollectionRef = firestoreInstance.collection('users');

    final User? currentUser = FirebaseAuth.instance.currentUser;
    late final userUid = currentUser?.uid;

    final batch = firestoreInstance.batch();

    final dogDocumentRef = dogsCollectionRef.doc(dogRef);
    batch.set(dogDocumentRef, {
      'Name': name,
      'Breed': breed,
      'Age': age,
      'Gender': gender,
      'Is castrated': isCastrated,
      'Activity Level': activity,
      'Size': size,
      'Biography': bio,
      'owner': usersCollectionRef.doc(userUid),
      'picture': profilePic,
    });

    await batch.commit();
  }

  static Future<String?> getDogId() async {
    final firestoreInstance = FirebaseFirestore.instance;
    final usersCollectionRef = firestoreInstance.collection('users');

    final User? currentUser = FirebaseAuth.instance.currentUser;
    late final userUid = currentUser?.uid;

    final userDocumentRef = usersCollectionRef.doc(userUid);
    final dogDocumentRef = userDocumentRef.collection('dogs');
    String? dogID = (await dogDocumentRef.get()).docs[0].id;
    return dogID;
  }

  static Future<String?> getDogId2() async {
    String? dogRef;
    final userUid = FirebaseAuth.instance.currentUser?.uid;
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    DocumentSnapshot documentSnapshot = await users.doc(userUid).get();
    if (documentSnapshot.exists) {
      dogRef = documentSnapshot.get('dogs');
    }
    return dogRef;
  }

  static Stream<String?> getDogId3(String? userId) async* {
    String? userUid = userId;
    if(userId == 'defaultValue'){
      userUid = FirebaseAuth.instance.currentUser?.uid;
    }
    final users = FirebaseFirestore.instance.collection('users');
    final dogs = await users.doc(userUid).get().then((doc) => doc.get('dogs') as String?);
    if (dogs != null) {
      yield dogs.toString();
    } else {
      yield null;
    }
  }

  //funkar inte
  static Future<String?>? getDogPic(String? userId) async {
    final dogUid = await getDogId3(userId).first;
    if (dogUid != null) {
      final dogs = FirebaseFirestore.instance.collection('Dogs');
      final pic = await dogs.doc(dogUid).get().then((doc) => doc.get('picture') as String?).catchError((error) => print("Error getting dog picture: $error"));;
      return pic;
    } else {
      return null;
    }
  }

  /*static Future<String?>? getOwnerPic() {
    final userUid = FirebaseAuth.instance.currentUser?.uid;
    final dogs = FirebaseFirestore.instance.collection('users');
    final pic = dogs.doc(userUid).get().then((doc) => doc.get('picture') as String?);
    if (pic != null) {
      return pic;
    } else {
      return null;
    }
  }*/
  // below is the updated code above, through this solution i fixed TODO comment of "View_dog_profile.dart" regarding the picture changes.
  // i decided to keep the code above just in case we need it in the future.
  static Stream<String?> getOwnerPicStream() {
    final userUid = FirebaseAuth.instance.currentUser?.uid;
    final users = FirebaseFirestore.instance.collection('users');
    final ownerDocumentRef = users.doc(userUid);

    return ownerDocumentRef.snapshots().map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data()?['picture'] as String?;
      } else {
        return null;
      }
    });
  }

  static Stream<String?> getDogNameFromOwnerID(String ownerID) async* {
    final users = FirebaseFirestore.instance.collection('users');
    final dogs = await users
        .doc(ownerID)
        .get()
        .then((doc) => doc.get('dogs') as String?);

    if (dogs != null) {
      final dog = FirebaseFirestore.instance.collection('Dogs');
      final name =
          await dog.doc(dogs).get().then((doc) => doc.get('Name') as String?);
      yield name;
    } else {
      yield null;
    }
  }
  static Stream<String?> getOwnerNameFromOwnerID(String ownerID) async* {
    final users = FirebaseFirestore.instance.collection('users');
    final ownerSnapshot = await users.doc(ownerID).get();
    final ownerData = ownerSnapshot.data();

    if (ownerData != null && ownerData.containsKey('name')) {
      final ownerName = ownerData['name'] as String;
      yield ownerName;
    } else {
      yield null;
    }
  }

  static void addRandomFriend() {
    final firestoreInstance = FirebaseFirestore.instance;
    final usersCollectionRef = firestoreInstance.collection('users');

    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String? userUid = currentUser?.uid;

    final batch = firestoreInstance.batch();

    // Get a random user from the collection excluding the current user
    usersCollectionRef.get().then((snapshot) {
      final List<String> allUserIds =
          snapshot.docs.map((doc) => doc.id).toList();
      allUserIds.remove(userUid);

      if (allUserIds.isNotEmpty) {
        final randomIndex = Random().nextInt(allUserIds.length);
        final randomFriendUid = allUserIds[randomIndex];

        final userDocumentRef = usersCollectionRef.doc(userUid);
        batch.update(userDocumentRef, {
          'friends': FieldValue.arrayUnion([randomFriendUid])
        });
        batch.commit();
      }
    }).catchError((error) {
      print('Error getting random friend: $error');
    });
  }

  //TODO: kontrollera att användaren har hund
  static Future<List<String>?> getMatches() async {
    final firestoreInstance = FirebaseFirestore.instance;
    final usersCollectionRef = firestoreInstance.collection('users');

    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String? userUid = currentUser?.uid;

    try {
      final snapshot = await usersCollectionRef.get();
      List<String> test = snapshot.docs.map((doc) => doc.id).toList();
      test.remove(userUid);
      // print(test);
      // print(allUserIds);
      return test;
    } catch (error) {
      print('Error getting random friend: $error');
      return null;
    }
  }
}
