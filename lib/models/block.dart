enum BlockType {
  cat1, // Yellow / Calico cat
  cat2, // White / Grey cat
  cat3, // Brown / Tabby cat
  bomb, // Explodes surroundings
  lightning, // Zaps line or random
  ice, // Requires 2 clears
  gift, // Reward block
  sealed, // Chained block, cannot be slid
}

class CatBlock {
  final String id;
  int col; // 0 to 7
  int row; // 0 (bottom) to 9 (top)
  final int width; // 1, 2, 3, or 4 cells
  BlockType type;
  int health; // 2 for ice, 1 for normal
  int bombCountdown;
  bool isClearing;
  bool isFalling;

  CatBlock({
    required this.id,
    required this.col,
    required this.row,
    required this.width,
    required this.type,
    this.health = 1,
    this.bombCountdown = 5,
    this.isClearing = false,
    this.isFalling = false,
  }) {
    if (type == BlockType.ice) {
      health = 2;
    }
  }

  List<int> get occupiedCols {
    return List.generate(width, (i) => col + i);
  }

  String get spriteAsset {
    final w = width.clamp(1, 4);
    switch (type) {
      case BlockType.cat1:
        return 'assets/images/sprites/cats/gameplay_cat1_${w}cell.png';
      case BlockType.cat2:
        return 'assets/images/sprites/cats/gameplay_cat2_${w}cell.png';
      case BlockType.cat3:
        return 'assets/images/sprites/cats/gameplay_cat3_${w}cell.png';
      case BlockType.bomb:
        return 'assets/images/sprites/cats/gameplay_bomb_${w}cell.png';
      case BlockType.lightning:
        return 'assets/images/sprites/cats/gameplay_lightning_${w}cell.png';
      case BlockType.ice:
        return 'assets/images/sprites/cats/gameplay_ice_${w}cell.png';
      case BlockType.gift:
        return 'assets/images/sprites/cats/gameplay_gift_${w}cell.png';
      case BlockType.sealed:
        return 'assets/images/sprites/cats/gameplay_cat3_${w}cell.png';
    }
  }

  /// Original 36px-tall sprite specifically designed for the bottom preview slot
  String get previewSpriteAsset {
    final w = width.clamp(1, 4);
    switch (type) {
      case BlockType.cat1:
        return 'assets/images/sprites/cats/next_block_cat_01_${w}cell.png';
      case BlockType.cat2:
        return 'assets/images/sprites/cats/next_block_cat_02_${w}cell.png';
      case BlockType.cat3:
        return 'assets/images/sprites/cats/next_block_cat_03_${w}cell.png';
      case BlockType.bomb:
        return 'assets/images/sprites/cats/next_block_cat_bomb_${w}cell.png';
      case BlockType.lightning:
        return 'assets/images/sprites/cats/next_block_cat_electric_${w}cell.png';
      case BlockType.ice:
        return 'assets/images/sprites/cats/next_block_cat_ice_${w}cell.png';
      case BlockType.gift:
        return 'assets/images/sprites/cats/next_block_cat_gift_${w}cell.png';
      case BlockType.sealed:
        if (w <= 2) {
          return 'assets/images/sprites/cats/next_block_cat_xich_block_${w}cell.png';
        }
        return 'assets/images/sprites/cats/next_block_cat_03_${w}cell.png';
    }
  }

  CatBlock clone() {
    return CatBlock(
      id: id,
      col: col,
      row: row,
      width: width,
      type: type,
      health: health,
      isClearing: isClearing,
      isFalling: isFalling,
    );
  }
}
