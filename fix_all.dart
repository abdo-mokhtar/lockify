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

    // 1️⃣ استبدال withOpacity(x) -> withValues(alpha: x)
    fixedContent = fixedContent.replaceAllMapped(
      RegExp(r'\.withOpacity\(([^)]+)\)'),
      (match) => '.withValues(alpha: ${match.group(1)})',
    );

    // 2️⃣ استبدال print(...) -> debugPrint(... .toString())
    fixedContent = fixedContent.replaceAllMapped(
      RegExp(r'print\((.*)\);'),
      (match) => 'debugPrint(${match.group(1)}.toString());',
    );

    // 3️⃣ استبدال constructors اللي فيها Key? key -> super.key
    fixedContent = fixedContent.replaceAllMapped(
      RegExp(r'\{Key\? key\}\)\s*:\s*super\(key: key\)'),
      (match) => '{super.key})',
    );

    if (content != fixedContent) {
      File(file.path).writeAsStringSync(fixedContent);
      print('✅ Fixed: ${file.path}');
    }
  }

  print('\n🎉 Done! All fixes applied.');
}
