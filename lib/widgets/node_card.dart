import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:notes/style/app_style.dart';

Widget NoteCard(Function()? onTap, QueryDocumentSnapshot doc) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: AppStyle.cardsColors[doc['color_id']],
        borderRadius: BorderRadius.circular(8.0)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(doc["note_title"], style: AppStyle.mainTitle, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4.0,),
          Text(doc["note_date"], style: AppStyle.dateTitle),
          const SizedBox(height: 8.0,),
          Text(doc["note_preview"], style: AppStyle.mainContent)
        ],        
      ),
    ),
  );
}