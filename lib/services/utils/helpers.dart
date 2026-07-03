import 'dart:io';


List<String> getMusicsDirectory() { // example : home/amin/musics 
  final home = Platform.environment['HOME']!;
  final directory = Directory('$home/Music');
  const extensions = ['.mp3'];

  if(!directory.existsSync()){
    print(directory);
    return ['list is empty'];
  }

  return directory.listSync(recursive: true).whereType<File>().where((f) => extensions.any((e) => f.path.toLowerCase().endsWith(e))).map((f) => f.path).toList();
  
}



debug(){
  final home = Platform.environment['HOME']!;
  final dir = Directory('$home/Music');
  final files = dir.listSync(recursive: true);

  print("Found: ${files.length}");

  for (final f in files) {
    print(f.path);
  }
}

