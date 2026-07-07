import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/models/floor_plan_data.dart';
import '../../data/models/measurement_project.dart';
import '../../data/storage/settings_storage.dart';
import 'math/door_position_math.dart';
import 'painter/floor_plan_painter.dart';
import 'widgets/floor_plan_size_panel.dart';
import 'widgets/floor_plan_direction_panel.dart';
import 'widgets/floor_plan_door_edit_panel.dart';
import 'widgets/floor_plan_toolbar.dart';
import 'widgets/palace_detail_dialog.dart';
import 'widgets/mountain_detail_dialog.dart';
import 'painter/draw_floor_plan_eight_palace.dart';
import 'painter/draw_floor_plan_mountains.dart';

class FloorPlanPage extends StatefulWidget {
  final MeasurementProject project;
  const FloorPlanPage({super.key, required this.project});

  @override
  State<FloorPlanPage> createState() => _FloorPlanPageState();
}

class _FloorPlanPageState extends State<FloorPlanPage> {
  final _storage = SettingsStorage();
  final TransformationController _transformCtrl = TransformationController();
  FloorPlanData? _data;
  bool _loading = true;
  static const double _canvasBase = 600;
  double _canvasW = 600;
  double _canvasH = 600;
  // ---- 对象编辑交互（长按进入编辑模式，全局通用） ----
  String? _editObjectId; // 当前处于编辑/可拖动状态的对象 ID
  String? _pressedObjectId; // 按下时命中的对象 ID
  Timer? _longPressTimer;
  static const int _longPressMs = 600;
  static const double _longPressMoveThreshold = 8.0;

  Offset? _pointerDownViewport;
  DateTime? _pointerDownTime;
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;
  static const int _doubleTapMs = 300;
  static const double _doubleTapDist = 24.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _transformCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await _storage.loadFloorPlan(widget.project.id);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
    if (data != null) {
      _initCanvas(data);
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerView());
    }
  }

  void _initCanvas(FloorPlanData data) {
    final a = data.widthCm / data.heightCm;
    if (a >= 1) {
      _canvasW = _canvasBase * a;
      _canvasH = _canvasBase;
    } else {
      _canvasW = _canvasBase;
      _canvasH = _canvasBase / a;
    }
  }

  void _centerView() {
    if (!mounted) return;
    final s = MediaQuery.of(context).size;
    final th = 56.0;
    final aw = s.width,
        ah =
            s.height -
            kToolbarHeight -
            th -
            MediaQuery.of(context).padding.top -
            8;
    final sc =
        ((aw / _canvasW) < (ah / _canvasH)
            ? (aw / _canvasW)
            : (ah / _canvasH)) *
        0.9;
    _transformCtrl.value =
        Matrix4.translationValues(
          (aw - _canvasW * sc) / 2,
          (ah - _canvasH * sc) / 2,
          0,
        ) *
        Matrix4.diagonal3Values(sc, sc, 1);
  }

  /// 视口坐标（Stack 空间）→ 画布坐标
  Offset _viewportToCanvas(Offset vp) {
    final m = _transformCtrl.value.clone()..invert();
    return MatrixUtils.transformPoint(m, vp);
  }

  Rect? _floorRectOnCanvas() {
    if (_data == null) return null;
    const p = 40.0;
    final iw = _canvasW - p * 2, ih = _canvasH - p * 2;
    if (iw <= 0 || ih <= 0) return null;
    final a = _data!.widthCm / _data!.heightCm;
    final w = iw / ih > a ? ih * a : iw;
    final h = iw / ih > a ? ih : iw / a;
    return Offset((_canvasW - w) / 2, (_canvasH - h) / 2) & Size(w, h);
  }

  Future<void> _saveData(FloorPlanData d) async {
    await _storage.saveFloorPlan(widget.project.id, d);
    if (!mounted) return;
    setState(() {
      _data = d;
    });
    _initCanvas(d);
    _centerView();
  }

  // ---- 工具栏 ----
  void _onToolbarAction(FloorPlanToolAction a) {
    switch (a) {
      case FloorPlanToolAction.size:
        _showSizePanel();
      case FloorPlanToolAction.swap:
        _swapDimensions();
      case FloorPlanToolAction.direction:
        _showDirectionPanel();
      case FloorPlanToolAction.addDoor:
        _addOrEditDoor();
      case FloorPlanToolAction.grid:
        _cycleGrid();
      case FloorPlanToolAction.taijiLines:
        _toggleTaijiLines();
    }
  }

  void _toggleTaijiLines() {
    if (_data == null) return;
    final ov = _data!.overlays;
    _saveData(
      _data!.copyWith(
        overlays: ov.copyWith(showTaijiLines: !ov.showTaijiLines),
      ),
    );
  }

  Future<void> _showSizePanel() async {
    final r = await showFloorPlanSizePanel(context: context, existing: _data);
    if (r != null) await _saveData(r);
  }

  Future<void> _swapDimensions() async {
    if (_data == null) return;
    final s = _data!.swapDimensions();
    final had =
        _data!.mainDoor != null &&
        _data!.mainDoor!.offsetCm != s.mainDoor?.offsetCm;
    await _saveData(s);
    if (had && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('横竖交换后，门距已自动调整到合法范围')));
    }
  }

  Future<void> _showDirectionPanel() async {
    if (_data == null) return;
    final r = await showFloorPlanDirectionPanel(
      context: context,
      existing: _data!,
    );
    if (r != null) await _saveData(r);
  }

  Future<void> _addOrEditDoor() async {
    if (_data == null) return;
    if (_data!.mainDoor != null) {
      // 已有门 → 打开编辑面板
      final r = await showDoorEditPanel(context: context, data: _data!);
      if (r != null) {
        await _saveData(_data!.copyWith(mainDoor: r));
      } else if (r == null && _data!.mainDoor != null) {
        await _saveData(_data!.copyWith(clearDoor: true));
      }
      return;
    }
    final c = centeredOffset(_data!, 'bottom', 90);
    _saveData(
      _data!.copyWith(
        mainDoor: FloorPlanDoor(
          wall: 'bottom',
          widthCm: 90,
          offsetCm: c,
          offsetFrom: 'left',
        ),
      ),
    );
  }

  void _cycleGrid() {
    if (_data == null) return;
    final ov = _data!.overlays;
    if (ov.showGrid && _data!.gridMode == 'grid7') {
      // 山盘 -> 八宫
      _saveData(_data!.copyWith(gridMode: 'grid4'));
    } else if (ov.showGrid && _data!.gridMode == 'grid4') {
      // 八宫 -> 关网格
      _saveData(_data!.copyWith(overlays: ov.copyWith(showGrid: false)));
    } else {
      // 关 -> 山盘
      _saveData(
        _data!.copyWith(
          gridMode: 'grid7',
          overlays: ov.copyWith(showGrid: true),
        ),
      );
    }
  }

  // ---- 门命中检测（画布坐标空间） ----
  bool _isNearDoor(Offset cv, FloorPlanData data) {
    final door = data.mainDoor;
    if (door == null) return false;
    final seg = calcDoorSegment(data, door);
    final wLen = doorWallLength(data, door.wall);
    final rect = _floorRectOnCanvas();
    if (rect == null) return false;

    // 门在画布上的像素宽度
    final doorPx =
        (door.widthCm / wLen) *
        (door.wall == 'top' || door.wall == 'bottom'
            ? rect.width
            : rect.height);
    // 门中心画布坐标
    double cx, cy;
    switch (door.wall) {
      case 'top':
        cx = rect.left + (seg.centerCm / data.widthCm) * rect.width;
        cy = rect.top;
        break;
      case 'bottom':
        cx = rect.left + (seg.centerCm / data.widthCm) * rect.width;
        cy = rect.bottom;
        break;
      case 'left':
        cy = rect.top + (seg.centerCm / data.heightCm) * rect.height;
        cx = rect.left;
        break;
      case 'right':
        cy = rect.top + (seg.centerCm / data.heightCm) * rect.height;
        cx = rect.right;
        break;
      default:
        return false;
    }

    // 命中区域：门宽 × 60dp 矩形
    final hitW = (doorPx + 20).clamp(44.0, 200.0);
    final hitH = 60.0;
    final hitRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: hitW,
      height: hitH,
    );
    final hit = hitRect.contains(cv);
    dev.log(
      '【宅盘门命中】门中心=(${cx.toStringAsFixed(0)},${cy.toStringAsFixed(0)}) '
      '命中框=${hitRect.toString()} 点击=(${cv.dx.toStringAsFixed(0)},${cv.dy.toStringAsFixed(0)}) 命中=$hit',
    );
    return hit;
  }

  // ---- 对象命中检测（画布坐标空间） ----
  /// 返回命中的可编辑对象 ID；当前只有门，后续可扩展为矩形、家具等
  String? _hitObject(Offset cv, FloorPlanData data) {
    if (_isNearDoor(cv, data)) return 'door';
    return null;
  }

  /// 对象显示名称，用于 SnackBar 提示
  String _objectLabel(String objectId) {
    return switch (objectId) {
      'door' => '门',
      _ => objectId,
    };
  }

  // ---- 指针事件（坐标来自 Listener localPosition → Stack 空间 → 画布空间） ----
  void _onPointerDown(PointerDownEvent ev) {
    if (_data == null) return;
    _pointerDownViewport = ev.localPosition;
    _pointerDownTime = DateTime.now();

    final cv = _viewportToCanvas(ev.localPosition);

    final hitId = _hitObject(cv, _data!);
    _pressedObjectId = hitId;

    if (hitId != null) {
      _startLongPress(hitId);
    }
  }

  void _onPointerMove(PointerMoveEvent ev) {
    if (_data == null) return;

    // 如果尚未进入编辑模式，但移动超过阈值，取消长按并释放对象，交给 InteractiveViewer 平移
    if (_pressedObjectId != null &&
        _editObjectId == null &&
        _pointerDownViewport != null &&
        (ev.localPosition - _pointerDownViewport!).distance >
            _longPressMoveThreshold) {
      _cancelLongPress();
      setState(() => _pressedObjectId = null);
    }

    // 编辑模式下拖动当前对象
    if (_editObjectId == 'door') {
      _moveDoor(ev.localPosition);
    }
  }

  void _onPointerUp(PointerUpEvent ev) async {
    if (_data == null) return;

    _cancelLongPress();
    final pressedId = _pressedObjectId;
    final wasEditMode = _editObjectId != null;

    if (wasEditMode) {
      // 编辑模式下松开：保存并退出编辑
      await _storage.saveFloorPlan(widget.project.id, _data!);
      setState(() {
        _editObjectId = null;
        _pressedObjectId = null;
      });
      _resetPointerState();
      return;
    }

    if (pressedId != null) {
      // 在对象上单击/双击：处理对象级点击（双击打开编辑面板）
      setState(() => _pressedObjectId = null);
      await _handleObjectTap(pressedId, ev.localPosition);
      _resetPointerState();
      return;
    }

    // 普通点击：检测八宫 / 山盘山位 / 山盘宫位命中
    if (_isPlainTap(ev.localPosition)) {
      final rect = _floorRectOnCanvas();
      if (rect != null) {
        final cv = _viewportToCanvas(ev.localPosition);
        if (_data!.gridMode == 'grid4') {
          final hitInfo = hitTestEightPalace(cv, _data!, rect);
          if (hitInfo != null && mounted) {
            await showPalaceDetailDialog(
              context: context,
              hitInfo: hitInfo,
              data: _data!,
              floorRect: rect,
            );
          }
        } else {
          // 山盘优先检测单个山格，再检测所属宫位
          final mountainCell = hitTestMountain(cv, _data!, rect);
          if (mountainCell != null && mounted) {
            await showMountainDetailDialog(
              context: context,
              cell: mountainCell,
              data: _data!,
              floorRect: rect,
            );
          } else {
            final hitInfo = hitTestMountainPalace(cv, _data!, rect);
            if (hitInfo != null && mounted) {
              await showPalaceDetailDialog(
                context: context,
                hitInfo: hitInfo,
                data: _data!,
                floorRect: rect,
              );
            }
          }
        }
      }
    }

    _resetPointerState();
  }

  void _resetPointerState() {
    _pointerDownViewport = null;
    _pointerDownTime = null;
  }

  bool _isPlainTap(Offset upPosition) {
    if (_pointerDownViewport == null || _pointerDownTime == null) return false;
    final moved = (upPosition - _pointerDownViewport!).distance;
    final elapsed = DateTime.now().difference(_pointerDownTime!).inMilliseconds;
    return moved < 12 && elapsed < 300;
  }

  // ---- 长按进入编辑模式 ----
  void _startLongPress(String objectId) {
    _longPressTimer?.cancel();
    _longPressTimer = Timer(const Duration(milliseconds: _longPressMs), () {
      if (!mounted) return;
      dev.log('【宅盘编辑】长按 $objectId，进入编辑模式');
      setState(() => _editObjectId = objectId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('开始编辑${_objectLabel(objectId)}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });
  }

  void _cancelLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  // ---- 对象点击（双击打开编辑面板） ----
  Future<void> _handleObjectTap(String objectId, Offset viewportPos) async {
    if (objectId != 'door' || _data?.mainDoor == null) return;

    final now = DateTime.now();
    final isDoubleTap =
        _lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds <= _doubleTapMs &&
        _lastTapPosition != null &&
        (viewportPos - _lastTapPosition!).distance <= _doubleTapDist;

    if (isDoubleTap) {
      _lastTapTime = null;
      _lastTapPosition = null;
      dev.log('【宅盘门编辑】双击打开编辑面板');
      final r = await showDoorEditPanel(context: context, data: _data!);
      if (r != null) {
        await _saveData(_data!.copyWith(mainDoor: r));
      } else if (r == null && _data!.mainDoor != null) {
        await _saveData(_data!.copyWith(clearDoor: true));
      }
    } else {
      // 记录第一次点击，等待第二次
      _lastTapTime = now;
      _lastTapPosition = viewportPos;
      dev.log('【宅盘门编辑】单击门，等待双击');
    }
  }

  // ---- 门拖动 ----
  void _moveDoor(Offset viewportPos) {
    if (_data?.mainDoor == null) return;
    final cv = _viewportToCanvas(viewportPos);
    final rect = _floorRectOnCanvas();
    if (rect == null) return;

    final nx = ((cv.dx - rect.left) / rect.width).clamp(0.0, 1.0);
    final ny = ((cv.dy - rect.top) / rect.height).clamp(0.0, 1.0);
    final wall = snapWall(nx, ny);
    final w = _data!.mainDoor!.widthCm;
    final ratio = (wall == 'top' || wall == 'bottom') ? nx : ny;
    final wLen = doorWallLength(_data!, wall);
    // ratio 对应门中心点位置，转换为门起点距基准角的距离
    var off = ratio * wLen - w / 2;
    off = off.clamp(0.0, (wLen - w).clamp(0, wLen));
    dev.log('【宅盘门拖动】wall=$wall offsetCm=${off.toStringAsFixed(0)}');
    setState(() {
      _data = _data!.copyWith(
        mainDoor: _data!.mainDoor!.copyWith(
          wall: wall,
          offsetCm: off,
          offsetFrom: defaultOffsetFrom(wall),
        ),
      );
    });
  }

  // ---- Build ----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F1),
      appBar: AppBar(
        title: const Text('宅盘图'),
        centerTitle: true,
        backgroundColor: const Color(0xFFc8b898),
        foregroundColor: const Color(0xFF333333),
      ),
      body: _buildBody(),
      bottomNavigationBar: _data != null
          ? FloorPlanToolbar(data: _data!, onAction: _onToolbarAction)
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_data == null) return _buildEmptyState();
    if (_data!.widthCm <= 0 || _data!.heightCm <= 0) {
      return _buildInvalidState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          child: Stack(
            children: [
              InteractiveViewer(
                transformationController: _transformCtrl,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.1,
                maxScale: 6.0,
                panEnabled: _editObjectId == null,
                child: SizedBox(
                  width: _canvasW,
                  height: _canvasH,
                  child: CustomPaint(
                    size: Size(_canvasW, _canvasH),
                    painter: FloorPlanPainter(data: _data!),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: GestureDetector(
                  onTap: _centerView,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A4724),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.center_focus_strong,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home_outlined, size: 56, color: AppTheme.hintText),
            const SizedBox(height: 16),
            const Text(
              '暂无宅盘数据',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textTitle,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '请先设置宅盘的长和宽，生成宅盘底座。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showSizePanel,
              icon: const Icon(Icons.straighten, size: 18),
              label: const Text('设置尺寸'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5A4724),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvalidState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '宅盘尺寸无效',
            style: TextStyle(fontSize: 16, color: AppTheme.badText),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _showSizePanel,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('重新设置'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5A4724),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
