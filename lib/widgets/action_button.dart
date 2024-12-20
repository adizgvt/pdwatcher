import 'package:fluent_ui/fluent_ui.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Widget actionButton({
  required IconData icon,
  required String label,
  required Function() onPressed
}){

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 5),
    child: Button(
        child: Row(
          children: [
            Icon(icon, size: 10,),
            SizedBox(width: 5,),
            Text(label, style: TextStyle(fontSize: 10))
          ],
        ),
        onPressed: onPressed
    ),
  );

}