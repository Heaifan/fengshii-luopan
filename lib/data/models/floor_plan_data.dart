/// 宅盘门对象
class FloorPlanDoor {
  final String id;
  final String label;
  final String wall; // 'top' | 'bottom' | 'left' | 'right'
  final double widthCm;
  final double offsetCm; // 门距基准角
  final String offsetFrom; // 'left' | 'right' | 'top' | 'bottom'
  final bool isMainQiDoor;

  const FloorPlanDoor({
    this.id = 'main-door',
    this.label = '入户门',
    this.wall = 'bottom',
    this.widthCm = 90,
    this.offsetCm = 0,
    this.offsetFrom = 'left',
    this.isMainQiDoor = true,
  });

  FloorPlanDoor copyWith({
    String? id,
    String? label,
    String? wall,
    double? widthCm,
    double? offsetCm,
    String? offsetFrom,
    bool? isMainQiDoor,
  }) {
    return FloorPlanDoor(
      id: id ?? this.id,
      label: label ?? this.label,
      wall: wall ?? this.wall,
      widthCm: widthCm ?? this.widthCm,
      offsetCm: offsetCm ?? this.offsetCm,
      offsetFrom: offsetFrom ?? this.offsetFrom,
      isMainQiDoor: isMainQiDoor ?? this.isMainQiDoor,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'wall': wall,
        'widthCm': widthCm,
        'offsetCm': offsetCm,
        'offsetFrom': offsetFrom,
        'isMainQiDoor': isMainQiDoor,
      };

  factory FloorPlanDoor.fromJson(Map<String, dynamic> json) {
    return FloorPlanDoor(
      id: json['id'] as String? ?? 'main-door',
      label: json['label'] as String? ?? '入户门',
      wall: json['wall'] as String? ?? 'bottom',
      widthCm: (json['widthCm'] as num?)?.toDouble() ?? 90,
      offsetCm: (json['offsetCm'] as num?)?.toDouble() ?? 0,
      offsetFrom: json['offsetFrom'] as String? ?? 'left',
      isMainQiDoor: json['isMainQiDoor'] as bool? ?? true,
    );
  }
}

/// 宅盘图层显示开关
class FloorPlanOverlays {
  final bool showGrid;
  final bool showTwentyFourMountains;
  final bool showEightPalaces;
  final bool showTaijiLines;
  final bool showDoorMeasure;

  const FloorPlanOverlays({
    this.showGrid = true,
    this.showTwentyFourMountains = true,
    this.showEightPalaces = false,
    this.showTaijiLines = false,
    this.showDoorMeasure = true,
  });

  FloorPlanOverlays copyWith({
    bool? showGrid,
    bool? showTwentyFourMountains,
    bool? showEightPalaces,
    bool? showTaijiLines,
    bool? showDoorMeasure,
  }) {
    return FloorPlanOverlays(
      showGrid: showGrid ?? this.showGrid,
      showTwentyFourMountains:
          showTwentyFourMountains ?? this.showTwentyFourMountains,
      showEightPalaces: showEightPalaces ?? this.showEightPalaces,
      showTaijiLines: showTaijiLines ?? this.showTaijiLines,
      showDoorMeasure: showDoorMeasure ?? this.showDoorMeasure,
    );
  }

  Map<String, dynamic> toJson() => {
        'showGrid': showGrid,
        'showTwentyFourMountains': showTwentyFourMountains,
        'showEightPalaces': showEightPalaces,
        'showTaijiLines': showTaijiLines,
        'showDoorMeasure': showDoorMeasure,
      };

  factory FloorPlanOverlays.fromJson(Map<String, dynamic> json) {
    return FloorPlanOverlays(
      showGrid: json['showGrid'] as bool? ?? true,
      showTwentyFourMountains:
          json['showTwentyFourMountains'] as bool? ?? true,
      showEightPalaces: json['showEightPalaces'] as bool? ?? true,
      showTaijiLines: json['showTaijiLines'] as bool? ?? false,
      showDoorMeasure: json['showDoorMeasure'] as bool? ?? true,
    );
  }
}

/// 宅盘数据结构，按 projectId 独立保存
class FloorPlanData {
  final int version;
  final double widthCm;
  final double heightCm;
  final String gridMode; // 'grid4' | 'grid7'
  final String? sittingMountain;
  final String? facingMountain;
  final String topSideRole; // 'facing' | 'sitting'
  final FloorPlanDoor? mainDoor;
  final FloorPlanOverlays overlays;

  const FloorPlanData({
    this.version = 1,
    required this.widthCm,
    required this.heightCm,
    this.gridMode = 'grid7',
    this.sittingMountain,
    this.facingMountain,
    this.topSideRole = 'facing',
    this.mainDoor,
    this.overlays = const FloorPlanOverlays(),
  });

  FloorPlanData copyWith({
    int? version,
    double? widthCm,
    double? heightCm,
    String? gridMode,
    String? sittingMountain,
    String? facingMountain,
    String? topSideRole,
    FloorPlanDoor? mainDoor,
    FloorPlanOverlays? overlays,
    bool clearDirection = false,
    bool clearDoor = false,
  }) {
    return FloorPlanData(
      version: version ?? this.version,
      widthCm: widthCm ?? this.widthCm,
      heightCm: heightCm ?? this.heightCm,
      gridMode: gridMode ?? this.gridMode,
      sittingMountain: clearDirection ? null : (sittingMountain ?? this.sittingMountain),
      facingMountain: clearDirection ? null : (facingMountain ?? this.facingMountain),
      topSideRole: topSideRole ?? this.topSideRole,
      mainDoor: clearDoor ? null : (mainDoor ?? this.mainDoor),
      overlays: overlays ?? this.overlays,
    );
  }

  /// 横竖交换
  FloorPlanData swapDimensions() {
    var door = mainDoor;
    if (door != null) {
      final oldWall = door.wall;
      final oldOffset = door.offsetCm;
      final newWall = _swapWall(oldWall);
      final maxOffset = (newWall == 'top' || newWall == 'bottom')
          ? heightCm - door.widthCm
          : widthCm - door.widthCm;
      final clamped = oldOffset.clamp(0, maxOffset).toDouble();
      final newOffsetFrom = switch (newWall) {
        'top' || 'bottom' => 'left',
        'left' || 'right' => 'top',
        _ => 'left',
      };
      door = door.copyWith(
          wall: newWall, offsetCm: clamped, offsetFrom: newOffsetFrom);
    }
    return FloorPlanData(
      version: version,
      widthCm: heightCm,
      heightCm: widthCm,
      gridMode: gridMode,
      sittingMountain: sittingMountain,
      facingMountain: facingMountain,
      topSideRole: topSideRole,
      mainDoor: door,
      overlays: overlays,
    );
  }

  static String _swapWall(String wall) {
    switch (wall) {
      case 'top': return 'left';
      case 'bottom': return 'right';
      case 'left': return 'top';
      case 'right': return 'bottom';
      default: return wall;
    }
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'widthCm': widthCm,
        'heightCm': heightCm,
        'gridMode': gridMode,
        'sittingMountain': sittingMountain,
        'facingMountain': facingMountain,
        'topSideRole': topSideRole,
        'mainDoor': mainDoor?.toJson(),
        'overlays': overlays.toJson(),
      };

  factory FloorPlanData.fromJson(Map<String, dynamic> json) {
    return FloorPlanData(
      version: json['version'] as int? ?? 1,
      widthCm: (json['widthCm'] as num?)?.toDouble() ?? 0,
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0,
      gridMode: json['gridMode'] as String? ?? 'grid7',
      sittingMountain: json['sittingMountain'] as String?,
      facingMountain: json['facingMountain'] as String?,
      topSideRole: json['topSideRole'] as String? ?? 'facing',
      mainDoor: json['mainDoor'] != null
          ? FloorPlanDoor.fromJson(json['mainDoor'] as Map<String, dynamic>)
          : null,
      overlays: json['overlays'] != null
          ? FloorPlanOverlays.fromJson(
              json['overlays'] as Map<String, dynamic>)
          : const FloorPlanOverlays(),
    );
  }
}
