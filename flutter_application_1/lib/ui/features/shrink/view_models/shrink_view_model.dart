/// 缩水主界面 ViewModel（对应 shrink_tool.py 的 ShrinkWindow 业务部分）。
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import 'package:flutter_application_1/data/full_data_loader.dart';
import 'package:flutter_application_1/data/repositories/settings_repository.dart';
import 'package:flutter_application_1/data/services/lottery_service.dart';
import 'package:flutter_application_1/domain/filter_conditions.dart';
import 'package:flutter_application_1/ui/features/shrink/model/shrink_settings.dart';

const int kPreviewRows = 2000; // 表格最多预览行数
const String kDefaultSave = r'E:\app2\ai_dlt\front_numbers_shrunk.txt';

/// 主界面状态与操作。
class ShrinkViewModel extends ChangeNotifier {
  final LotteryService _lotteryService = LotteryService();
  final SettingsRepository _settingsRepo = SettingsRepository();

  ShrinkSettings settings = ShrinkSettings();

  Uint8List? groupFlat; // 全量组合扁平字节(每组5号)
  int groupCount = 0;
  List<int> resultIndices = []; // 缩水结果(组合索引)

  String statusText = '请先载入数据';
  String latestText = '最新开奖: 未获取';
  LatestDraw? latestDraw;
  bool busy = false;
  bool latestLoading = false;
  String savePath = kDefaultSave;

  /// 重置令牌: 递增以通知所有数字输入框刷新文本。
  int resetToken = 0;

  bool initialized = false;

  /// 条件控件变更后通知界面刷新(复选框等为无状态组件)。
  void changed() => notifyListeners();

  /// 启动: 恢复配置 → 载入数据 → 获取最新开奖。
  Future<void> init() async {
    final saved = _settingsRepo.load();
    if (saved != null) {
      settings.updateFromJson(saved);
    }
    await loadGroups();
    initialized = true;
    notifyListeners();
    // 启动时后台获取最新开奖号码
    unawaited(fetchLatest());
  }

  /// 载入内嵌全量数据(对应 on_load)。
  Future<void> loadGroups() async {
    try {
      groupFlat = await loadGroupFlatBytes();
      groupCount = groupFlat!.length ~/ 5;
      resultIndices = [];
      statusText = '已载入 $groupCount 组号码: (全量数据)';
    } catch (e) {
      groupFlat = null;
      statusText = '载入失败: $e';
    }
    notifyListeners();
  }

  /// 获取最新开奖(后台执行, 对应 on_fetch_latest)。
  Future<void> fetchLatest() async {
    latestLoading = true;
    latestText = '最新开奖: 获取中...';
    notifyListeners();
    final result = await _lotteryService.fetchLatestDraw();
    latestLoading = false;
    if (result == null) {
      latestText = '最新开奖: 获取失败(请检查网络)';
    } else {
      latestDraw = result;
      final frontStr = result.front.map((n) => n.toString().padLeft(2, '0')).join(' ');
      final backStr = result.back.map((n) => n.toString().padLeft(2, '0')).join(' ');
      final ac = acValue(result.front);
      latestText =
          '最新开奖: 第${result.drawNum}期(${result.drawTime})  $frontStr + $backStr  (AC值: $ac)';
    }
    notifyListeners();
  }

  /// 开始缩水(对应 on_shrink): 后台 Isolate 过滤全量组合。
  Future<void> shrink() async {
    final flat = groupFlat;
    if (flat == null || groupCount == 0) {
      statusText = '请先载入数据';
      notifyListeners();
      return;
    }
    final cond = settings.toConditions();
    busy = true;
    statusText = '缩水中...';
    notifyListeners();
    final watch = Stopwatch()..start();
    try {
      resultIndices = await Isolate.run(() => _filterAll(flat, cond));
    } catch (e) {
      statusText = '缩水失败: $e';
      busy = false;
      notifyListeners();
      return;
    }
    watch.stop();
    busy = false;
    final note = resultIndices.length <= kPreviewRows
        ? ''
        : '（表格仅预览前 $kPreviewRows 行）';
    statusText = '共 $groupCount 组 → 条件过滤 ${resultIndices.length} 组, '
        '最终 ${resultIndices.length} 组, 耗时 ${watch.elapsedMilliseconds / 1000.0} 秒 $note';
    notifyListeners();
    persistState();
  }

  static List<int> _filterAll(Uint8List flat, FilterConditions cond) {
    final row = Uint8List(5);
    final out = <int>[];
    for (var i = 0; i + 5 <= flat.length; i += 5) {
      for (var j = 0; j < 5; j++) {
        row[j] = flat[i + j];
      }
      if (cond.match(row)) {
        out.add(i ~/ 5);
      }
    }
    return out;
  }

  /// 保存结果(对应 on_save)。
  Future<void> saveResults() async {
    if (resultIndices.isEmpty) {
      statusText = '没有可保存的结果, 请先缩水';
      notifyListeners();
      return;
    }
    try {
      final sb = StringBuffer();
      sb.writeln('大乐透前区缩水结果（${resultIndices.length}组，5/35）');
      sb.writeln('-' * 40);
      final flat = groupFlat!;
      for (var k = 0; k < resultIndices.length; k++) {
        final base = resultIndices[k] * 5;
        final nums = [
          for (var j = 0; j < 5; j++)
            flat[base + j].toString().padLeft(2, '0'),
        ];
        sb.writeln('${(k + 1).toString().padLeft(4, '0')}: ${nums.join(' ')}');
      }
      await File(savePath).writeAsString(sb.toString());
      statusText = '已保存 ${resultIndices.length} 组至: $savePath';
    } catch (e) {
      statusText = '保存失败: $e';
    }
    notifyListeners();
  }

  /// 重置条件(对应 on_reset)。
  void resetConditions() {
    final keepKill = settings.killText;
    final keepDan = settings.danText;
    final keepPrev = settings.prevText;
    final keepSave = savePath;
    settings = ShrinkSettings();
    settings.killText = keepKill;
    settings.danText = keepDan;
    settings.prevText = keepPrev;
    savePath = keepSave;
    resetToken++;
    statusText = '条件已重置';
    notifyListeners();
  }

  /// 持久化当前状态(对应 _save_state)。
  void persistState() {
    _settingsRepo.save(settings.toJson());
  }
}
