import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/src/material/time.dart';
import 'package:image_picker/image_picker.dart';
import 'package:time_range_picker/time_range_picker.dart';

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
// Sends like to other person, if they have already liked you, it will create a match
  static Future<bool> sendLike(String friendID) async {
    final firestoreInstance = FirebaseFirestore.instance;
    final usersCollectionRef = firestoreInstance.collection('users');
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String? userUid = currentUser?.uid;

    final ownerDocumentRef = usersCollectionRef.doc(userUid);
    final friendDocumentRef = usersCollectionRef.doc(friendID);

    try {
      final ownerSnapshot = await ownerDocumentRef.get();
      final friendSnapshot = await friendDocumentRef.get();

      if (ownerSnapshot.exists && friendSnapshot.exists) {
        final ownerData = ownerSnapshot.data();
        final friendData = friendSnapshot.data();

        if (ownerData != null && friendData != null) {
          if (ownerData.containsKey('matches') &&
              ownerData['matches'].contains(friendID)) {
            return true;
          } else if (ownerData.containsKey('matches') &&
              ownerData['pendingLikes'].contains(friendID)) {
            return false;
          }

          final batch = firestoreInstance.batch();

          if (ownerData.containsKey('receivedLikes') &&
              ownerData['receivedLikes'].contains(friendID)) {
            batch.update(ownerDocumentRef, {
              'matches': FieldValue.arrayUnion([friendID]),
              'receivedLikes': FieldValue.arrayRemove([friendID]),
            });

            batch.update(friendDocumentRef, {
              'matches': FieldValue.arrayUnion([userUid]),
              'pendingLikes': FieldValue.arrayRemove([userUid]),
            });

            await batch.commit();
            return true; // Match has been made, so return true
          } else {
            batch.update(ownerDocumentRef, {
              'pendingLikes': FieldValue.arrayUnion([friendID]),
            });

            batch.update(friendDocumentRef, {
              'receivedLikes': FieldValue.arrayUnion([userUid]),
            });

            await batch.commit();
            return false; // No match has been made, so return false
          }
        }
      }
    } catch (error) {
      print('Error sending like: $error');
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

    final userDocumentRef = usersCollectionRef.doc(userUid);
    batch.update(userDocumentRef, {
      'friends': FieldValue.arrayUnion([friendUid]),
      'friendrequests': FieldValue.arrayRemove([friendUid]),
      'matches': FieldValue.arrayRemove([friendUid])
    });

    final friendDocumentRef = usersCollectionRef.doc(friendUid);
    batch.update(friendDocumentRef, {
      'friends': FieldValue.arrayUnion([userUid]),
      'friendrequests': FieldValue.arrayRemove([userUid]),
      'matches': FieldValue.arrayRemove([userUid])
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

  static Future<void> removeFriendrequest(String friendUid) async {
    final firestoreInstance = FirebaseFirestore.instance;
    final usersCollectionRef = firestoreInstance.collection('users');

    final User? currentUser = FirebaseAuth.instance.currentUser;
    final userUid = currentUser?.uid;

    // Create a batch write operation
    final batch = firestoreInstance.batch();

    // Remove the friendUid from the owner's 'friends' array in the 'users' collection
    final userDocumentRef = usersCollectionRef.doc(userUid);
    batch.update(userDocumentRef, {
      'friendrequests': FieldValue.arrayRemove([friendUid])
    });

    // Commit the batch write operation
    await batch.commit();
  }

  /*static Future<void> sendFriendRequest(String friendUid) async {
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
  }*/

  static Future<void> sendFriendRequest(String friendUid) async {
    final firestoreInstance = FirebaseFirestore.instance;
    final usersCollectionRef = firestoreInstance.collection('users');
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String? userUid = currentUser?.uid;

    final ownerDocumentRef = usersCollectionRef.doc(userUid);
    final friendDocumentRef = usersCollectionRef.doc(friendUid);

    try {
      final ownerSnapshot = await ownerDocumentRef.get();
      final friendSnapshot = await friendDocumentRef.get();

      if (ownerSnapshot.exists && friendSnapshot.exists) {
        final ownerData = ownerSnapshot.data();
        final friendData = friendSnapshot.data();

        if (ownerData != null && friendData != null) {

          if (ownerData.containsKey('friendrequests') &&
              ownerData['friendrequests'].contains(friendUid)) {
            addFriend(friendUid);
          } else {
            final batch = firestoreInstance.batch();
            batch.update(friendDocumentRef, {
              'friendrequests': FieldValue.arrayUnion([userUid]),
            });

            await batch.commit();
          }
        }
      }
    } catch (error) {
      print('Error sending like: $error');
    }
  }

  static Future<void> unmatch(String matchUid) async {
    final firestoreInstance = FirebaseFirestore.instance;
    final usersCollectionRef = firestoreInstance.collection('users');

    final User? currentUser = FirebaseAuth.instance.currentUser;
    final userUid = currentUser?.uid;

    // Create a batch write operation
    final batch = firestoreInstance.batch();

    // Remove the matchUid from the owner's 'matches' array in the 'users' collection
    final userDocumentRef = usersCollectionRef.doc(userUid);
    batch.update(userDocumentRef, {
      'matches': FieldValue.arrayRemove([matchUid])
    });

    final friendDocumentRef = usersCollectionRef.doc(matchUid);
    batch.update(friendDocumentRef, {
      'matches': FieldValue.arrayRemove([userUid])
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


  // TODO: edit removes all friends and matches.
  static Future<void> updateUser(String fName, String lName, String gender,
      int age, String bio, String? profilePic, String dogRef) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    late final userUid = currentUser?.uid;
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    final userDocumentRef = users.doc(userUid);
    await userDocumentRef.update({
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

  static Future<void> addDogToDatabase(String name, String breed, int age, String gender, bool isCastrated, String activity, String size, String biography, List<String> pictureUrls,) async { //String? profilePic
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
      'owner': userUid.toString(),
      //'picture': profilePic,
      'pictureUrls': pictureUrls
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
      //String? profilePic,
      List<String>? pictureUrls,
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
      'owner': userUid.toString(),
      'pictureUrls': pictureUrls,
      //'picture': profilePic
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

  static Stream<String?> getDogPic(String? userId) async* {
    final dogUid = await getDogId3(userId).first;
    if (dogUid != null) {
      final dogs = FirebaseFirestore.instance.collection('Dogs');
      yield* dogs.doc(dogUid).snapshots().map((doc) {
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data.containsKey('pictureUrls')) {
            final pictureUrls = data['pictureUrls'] as List<dynamic>;
            if (pictureUrls.isNotEmpty && pictureUrls[0] is String) {
              return pictureUrls[0] as String;
            }
          }
        }
        // Handle the case when the 'pictureUrls' field doesn't exist or is empty
        return null;
      }).handleError((error) {
        print("Error getting dog picture: $error");
        return null;
      });
    } else {
      yield null;
    }
  }

  static Stream<String?> getOwnerPicStream(String userId) {
    //final userUid = FirebaseAuth.instance.currentUser?.uid;
    final users = FirebaseFirestore.instance.collection('users');
    final ownerDocumentRef = users.doc(userId);

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

  static Stream<String?> getMatches(String? userId) {
    final users = FirebaseFirestore.instance.collection('users');
    final matchesField = users.doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data.containsKey('matches')) {
          final matches = data['matches'] as List<dynamic>;
          if (matches.isNotEmpty && matches[0] is String) {
            return matches[0] as String;
          }
        }
      }
      // Handle the case when the 'matches' field doesn't exist or is empty
      return null;
    }).handleError((error) {
      print("Error getting matches: $error");
      return null;
    });

    return matchesField;
  }


  static Future<List<String>> getList() {
    return Future.value(['1', '2']);
  }

  static void storeTimeSlot(TimeOfDay startTime, TimeOfDay endTime) {
    final firestoreInstance = FirebaseFirestore.instance;
    final usersCollectionRef = firestoreInstance.collection('users');
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String? userUid = currentUser?.uid;
    final batch = firestoreInstance.batch();

    final availability = {
      "createdOn": DateTime.now(),
      "startTime": '${startTime.hour}:${startTime.minute}',
      "endTime": '${endTime.hour}:${endTime.minute}',
    };

    final userDocumentRef = usersCollectionRef.doc(userUid);

    batch.update(userDocumentRef, {'availability': availability});
    batch.commit();
  }

// graveyard of broken souls
/*static void setAvailability(TimeOfDay startTime, TimeOfDay endTime) {
    String startHour = startTime.hour.toString();
    String startMinute = startTime.minute.toString();
    if (startTime.hour < 10) {
      startHour = '0${startTime.hour}';
    }
    if (startTime.minute < 10) {
      startMinute = '0${startTime.minute}';
    }
    String endHour = endTime.hour.toString();
    String endMinute = endTime.minute.toString();
    if (endTime.hour < 10) {
      endHour = '0${endTime.hour}';
    }
    if (endTime.minute < 10) {
      endMinute = '0${endTime.minute}';
    }
    final firestoreInstance = FirebaseFirestore.instance;
    final usersCollectionRef = firestoreInstance.collection('users');

    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String? userUid = currentUser?.uid;

    final batch = firestoreInstance.batch();

    final userDocumentRef = usersCollectionRef.doc(userUid);
    batch.update(userDocumentRef, {
      'startTime': '$startHour:$startMinute',
      'endTime': '$endHour:$endMinute',
    });
    batch.commit();
  }*/

/*  static void _getTimeSlot(String userID, void Function(TimeRange?) callback) {
    final firestoreInstance = FirebaseFirestore.instance;
    final usersCollectionRef = firestoreInstance.collection('users');

    usersCollectionRef.doc(userID).get().then((userDocumentSnapshot) {
      if (userDocumentSnapshot.exists) {
        if (userDocumentSnapshot.data().toString().contains('availability')) {
          final data = userDocumentSnapshot.data();
          if (data != null && data['availability'] != null) {
            final startTimeString = data['availability']['startTime'];
            final endTimeString = data['availability']['endTime'];

            final startTimeParts = startTimeString.split(':');
            final endTimeParts = endTimeString.split(':');

            final startTime = TimeOfDay(
              hour: int.parse(startTimeParts[0]),
              minute: int.parse(startTimeParts[1]),
            );

            final endTime = TimeOfDay(
              hour: int.parse(endTimeParts[0]),
              minute: int.parse(endTimeParts[1]),
            );

            final TimeRange timeRange = TimeRange(
              startTime: startTime,
              endTime: endTime,
            );
            print("getTimeSlot: " + timeRange.toString());
            callback(timeRange);
          } else {
            callback(null);
          }
        } else {
          callback(null);
        }
      } else {
        callback(null);
      }
    });
  }

  static void getTimeRange(String userID, void Function(TimeRange?) callback) {
    _getTimeSlot(userID, (timeRange) {
      print("getTimeRange: " + timeRange.toString());
      callback(timeRange);
    });
  }*/

// works?? nej
/*  static void getTimeSlot(String userID, void Function(TimeRange?) callback) {
    final firestoreInstance = FirebaseFirestore.instance;
    final usersCollectionRef = firestoreInstance.collection('users');

    usersCollectionRef.doc(userID).get().then((userDocumentSnapshot) {
      if (userDocumentSnapshot.exists) {
        if (userDocumentSnapshot.data().toString().contains('availability')) {
          final data = userDocumentSnapshot.data();
          if (data != null && data['availability'] != null) {
            final startTimeString = data['availability']['startTime'];
            final endTimeString = data['availability']['endTime'];

            final startTimeParts = startTimeString.split(':');
            final endTimeParts = endTimeString.split(':');

            final startTime = TimeOfDay(
              hour: int.parse(startTimeParts[0]),
              minute: int.parse(startTimeParts[1]),
            );

            final endTime = TimeOfDay(
              hour: int.parse(endTimeParts[0]),
              minute: int.parse(endTimeParts[1]),
            );

            final TimeRange timeRange = TimeRange(
              startTime: startTime,
              endTime: endTime,
            );
            print("getTimeSlot: " + timeRange.toString());
            callback(timeRange);
          } else {
            callback(null);
          }
        } else {
          callback(null);
        }
      } else {
        callback(null);
      }
    });
  }

  static void getTimeRange(String userID, void Function(TimeRange?) callback) {
    getTimeSlot(userID, (timeRange) {
      print("getTimeRange: " + timeRange.toString());
      callback(timeRange);
    });
  }*/

/*  static Future<TimeRange?> getTimeSlot(String userID) async {
    final firestoreInstance = FirebaseFirestore.instance;
    final usersCollectionRef = firestoreInstance.collection('users');

    final userDocumentSnapshot = await usersCollectionRef.doc(userID).get();
    if (userDocumentSnapshot.exists) {
      final data = userDocumentSnapshot.data();
      if (data != null && data['availability'] != null) {
        final startTimeString = data['availability']['startTime'];
        final endTimeString = data['availability']['endTime'];

        final startTimeParts = startTimeString.split(':');
        final endTimeParts = endTimeString.split(':');

        final startTime = TimeOfDay(
          hour: int.parse(startTimeParts[0]),
          minute: int.parse(startTimeParts[1]),
        );

        final endTime = TimeOfDay(
          hour: int.parse(endTimeParts[0]),
          minute: int.parse(endTimeParts[1]),
        );

        final TimeRange timeRange = TimeRange(
          startTime: startTime,
          endTime: endTime,
        );
        print (timeRange);
        return timeRange;
      }
      return null;
    }
    return null;
  }*/

/*  static Stream<TimeRange?> getTimeSlot(String userID) async* {
    final firestoreInstance = FirebaseFirestore.instance;
    final usersCollectionRef = firestoreInstance.collection('users');

    final userDocumentSnapshot = await usersCollectionRef.doc(userID).get();
    if (userDocumentSnapshot.exists) {
      if (userDocumentSnapshot.data().toString().contains('availability')) {
        final data = userDocumentSnapshot.data();
        if (data != null && data['availability'] != null) {
          final startTimeString = data['availability']['startTime'];
          final endTimeString = data['availability']['endTime'];

          final startTimeParts = startTimeString.split(':');
          final endTimeParts = endTimeString.split(':');

          final startTime = TimeOfDay(
            hour: int.parse(startTimeParts[0]),
            minute: int.parse(startTimeParts[1]),
          );

          final endTime = TimeOfDay(
            hour: int.parse(endTimeParts[0]),
            minute: int.parse(endTimeParts[1]),
          );

          final TimeRange timeRange = TimeRange(
            startTime: startTime,
            endTime: endTime,
          );
          print("getTimeSlot: " + timeRange.toString());
          yield timeRange;
        } else {
          yield null;
        }
      } else {
        yield null;
      }
    } else {
      yield null;
    }
  }

  static TimeRange? getTimeRange(String userID) {
    Stream<TimeRange?> timeSlotStream = getTimeSlot(userID);
    TimeRange? currentUserAvailabilityRange;

    timeSlotStream.listen((timeRange) {
      currentUserAvailabilityRange = timeRange;
    }).onDone(() {
      print("getTimeRange: " + currentUserAvailabilityRange.toString());
    });

    return currentUserAvailabilityRange;
  }
*/

/*  static TimeRange? getTimeRange(String userID) {
    TimeRange timeRange = getTimeSlot(userID) as TimeRange;
    print("getTimeRange: " + timeRange.toString());
    return timeRange;
  }*/
}
