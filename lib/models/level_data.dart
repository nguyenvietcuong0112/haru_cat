class LevelStarRequirement {
  final int starIndex;
  final int minMoves;

  LevelStarRequirement({
    required this.starIndex,
    required this.minMoves,
  });

  factory LevelStarRequirement.fromJson(Map<String, dynamic> json) {
    return LevelStarRequirement(
      starIndex: json['star_index'] as int? ?? 1,
      minMoves: json['min_moves'] as int? ?? 10,
    );
  }
}

class LevelBlockData {
  final int startPoint; // column
  final int size; // width (1..4)
  final int type; // 0, 1, 2, 3

  LevelBlockData({
    required this.startPoint,
    required this.size,
    required this.type,
  });

  factory LevelBlockData.fromJson(Map<String, dynamic> json) {
    return LevelBlockData(
      startPoint: json['start_point'] as int? ?? 0,
      size: json['size'] as int? ?? 1,
      type: json['type'] as int? ?? 0,
    );
  }
}

class LevelData {
  final String levelId;
  final String title;
  final List<List<LevelBlockData>> map;
  final List<LevelStarRequirement> requirements;

  LevelData({
    required this.levelId,
    required this.title,
    required this.map,
    required this.requirements,
  });

  factory LevelData.fromJson(String levelId, String title, Map<String, dynamic> json) {
    final rawMap = json['map'] as List<dynamic>? ?? [];
    final parsedMap = <List<LevelBlockData>>[];

    for (final row in rawMap) {
      if (row is List) {
        final rowBlocks = row
            .map((b) => LevelBlockData.fromJson(b as Map<String, dynamic>))
            .toList();
        parsedMap.add(rowBlocks);
      }
    }

    final rawDetails = json['level_detail'] as List<dynamic>? ?? [];
    final parsedReqs = rawDetails
        .map((r) => LevelStarRequirement.fromJson(r as Map<String, dynamic>))
        .toList();

    return LevelData(
      levelId: levelId,
      title: title,
      map: parsedMap,
      requirements: parsedReqs,
    );
  }

  int getStars(int movesUsed) {
    // Requirements usually sorted descending by star_index: 3 stars <= min_moves_3, 2 stars <= min_moves_2, etc.
    final threeStar = requirements.firstWhere((r) => r.starIndex == 3, orElse: () => LevelStarRequirement(starIndex: 3, minMoves: 3));
    final twoStar = requirements.firstWhere((r) => r.starIndex == 2, orElse: () => LevelStarRequirement(starIndex: 2, minMoves: 6));
    final oneStar = requirements.firstWhere((r) => r.starIndex == 1, orElse: () => LevelStarRequirement(starIndex: 1, minMoves: 10));

    if (movesUsed <= threeStar.minMoves) return 3;
    if (movesUsed <= twoStar.minMoves) return 2;
    if (movesUsed <= oneStar.minMoves) return 1;
    return 1;
  }
}
