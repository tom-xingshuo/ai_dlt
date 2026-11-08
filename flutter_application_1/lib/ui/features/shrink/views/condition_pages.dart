/// 12 个条件页签(移植自 shrink_tool.py _build_filters_box 的全部页面)。
library;

import 'package:flutter/material.dart';

import 'package:flutter_application_1/data/constants.dart';
import 'package:flutter_application_1/ui/core/widgets.dart';
import 'package:flutter_application_1/ui/features/shrink/view_models/shrink_view_model.dart';

/// 构建全部条件页(与 Python 页签顺序一致)。
List<Widget> buildConditionPages(ShrinkViewModel vm) {
  final s = vm.settings;
  final token = vm.resetToken;

  String members(Set<int> set, {bool pad = true}) =>
      (set.toList()..sort()).map((n) => pad ? two(n) : '$n').join(',');

  Widget rangeRow(String label, Range2 v, int lo, int hi,
          void Function(int, int) onSet,
          {String? labelTooltip}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          labelTooltip != null
              ? Tooltip(message: labelTooltip, child: RowLabel(label))
              : RowLabel(label),
          const SizedBox(width: 6),
          NumberField(
              value: v.$1,
              min: lo,
              max: hi,
              resetToken: token,
              onCommit: (x) => onSet(x, v.$2)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('~', style: TextStyle(fontSize: 13)),
          ),
          NumberField(
              value: v.$2,
              min: lo,
              max: hi,
              resetToken: token,
              onCommit: (x) => onSet(v.$1, x)),
        ]),
      );

  Widget zoneRows(List<String> labels, List<Range2> limits,
          void Function(int i, int lo, int hi) onSet) =>
      Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < labels.length; i++)
              rangeRow(labels[i], limits[i], 0, 5,
                  (lo, hi) => onSet(i, lo, hi)),
          ]);

  Widget page(Widget child) => SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Align(
          alignment: Alignment.topLeft,
          child: child,
        ),
      );

  Widget chk(String title, bool value, void Function(bool) onSet,
          {String? tooltip}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: CondCheckbox(
            title: title, value: value, tooltip: tooltip, onChanged: onSet),
      );

  // ---- 页1: 杀号/区间与比例 ----
  final page1 = page(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        const RowLabel('杀号(排除):'),
        const SizedBox(width: 6),
        TextEditField(
          value: s.killText,
          resetToken: token,
          hint: '如: 03 11 22',
          width: 220,
          onChanged: (v) => s.killText = v,
        ),
      ]),
      rangeRow('AC值区间:', (s.acMin, s.acMax), 0, 6, (lo, hi) {
        s.acMin = lo;
        s.acMax = hi;
      }),
      chk('龙头-中间-凤尾分区出号(启用)', s.chkZone, (v) {
        s.chkZone = v;
        vm.changed();
      }, tooltip: '龙头01~13 / 中间09~26 / 凤尾24~35, 区间可重叠:\n'
              '号码09~13同时计入龙头与中间, 24~26同时计入中间与凤尾\n'
              '不勾选=不启用该过滤'),
      rangeRow('龙头 01~13 出号:', (s.zoneHeadMin, s.zoneHeadMax), 0, 5,
          (lo, hi) {
        s.zoneHeadMin = lo;
        s.zoneHeadMax = hi;
      }),
      rangeRow('中间 09~26 出号:', (s.zoneMidMin, s.zoneMidMax), 0, 5, (lo, hi) {
        s.zoneMidMin = lo;
        s.zoneMidMax = hi;
      }),
      rangeRow('凤尾 24~35 出号:', (s.zoneTailMin, s.zoneTailMax), 0, 5, (lo, hi) {
        s.zoneTailMin = lo;
        s.zoneTailMax = hi;
      }),
      Row(mainAxisSize: MainAxisSize.min, children: [
        rangeRow('和值区间:', (s.sumMin, s.sumMax), 15, 165, (lo, hi) {
          s.sumMin = lo;
          s.sumMax = hi;
        }),
        const SizedBox(width: 8),
        chk('启用', s.chkSum, (v) {
          s.chkSum = v;
          vm.changed();
        }, tooltip: '不勾选=不过滤和值'),
      ]),
      Row(mainAxisSize: MainAxisSize.min, children: [
        rangeRow('跨度区间:', (s.spanMin, s.spanMax), 4, 34, (lo, hi) {
          s.spanMin = lo;
          s.spanMax = hi;
        }),
        const SizedBox(width: 8),
        chk('启用', s.chkSpan, (v) {
          s.chkSpan = v;
          vm.changed();
        }, tooltip: '不勾选=不启用跨度过滤'),
      ]),
      const SizedBox(height: 4),
      RatioGroupBox(
        title: '奇数个数(奇:偶)',
        tooltip: '勾选允许的奇数个数, 全不勾=不过滤',
        checks: s.oddChecks,
        onToggle: (k) {
          s.oddChecks[k] = !s.oddChecks[k];
          vm.changed();
        },
      ),
      const SizedBox(height: 4),
      RatioGroupBox(
        title: '大号个数(大:小)',
        tooltip: '大号 >= $kBigBoundary, 全不勾=不过滤',
        checks: s.bigChecks,
        onToggle: (k) {
          s.bigChecks[k] = !s.bigChecks[k];
          vm.changed();
        },
      ),
      const SizedBox(height: 4),
      RatioGroupBox(
        title: '质数个数(质:合)',
        tooltip: '质数: 2,3,5,7,11,13,17,19,23,29,31',
        checks: s.primeChecks,
        onToggle: (k) {
          s.primeChecks[k] = !s.primeChecks[k];
          vm.changed();
        },
      ),
    ],
  ));

  // ---- 页2: 五行(洛书) ----
  final pageWx = page(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      chk('五行(洛书)分区出号(启用)', s.chkWx, (v) {
        s.chkWx = v;
        vm.changed();
      }, tooltip: '尾数1/6=水, 2/7=火, 3/8=木, 4/9=金, 5/0=土, 每组7个号, 组间不重叠\n'
              '不勾选=不启用该过滤'),
      zoneRows(
        [for (final z in kWXZones) '${z.name}(${members(z.elements)}) 出号:'],
        s.wxLimits,
        (i, lo, hi) {
          s.wxLimits[i] = (lo, hi);
        },
      ),
    ],
  ));

  // ---- 页3: 五行(易经) ----
  final pageYj = page(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      chk('五行(易经)分区出号(启用)', s.chkYj, (v) {
        s.chkYj = v;
        vm.changed();
      }, tooltip: '金木水火土五组(与洛书分法不同), 覆盖1~35, 组间不重叠\n'
              '不勾选=不启用该过滤'),
      zoneRows(
        [for (final z in kYJZones) '${z.name}(${members(z.elements)}) 出号:'],
        s.yjLimits,
        (i, lo, hi) {
          s.yjLimits[i] = (lo, hi);
        },
      ),
    ],
  ));

  // ---- 页4: 五行尾数 ----
  final pageTwx = page(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      chk('五行尾数过滤(启用)', s.chkTailwx, (v) {
        s.chkTailwx = v;
        vm.changed();
      }, tooltip: '按个位尾数分五行: 金(4,9) 木(3,8) 水(1,6) 火(2,7) 土(0,5)\n'
              '各五行尾的出号个数及种类数均须落在设定范围内\n'
              '不勾选=不启用该过滤'),
      zoneRows(
        [for (final z in kTailWX) '${z.name}(${members(z.elements, pad: false)}):'],
        s.tailwxLimits,
        (i, lo, hi) {
          s.tailwxLimits[i] = (lo, hi);
        },
      ),
      rangeRow('五行尾数种类:', (s.tailwxKindMin, s.tailwxKindMax), 1, 5, (lo, hi) {
        s.tailwxKindMin = lo;
        s.tailwxKindMax = hi;
      }),
    ],
  ));

  // ---- 页5: 4分区 ----
  final pageFour = page(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      chk('4分区出号(启用)', s.chkFour, (v) {
        s.chkFour = v;
        vm.changed();
      }, tooltip: '0区01~09 / 1区10~19 / 2区20~29 / 3区30~35\n'
              '不勾选=不启用该过滤'),
      zoneRows(
        [
          for (var i = 0; i < kFourZones.length; i++)
            '$i区 ${two(kFourZones[i].$1)}~${two(kFourZones[i].$2)} 出号:',
        ],
        s.fourLimits,
        (i, lo, hi) {
          s.fourLimits[i] = (lo, hi);
        },
      ),
    ],
  ));

  // ---- 页6: 5分区 ----
  final pageFive = page(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      chk('5分区出号(启用)', s.chkFive, (v) {
        s.chkFive = v;
        vm.changed();
      }, tooltip: '1区01~07 / 2区08~14 / 3区15~21 / 4区22~28 / 5区29~35, 每区7个号\n'
              '不勾选=不启用该过滤'),
      zoneRows(
        [
          for (var i = 0; i < kFiveZones.length; i++)
            '${i + 1}区 ${two(kFiveZones[i].$1)}~${two(kFiveZones[i].$2)} 出号:',
        ],
        s.fiveLimits,
        (i, lo, hi) {
          s.fiveLimits[i] = (lo, hi);
        },
      ),
      chk('5区边缘码出号(启用)', s.chkEdge, (v) {
        s.chkEdge = v;
        vm.changed();
      }, tooltip: '边缘码=各分区首尾号: 01,07,08,14,15,21,22,28,29,35\n'
              '每个分区的边缘码最多1个\n'
              '不勾选=不启用该过滤'),
      rangeRow('边缘码出号个数:', (s.edgeMin, s.edgeMax), 0, 5, (lo, hi) {
        s.edgeMin = lo;
        s.edgeMax = hi;
      }),
    ],
  ));

  // ---- 页7: 红蓝绿波 ----
  final pageWave = page(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      chk('红蓝绿波过滤(启用)', s.chkWave, (v) {
        s.chkWave = v;
        vm.changed();
      }, tooltip: '红: 01,02,07,08,12,13,18,19,23,24,29,30\n'
              '蓝: 03,04,09,10,14,15,20,25,26,31,34,35\n'
              '绿: 05,06,11,16,17,21,22,27,28,32,33\n'
              '各波色出号个数须落在设定范围内\n不勾选=不启用该过滤'),
      zoneRows(
        [for (final z in kWaveZones) '${z.name}波出号:'],
        s.waveLimits,
        (i, lo, hi) {
          s.waveLimits[i] = (lo, hi);
        },
      ),
    ],
  ));

  // ---- 页8: 7分区与跨区 ----
  final pageSeven = page(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      chk('7分区出号(启用)', s.chkSeven, (v) {
        s.chkSeven = v;
        vm.changed();
      }, tooltip: '1区01~05 / 2区06~10 / 3区11~15 / 4区16~20 / 5区21~25 / '
              '6区26~30 / 7区31~35, 每区5个号\n不勾选=不启用该过滤'),
      zoneRows(
        [
          for (var i = 0; i < kSevenZones.length; i++)
            '${i + 1}区 ${two(kSevenZones[i].$1)}~${two(kSevenZones[i].$2)} 出号:',
        ],
        s.sevenLimits,
        (i, lo, hi) {
          s.sevenLimits[i] = (lo, hi);
        },
      ),
      chk('7分区跨区条件(启用)', s.chkSevenSpan, (v) {
        s.chkSevenSpan = v;
        vm.changed();
      }, tooltip: '统计5个号覆盖的分区数(1~5), 须落在设定范围内\n'
              '不勾选=不启用该过滤'),
      rangeRow('跨区范围(覆盖分区数):', (s.sevenSpanMin, s.sevenSpanMax), 1, 5,
          (lo, hi) {
        s.sevenSpanMin = lo;
        s.sevenSpanMax = hi;
      }),
      chk('7区边缘码出号(启用)', s.chkEdge7, (v) {
        s.chkEdge7 = v;
        vm.changed();
      }, tooltip: '边缘码=各分区首尾号: 01,05,06,10,11,15,16,20,21,25,26,30,31,35\n'
              '每个分区的边缘码最多1个\n'
              '不勾选=不启用该过滤'),
      rangeRow('边缘码出号个数:', (s.edge7Min, s.edge7Max), 0, 5, (lo, hi) {
        s.edge7Min = lo;
        s.edge7Max = hi;
      }),
    ],
  ));

  // ---- 页9: 三区间比 ----
  final pageSan = page(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      chk('三区间比过滤(启用)', s.chkSan, (v) {
        s.chkSan = v;
        vm.changed();
      }, tooltip: '1区01~11 / 2区12~22 / 3区23~35\n'
              '勾选各档允许的(1区:2区:3区)分布, 全不勾=不按分布过滤\n'
              '不勾选=不启用该过滤'),
      for (var t = 0; t < kSanTierNames.length; t++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: CondCheckbox(
            title: '${kSanTierNames[t]}:  '
                '${kSanPatterns[t].map((p) => '${p.$1}:${p.$2}:${p.$3}').join('  ')}',
            value: s.sanTiers[t],
            onChanged: (v) {
              s.sanTiers[t] = v;
              vm.changed();
            },
          ),
        ),
      zoneRows(
        [
          for (var i = 0; i < kSanRanges.length; i++)
            '${i + 1}区 ${two(kSanRanges[i].$1)}~${two(kSanRanges[i].$2)} 出号:',
        ],
        s.sanLimits,
        (i, lo, hi) {
          s.sanLimits[i] = (lo, hi);
        },
      ),
    ],
  ));

  // ---- 页10: 余数与结构 ----
  Widget pairField(String key, int value, int lo, int hi,
          void Function(int) onSet) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        NumberField(
            value: value,
            min: lo,
            max: hi,
            resetToken: token,
            onCommit: onSet,
            width: 52),
        const SizedBox(width: 6),
      ]);

  final pageRemainder = page(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      chk('012路出号(启用)', s.chkMod3, (v) {
        s.chkMod3 = v;
        vm.changed();
      }, tooltip: '0路=03,06,...,33; 1路=01,04,...,34; 2路=02,05,...,35\n'
              '各路出号个数须落在设定范围内\n不勾选=不启用该过滤'),
      Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < 3; i++)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text('$i路', style: const TextStyle(fontSize: 13, color: kTextDark)),
            const SizedBox(width: 4),
            pairField('mod3_min_$i', s.mod3Limits[i].$1, 0, 5,
                (x) => s.mod3Limits[i] = (x, s.mod3Limits[i].$2)),
            pairField('mod3_max_$i', s.mod3Limits[i].$2, 0, 5,
                (x) => s.mod3Limits[i] = (s.mod3Limits[i].$1, x)),
            const SizedBox(width: 10),
          ]),
      ]),
      chk('除7余数出号(启用)', s.chkMod7, (v) {
        s.chkMod7 = v;
        vm.changed();
      }, tooltip: '余0~余6共7组, 每组5个号, 每组出号个数须落在设定范围内\n'
              '不勾选=不启用该过滤'),
      Wrap(
        spacing: 14,
        runSpacing: 4,
        children: [
          for (var i = 0; i < 7; i++)
            Tooltip(
              message: '每组号码: '
                  '${[for (var n = 1; n <= 35; n++) if (n % 7 == i % 7) two(n)].join(', ')}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('余$i', style: const TextStyle(fontSize: 13, color: kTextDark)),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    pairField('mod7_min_$i', s.mod7Limits[i].$1, 0, 5,
                        (x) => s.mod7Limits[i] = (x, s.mod7Limits[i].$2)),
                    pairField('mod7_max_$i', s.mod7Limits[i].$2, 0, 5,
                        (x) => s.mod7Limits[i] = (s.mod7Limits[i].$1, x)),
                  ]),
                ],
              ),
            ),
        ],
      ),
      chk('余7跨区条件(启用)', s.chkMod7Span, (v) {
        s.chkMod7Span = v;
        vm.changed();
      }, tooltip: '统计5个号覆盖的余数组数(1~5), 须落在设定范围内\n'
              '不勾选=不启用该过滤'),
      rangeRow('跨区范围(覆盖余数组数):', (s.mod7SpanMin, s.mod7SpanMax), 1, 5,
          (lo, hi) {
        s.mod7SpanMin = lo;
        s.mod7SpanMax = hi;
      }),
      chk('连号过滤(启用)', s.chkCon, (v) {
        s.chkCon = v;
        vm.changed();
      }, tooltip: '2连号组数=长度恰为2的连号段个数; 三连号组数=长度>=3的连号段个数\n'
              '如 08,09,15,16,22 → 2连号2组 三连号0组; 08,09,10,22,25 → 2连号0组 三连号1组\n'
              '不勾选=不启用该过滤'),
      Row(mainAxisSize: MainAxisSize.min, children: [
        rangeRow('2连号组数:', (s.con2Min, s.con2Max), 0, 2, (lo, hi) {
          s.con2Min = lo;
          s.con2Max = hi;
        }),
        const SizedBox(width: 16),
        rangeRow('三连号组数:', (s.con3Min, s.con3Max), 0, 1, (lo, hi) {
          s.con3Min = lo;
          s.con3Max = hi;
        }),
      ]),
      rangeRow('尾数种类:', (s.tailMin, s.tailMax), 1, 5, (lo, hi) {
        s.tailMin = lo;
        s.tailMax = hi;
      }),
      chk('尾数之和过滤(启用)', s.chkTsum, (v) {
        s.chkTsum = v;
        vm.changed();
      }, tooltip: '5个号码的个位数相加, 如 08,12,15,29,30 → 8+2+5+9+0=24\n'
              '不勾选=不启用该过滤'),
      rangeRow('尾数和范围:', (s.tsumMin, s.tsumMax), 0, 45, (lo, hi) {
        s.tsumMin = lo;
        s.tsumMax = hi;
      }),
    ],
  ));

  // ---- 页11: 号码限定 ----
  final pageLimit = page(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        const RowLabel('胆码(必含):'),
        const SizedBox(width: 6),
        TextEditField(
          value: s.danText,
          resetToken: token,
          hint: '如: 07 18',
          width: 180,
          onChanged: (v) => s.danText = v,
        ),
      ]),
      Row(mainAxisSize: MainAxisSize.min, children: [
        const RowLabel('上期号码:'),
        const SizedBox(width: 6),
        TextEditField(
          value: s.prevText,
          resetToken: token,
          hint: '如: 04 13 19 29 31 (留空=不使用重邻孤)',
          width: 260,
          onChanged: (v) => s.prevText = v,
        ),
      ]),
      chk('重邻孤过滤(启用)', s.chkRn, (v) {
        s.chkRn = v;
        vm.changed();
      }, tooltip: '重号=上期开奖号码; 邻号=上期号码左右相邻(±1, 已剔除重号);\n'
              '孤号=既非重号也非邻号的号码。上期号码留空=不过滤'),
      Row(mainAxisSize: MainAxisSize.min, children: [
        rangeRow('重号个数:', (s.repMin, s.repMax), 0, 5, (lo, hi) {
          s.repMin = lo;
          s.repMax = hi;
        }),
        const SizedBox(width: 16),
        rangeRow('邻号个数:', (s.nbrMin, s.nbrMax), 0, 5, (lo, hi) {
          s.nbrMin = lo;
          s.nbrMax = hi;
        }),
      ]),
      rangeRow('孤号个数:', (s.orphMin, s.orphMax), 0, 5, (lo, hi) {
        s.orphMin = lo;
        s.orphMax = hi;
      }),
    ],
  ));

  // ---- 页12: 固定胆组 ----
  final pageDangroup = page(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      chk('固定胆组过滤(启用)', s.chkDangroup, (v) {
        s.chkDangroup = v;
        vm.changed();
      }, tooltip: '8组预定义号码集合, 每组设置该组号码的出现个数范围\n'
              '悬停查看各组号码; 0~5=该组不限制\n不勾选=不启用该过滤'),
      for (var i = 0; i < kDanGroups.length; i++)
        rangeRow(
          _danGroupLabel(i),
          s.dangroupLimits[i],
          0,
          5,
          (lo, hi) => s.dangroupLimits[i] = (lo, hi),
          labelTooltip: danGroupTooltip(i),
        ),
    ],
  ));

  return [
    page1,
    pageWx,
    pageYj,
    pageTwx,
    pageFour,
    pageFive,
    pageWave,
    pageSeven,
    pageSan,
    pageRemainder,
    pageLimit,
    pageDangroup,
  ];
}

const List<String> _kTabTitles = [
  '杀号/区间与比例',
  '五行(洛书)',
  '五行(易经)',
  '五行尾数',
  '4分区',
  '5分区',
  '红蓝绿波',
  '7分区与跨区',
  '三区间比',
  '余数与结构',
  '号码限定',
  '固定胆组',
];

List<String> get conditionTabTitles => _kTabTitles;

String _danGroupLabel(int i) {
  final numsTxt = (kDanGroups[i].toList()..sort()).map(two).join(',');
  final short = numsTxt.length <= 11 ? numsTxt : '${numsTxt.substring(0, 11)}…';
  return '胆组${i + 1}: $short';
}

/// 胆组完整号码(用于悬停提示)。
String danGroupTooltip(int i) =>
    (kDanGroups[i].toList()..sort()).map(two).join(',');
