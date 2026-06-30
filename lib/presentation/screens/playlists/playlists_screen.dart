// lib/presentation/screens/playlists/playlists_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/playlist_provider.dart';
import '../../../theme/app_theme.dart';
import '../home/playlist_detail_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Playlists', style: AppTypography.heading(size: 24)),
        centerTitle: false,
      ),
      body: Consumer<PlaylistProvider>(
        builder: (context, playlistProvider, child) {
          if (playlistProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final playlists = playlistProvider.playlists;

          return Stack(
            children: [
              if (playlists.isEmpty)
                Center(
                  child: Text(
                    'No playlists found',
                    style: AppTypography.body(color: AppColors.textMuted),
                  ),
                )
              else
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 56,
                        height: 56,
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
                      subtitle: Text(
                        '${playlist.tracks.length} tracks',
                        style: AppTypography.label(color: AppColors.textMuted),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PlaylistDetailScreen(playlist: playlist),
                          ),
                        );
                      },
                    );
                  },
                ),
              Positioned(
                bottom: 80,
                right: 24,
                child: FloatingActionButton(
                  onPressed: () {
                    _showCreatePlaylistDialog(context);
                  },
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          );
        },
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
