import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quilllib;
import 'package:intl/intl.dart';
import 'package:notes/style/app_style.dart';

class NoteManagerScreen extends StatefulWidget {
  NoteManagerScreen(this.doc, {Key? key}) : super(key: key);
  QueryDocumentSnapshot? doc;

  @override
  State<NoteManagerScreen> createState() => NoteManagerScreenState();
}

class NoteManagerScreenState extends State<NoteManagerScreen> {
  int mColorId = Random().nextInt(AppStyle.cardsColors.length);
  final DateFormat dateFormat = DateFormat("yyyy-MM-dd");
  TextEditingController mTitleController = TextEditingController();
  TextEditingController mMainController = TextEditingController();
  quilllib.QuillController? _controller;
  final FocusNode _focusNode = FocusNode();
  bool showToolBar = false;
  bool isNewDocument = true;
  EdgeInsets floatingButton = const EdgeInsets.only(bottom: 0);

  @override
  void dispose(){
    super.dispose();
    _controller?.dispose();
  }

  @override
  void initState() {
    super.initState();

    _loadDocument();

    _focusNode.addListener(() {
      setState(() {
        showToolBar = _focusNode.hasFocus;

        if (_focusNode.hasFocus)
        {
          floatingButton = const EdgeInsets.only(bottom: 50);
        }
        else {
          floatingButton = const EdgeInsets.only(bottom: 0);
        }
      });
    });
  }

  Future<void> _loadDocument() async {
    try {
      if (widget.doc == null) {
        createEmptyDoc();
      }
      else  {
        var content = widget.doc!["note_content"].toString();
        var myJSON = jsonDecode(content);
        final doc = quilllib.Document.fromJson(myJSON);
        setState(() {
          _controller = quilllib.QuillController(
            document: doc, 
            selection: const TextSelection.collapsed(offset: 0)
            );

            isNewDocument = false;
        });
      }
    }
    catch (error) {
      createEmptyDoc();
    }
  }

  void createEmptyDoc() {
    final doc = quilllib.Document()..insert(0, '');
    setState(() {
        _controller = quilllib.QuillController(
            document: doc, 
            selection: const TextSelection.collapsed(offset: 0)
          );
      });
  }

  @override
  Widget build(BuildContext context) {

    if (_controller == null) {
      return const Scaffold(body: Center(child: Text('Loading ...')));
    }

    String mDate = dateFormat.format(DateTime.now());
    const cPadding = EdgeInsets.only(left: 10, right: 10);

    if (!isNewDocument) {
      mColorId = widget.doc!["color_id"];
      mTitleController.text = widget.doc!["note_title"];
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppStyle.cardsColors[mColorId],
        elevation: 0.0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          getPageTitle(),
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          if (!isNewDocument)
          Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
              onTap: () {
                showDeleteDialog(context);
              },
              child: const Icon(
                  Icons.delete,
                  size: 26.0,
                ),
              )
            ),
        ]
      ),
      body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: cPadding,
                child: TextField(
                  controller: mTitleController,
                  decoration: InputDecoration(
                      border: InputBorder.none, 
                      hintText: getDocumentTitle()),
                  style: AppStyle.mainTitle,
                ),
              ),
              const SizedBox(height: 5.0),
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding: cPadding,
                  child: NoteContentEditorv2(context, _controller, _focusNode, mColorId),
                ),
              ),
              if (showToolBar)
                Container(
                  child: Column(
                    mainAxisAlignment : MainAxisAlignment.center,
                    children : [ 
                      getNoteEditorToolbar(_controller)
                    ]
                  ),
                  padding: const EdgeInsets.only(left: 5, right: 5),
                  height: 60,
                  color: Colors.grey[50],
                ),
          ]
        ),
      ),
      floatingActionButton: Padding(
        padding: floatingButton,
        child: FloatingActionButton(
          backgroundColor: AppStyle.accentColor,
          onPressed: () async {
            
            var notePreview = _controller!.document.toPlainText();
            if (notePreview.length > 100) {
              notePreview = notePreview.substring(0, 100) + ' ...';
            }

            String title = mTitleController.text;
            String content = jsonEncode(_controller!.document.toDelta().toJson());

            if (isNewDocument) {
              FirebaseFirestore.instance.collection("notes").add({
                "note_title": title,
                "note_content": content,
                "note_preview": notePreview,
                "note_date": mDate,
                "color_id": mColorId
              }).then((value) {
                Navigator.pop(context);
              }).catchError(
                  (onError) => print("Failed to add new note due to $onError"));
            }
            else {
              FirebaseFirestore.instance.collection("notes").doc(widget.doc!.id).update({
                "note_title": title,
                "note_content": content,
                "note_preview": notePreview,
                "note_date": mDate,
              }).then((value) {
                Navigator.pop(context);
              }).catchError(
                  (onError) => print("Failed to update note due to $onError"));
            }

          },
          child: const Icon(Icons.save),
        ),
      ),
    );
  }

  String getPageTitle() {
    return isNewDocument ? "Adding a new Note" : widget.doc!["note_title"];
  }

  String getDocumentTitle() {
    return isNewDocument ? "Note Title" : widget.doc!["note_title"];
  }

  void showDeleteDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: const Text("Cancel"),
      onPressed:  () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = TextButton(
      child: const  Text("Delete"),
      onPressed:  () {
        Navigator.pop(context);

        FirebaseFirestore.instance.collection("notes").doc(widget.doc!.id).delete()
        .then((value) => Navigator.pop(context))
        .catchError((onError) => print("Failed to update note due to $onError"));
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Delete"),
      content: const Text("Are you sure you want to delete the note?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}

Widget NoteContentEditor(BuildContext context, TextEditingController mMainController) {
  return TextField(
    controller: mMainController,
    keyboardType: TextInputType.multiline,
    maxLines: null,
    decoration: const InputDecoration(
        border: InputBorder.none, hintText: 'Note Content'),
    style: AppStyle.mainContent,
  );
}

Widget NoteContentEditorv2(BuildContext context, quilllib.QuillController? editorController, FocusNode focusNode, int mColorId) {
  return Container(
      //color: AppStyle.cardsColors[mColorId],
      color: Colors.white,
      padding: const EdgeInsets.all(0),
      child: quilllib.QuillEditor(
        controller: editorController!,
        scrollController: ScrollController(),
        scrollable: true,
        focusNode: focusNode,
        readOnly: false, // true for view only mode
        autoFocus: false,
        placeholder: 'Note Content',
        expands: false,
        padding: EdgeInsets.zero,
      )
  );
}

Widget getNoteEditorToolbar(quilllib.QuillController? editorController) {
  var toolbar = quilllib.QuillToolbar.basic(
      controller: editorController!,
      // provide a callback to enable picking images from device.
      // if omit, "image" button only allows adding images from url.
      // same goes for videos.
      //onImagePickCallback: _onImagePickCallback,
      //onVideoPickCallback: _onVideoPickCallback,
      // uncomment to provide a custom "pick from" dialog.
      // mediaPickSettingSelector: _selectMediaPickSetting,
      showAlignmentButtons: true,
      showStrikeThrough: false,
      showColorButton: false,
      showBackgroundColorButton: false,
      showListCheck: false,
      showIndent: false,
    );

  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: toolbar,
  );
}