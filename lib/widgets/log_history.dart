import 'package:fluent_ui/fluent_ui.dart';

import '../services/log_service.dart';

logHistory(context){

  return Column(
    children: [
      SizedBox(height: 10,),
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(width: 10,),
          Text('LOGS', style: FluentTheme.of(context).typography.bodyStrong,),
        ],
      ),
      SizedBox(height: 5,),
      Divider(),
      SizedBox(height: 5,),
      Expanded(
        child: CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                  // Get log messages from the Log class
                  return Padding(
                    padding: const EdgeInsets.all(0),
                    child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1), // Auto-width for "Type"
                          1: FlexColumnWidth(3), // Expands for "Message"
                        },
                        border: TableBorder.all(color: Colors.transparent, width: 0.5),
                        children: [
                          TableRow(children: [
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                Log.logMessages[index].split(': <barrier>')[0],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: Colors.black,
                                  fontFamily: 'Courier',
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                Log.logMessages[index].split(': <barrier>')[1],
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'Courier',
                                  color: Colors.grey,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ])
                        ]
                    ),
                  );

                },
                childCount: Log.logMessages.length, // The number of log messages to display
              ),
            ),
          ],
        ),
      )
    ],
  );

}