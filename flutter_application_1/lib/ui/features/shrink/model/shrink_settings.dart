/// 界面条件状态(对应 shrink_tool.py 各输入控件), 可 JSON 持久化,
/// 并可生成 FilterConditions(对应 _collect_conditions)。
library;

import 'package:flutter_application_1/data/constants.dart';
import 'package:flutter_application_1/domain/filter_conditions.dart';

class ShrinkSettings {
  String killText = '';
  String danText = '';
  String prevText = '';

  int acMin = 2, acMax = 6;
  bool chkZone = true;
  int zoneHeadMin = 1, zoneHeadMax = 3;
  int zoneMidMin = 1, zoneMidMax = 4;
  int zoneTailMin = 1, zoneTailMax = 3;
  bool chkSum = true;
  int sumMin = 70, sumMax = 110;
  bool chkSpan = true;
  int spanMin = 4, spanMax = 6;
  List<bool> oddChecks = List.filled(6, false);
  List<bool> bigChecks = List.filled(6, false);
  List<bool> primeChecks = List.filled(6, false);

  bool chkWx = true;
  List<Range2> wxLimits = defaultLimits(5, 0, 3);
  bool chkYj = true;
  List<Range2> yjLimits = List.of(kYJDefaults);
  bool chkTailwx = true;
  List<Range2> tailwxLimits = List.of(kTailWXDefaults);
  int tailwxKindMin = 2, tailwxKindMax = 5;
  bool chkFour = true;
  List<Range2> fourLimits = List.of(kFourDefaults);
  bool chkFive = true;
  List<Range2> fiveLimits = List.of(kFiveDefaults);
  bool chkEdge = true;
  int edgeMin = 0, edgeMax = 3;
  bool chkWave = true;
  List<Range2> waveLimits = List.of(kWaveDefaults);
  bool chkSeven = true;
  List<Range2> sevenLimits = List.of(kSevenDefaults);
  bool chkSevenSpan = true;
  int sevenSpanMin = kSevenSpanDefault.$1, sevenSpanMax = kSevenSpanDefault.$2;
  bool chkEdge7 = true;
  int edge7Min = 0, edge7Max = 4;
  bool chkSan = true;
  List<bool> sanTiers = [true, false, false];
  List<Range2> sanLimits = defaultLimits(3, 0, 3);
  bool chkMod3 = true;
  List<Range2> mod3Limits = defaultLimits(3, 0, 5);
  bool chkMod7 = true;
  List<Range2> mod7Limits = defaultLimits(7, 0, 2);
  bool chkMod7Span = true;
  int mod7SpanMin = 2, mod7SpanMax = 4;
  bool chkCon = true;
  int con2Min = 0, con2Max = 1;
  int con3Min = 0, con3Max = 1;
  int tailMin = 1, tailMax = 5;
  bool chkTsum = true;
  int tsumMin = 10, tsumMax = 34;
  bool chkDangroup = false;
  List<Range2> dangroupLimits = defaultLimits(kDanGroups.length, 0, 5);
  bool chkRn = true;
  int repMin = 0, repMax = 2;
  int nbrMin = 1, nbrMax = 3;
  int orphMin = 1, orphMax = 4;

  /// 生成过滤条件(对应 Python _collect_conditions)。
  FilterConditions toConditions() {
    final c = FilterConditions();
    c.sumMin = sumMin;
    c.sumMax = sumMax;
    c.sumFilter = chkSum;
    c.spanMin = spanMin;
    c.spanMax = spanMax;
    c.spanFilter = chkSpan;
    c.acMin = acMin;
    c.acMax = acMax;
    c.zoneFilter = chkZone;
    c.zoneHeadMin = zoneHeadMin;
    c.zoneHeadMax = zoneHeadMax;
    c.zoneMidMin = zoneMidMin;
    c.zoneMidMax = zoneMidMax;
    c.zoneTailMin = zoneTailMin;
    c.zoneTailMax = zoneTailMax;
    c.wxFilter = chkWx;
    c.wxLimits = List.of(wxLimits);
    c.yjFilter = chkYj;
    c.yjLimits = List.of(yjLimits);
    c.fourFilter = chkFour;
    c.fourLimits = List.of(fourLimits);
    c.fiveFilter = chkFive;
    c.fiveLimits = List.of(fiveLimits);
    c.sevenFilter = chkSeven;
    c.sevenLimits = List.of(sevenLimits);
    c.sevenSpanFilter = chkSevenSpan;
    c.sevenSpanMin = sevenSpanMin;
    c.sevenSpanMax = sevenSpanMax;
    c.edgeFilter = chkEdge;
    c.edgeMin = edgeMin;
    c.edgeMax = edgeMax;
    c.edge7Filter = chkEdge7;
    c.edge7Min = edge7Min;
    c.edge7Max = edge7Max;
    if (oddChecks.any((v) => v)) {
      c.oddCounts = {
        for (var i = 0; i < oddChecks.length; i++)
          if (oddChecks[i]) i,
      };
    }
    if (bigChecks.any((v) => v)) {
      c.bigCounts = {
        for (var i = 0; i < bigChecks.length; i++)
          if (bigChecks[i]) i,
      };
    }
    if (primeChecks.any((v) => v)) {
      c.primeCounts = {
        for (var i = 0; i < primeChecks.length; i++)
          if (primeChecks[i]) i,
      };
    }
    c.mod3Filter = chkMod3;
    c.mod3Limits = List.of(mod3Limits);
    c.mod7Filter = chkMod7;
    c.mod7Limits = List.of(mod7Limits);
    c.mod7SpanFilter = chkMod7Span;
    c.mod7SpanMin = mod7SpanMin;
    c.mod7SpanMax = mod7SpanMax;
    c.conFilter = chkCon;
    c.con2Min = con2Min;
    c.con2Max = con2Max;
    c.con3Min = con3Min;
    c.con3Max = con3Max;
    c.tailMin = tailMin;
    c.tailMax = tailMax;
    c.tsumFilter = chkTsum;
    c.tsumMin = tsumMin;
    c.tsumMax = tsumMax;
    c.tailwxFilter = chkTailwx;
    c.tailwxLimits = List.of(tailwxLimits);
    c.tailwxKindMin = tailwxKindMin;
    c.tailwxKindMax = tailwxKindMax;
    c.waveFilter = chkWave;
    c.waveLimits = List.of(waveLimits);
    c.sanFilter = chkSan;
    c.sanTiers = List.of(sanTiers);
    c.sanLimits = List.of(sanLimits);
    c.dangroupFilter = chkDangroup;
    c.dangroupLimits = List.of(dangroupLimits);
    c.kill = parseInts(killText);
    c.dan = parseInts(danText);
    final prev = parseInts(prevText);
    if (prev.isNotEmpty) {
      c.prevDraw = prev;
    }
    c.rnFilter = chkRn;
    c.repMin = repMin;
    c.repMax = repMax;
    c.nbrMin = nbrMin;
    c.nbrMax = nbrMax;
    c.orphMin = orphMin;
    c.orphMax = orphMax;
    return c;
  }

  /// 提取文本中的号码(1~35 去重), 对应 Python _parse_nums。
  static Set<int> parseInts(String text) {
    final nums = <int>{};
    final re = RegExp(r'\d+');
    for (final m in re.allMatches(text)) {
      final n = int.tryParse(m.group(0)!);
      if (n != null && n >= 1 && n <= 35) {
        nums.add(n);
      }
    }
    return nums;
  }

  // ---------------- JSON 持久化 ----------------

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'killText': killText,
      'danText': danText,
      'prevText': prevText,
      'acMin': acMin, 'acMax': acMax,
      'chkZone': chkZone,
      'zoneHeadMin': zoneHeadMin, 'zoneHeadMax': zoneHeadMax,
      'zoneMidMin': zoneMidMin, 'zoneMidMax': zoneMidMax,
      'zoneTailMin': zoneTailMin, 'zoneTailMax': zoneTailMax,
      'chkSum': chkSum, 'sumMin': sumMin, 'sumMax': sumMax,
      'chkSpan': chkSpan, 'spanMin': spanMin, 'spanMax': spanMax,
      'oddChecks': oddChecks, 'bigChecks': bigChecks, 'primeChecks': primeChecks,
      'chkWx': chkWx, 'wxLimits': _limitsToJson(wxLimits),
      'chkYj': chkYj, 'yjLimits': _limitsToJson(yjLimits),
      'chkTailwx': chkTailwx, 'tailwxLimits': _limitsToJson(tailwxLimits),
      'tailwxKindMin': tailwxKindMin, 'tailwxKindMax': tailwxKindMax,
      'chkFour': chkFour, 'fourLimits': _limitsToJson(fourLimits),
      'chkFive': chkFive, 'fiveLimits': _limitsToJson(fiveLimits),
      'chkEdge': chkEdge, 'edgeMin': edgeMin, 'edgeMax': edgeMax,
      'chkWave': chkWave, 'waveLimits': _limitsToJson(waveLimits),
      'chkSeven': chkSeven, 'sevenLimits': _limitsToJson(sevenLimits),
      'chkSevenSpan': chkSevenSpan,
      'sevenSpanMin': sevenSpanMin, 'sevenSpanMax': sevenSpanMax,
      'chkEdge7': chkEdge7, 'edge7Min': edge7Min, 'edge7Max': edge7Max,
      'chkSan': chkSan, 'sanTiers': sanTiers, 'sanLimits': _limitsToJson(sanLimits),
      'chkMod3': chkMod3, 'mod3Limits': _limitsToJson(mod3Limits),
      'chkMod7': chkMod7, 'mod7Limits': _limitsToJson(mod7Limits),
      'chkMod7Span': chkMod7Span, 'mod7SpanMin': mod7SpanMin, 'mod7SpanMax': mod7SpanMax,
      'chkCon': chkCon, 'con2Min': con2Min, 'con2Max': con2Max,
      'con3Min': con3Min, 'con3Max': con3Max,
      'tailMin': tailMin, 'tailMax': tailMax,
      'chkTsum': chkTsum, 'tsumMin': tsumMin, 'tsumMax': tsumMax,
      'chkDangroup': chkDangroup, 'dangroupLimits': _limitsToJson(dangroupLimits),
      'chkRn': chkRn, 'repMin': repMin, 'repMax': repMax,
      'nbrMin': nbrMin, 'nbrMax': nbrMax, 'orphMin': orphMin, 'orphMax': orphMax,
    };
    return m;
  }

  static List<List<int>> _limitsToJson(List<Range2> limits) =>
      [for (final (a, b) in limits) [a, b]];

  static List<Range2> _limitsFromJson(dynamic v, int n, List<Range2> fallback) {
    if (v is! List || v.isEmpty) {
      return List.of(fallback);
    }
    return List.generate(n, (i) {
      if (i >= v.length || v[i] is! List || (v[i] as List).length < 2) {
        return fallback[i < fallback.length ? i : 0];
      }
      final pair = v[i] as List;
      return (pair[0] as int, pair[1] as int);
    });
  }

  static List<bool> _boolsFromJson(dynamic v, int n, List<bool> fallback) {
    if (v is! List) {
      return List.of(fallback);
    }
    return List.generate(n, (i) => i < v.length ? v[i] == true : false);
  }

  static int _int(dynamic v, int fallback) => v is int ? v : fallback;

  static bool _bool(dynamic v, bool fallback) => v is bool ? v : fallback;

  static String _str(dynamic v, String fallback) => v is String ? v : fallback;

  void updateFromJson(Map<String, dynamic> m) {
    killText = _str(m['killText'], killText);
    danText = _str(m['danText'], danText);
    prevText = _str(m['prevText'], prevText);
    acMin = _int(m['acMin'], acMin);
    acMax = _int(m['acMax'], acMax);
    chkZone = _bool(m['chkZone'], chkZone);
    zoneHeadMin = _int(m['zoneHeadMin'], zoneHeadMin);
    zoneHeadMax = _int(m['zoneHeadMax'], zoneHeadMax);
    zoneMidMin = _int(m['zoneMidMin'], zoneMidMin);
    zoneMidMax = _int(m['zoneMidMax'], zoneMidMax);
    zoneTailMin = _int(m['zoneTailMin'], zoneTailMin);
    zoneTailMax = _int(m['zoneTailMax'], zoneTailMax);
    chkSum = _bool(m['chkSum'], chkSum);
    sumMin = _int(m['sumMin'], sumMin);
    sumMax = _int(m['sumMax'], sumMax);
    chkSpan = _bool(m['chkSpan'], chkSpan);
    spanMin = _int(m['spanMin'], spanMin);
    spanMax = _int(m['spanMax'], spanMax);
    oddChecks = _boolsFromJson(m['oddChecks'], 6, oddChecks);
    bigChecks = _boolsFromJson(m['bigChecks'], 6, bigChecks);
    primeChecks = _boolsFromJson(m['primeChecks'], 6, primeChecks);
    chkWx = _bool(m['chkWx'], chkWx);
    wxLimits = _limitsFromJson(m['wxLimits'], 5, wxLimits);
    chkYj = _bool(m['chkYj'], chkYj);
    yjLimits = _limitsFromJson(m['yjLimits'], 5, yjLimits);
    chkTailwx = _bool(m['chkTailwx'], chkTailwx);
    tailwxLimits = _limitsFromJson(m['tailwxLimits'], 5, tailwxLimits);
    tailwxKindMin = _int(m['tailwxKindMin'], tailwxKindMin);
    tailwxKindMax = _int(m['tailwxKindMax'], tailwxKindMax);
    chkFour = _bool(m['chkFour'], chkFour);
    fourLimits = _limitsFromJson(m['fourLimits'], 4, fourLimits);
    chkFive = _bool(m['chkFive'], chkFive);
    fiveLimits = _limitsFromJson(m['fiveLimits'], 5, fiveLimits);
    chkEdge = _bool(m['chkEdge'], chkEdge);
    edgeMin = _int(m['edgeMin'], edgeMin);
    edgeMax = _int(m['edgeMax'], edgeMax);
    chkWave = _bool(m['chkWave'], chkWave);
    waveLimits = _limitsFromJson(m['waveLimits'], 3, waveLimits);
    chkSeven = _bool(m['chkSeven'], chkSeven);
    sevenLimits = _limitsFromJson(m['sevenLimits'], 7, sevenLimits);
    chkSevenSpan = _bool(m['chkSevenSpan'], chkSevenSpan);
    sevenSpanMin = _int(m['sevenSpanMin'], sevenSpanMin);
    sevenSpanMax = _int(m['sevenSpanMax'], sevenSpanMax);
    chkEdge7 = _bool(m['chkEdge7'], chkEdge7);
    edge7Min = _int(m['edge7Min'], edge7Min);
    edge7Max = _int(m['edge7Max'], edge7Max);
    chkSan = _bool(m['chkSan'], chkSan);
    sanTiers = _boolsFromJson(m['sanTiers'], 3, sanTiers);
    sanLimits = _limitsFromJson(m['sanLimits'], 3, sanLimits);
    chkMod3 = _bool(m['chkMod3'], chkMod3);
    mod3Limits = _limitsFromJson(m['mod3Limits'], 3, mod3Limits);
    chkMod7 = _bool(m['chkMod7'], chkMod7);
    mod7Limits = _limitsFromJson(m['mod7Limits'], 7, mod7Limits);
    chkMod7Span = _bool(m['chkMod7Span'], chkMod7Span);
    mod7SpanMin = _int(m['mod7SpanMin'], mod7SpanMin);
    mod7SpanMax = _int(m['mod7SpanMax'], mod7SpanMax);
    chkCon = _bool(m['chkCon'], chkCon);
    con2Min = _int(m['con2Min'], con2Min);
    con2Max = _int(m['con2Max'], con2Max);
    con3Min = _int(m['con3Min'], con3Min);
    con3Max = _int(m['con3Max'], con3Max);
    tailMin = _int(m['tailMin'], tailMin);
    tailMax = _int(m['tailMax'], tailMax);
    chkTsum = _bool(m['chkTsum'], chkTsum);
    tsumMin = _int(m['tsumMin'], tsumMin);
    tsumMax = _int(m['tsumMax'], tsumMax);
    chkDangroup = _bool(m['chkDangroup'], chkDangroup);
    dangroupLimits = _limitsFromJson(m['dangroupLimits'], kDanGroups.length, dangroupLimits);
    chkRn = _bool(m['chkRn'], chkRn);
    repMin = _int(m['repMin'], repMin);
    repMax = _int(m['repMax'], repMax);
    nbrMin = _int(m['nbrMin'], nbrMin);
    nbrMax = _int(m['nbrMax'], nbrMax);
    orphMin = _int(m['orphMin'], orphMin);
    orphMax = _int(m['orphMax'], orphMax);
  }
}
