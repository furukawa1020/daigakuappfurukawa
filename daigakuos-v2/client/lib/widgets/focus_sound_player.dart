import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    _player.setReleaseMode(ReleaseMode.loop);
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
      try {
        await _player.play(AssetSource('sounds/$_currentTrack'));
      } catch (e) {
        debugPrint("Error playing sound: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sound file not found"), duration: Duration(seconds: 1)),
          );
        }
        return;
      }
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  Future<void> _changeTrack(String trackFileName) async {
    bool wasPlaying = _isPlaying;
    if (wasPlaying) await _player.stop();
    
    setState(() {
      _currentTrack = trackFileName;
      if (!wasPlaying) _isPlaying = true; 
    });

    try {
      await _player.play(AssetSource('sounds/$_currentTrack'));
      setState(() => _isPlaying = true);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Track Selector (Chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tracks.entries.map((e) {
                final isSelected = _currentTrack == e.value;
                return GestureDetector(
                  onTap: () => _changeTrack(e.value),
                  child: AnimatedContainer(
                    duration: 300.ms,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orangeAccent.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? Colors.orangeAccent : Colors.white24),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getIconForTrack(e.key), 
                          size: 16, 
                          color: isSelected ? Colors.orangeAccent : Colors.white70
                        ),
                        const SizedBox(width: 8),
                        Text(
                          e.key,
                          style: TextStyle(
                            color: isSelected ? Colors.orangeAccent : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(1,1), end: const Offset(1.05, 1.05)),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),

          Row(
            children: [
              // Play/Pause Button
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: _isPlaying ? Colors.orangeAccent : Colors.white12,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: _isPlaying ? Colors.white : Colors.white70,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Volume Control
              Expanded(
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                        activeTrackColor: Colors.orangeAccent,
                        inactiveTrackColor: Colors.white12,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: _volume,
                        onChanged: (v) async {
                          setState(() => _volume = v);
                          await _player.setVolume(v);
                        },
                      ),
                    ),
                  ],
                ),
              ),
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
