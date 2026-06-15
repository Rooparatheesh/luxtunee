// lib/presentation/screens/player/player_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../../providers/player_provider.dart';
import '../../widgets/common/blob_painter.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _enterCtrl;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PlayerProvider>();
      if (provider.tracks.isEmpty) {
        provider.loadLibrary().then((_) {
          if (provider.tracks.isNotEmpty && provider.currentTrack == null) {
            provider.playTrack(provider.tracks.first);
          }
        });
      }
    });
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
    final screenW = MediaQuery.of(context).size.width;
    final blobSize = screenW * 0.84;

    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final track = player.currentTrack;
        final progress = player.duration.inSeconds > 0
            ? player.position.inSeconds / player.duration.inSeconds
            : 0.0;

        if (player.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFEAE6E1),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF1A1814)),
            ),
          );
        }

        if (!player.isLoading && player.tracks.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFFEAE6E1),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.music_off_rounded,
                    size: 64,
                    color: Color(0xFFA8A39D),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No music found',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1814),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Make sure storage permission is granted',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: const Color(0xFF7A7570),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => player.loadLibrary(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1814),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Retry',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFEAE6E1),
          body: SafeArea(
            child: FadeTransition(
              opacity: _enterCtrl,
              child: Column(
                children: [
                  // ── Top bar ──
                  _TopBar(
                    isFavorite: _isFavorite,
                    onBack: () => Navigator.maybePop(context),
                    onFav: () => setState(() => _isFavorite = !_isFavorite),
                  ),

                  const SizedBox(height: 6),

                  // ── Timestamp ──
                  _Timestamp(
                    position: _fmt(player.position),
                    total: _fmt(player.duration),
                  ),

                  const SizedBox(height: 12),

                  // ── Blob with album art ──
                  Center(
                    child: AnimatedBlobWithDot(
                      size: blobSize,
                      blobColor: const Color(0xFFD8D3CC),
                      progress: progress.clamp(0.0, 1.0),
                      seed: 7,
                      dotSize: 16,
                      dotColor: Colors.black,
                      strokeColor: Colors.black.withOpacity(0.25),
                      strokeWidth: 2.0,
                      child: track != null
                          ? QueryArtworkWidget(
                              id: track.albumId ?? 0,
                              type: ArtworkType.ALBUM,
                              artworkWidth: blobSize,
                              artworkHeight: blobSize,
                              artworkFit: BoxFit.cover,
                              nullArtworkWidget: Container(
                                width: blobSize,
                                height: blobSize,
                                color: const Color(0xFF1A1814),
                                child: const Icon(
                                  Icons.music_note_rounded,
                                  size: 72,
                                  color: Colors.white24,
                                ),
                              ),
                            )
                          : Container(
                              width: blobSize,
                              height: blobSize,
                              color: const Color(0xFF1A1814),
                              child: const Icon(
                                Icons.music_note_rounded,
                                size: 72,
                                color: Colors.white24,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Track title + artist ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      (track?.title ?? 'No Track').toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1814),
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      track?.artist ?? '',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: const Color(0xFF7A7570),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Seek bar ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                        activeTrackColor: const Color(0xFF1A1814),
                        inactiveTrackColor: const Color(0xFFD8D3CC),
                        thumbColor: const Color(0xFF1A1814),
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: (v) => player.seek(
                          Duration(
                            seconds: (v * player.duration.inSeconds).round(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Playback controls ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CtrlIcon(
                          icon: Icons.repeat_rounded,
                          active: false,
                          onTap: () {},
                        ),
                        _CtrlIcon(
                          icon: Icons.skip_previous_rounded,
                          size: 30,
                          onTap: () => player.skipPrev(),
                        ),
                        GestureDetector(
                          onTap: () => player.togglePlayPause(),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1814),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.20),
                                  blurRadius: 16,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              player.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        _CtrlIcon(
                          icon: Icons.skip_next_rounded,
                          size: 30,
                          onTap: () => player.skipNext(),
                        ),
                        _CtrlIcon(
                          icon: Icons.shuffle_rounded,
                          active: false,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Lyrics + Up Next scrollable section ──
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Lyrics section
                          _SectionHeader(
                            title: 'Lyrics',
                            trailing: const Icon(
                              Icons.open_in_full_rounded,
                              size: 16,
                              color: Color(0xFF7A7570),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0EDE8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child:
                                track?.lyrics != null &&
                                    track!.lyrics.isNotEmpty
                                ? Text(
                                    track.lyrics,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      color: const Color(0xFF7A7570),
                                      height: 1.8,
                                    ),
                                  )
                                : Text(
                                    'No lyrics available',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      color: const Color(0xFFA8A39D),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 20),

                          // Up Next section
                          _SectionHeader(
                            title: 'Up Next',
                            trailing: Text(
                              '${player.tracks.length} songs',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: const Color(0xFF7A7570),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Track list — NOT inside Expanded/ListView
                          // Use Column to avoid nested scroll issues
                          ...player.tracks.map((t) {
                            final isActive = t.id == player.currentTrack?.id;
                            return GestureDetector(
                              onTap: () => player.playTrack(t),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFF1A1814)
                                      : const Color(0xFFF0EDE8),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t.title,
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isActive
                                                  ? Colors.white
                                                  : const Color(0xFF1A1814),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            t.artist,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 11,
                                              color: isActive
                                                  ? Colors.white60
                                                  : const Color(0xFF7A7570),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      t.formattedDuration,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        color: isActive
                                            ? Colors.white60
                                            : const Color(0xFFA8A39D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1814),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onFav;

  const _TopBar({
    required this.isFavorite,
    required this.onBack,
    required this.onFav,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _Pill(icon: Icons.chevron_left_rounded, onTap: onBack),
          const Expanded(
            child: Center(
              child: Text(
                'Current Track',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1814),
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          _Pill(
            icon: isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            onTap: onFav,
            filled: isFavorite,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _Pill({required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF1A1814) : const Color(0xFFF0EDE8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: filled ? Colors.white : const Color(0xFF1A1814),
        ),
      ),
    );
  }
}

class _Timestamp extends StatelessWidget {
  final String position;
  final String total;

  const _Timestamp({required this.position, required this.total});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 13,
      color: Color(0xFF7A7570),
      fontWeight: FontWeight.w500,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(position, style: style),
        const Text(
          '  |  ',
          style: TextStyle(fontSize: 13, color: Color(0xFFA8A39D)),
        ),
        Text(total, style: style),
      ],
    );
  }
}

class _CtrlIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool active;

  const _CtrlIcon({
    required this.icon,
    required this.onTap,
    this.size = 22,
    this.active = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: size,
          color: active ? const Color(0xFF1A1814) : const Color(0xFFA8A39D),
        ),
      ),
    );
  }
}
