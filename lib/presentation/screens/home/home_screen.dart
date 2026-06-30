// lib/presentation/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../../providers/player_provider.dart';
import '../../../theme/app_theme.dart';
import '../../components/add_to_playlist_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _filters = ['SONGS', 'ALBUMS', 'ARTIST'];
  int _selectedFilter = 0;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PlayerProvider>();
      if (provider.tracks.isEmpty) {
        provider.loadLibrary();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_isSearching)
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: AppTypography.body(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search songs or artists...',
                          hintStyle: AppTypography.body(
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value.toLowerCase()),
                      ),
                    )
                  else
                    Text(
                      'Library',
                      style: AppTypography.display(
                        size: 28,
                        weight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isSearching
                              ? Icons.close_rounded
                              : Icons.search_rounded,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_isSearching) {
                              _isSearching = false;
                              _searchQuery = '';
                              _searchController.clear();
                            } else {
                              _isSearching = true;
                            }
                          });
                        },
                      ),
                      if (!_isSearching)
                        IconButton(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: () {},
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final isSelected = _selectedFilter == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.libraryPillActiveBg
                            : AppColors.libraryPillBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _filters[index],
                        style: AppTypography.label(
                          size: 12,
                          weight: FontWeight.w600,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 24),

            // Track List
            Expanded(
              child: Consumer<PlayerProvider>(
                builder: (context, player, child) {
                  if (player.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  }

                  var filteredTracks = player.tracks;
                  if (_searchQuery.isNotEmpty) {
                    filteredTracks = filteredTracks
                        .where(
                          (track) =>
                              track.title.toLowerCase().contains(
                                _searchQuery,
                              ) ||
                              track.artist.toLowerCase().contains(_searchQuery),
                        )
                        .toList();
                  }

                  if (filteredTracks.isEmpty) {
                    return Center(
                      child: Text(
                        'No music found',
                        style: AppTypography.body(color: AppColors.textMuted),
                      ),
                    );
                  }

                  // Ensure we pad the bottom so the mini player doesn't hide the last items
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    itemCount: filteredTracks.length,
                    itemBuilder: (context, index) {
                      final track = filteredTracks[index];
                      final isPlaying = player.currentTrack?.id == track.id;

                      return GestureDetector(
                        onTap: () {
                          player.playTrack(track, newQueue: filteredTracks);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              // Album Art Square
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: QueryArtworkWidget(
                                  id: track.albumId ?? 0,
                                  type: ArtworkType.ALBUM,
                                  artworkBorder: BorderRadius.circular(8),
                                  keepOldArtwork: true,
                                  nullArtworkWidget: const Center(
                                    child: Icon(
                                      Icons.music_note_rounded,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Track Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      track.title,
                                      style: AppTypography.body(
                                        size: 15,
                                        weight: FontWeight.w600,
                                        color: isPlaying
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${track.artist} • ${track.formattedDuration}',
                                      style: AppTypography.label(
                                        size: 12,
                                        color: AppColors.textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Options / More
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  color: AppColors.textMuted,
                                ),
                                color: Theme.of(context).cardColor,
                                onSelected: (value) {
                                  if (value == 'remove') {
                                    player.removeTrack(track);
                                  } else if (value == 'add_playlist') {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) =>
                                          FractionallySizedBox(
                                            heightFactor: 0.6,
                                            child: AddToPlaylistSheet(
                                              track: track,
                                            ),
                                          ),
                                    );
                                  }
                                },
                                itemBuilder: (BuildContext context) => [
                                  PopupMenuItem(
                                    value: 'add_playlist',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.playlist_add_rounded,
                                          color: AppColors.textMuted,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Add to Playlist',
                                          style: AppTypography.body(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'remove',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Remove from Library',
                                          style: AppTypography.body(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
