import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import 'theme.dart';

Future<void> showSavedPdfDialog(BuildContext context, {required String path}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('PDF saved'),
        content: Text(path),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              SharePlus.instance.share(ShareParams(files: [XFile(path)]));
            },
            child: const Text('Share'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => OpenFilex.open(path),
            child: const Text('Open'),
          ),
        ],
      );
    },
  );
}
