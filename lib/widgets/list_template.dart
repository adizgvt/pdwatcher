import 'package:fluent_ui/fluent_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdwatcher/utils/icon_list.dart';

Widget listTemplate({
  required BuildContext context,
  required String id,
  required String localPath,
  required String localTimestamp,
  required String localModified,
  required String remoteId,
  required String remoteTimestamp,
  required String toDelete,
  bool showTitle = true, // New parameter to control title visibility
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildColumn(context, 'ID', id, showTitle),
        buildColumn(context, 'Local Path', localPath, showTitle, flex: 2),
        buildColumn(context, 'Local T', localTimestamp, showTitle),
        buildColumn(
          context,
          'Modified',
          localModified == '1' ? 'MODIFIED' : 'UNTOUCHED',
          showTitle,
          textColor: localModified == '1' ? Colors.orange : Colors.grey,
        ),
        buildColumn(context, 'Remote ID', remoteId, showTitle),
        buildColumn(context, 'Remote T', remoteTimestamp, showTitle),
        buildColumn(
          context,
          'To Delete',
          toDelete == '1' ? 'YES' : '',
          showTitle,
          textColor: toDelete == '1' ? Colors.red : Colors.green,
        ),
      ],
    ),
  );
}

/// Helper function to create a column with optional title
Widget buildColumn(
    BuildContext context,
    String title,
    String value,
    bool showTitle, {
      int flex = 1,
      Color? textColor,
    }) {
  return Expanded(
    flex: flex,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle)...[
            Text(
              title,
              style: GoogleFonts.roboto( // Use Google Font here
                fontWeight: FontWeight.bold,
                fontSize: 12,  // Customize font size if necessary
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              if (title == 'Local Path') ...[
                getFileIcon(value),
                SizedBox(width: 10),
              ],
              Expanded(  // Make the text flexible to handle overflow
                child: Text(
                  value,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,  // Customize font size if necessary
                    color: textColor ?? Colors.black,
                  ),
                  softWrap: true, // Allow text to wrap to the next line
                ),
              ),
            ],
          )
        ],
      ),
    ),
  );
}
