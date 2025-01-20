import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';

listTemplate({
    required BuildContext context,
    required String id,
    required String localPath,
    required String localTimestamp,
    required String localModified,
    required String remoteId,
    required String remoteTimestamp,
    required String toDelete,
}){
    return Container(
      margin: EdgeInsets.all(10),
      child: InfoBar(
        isIconVisible: false,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(id, style: FluentTheme.of(context).typography.caption)),
            SizedBox(width: 10,),
            Expanded(child: Text(localPath, style: FluentTheme.of(context).typography.caption)),
            SizedBox(width: 10,),
            Expanded(child: Text(localTimestamp, style: FluentTheme.of(context).typography.caption)),
            SizedBox(width: 10,),
            Expanded(child: Text(localModified == '1' ? 'MODIFIED' : 'UNTOUCHED', style: FluentTheme.of(context).typography.caption)),
            SizedBox(width: 10,),
            Expanded(child: Text(remoteId, style: FluentTheme.of(context).typography.caption)),
            SizedBox(width: 10,),
            Expanded(child: Text(remoteTimestamp, style: FluentTheme.of(context).typography.caption)),
            SizedBox(width: 10,),
            Expanded(child: Text(toDelete, style: FluentTheme.of(context).typography.caption)),
          ],
        ),
      ),
    );
}