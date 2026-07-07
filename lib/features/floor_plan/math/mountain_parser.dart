import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../data/models/floor_plan_data.dart';
import '../../../fengshui/bagua.dart';
import '../../../fengshui/bazhai_you_nian_table.dart';
import '../../../fengshui/direction_sector.dart';

/// 二十四山基础顺序
const List<String> kMountains24 = [
  '子', '癸', '丑', '艮', '寅', '甲',
  '卯', '乙', '辰', '巽', '巳', '丙',
  '午', '丁', '未', '坤', '申', '庚',
  '酉', '辛', '戌', '乾', '亥', '壬',
];

/// 天地人三元色
const Map<String, Color3> kSanyuanColor = {
  '子': Color3.red, '午': Color3.red, '卯': Color3.red, '酉': Color3.red,
  '乾': Color3.red, '坤': Color3.red, '艮': Color3.red, '巽': Color3.red,
  '甲': Color3.blue, '庚': Color3.blue, '丙': Color3.blue, '壬': Color3.blue,
  '辰': Color3.blue, '戌': Color3.blue, '丑': Color3.blue, '未': Color3.blue,
  '乙': Color3.green, '辛': Color3.green, '丁': Color3.green, '癸': Color3.green,
  '寅': Color3.green, '申': Color3.green, '巳': Color3.green, '亥': Color3.green,
};

enum Color3 { red, blue, green }

int color3Value(Color3 c) {
  switch (c) {
    case Color3.red: return 0xFFC62828;
    case Color3.blue: return 0xFF2A5D84;
    case Color3.green: return 0xFF4A7741;
  }
}

String color3Label(Color3 c) {
  switch (c) {
    case Color3.red: return '天元';
    case Color3.blue: return '地元';
    case Color3.green: return '人元';
  }
}

/// 24 组正对坐向
const List<List<String>> kSittingFacingPairs = [
  ['壬山丙向', '壬', '丙'],
  ['子山午向', '子', '午'],
  ['癸山丁向', '癸', '丁'],
  ['丑山未向', '丑', '未'],
  ['艮山坤向', '艮', '坤'],
  ['寅山申向', '寅', '申'],
  ['甲山庚向', '甲', '庚'],
  ['卯山酉向', '卯', '酉'],
  ['乙山辛向', '乙', '辛'],
  ['辰山戌向', '辰', '戌'],
  ['巽山乾向', '巽', '乾'],
  ['巳山亥向', '巳', '亥'],
  ['丙山壬向', '丙', '壬'],
  ['午山子向', '午', '子'],
  ['丁山癸向', '丁', '癸'],
  ['未山丑向', '未', '丑'],
  ['坤山艮向', '坤', '艮'],
  ['申山寅向', '申', '寅'],
  ['庚山甲向', '庚', '甲'],
  ['酉山卯向', '酉', '卯'],
  ['辛山乙向', '辛', '乙'],
  ['戌山辰向', '戌', '辰'],
  ['乾山巽向', '乾', '巽'],
  ['亥山巳向', '亥', '巳'],
];

/// 获取二十四山外框 7/5/7/5 排布
/// 返回 [top(7), right(5), bottom(7), left(5)]
List<List<String>> getMountainsAroundRect(FloorPlanData data) {
  final facing = data.facingMountain;
  final sitting = data.sittingMountain;
  if (facing == null || sitting == null) return _defaultLayout();

  final facIdx = kMountains24.indexOf(facing);
  if (facIdx < 0) return _defaultLayout();

  return [
    // top: 7 (facingMountain at top[3])
    List.generate(7, (i) => kMountains24[(facIdx - 3 + i) % 24]),
    // right: 5
    List.generate(5, (i) => kMountains24[(facIdx + 4 + i) % 24]),
    // bottom: 7 (从左到右，facing+9..facing+15 的逆序)
    List.generate(7, (i) => kMountains24[(facIdx + 15 - i) % 24]),
    // left: 5 (从上到下)
    List.generate(5, (i) => kMountains24[(facIdx + 20 - i) % 24]),
  ];
}

List<List<String>> _defaultLayout() {
  return [
    ['辰', '巽', '巳', '丙', '午', '丁', '未'],
    ['坤', '申', '庚', '酉', '辛'],
    ['丑', '癸', '子', '壬', '亥', '乾', '戌'],
    ['乙', '卯', '甲', '寅', '艮'],
  ];
}

/// 坐向标签
String sittingFacingLabel(FloorPlanData data) {
  if (data.sittingMountain == null || data.facingMountain == null) {
    return '未设置坐向';
  }
  final pair = kSittingFacingPairs.where((p) =>
      p[1] == data.sittingMountain && p[2] == data.facingMountain);
  if (pair.isNotEmpty) return pair.first[0];
  return '${data.sittingMountain}山${data.facingMountain}向';
}

/// 从坐向对找到 facingMountain 的 compass 角度（度）
double facingAngle(String facing) {
  final idx = kMountains24.indexOf(facing);
  if (idx < 0) return 0;
  return idx * 15.0;
}

/// 从宅心到门中点计算 heading
/// 图纸上方 = facingMountain 方向
double doorCenterToHeading(FloorPlanData data) {
  final door = data.mainDoor;
  if (door == null || data.facingMountain == null) return 0;
  final cw = data.widthCm / 2, ch = data.heightCm / 2;

  // 门中点 cm 坐标
  double dx = door.offsetCm + door.widthCm / 2;
  if (door.offsetFrom == 'right' || door.offsetFrom == 'bottom') {
    final len = (door.wall == 'top' || door.wall == 'bottom')
        ? data.widthCm : data.heightCm;
    dx = len - door.offsetCm - door.widthCm / 2;
  }
  double dy;
  switch (door.wall) {
    case 'top': dy = 0; break;
    case 'bottom': dy = data.heightCm; break;
    case 'left': dy = dx; dx = 0; break;
    case 'right': dy = dx; dx = data.widthCm; break;
    default: dy = data.heightCm / 2;
  }

  // 相对宅心的纸面方向角（上=0°, 右=90°）
  final paperDx = dx - cw, paperDy = dy - ch;
  var paperAngle = math.atan2(paperDx, -paperDy) * 180 / math.pi;
  if (paperAngle < 0) paperAngle += 360;

  // 加上 facingMountain 的实际罗盘角度
  return (facingAngle(data.facingMountain!) + paperAngle) % 360;
}

/// 计算八宫结果
class PalaceResult {
  final String gua;        // 卦名 乾兑离震...
  final String star;       // 星名 伏位生气延年...
  final bool isAuspicious;
  final String rank;       // 一吉、二吉、一凶、二凶...
  PalaceResult({
    required this.gua,
    required this.star,
    required this.isAuspicious,
    this.rank = '',
  });
}

/// 命中检测结果：包含宫位结果及其在画布上的外接矩形
class PalaceHitInfo {
  final PalaceResult palace;
  final Rect rect;
  const PalaceHitInfo({required this.palace, required this.rect});
}

Map<String, PalaceResult> calculateEightPalaces(FloorPlanData data) {
  final door = data.mainDoor;
  if (door == null || data.facingMountain == null) {
    return {};
  }
  final heading = doorCenterToHeading(data);
  final sector = DirectionSector.sector8FromHeading(heading);
  final doorGua = DirectionSector.sectorToGua(sector);
  if (doorGua.isEmpty) return {};

  const guas = ['乾', '兑', '艮', '坤', '坎', '震', '巽', '离'];
  final results = <String, PalaceResult>{};
  for (final g in guas) {
    final star = getBazhaiStar(houseGua: doorGua, palaceGua: g);
    final meta = bazhaiStarMetaMap[star];
    results[g] = PalaceResult(
      gua: g,
      star: star,
      isAuspicious: meta?.isGood ?? false,
      rank: getBazhaiStarRank(houseGua: doorGua, starName: star),
    );
  }
  return results;
}

/// 山盘八宫：以坐山所在卦宫为伏位，按大游年顺布八星
/// 与宫盘（以门定向）独立，故两者伏位可能不同
Map<String, PalaceResult> calculateMountainPalaces(FloorPlanData data) {
  final sitting = data.sittingMountain;
  if (sitting == null) return {};
  final houseGua = BaguaCalculator.fromMountain(sitting);
  if (houseGua == '未知' || houseGua.isEmpty) return {};

  const guas = ['乾', '兑', '艮', '坤', '坎', '震', '巽', '离'];
  final results = <String, PalaceResult>{};
  for (final g in guas) {
    final star = getBazhaiStar(houseGua: houseGua, palaceGua: g);
    final meta = bazhaiStarMetaMap[star];
    results[g] = PalaceResult(
      gua: g,
      star: star,
      isAuspicious: meta?.isGood ?? false,
      rank: getBazhaiStarRank(houseGua: houseGua, starName: star),
    );
  }
  return results;
}

/// 穿宫判定：星之本位宫位与当前宫位形成对冲（洛书对冲）
bool isChuanGong(String currentGua, String starName) {
  const starHomeGua = <String, String>{
    '生气': '震',
    '天医': '艮',
    '延年': '乾',
    '伏位': '', // 随宅卦，不判定
    '绝命': '兑',
    '五鬼': '离',
    '六煞': '坎',
    '祸害': '坤',
  };
  final homeGua = starHomeGua[starName];
  if (homeGua == null || homeGua.isEmpty) return false;

  const opposites = {
    '坎': '离', '离': '坎',
    '坤': '艮', '艮': '坤',
    '震': '兑', '兑': '震',
    '巽': '乾', '乾': '巽',
  };
  return opposites[homeGua] == currentGua;
}
