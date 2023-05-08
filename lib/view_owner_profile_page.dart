import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'settings_page.dart';

class ViewOwnerProfile extends StatelessWidget {
  const ViewOwnerProfile({Key? key});

  @override
  Widget build(BuildContext context) {
    final userUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ownerprofile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsPage()));
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userUid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final userData = snapshot.data!;
            final name = userData.get('name');
            final surname = userData.get('surname');
            final about = userData.get('about') as String?;
            final age = userData.get('age') as int?;
            final gender = userData.get('gender');
            final String? profilePic = userData.get('picture') as String?;

            return Stack(alignment: Alignment.center, children: <Widget>[
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topLeft,
                      child: ElevatedButton(
                        child: const Text('Lägg till plats'),
                        onPressed: () {},
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: CircleAvatar(
                          radius: 50.0,
                          backgroundImage: AssetImage(
                              'assets/images/placeholder-dog-image2.png'),
                        ),
                      ),
                    ),
                  ]),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircleAvatar(
                    radius: 100.0,
                    backgroundImage: profilePic != null
                        ? NetworkImage(profilePic)
                        : AssetImage(
                        'assets/images/placeholder-profile-image.png') as ImageProvider<Object>,
                  ),
                  Text(
                    name + ' ' + surname,
                    style: const TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    //height: 500.0,
                    width: 300.0,
                    child: TextField(
                      readOnly: true,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        // TODO: get this information from the database
                          hintText:
                          '• ' + gender! + '\n• ' + age.toString(),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              //Navigator.push(context, MaterialPageRoute(builder: (context) => const EditOwnerProfile()));
                            },
                          )),
                      style: const TextStyle(
                        fontSize: 18.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  SizedBox(
                    //height: 500.0,
                    width: 300.0,
                    child: TextField(
                      readOnly: true,
                      minLines: 5,
                      maxLines: 5,
                      decoration: InputDecoration(
                        // TODO: get this information from the database
                        hintText: '• ' + about!,
                        border: OutlineInputBorder(),
                      ),
                      style: TextStyle(
                        fontSize: 18.0,
                      ),
                    ),
                  ),
                ],
              ),
            ]);
          }),
    );
  }
}