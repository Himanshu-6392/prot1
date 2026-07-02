import 'package:flutter/material.dart';

// Ignore this file, it's just a script to remove const from the codebase.
import 'dart:io';

void main() {
  final dir = Directory('lib');
  if (!dir.existsSync()) {
    print('lib directory not found');
    return;
  }

  int count = 0;
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart') && !entity.path.contains('remove_const.dart')) {
      final content = entity.readAsStringSync();
      var newContent = content.replaceAll('BoxDecoration', 'BoxDecoration');
      newContent = newContent.replaceAll('LinearGradient', 'LinearGradient');
      newContent = newContent.replaceAll('RadialGradient', 'RadialGradient');
      
      if (content != newContent) {
        entity.writeAsStringSync(newContent);
        count++;
        print('Updated: \${entity.path}');
      }
    }
  }
  print('Removed const from \$count files.');
}
