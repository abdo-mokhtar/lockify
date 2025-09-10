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

    // استبدال withOpacity(x) بـ withValues(alpha: x)
    final fixedContent = content.replaceAllMapped(
      RegExp(r'\.withOpacity\(([^)]+)\)'),
      (match) => '.withValues(alpha: ${match.group(1)})',
    );

    if (content != fixedContent) {
      File(file.path).writeAsStringSync(fixedContent);
      print('✅ Fixed: ${file.path}');
    }
  }
}
