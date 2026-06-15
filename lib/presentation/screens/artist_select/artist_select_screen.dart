// lib/presentation/screens/artist_select/artist_select_screen.dart

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart' as audio_query;
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/artist_model.dart';
import '../player/player_screen.dart';

class ArtistSelectScreen extends StatefulWidget {
  const ArtistSelectScreen({super.key});

  @override
  State<ArtistSelectScreen> createState() => _ArtistSelectScreenState();
}

class _ArtistSelectScreenState extends State<ArtistSelectScreen>
    with TickerProviderStateMixin {
  late List<ArtistModel> _artists;
  late AnimationController _headerCtrl;
  late AnimationController _gridCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _artists = [];

    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _gridCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeIn));
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));

    _headerCtrl.forward();
    _loadArtists();
  }

  Future<void> _loadArtists() async {
    final query = audio_query.OnAudioQuery();
    final granted = await query.permissionsRequest();
    if (!granted || !mounted) return;

    final deviceArtists = await query.queryArtists(
      sortType: audio_query.ArtistSortType.ARTIST,
      orderType: audio_query.OrderType.ASC_OR_SMALLER,
    );

    if (!mounted) return;

    setState(() {
      _artists = deviceArtists
          .map(
            (a) => ArtistModel(
              id: a.id.toString(),
              name: a.artist,
              imageUrl: '',
              genre: '',
              monthlyListeners: a.numberOfTracks ?? 0,
            ),
          )
          .toList();
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _gridCtrl.forward();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _gridCtrl.dispose();
    super.dispose();
  }

  void _toggleArtist(int index) {
    setState(() {
      final artist = _artists[index];
      _artists[index] = artist.copyWith(isSelected: !artist.isSelected);
    });
  }

  int get _selectedCount => _artists.where((a) => a.isSelected).length;

  void _navigateToPlayer() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const PlayerScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top navigation bar ──
            AnimatedBuilder(
              animation: _headerCtrl,
              builder: (_, child) => FadeTransition(
                opacity: _headerFade,
                child: SlideTransition(position: _headerSlide, child: child),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    _NavBtn(
                      icon: Icons.chevron_left_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Your Playlist',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    _NavBtn(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),

            // ── Tab indicator ──
            Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 100),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 24),

            // ── Title ──
            AnimatedBuilder(
              animation: _headerCtrl,
              builder: (_, child) =>
                  FadeTransition(opacity: _headerFade, child: child),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Choose ',
                          style: AppTypography.display(
                            size: 28,
                            weight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: 'Your Favorite\nArtist',
                          style: AppTypography.display(
                            size: 28,
                            weight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Artist Grid or loading/empty states ──
            Expanded(
              child: _artists.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1A1814),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: _artists.length,
                      itemBuilder: (ctx, i) {
                        final artist = _artists[i];
                        return AnimatedBuilder(
                          animation: _gridCtrl,
                          builder: (_, child) {
                            final delay = (i / _artists.length) * 0.6;
                            final animValue = ((_gridCtrl.value - delay) / 0.4)
                                .clamp(0.0, 1.0);
                            return Opacity(
                              opacity: Curves.easeIn.transform(animValue),
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  30 *
                                      (1 - Curves.easeOut.transform(animValue)),
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: _ArtistCard(
                            artist: artist,
                            onTap: () => _toggleArtist(i),
                          ),
                        );
                      },
                    ),
            ),

            // ── Continue button ──
            if (_selectedCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: _ContinueButton(
                  count: _selectedCount,
                  onTap: _navigateToPlayer,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArtistCard extends StatefulWidget {
  final ArtistModel artist;
  final VoidCallback onTap;

  const _ArtistCard({required this.artist, required this.onTap});

  @override
  State<_ArtistCard> createState() => _ArtistCardState();
}

class _ArtistCardState extends State<_ArtistCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkCtrl;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _checkScale = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut));
    if (widget.artist.isSelected) _checkCtrl.value = 1;
  }

  @override
  void didUpdateWidget(_ArtistCard old) {
    super.didUpdateWidget(old);
    if (widget.artist.isSelected != old.artist.isSelected) {
      widget.artist.isSelected ? _checkCtrl.forward() : _checkCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.artist.isSelected;

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.ink : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Avatar — icon fallback since device artists have no image
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: AppConstants.artistAvatarSize,
                  height: AppConstants.artistAvatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.ink
                        : AppColors.surfaceVariant,
                  ),
                  child: widget.artist.imageUrl.isNotEmpty
                      ? ClipOval(
                          child: ColorFiltered(
                            colorFilter: isSelected
                                ? const ColorFilter.mode(
                                    Colors.transparent,
                                    BlendMode.saturation,
                                  )
                                : const ColorFilter.matrix([
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0,
                                    0,
                                    0,
                                    1,
                                    0,
                                  ]),
                            child: Image.network(
                              widget.artist.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.inkLight,
                              ),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: AppConstants.artistAvatarSize * 0.5,
                          color: isSelected ? Colors.white : AppColors.inkLight,
                        ),
                ),

                // Check overlay
                AnimatedBuilder(
                  animation: _checkScale,
                  builder: (_, __) => _checkScale.value > 0
                      ? Container(
                          width: AppConstants.artistAvatarSize,
                          height: AppConstants.artistAvatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.ink.withOpacity(0.35),
                          ),
                          child: Center(
                            child: Transform.scale(
                              scale: _checkScale.value,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.white,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.ink,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          Text(
            widget.artist.name,
            style: AppTypography.label(
              size: 11,
              color: isSelected ? AppColors.ink : AppColors.inkMuted,
              weight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Show track count instead of genre
          Text(
            '${widget.artist.monthlyListeners} songs',
            style: AppTypography.label(
              size: 9,
              color: AppColors.inkLight,
              weight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.ink),
      ),
    );
  }
}

class _ContinueButton extends StatefulWidget {
  final int count;
  final VoidCallback onTap;

  const _ContinueButton({required this.count, required this.onTap});

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut)),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue',
                style: AppTypography.body(
                  size: 16,
                  weight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.count}',
                  style: AppTypography.label(
                    size: 12,
                    color: AppColors.white,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
