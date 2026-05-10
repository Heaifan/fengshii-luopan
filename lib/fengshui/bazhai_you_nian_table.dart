import 'package:flutter/material.dart';

// ==========================================
// Bazhai Star Meta (no rank — rank is dynamic per house group)
// ==========================================

class BazhaiStarMeta {
  final String name;
  final String element;
  final bool isGood;
  final Color color;
  const BazhaiStarMeta(this.name, this.element, this.isGood, this.color);
}

const bazhaiStarMetaMap = <String, BazhaiStarMeta>{
  '生气': BazhaiStarMeta('生气', '木', true, Color(0xFF2E7D32)),
  '天医': BazhaiStarMeta('天医', '土', true, Color(0xFF9A7A2F)),
  '延年': BazhaiStarMeta('延年', '金', true, Color(0xFF8A6A30)),
  '伏位': BazhaiStarMeta('伏位', '木', true, Color(0xFF2E7D32)),
  '绝命': BazhaiStarMeta('绝命', '金', false, Color(0xFF8A6A30)),
  '五鬼': BazhaiStarMeta('五鬼', '火', false, Color(0xFFC43C32)),
  '六煞': BazhaiStarMeta('六煞', '水', false, Color(0xFF2A5D84)),
  '祸害': BazhaiStarMeta('祸害', '土', false, Color(0xFF9A7A2F)),
};

// ==========================================
// House group
// ==========================================

const houseGroupMap = <String, String>{
  '坎': '东四宅', '离': '东四宅', '震': '东四宅', '巽': '东四宅',
  '乾': '西四宅', '兑': '西四宅', '艮': '西四宅', '坤': '西四宅',
};

String getHouseGroup(String houseGua) => houseGroupMap[houseGua] ?? '';

// ==========================================
// Star rank by house group
// ==========================================

const eastFourStarRankMap = <String, String>{
  '生气': '一吉', '天医': '二吉', '延年': '三吉', '伏位': '四吉',
  '绝命': '一凶', '五鬼': '二凶', '六煞': '三凶', '祸害': '四凶',
};

const westFourStarRankMap = <String, String>{
  '延年': '一吉', '天医': '二吉', '生气': '三吉', '伏位': '四吉',
  '绝命': '一凶', '五鬼': '二凶', '六煞': '三凶', '祸害': '四凶',
};

String getBazhaiStarRank({required String houseGua, required String starName}) {
  final group = houseGroupMap[houseGua];
  if (group == '东四宅') return eastFourStarRankMap[starName] ?? '';
  if (group == '西四宅') return westFourStarRankMap[starName] ?? '';
  return '';
}

// ==========================================
// Bazhai You Nian full table (house gua → palace gua → star)
// ==========================================

const bazhaiYouNianMap = <String, Map<String, String>>{
  '乾': {
    '乾': '伏位', '兑': '生气', '艮': '天医', '坤': '延年',
    '离': '绝命', '震': '五鬼', '巽': '祸害', '坎': '六煞',
  },
  '兑': {
    '兑': '伏位', '乾': '生气', '坤': '天医', '艮': '延年',
    '震': '绝命', '离': '五鬼', '坎': '祸害', '巽': '六煞',
  },
  '艮': {
    '艮': '伏位', '坤': '生气', '乾': '天医', '兑': '延年',
    '巽': '绝命', '坎': '五鬼', '离': '祸害', '震': '六煞',
  },
  '坤': {
    '坤': '伏位', '艮': '生气', '兑': '天医', '乾': '延年',
    '坎': '绝命', '巽': '五鬼', '震': '祸害', '离': '六煞',
  },
  '坎': {
    '坎': '伏位', '巽': '生气', '震': '天医', '离': '延年',
    '坤': '绝命', '艮': '五鬼', '兑': '祸害', '乾': '六煞',
  },
  '离': {
    '离': '伏位', '震': '生气', '巽': '天医', '坎': '延年',
    '乾': '绝命', '兑': '五鬼', '艮': '祸害', '坤': '六煞',
  },
  '震': {
    '震': '伏位', '离': '生气', '坎': '天医', '巽': '延年',
    '兑': '绝命', '乾': '五鬼', '坤': '祸害', '艮': '六煞',
  },
  '巽': {
    '巽': '伏位', '坎': '生气', '离': '天医', '震': '延年',
    '艮': '绝命', '坤': '五鬼', '乾': '祸害', '兑': '六煞',
  },
};

String getBazhaiStar({required String houseGua, required String palaceGua}) {
  return bazhaiYouNianMap[houseGua]?[palaceGua] ?? '';
}
