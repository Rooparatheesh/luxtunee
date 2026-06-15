// lib/data/models/artist_model.dart

class ArtistModel {
  final String id;
  final String name;
  final String imageUrl;
  final String genre;
  final bool isSelected;
  final int monthlyListeners;

  const ArtistModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.genre,
    this.isSelected = false,
    this.monthlyListeners = 0,
  });

  ArtistModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? genre,
    bool? isSelected,
    int? monthlyListeners,
  }) => ArtistModel(
    id: id ?? this.id,
    name: name ?? this.name,
    imageUrl: imageUrl ?? this.imageUrl,
    genre: genre ?? this.genre,
    isSelected: isSelected ?? this.isSelected,
    monthlyListeners: monthlyListeners ?? this.monthlyListeners,
  );
}
