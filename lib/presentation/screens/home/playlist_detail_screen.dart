// lib/presentation/screens/home/playlist_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart' hide PlaylistModel;
import '../../../data/models/playlist_model.dart';
import '../../../providers/playlist_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/explore_provider.dart';
import '../../../theme/app_theme.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final PlaylistModel playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  void _showRenameDialog(BuildContext context, PlaylistProvider provider) {
    final controller = TextEditingController(text: playlist.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'New Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                provider.renamePlaylist(playlist.id, newName);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, provider, child) {
        // Find the latest version of the playlist in case it was updated
        final currentPlaylist = provider.playlists.firstWhere(
          (p) => p.id == playlist.id,
          orElse: () => playlist,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(currentPlaylist.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showRenameDialog(context, provider),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Playlist?'),
                      content: const Text(
                        'Are you sure you want to delete this playlist? The songs will remain in your library.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          onPressed: () {
                            provider.deletePlaylist(currentPlaylist.id);
                            Navigator.pop(context);
                            Navigator.pop(context); // Go back to Library
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: currentPlaylist.tracks.isEmpty
              ? const Center(child: Text('No songs in this playlist yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: currentPlaylist.tracks.length,
                  itemBuilder: (context, index) {
                    final track = currentPlaylist.tracks[index];
                    final player = context.watch<PlayerProvider>();
                    final isPlaying = player.currentTrack?.id == track.id;

                    return ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: QueryArtworkWidget(
                          id: track.albumId ?? 0,
                          type: ArtworkType.ALBUM,
                          artworkBorder: BorderRadius.circular(8),
                          nullArtworkWidget: const Icon(
                            Icons.music_note_rounded,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      title: Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(
                          size: 15,
                          weight: FontWeight.w600,
                          color: isPlaying
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        '${track.artist} • ${track.formattedDuration}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label(color: AppColors.textMuted),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: AppColors.textMuted,
                        ),
                        onSelected: (value) {
                          if (value == 'remove') {
                            provider.removeTrackFromPlaylist(
                              currentPlaylist.id,
                              track.id,
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'remove',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Remove from Playlist',
                                  style: AppTypography.body(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        player.playTrack(
                          track,
                          urlResolver: track.source == 'youtube'
                              ? context.read<ExploreProvider>().getAudioUrl
                              : null,
                          newQueue: currentPlaylist.tracks,
                        );
                      },
                    );
                  },
                ),
          floatingActionButton: currentPlaylist.tracks.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () {
                    context.read<PlayerProvider>().playTrack(
                      currentPlaylist.tracks.first,
                      urlResolver:
                          currentPlaylist.tracks.first.source == 'youtube'
                          ? context.read<ExploreProvider>().getAudioUrl
                          : null,
                      newQueue: currentPlaylist.tracks,
                    );
                  },
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Play All',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                )
              : null,
        );
      },
    );
  }
}
