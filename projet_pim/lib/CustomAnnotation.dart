import 'package:ar_location_view/ar_annotation.dart';
import 'package:geolocator/geolocator.dart';

class CustomAnnotation extends ArAnnotation {
  final String title;
  final String? imageUrl; // image facultative
  final String? subtitle; // texte additionnel facultatif

  CustomAnnotation({
    required String uid,
    required Position position,
    required this.title,
    this.imageUrl,
    this.subtitle,
  }) : super(uid: uid, position: position);
}
