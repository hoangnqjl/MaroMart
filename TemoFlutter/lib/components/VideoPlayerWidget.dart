import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:video_player/video_player.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:temo/Colors/AppColors.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onFullscreen;

  const VideoPlayerWidget({Key? key, required this.videoUrl, this.onFullscreen}) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  bool _isMuted = false;
  double _playbackSpeed = 1.0;
  String _quality = "720p";

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });
      _controller.setLooping(true); // Lặp lại video
    } catch (e) {
      print("Error loading video: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
    _resetControlTimer();
  }

  void _resetControlTimer() {
    setState(() => _showControls = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.error_outline, color: Colors.white54, size: 40),
            SizedBox(height: 8),
            Text("Không thể tải video", style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(child: ModernLoader(size: 30));
    }

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video background
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),

          // Controls Overlay
          if (_showControls)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top actions - Removed to avoid overlap with gallery close button
                    const SizedBox(height: 60),

                    // Center Play/Pause
                    GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ),

                    // Bottom Controls
                    SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Seek bar
                            VideoProgressIndicator(
                              _controller,
                              allowScrubbing: true,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              colors: VideoProgressColors(
                                playedColor: Colors.white,
                                bufferedColor: Colors.white24,
                                backgroundColor: Colors.white10,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  _formatDuration(_controller.value.position),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                const Text(" / ", style: TextStyle(color: Colors.white54, fontSize: 12)),
                                Text(
                                  _formatDuration(_controller.value.duration),
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                                const Spacer(),
                                _buildControlButton(
                                  icon: _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                  onTap: () {
                                    setState(() {
                                      _isMuted = !_isMuted;
                                      _controller.setVolume(_isMuted ? 0 : 1);
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                _buildControlButton(
                                  icon: Icons.settings_rounded,
                                  onTap: _showSettingsDialog,
                                ),
                                if (widget.onFullscreen != null) ...[
                                  const SizedBox(width: 8),
                                  _buildControlButton(
                                    icon: Icons.fullscreen_rounded,
                                    onTap: widget.onFullscreen!,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white10,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  void _showStyledBottomSheet({required String title, required Widget content}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(45),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    _showStyledBottomSheet(
      title: "Cài đặt video",
      content: Column(
        children: [
          _buildSettingOption(
            icon: Icons.speed_rounded,
            label: "Tốc độ phát",
            value: "${_playbackSpeed}x",
            onTap: _showSpeedPicker,
          ),
          const SizedBox(height: 12),
          _buildSettingOption(
            icon: Icons.high_quality_rounded,
            label: "Chất lượng",
            value: _quality,
            onTap: _showQualityPicker,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingOption({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(45),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
            const Spacer(),
            Text(value, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  void _showSpeedPicker() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    _showStyledBottomSheet(
      title: "Tốc độ phát",
      content: Column(
        children: speeds.map((s) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(
            _playbackSpeed == s ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: _playbackSpeed == s ? AppColors.primary : Colors.grey[300],
          ),
          title: Text("${s}x", style: TextStyle(fontWeight: _playbackSpeed == s ? FontWeight.bold : FontWeight.normal)),
          onTap: () {
            setState(() {
              _playbackSpeed = s;
              _controller.setPlaybackSpeed(s);
            });
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  void _showQualityPicker() {
    final qualities = ["360p", "720p", "1080p (Auto)"];
    _showStyledBottomSheet(
      title: "Chất lượng video",
      content: Column(
        children: qualities.map((q) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(
            _quality == q ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: _quality == q ? AppColors.primary : Colors.grey[300],
          ),
          title: Text(q, style: TextStyle(fontWeight: _quality == q ? FontWeight.bold : FontWeight.normal)),
          onTap: () {
            setState(() => _quality = q);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }
}