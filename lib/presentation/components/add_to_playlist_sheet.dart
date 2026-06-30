// lib/presentation/components/add_to_playlist_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/track_model.dart';
import '../../providers/playlist_provider.dart';
import '../../theme/app_theme.dart';

class AddToPlaylistSheet extends StatelessWidget {
  final TrackModel track;

  const AddToPlaylistSheet({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add to Playlist', style: AppTypography.heading(size: 18)),
                TextButton.icon(
                  onPressed: () {
                    _showCreatePlaylistDialog(context);
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('New'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: Consumer<PlaylistProvider>(
              builder: (context, provider, child) {
                if (provider.playlists.isEmpty) {
                  return const Center(
                    child: Text('No playlists yet. Create one!'),
                  );
                }

                return ListView.builder(
                  itemCount: provider.playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = provider.playlists[index];
                    final isAlreadyAdded = playlist.tracks.any(
                      (t) => t.id == track.id,
                    );

                    return ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.queue_music,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        playlist.title,
                        style: AppTypography.body(weight: FontWeight.w600),
                      ),
                      subtitle: Text('${playlist.tracks.length} tracks'),
                      trailing: isAlreadyAdded
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        if (isAlreadyAdded) {
                          provider.removeTrackFromPlaylist(
                            playlist.id,
                            track.id,
                          );
                        } else {
                          provider.addTrackToPlaylist(playlist.id, track);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to ${playlist.title}'),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Playlist'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Playlist Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  context.read<PlaylistProvider>().createPlaylist(name);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
