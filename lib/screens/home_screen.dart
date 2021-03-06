import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes/screens/note_editor.dart';
import 'package:notes/style/app_style.dart';
import 'package:notes/widgets/node_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({ Key? key }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.mainColor,
      appBar: AppBar(
        elevation: 0.0,
        title: const Text("Notes App"),
        centerTitle: true,
        backgroundColor: AppStyle.mainColor,
        actions: <Widget>[
          GestureDetector(
            onTap: () async {
              await FirebaseAuth.instance.signOut();
            },
            child: const Icon(
              Icons.logout,
              size: 26.0,
            )
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("notes").snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
            
                  if (snapshot.hasData) {
                    return GridView(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
                      children: snapshot.data!.docs
                          .map((note) => NoteCard(() {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => NoteManagerScreen(note)));
                          }, note))
                          .toList(),
                      );
                  }

                  return Align(
                    alignment: Alignment.center,
                    child: Text(
                      "There's no notes! Add a new one using the + button",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 25
                      )),
                  );
                },
              ),
            )
          ]
        ),
      ),
      floatingActionButton: 
        FloatingActionButton.extended(
          onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context) => NoteManagerScreen(null)));
          }, 
          label: const Text("Add"),
          icon: const Icon(Icons.add),
        )
    );
  }
}