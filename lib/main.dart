import 'package:flutter/material.dart';

import 'fengshui/mountain_24.dart';
import 'fengshui/bagua.dart';
import 'fengshui/bazhai.dart';
import 'fengshui/sanyuan_dragon.dart';
import 'fengshui/compass_math.dart';

void main() {
  runApp(const BazhaiCompassApp());
}

class BazhaiCompassApp extends StatelessWidget {
  const BazhaiCompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '测向工具',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
      ),
      home: const RuleTestPage(),
    );
  }
}

class RuleTestPage extends StatefulWidget {
  const RuleTestPage({super.key});

  @override
  State<RuleTestPage> createState() => _RuleTestPageState();
}

class _RuleTestPageState extends State<RuleTestPage> {
  double _degree = 226;
  String _houseGua = '乾';

  @override
  Widget build(BuildContext context) {
    final facing = Mountain24Calculator.fromDegree(_degree);
    final sitting = Mountain24Calculator.fromDegree(oppositeDegree(_degree));
    final gua = BaguaCalculator.fromMountain(facing.mountain);
    final sanyuan = SanyuanDragonCalculator.fromMountain(facing.mountain);
    final bazhai = BazhaiCalculator.getStar(
      houseGua: _houseGua,
      targetGua: gua,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('规则测试'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '角度：${_degree.toStringAsFixed(0)}°',
              style: const TextStyle(fontSize: 32),
            ),
            Slider(
              min: 0,
              max: 359,
              divisions: 359,
              value: _degree,
              onChanged: (v) => setState(() => _degree = v),
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: _houseGua,
              items: BazhaiCalculator.guas
                  .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text('$g宅',
                            style: const TextStyle(fontSize: 18)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _houseGua = v);
              },
            ),
            const SizedBox(height: 24),
            _InfoRow(label: '向山', value: facing.mountain),
            _InfoRow(label: '坐山', value: sitting.mountain),
            _InfoRow(
                label: '向坐',
                value: '坐${sitting.mountain}向${facing.mountain}'),
            _InfoRow(label: '宫位', value: '$gua宫'),
            _InfoRow(label: '三元龙', value: sanyuan.label),
            _InfoRow(label: '八宅星', value: bazhai.star),
            _InfoRow(
                label: '吉凶', value: bazhai.isAuspicious ? '吉' : '凶'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child:
                  Text(label, style: const TextStyle(fontSize: 16))),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
