import 'dart:io';

void main() {
  final directory = Directory('lib');
  final files =
      directory
          .listSync(recursive: true)
          .where((f) => f.path.endsWith('.dart'))
          .toList();

  for (var file in files) {
    final content = File(file.path).readAsStringSync();
    var fixedContent = content;

    // 1️⃣ استبدال print() بـ debugPrint()
    fixedContent = fixedContent.replaceAllMapped(
      RegExp(r'print\((.*)\);'),
      (match) => 'debugPrint(${match.group(1)}.toString());',
    );

    // 2️⃣ استبدال constructors اللي فيها Key بـ super.key
    fixedContent = fixedContent.replaceAllMapped(
      RegExp(r'\{Key\? key\}\)\s*:\s*super\(key: key\)'),
      (match) => '{super.key})',
    );

    if (content != fixedContent) {
      File(file.path).writeAsStringSync(fixedContent);
      print('✅ Fixed: ${file.path}');
    }
  }

  print('\n🎉 Done! All prints replaced & constructors fixed.');
}
