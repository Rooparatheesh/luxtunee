import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:marquee/marquee.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/explore_provider.dart';
import '../../../data/network/download_service.dart';
import '../../../theme/app_theme.dart';
import '../../components/animated_playback_controls.dart';
import '../../components/wavy_slider.dart';
import '../../components/queue_bottom_sheet.dart';
import '../../components/add_to_playlist_sheet.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _enterCtrl;
  bool _isFavorite = false;
  bool _isShuffle = false;
  bool _isRepeat = false;
  bool _isDownloading = false;
  double? _downloadProgress;
  final DownloadService _downloadService = DownloadService();

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  Future<void> _handleDownload(BuildContext context, dynamic track) async {
    if (track == null || _isDownloading) return;
    
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting download for ${track.title}...')),
    );

    try {
      // 1. Resolve URL if it's from YouTube
      String url = track.audioUrl;
      if (url.isEmpty && track.source == 'youtube') {
        final explore = context.read<ExploreProvider>();
        url = await explore.getAudioUrl(track);
      }

      if (url.isEmpty) {
        throw Exception('Could not resolve audio URL');
      }

      // 2. Download and save with progress
      final downloadedPath = await _downloadService.downloadTrack(
        url, 
        '${track.title} - ${track.artist}',
        albumArtUrl: track.albumArt,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );
      
      if (downloadedPath != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download complete! Added to local music.')),
          );
          // Scan the newly downloaded file so it appears in the MediaStore
          final playerProvider = context.read<PlayerProvider>();
          
          // Add it manually to the UI immediately
          playerProvider.addDownloadedTrack(track, downloadedPath);
          
          // Then run background scan and refresh
          await playerProvider.scanMedia(downloadedPath);
          await playerProvider.loadLibrary();
        }
      } else {
        throw Exception('Failed to save file.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final track = player.currentTrack;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: FadeTransition(
              opacity: _enterCtrl,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                      
                      // 1. Top Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTopIconButton(
                            icon: Icons.keyboard_arrow_down_rounded,
                            onTap: () => Navigator.maybePop(context),
                          ),
                          Text(
                            'Now Playing',
                            style: AppTypography.display(
                              size: 16,
                              weight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          _buildTopIconButton(
                            icon: Icons.queue_music_rounded,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => const FractionallySizedBox(
                                  heightFactor: 0.9,
                                  child: QueueBottomSheet(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const Spacer(),

                      // 2. The Album Art (Large Square)
                      Container(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.width - 48, // perfect square
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: track != null
                            ? (!track.isLocal && track.albumArt.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: track.albumArt,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                      child: Icon(Icons.music_note_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24), size: 80),
                                    ),
                                    errorWidget: (context, url, error) => Center(
                                      child: Icon(Icons.music_note_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24), size: 80),
                                    ),
                                  )
                                : QueryArtworkWidget(
                                    id: track.albumId ?? 0,
                                    type: ArtworkType.ALBUM,
                                    keepOldArtwork: true,
                                    artworkBorder: BorderRadius.zero,
                                    artworkFit: BoxFit.cover,
                                    artworkWidth: double.infinity,
                                    artworkHeight: double.infinity,
                                    size: 1000,
                                    nullArtworkWidget: Center(
                                      child: Icon(Icons.music_note_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24), size: 80),
                                    ),
                                  ))
                            : Center(
                                child: Icon(Icons.music_note_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24), size: 80),
                              ),
                      ),

                      const Spacer(),

                      // 3. Track Info Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track?.title ?? 'No Track',
                                  style: AppTypography.display(
                                    size: 28,
                                    weight: FontWeight.w800,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 20,
                                  child: Marquee(
                                    text: track?.artist ?? 'Unknown Artist',
                                    style: AppTypography.body(
                                      size: 16,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      weight: FontWeight.w500,
                                    ),
                                    scrollAxis: Axis.horizontal,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    blankSpace: 40.0,
                                    velocity: 30.0,
                                    pauseAfterRound: const Duration(seconds: 2),
                                    startPadding: 0.0,
                                    accelerationDuration: const Duration(seconds: 1),
                                    accelerationCurve: Curves.easeIn,
                                    decelerationDuration: const Duration(milliseconds: 500),
                                    decelerationCurve: Curves.easeOut,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              _buildActionSquare(
                                icon: track != null && player.isFavorite(track) 
                                    ? Icons.favorite_rounded 
                                    : Icons.favorite_border_rounded,
                                onTap: () {
                                  if (track != null) {
                                    player.toggleFavorite(track);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildActionSquare(
                                icon: Icons.lyrics_rounded,
                                onTap: () {},
                              ),
                              if (track != null && !track.isLocal) ...[
                                const SizedBox(width: 8),
                                _isDownloading 
                                  ? SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          SizedBox(
                                            width: 48,
                                            height: 48,
                                            child: CircularProgressIndicator(
                                              value: _downloadProgress,
                                              strokeWidth: 2.5,
                                              backgroundColor: AppColors.white.withOpacity(0.1),
                                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.libraryTextGreen),
                                            ),
                                          ),
                                          Icon(
                                            Icons.download_rounded, 
                                            color: AppColors.libraryTextGreen.withOpacity(0.5),
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    )
                                  : _buildActionSquare(
                                      icon: Icons.download_rounded,
                                      onTap: () => _handleDownload(context, track),
                                    ),
                              ],
                              const SizedBox(width: 8),
                              _buildActionSquare(
                                icon: Icons.more_vert_rounded,
                                onTap: () {
                                  if (track != null) {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => FractionallySizedBox(
                                        heightFactor: 0.6,
                                        child: AddToPlaylistSheet(track: track),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 4. Wavy Music Slider
                      StreamBuilder<Duration>(
                        stream: player.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? player.position;
                          final duration = player.duration;
                          final progress = duration.inSeconds > 0
                              ? position.inSeconds / duration.inSeconds
                              : 0.0;

                          return Column(
                            children: [
                              WavyMusicSlider(
                                value: progress.clamp(0.0, 1.0),
                                isPlaying: player.isPlaying,
                                activeColor: AppColors.pillPaleOrange,
                                inactiveColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                                onChanged: (v) {
                                  player.seek(
                                    Duration(seconds: (v * duration.inSeconds).round()),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _fmt(position),
                                    style: AppTypography.label(
                                      size: 12,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                  // Quality Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '44.1 kHz • 720 kbps • FLAC',
                                      style: AppTypography.label(
                                        size: 10,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _fmt(duration),
                                    style: AppTypography.label(
                                      size: 12,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // 5. Playback Controls (Animated)
                      AnimatedPlaybackControls(
                        isPlaying: player.isPlaying,
                        onPrevious: () => player.skipPrev(),
                        onPlayPause: () => player.togglePlayPause(),
                        onNext: () => player.skipNext(),
                      ),

                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
        );
      },
    );
  }

  Widget _buildTopIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 22),
      ),
    );
  }

  Widget _buildActionSquare({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 20),
      ),
    );
  }
}
