/// 界面状态持久化（对应 shrink_tool.py 的 QSettings ini: ~/.ai_dlt/shrink_ui_state.ini）。
///
/// 使用 JSON 存放在用户目录 ~/.ai_dlt/shrink_ui_state.json,
/// 打包后不依赖程序所在目录的写权限。
library;

import 'dart:convert';
import 'dart:io';

class SettingsRepository {
  final String filePath;

  SettingsRepository() : filePath = _defaultFilePath();

  static String _defaultFilePath() {
    final home = Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        '.';
    final dir =
        home.endsWith('\\') || home.endsWith('/') ? home : '$home\\';
    return '$dir.ai_dlt\\shrink_ui_state.json';
  }

  /// 读取保存的状态; 不存在或损坏返回 null。
  Map<String, dynamic>? load() {
    try {
      final f = File(filePath);
      if (!f.existsSync()) {
        return null;
      }
      final text = f.readAsStringSync();
      final data = jsonDecode(text);
      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (_) {
      // 损坏不影响使用, 返回默认配置
    }
    return null;
  }

  /// 保存状态, 失败静默(不影响使用)。
  void save(Map<String, dynamic> state) {
    try {
      final f = File(filePath);
      f.parent.createSync(recursive: true);
      f.writeAsStringSync(jsonEncode(state));
    } catch (_) {}
  }
}
