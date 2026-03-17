import 'package:just_audio/just_audio.dart';

void main() {
  final player = AudioPlayer();
  final p = player.sequence;
  print('just_audio API check: $p');
}
