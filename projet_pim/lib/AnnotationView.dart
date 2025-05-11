import 'package:flutter/material.dart';
import 'package:projet_pim/CustomAnnotation.dart';

class AnnotationView extends StatelessWidget {
  final CustomAnnotation annotation;

  const AnnotationView({Key? key, required this.annotation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4.0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Text(
        annotation.title,
        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
      ),
    );
  }
}
