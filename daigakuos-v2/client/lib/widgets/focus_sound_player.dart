import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FocusSoundPlayer extends StatefulWidget {
  const FocusSoundPlayer({super.key});

  @override
  State<FocusSoundPlayer> createState() => _FocusSoundPlayerState();
}

class _FocusSoundPlayerState extends State<FocusSoundPlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  double _volume = 0.5;
  String _currentTrack = 'white_noise.mp3';

  final Map<String, String> _tracks = {
    'Rain': 'rain.mp3',
    'Cafe': 'cafe.mp3',
    'White Noise': 'white_noise.mp3',
    'Clock': 'clock.mp3',
    'Fire': 'fire.mp3',
  };

  @override
  void initState() {
    super.initState();
    _player.setReleaseMode(ReleaseMode.loop); // Loop forever
    _player.setVolume(_volume);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      // Note: This expects files in assets/sounds/
      // e.g. assets/sounds/rain.mp3
      // AudioCache prefix is 'assets/' by default in newer versions? 
      // Actually source is usually AssetSource('sounds/rain.mp3')
      try {
          await _player.play(AssetSource('sounds/$_currentTrack'));
      } catch (e) {
          debugPrint("Error playing sound: $e");
          // If file not found, maybe show snackbar?
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text("Sound file not found in assets/sounds/"), duration: Duration(seconds: 1)),
             );
          }
          return;
      }
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  Future<void> _changeTrack(String trackFileName) async {
    bool wasPlaying = _isPlaying;
    if (wasPlaying) await _player.stop();
    
    setState(() {
      _currentTrack = trackFileName;
      if (!wasPlaying) _isPlaying = true; // Auto play on switch? Or require tap?
    });

    if (wasPlaying || _isPlaying) {
      await _player.play(AssetSource('sounds/$_currentTrack'));
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _setVolume(double v) async {
    setState(() => _volume = v);
    await _player.setVolume(v);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Track Selector
              DropdownButton<String>(
                value: _currentTrack,
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white),
                underline: Container(),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                onChanged: (val) {
                  if (val != null) _changeTrack(val);
                },
                items: _tracks.entries.map((e) {
                  return DropdownMenuItem(
                    value: e.value,
                    child: Row(
                      children: [
                        Icon(_getIconForTrack(e.key), size: 16, color: Colors.white70),
                        const SizedBox(width: 8),
                        Text(e.key),
                      ],
                    ),
                  );
                }).toList(),
              ),

              // Play/Pause
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                color: _isPlaying ? Colors.orangeAccent : Colors.white70,
                iconSize: 32,
                onPressed: _togglePlay,
              ),
            ],
          ),
          
          // Volume Slider
          if (_isPlaying)
            Row(
              children: [
                const Icon(Icons.volume_down, size: 16, color: Colors.white54),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: _volume,
                      onChanged: _setVolume,
                      activeColor: Colors.orangeAccent,
                      inactiveColor: Colors.white24,
                    ),
                  ),
                ),
                const Icon(Icons.volume_up, size: 16, color: Colors.white54),
              ],
            ),
        ],
      ),
    );
  }

  IconData _getIconForTrack(String name) {
    switch (name) {
      case 'Rain': return Icons.water_drop;
      case 'Cafe': return Icons.coffee;
      case 'Fire': return Icons.local_fire_department;
      case 'Clock': return Icons.access_time;
      default: return Icons.graphic_eq;
    }
  }
}
