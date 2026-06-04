class StarPalaceRelation {
  final String type; // 比和 / 星生宫 / 宫生星 / 星克宫 / 宫克星
  final String detail; // e.g. "水生木"
  final String description;

  const StarPalaceRelation({
    required this.type,
    required this.detail,
    required this.description,
  });
}

/// Palace → element mapping.
String palaceElement(String gua) {
  switch (gua) {
    case '坎':
      return '水';
    case '坤':
    case '艮':
    case '中':
      return '土';
    case '震':
    case '巽':
      return '木';
    case '乾':
    case '兑':
      return '金';
    case '离':
      return '火';
    default:
      return '土';
  }
}

/// Bazhai star → element mapping.
String starElement(String star) {
  switch (star) {
    case '生气':
    case '伏位':
      return '木';
    case '天医':
    case '祸害':
      return '土';
    case '延年':
    case '绝命':
      return '金';
    case '五鬼':
      return '火';
    case '六煞':
      return '水';
    default:
      return '土';
  }
}

bool _generates(String a, String b) {
  const map = {
    '木': '火',
    '火': '土',
    '土': '金',
    '金': '水',
    '水': '木',
  };
  return map[a] == b;
}

bool _controls(String a, String b) {
  const map = {
    '木': '土',
    '土': '水',
    '水': '火',
    '火': '金',
    '金': '木',
  };
  return map[a] == b;
}

StarPalaceRelation resolveStarPalaceRelation({
  required String palaceGua,
  required String starName,
}) {
  final pe = palaceElement(palaceGua);
  final se = starElement(starName);

  if (pe == se) {
    return StarPalaceRelation(
      type: '比和',
      detail: '$pe同气',
      description: '星与宫五行相同，气性相合。',
    );
  }
  if (_generates(se, pe)) {
    return StarPalaceRelation(
      type: '星生宫',
      detail: '$se生$pe',
      description: '八宅星生宫位，星气助宫。',
    );
  }
  if (_generates(pe, se)) {
    return StarPalaceRelation(
      type: '宫生星',
      detail: '$pe生$se',
      description: '宫位生八宅星，宫气助星。',
    );
  }
  if (_controls(se, pe)) {
    return StarPalaceRelation(
      type: '星克宫',
      detail: '$se克$pe',
      description: '八宅星克宫位，星气制宫。',
    );
  }
  if (_controls(pe, se)) {
    return StarPalaceRelation(
      type: '宫克星',
      detail: '$pe克$se',
      description: '宫位克八宅星，宫气制星。',
    );
  }
  return const StarPalaceRelation(
    type: '未知', detail: '', description: '',
  );
}

/// Build a human-readable good/bad hint combining bazhai rank and star-palace relation.
///
/// [bazhaiRank] is like "一凶" / "二吉" / "三吉" / "一吉".
/// [relationType] is like "比和" / "星生宫" / "宫生星" / "星克宫" / "宫克星".
/// Returns a sentence like "一凶，且宫克星，偏受制".
String buildGoodBadHint({
  required String bazhaiRank,
  required String relationType,
}) {
  String relationHint;
  switch (relationType) {
    case '比和':
      relationHint = '比和同气，较稳';
    case '星生宫':
      relationHint = '星生宫，偏顺';
    case '宫生星':
      relationHint = '宫生星，偏顺';
    case '星克宫':
      relationHint = '星克宫，偏冲克';
    case '宫克星':
      relationHint = '宫克星，偏受制';
    default:
      relationHint = '星与宫关系待定';
  }

  if (bazhaiRank.isEmpty) return '待定';
  return '$bazhaiRank，且$relationHint';
}
