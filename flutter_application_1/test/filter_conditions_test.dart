/// FilterConditions 与 Python 版对拍测试。
///
/// 向量由 utils/calcute_funcs.py 的随机条件+组合生成(见 match_vectors.json),
/// 校验 Dart 移植的 match() 与 Python 期望结果完全一致。
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/data/constants.dart';
import 'package:flutter_application_1/data/full_data_loader.dart';
import 'package:flutter_application_1/domain/filter_conditions.dart';

Range2 _pair(dynamic v) => (v[0] as int, v[1] as int);

List<Range2> _pairs(dynamic v) => [for (final p in v as List) _pair(p)];

FilterConditions condFromJson(Map<String, dynamic> m) {
  final c = FilterConditions();
  c.kill = {for (final n in (m['kill'] as List)) n as int};
  c.dan = {for (final n in (m['dan'] as List)) n as int};
  final prev = m['prev_draw'];
  c.prevDraw = prev == null ? null : {for (final n in prev as List) n as int};
  c.sumFilter = m['sum_filter'] as bool;
  c.sumMin = m['sum_min'] as int;
  c.sumMax = m['sum_max'] as int;
  c.spanFilter = m['span_filter'] as bool;
  c.spanMin = m['span_min'] as int;
  c.spanMax = m['span_max'] as int;
  c.acMin = m['ac_min'] as int;
  c.acMax = m['ac_max'] as int;
  c.zoneFilter = m['zone_filter'] as bool;
  c.zoneHeadMin = m['zone_head_min'] as int;
  c.zoneHeadMax = m['zone_head_max'] as int;
  c.zoneMidMin = m['zone_mid_min'] as int;
  c.zoneMidMax = m['zone_mid_max'] as int;
  c.zoneTailMin = m['zone_tail_min'] as int;
  c.zoneTailMax = m['zone_tail_max'] as int;
  c.wxFilter = m['wx_filter'] as bool;
  c.wxLimits = _pairs(m['wx_limits']);
  c.yjFilter = m['yj_filter'] as bool;
  c.yjLimits = _pairs(m['yj_limits']);
  c.fiveFilter = m['five_filter'] as bool;
  c.fiveLimits = _pairs(m['five_limits']);
  c.fourFilter = m['four_filter'] as bool;
  c.fourLimits = _pairs(m['four_limits']);
  c.sevenFilter = m['seven_filter'] as bool;
  c.sevenLimits = _pairs(m['seven_limits']);
  c.sevenSpanFilter = m['seven_span_filter'] as bool;
  c.sevenSpanMin = m['seven_span_min'] as int;
  c.sevenSpanMax = m['seven_span_max'] as int;
  c.edgeFilter = m['edge_filter'] as bool;
  c.edgeMin = m['edge_min'] as int;
  c.edgeMax = m['edge_max'] as int;
  c.edge7Filter = m['edge7_filter'] as bool;
  c.edge7Min = m['edge7_min'] as int;
  c.edge7Max = m['edge7_max'] as int;
  Set<int>? counts(dynamic v) =>
      v == null ? null : {for (final n in v as List) n as int};
  c.oddCounts = counts(m['odd_counts']);
  c.bigCounts = counts(m['big_counts']);
  c.primeCounts = counts(m['prime_counts']);
  c.mod3Filter = m['mod3_filter'] as bool;
  c.mod3Limits = _pairs(m['mod3_limits']);
  c.mod7Filter = m['mod7_filter'] as bool;
  c.mod7Limits = _pairs(m['mod7_limits']);
  c.mod7SpanFilter = m['mod7_span_filter'] as bool;
  c.mod7SpanMin = m['mod7_span_min'] as int;
  c.mod7SpanMax = m['mod7_span_max'] as int;
  c.conFilter = m['con_filter'] as bool;
  c.con2Min = m['con2_min'] as int;
  c.con2Max = m['con2_max'] as int;
  c.con3Min = m['con3_min'] as int;
  c.con3Max = m['con3_max'] as int;
  c.tailMin = m['tail_min'] as int;
  c.tailMax = m['tail_max'] as int;
  c.tsumFilter = m['tsum_filter'] as bool;
  c.tsumMin = m['tsum_min'] as int;
  c.tsumMax = m['tsum_max'] as int;
  c.tailwxFilter = m['tailwx_filter'] as bool;
  c.tailwxLimits = _pairs(m['tailwx_limits']);
  c.tailwxKindMin = m['tailwx_kind_min'] as int;
  c.tailwxKindMax = m['tailwx_kind_max'] as int;
  c.waveFilter = m['wave_filter'] as bool;
  c.waveLimits = _pairs(m['wave_limits']);
  c.sanFilter = m['san_filter'] as bool;
  c.sanTiers = [for (final b in m['san_tiers'] as List) b as bool];
  c.sanLimits = _pairs(m['san_limits']);
  c.dangroupFilter = m['dangroup_filter'] as bool;
  c.dangroupLimits = _pairs(m['dangroup_limits']);
  c.rnFilter = m['rn_filter'] as bool;
  c.repMin = m['rep_min'] as int;
  c.repMax = m['rep_max'] as int;
  c.nbrMin = m['nbr_min'] as int;
  c.nbrMax = m['nbr_max'] as int;
  c.orphMin = m['orph_min'] as int;
  c.orphMax = m['orph_max'] as int;
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late final Map<String, dynamic> vectors;

  setUpAll(() {
    final text = File('test/match_vectors.json').readAsStringSync();
    vectors = jsonDecode(text) as Map<String, dynamic>;
  });

  test('连号统计与 AC 值与 Python 一致', () {
    for (final v in vectors['stat_vectors'] as List) {
      final m = v as Map<String, dynamic>;
      final nums = [for (final n in m['nums'] as List) n as int];
      final (two, three) = consecutiveStats(nums);
      expect(two, m['two'], reason: 'nums=$nums 2连号');
      expect(three, m['three'], reason: 'nums=$nums 三连号');
      expect(acValue(nums), m['ac'], reason: 'nums=$nums AC值');
    }
  });

  test('全量数据资产可解压且规模正确', () async {
    final flat = await loadGroupFlatBytes();
    expect(flat.length, kTotalGroups * 5);
    // 首组 01 02 03 04 05, 末组 31 32 33 34 35
    expect(flat.sublist(0, 5), [1, 2, 3, 4, 5]);
    expect(flat.sublist(flat.length - 5), [31, 32, 33, 34, 35]);
    // 每组升序且范围 1~35
    for (var i = 0; i < flat.length; i += 5) {
      for (var j = 0; j < 5; j++) {
        final n = flat[i + j];
        expect(n, inInclusiveRange(1, 35), reason: '组合${i ~/ 5}号码越界');
        if (j > 0) {
          expect(n, greaterThan(flat[i + j - 1]), reason: '组合${i ~/ 5}非升序');
        }
      }
    }
  });

  test('match() 与 Python 基准一致', () {
    final cases = vectors['cases'] as List;
    var total = 0;
    var matched = 0;
    for (final caseItem in cases) {
      final m = caseItem as Map<String, dynamic>;
      final cond = condFromJson((m['cond'] as Map).cast<String, dynamic>());
      final combos = m['combos'] as List;
      final expected = m['expected'] as List;
      expect(combos.length, expected.length);
      for (var i = 0; i < combos.length; i++) {
        final nums = [for (final n in combos[i] as List) n as int];
        final got = cond.match(nums);
        final want = expected[i] as bool;
        if (got != want) {
          fail('条件用例不匹配: combo=$nums 期望=$want 实际=$got '
              'cond=${jsonEncode(m['cond'])}');
        }
        total++;
        if (got) {
          matched++;
        }
      }
    }
    expect(total, 127200);
    expect(matched, greaterThan(0), reason: '对拍样本应包含通过组合');
  });

  test('flat 扁平数据上的 match 与 List 输入一致', () {
    // 模拟 isolate 内逐行匹配路径: 用 Uint8List 行缓冲
    final flat = Uint8List.fromList([
      1, 2, 3, 4, 5, // 强连号
      6, 12, 18, 24, 30, // 均匀分布
      7, 13, 19, 25, 31, //
    ]);
    final cond = FilterConditions()
      ..wxFilter = false
      ..yjFilter = false
      ..fiveFilter = false
      ..fourFilter = false
      ..sevenFilter = false
      ..sevenSpanFilter = false
      ..edgeFilter = false
      ..edge7Filter = false
      ..mod3Filter = false
      ..mod7Filter = false
      ..mod7SpanFilter = false
      ..tailwxFilter = false
      ..waveFilter = false
      ..sanFilter = false
      ..conFilter = false
      ..tsumFilter = false
      ..zoneFilter = false
      ..sumFilter = false
      ..spanFilter = false
      ..rnFilter = false;
    final row = Uint8List(5);
    final results = <bool>[];
    for (var i = 0; i + 5 <= flat.length; i += 5) {
      for (var j = 0; j < 5; j++) {
        row[j] = flat[i + j];
      }
      results.add(cond.match(row));
    }
    // 仅剩 AC(0~6) 与尾数种类(1~5) 过滤: 三行均应通过
    expect(results, [true, true, true]);
  });
}
