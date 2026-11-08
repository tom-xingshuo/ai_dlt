/// ShrinkSettings JSON 持久化往返测试。
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/ui/features/shrink/model/shrink_settings.dart';

void main() {
  test('默认值 JSON 往返一致', () {
    final s = ShrinkSettings();
    final m = s.toJson();
    final s2 = ShrinkSettings();
    s2.updateFromJson(m);
    expect(s2.toJson(), m);
  });

  test('修改后 JSON 往返保留全部字段', () {
    final s = ShrinkSettings()
      ..killText = '03 11 22'
      ..danText = '07 18'
      ..prevText = '04 13 19 29 31'
      ..acMin = 3
      ..acMax = 5
      ..chkZone = false
      ..zoneHeadMin = 0
      ..zoneHeadMax = 4
      ..sumMin = 60
      ..sumMax = 120
      ..chkSum = false
      ..spanMin = 10
      ..spanMax = 30
      ..oddChecks = [true, false, true, false, true, false]
      ..bigChecks = [false, true, false, true, false, true]
      ..primeChecks = [true, true, false, false, false, true]
      ..wxLimits = [(1, 2), (0, 3), (2, 4), (0, 1), (1, 5)]
      ..sanTiers = [false, true, true]
      ..dangroupLimits = [(0, 5), (1, 2), (0, 3), (2, 5), (0, 0), (1, 1), (3, 4), (0, 2)]
      ..chkDangroup = true
      ..chkRn = false
      ..orphMin = 0
      ..orphMax = 5
      ..tailwxKindMin = 1
      ..tailwxKindMax = 4
      ..mod7Limits = List.filled(7, (0, 1))
      ..tailMin = 2
      ..tailMax = 4;

    final s2 = ShrinkSettings();
    s2.updateFromJson(s.toJson());

    expect(s2.killText, '03 11 22');
    expect(s2.danText, '07 18');
    expect(s2.prevText, '04 13 19 29 31');
    expect(s2.acMin, 3);
    expect(s2.acMax, 5);
    expect(s2.chkZone, false);
    expect(s2.zoneHeadMin, 0);
    expect(s2.zoneHeadMax, 4);
    expect(s2.sumMin, 60);
    expect(s2.sumMax, 120);
    expect(s2.chkSum, false);
    expect(s2.spanMin, 10);
    expect(s2.spanMax, 30);
    expect(s2.oddChecks, [true, false, true, false, true, false]);
    expect(s2.bigChecks, [false, true, false, true, false, true]);
    expect(s2.primeChecks, [true, true, false, false, false, true]);
    expect(s2.wxLimits, [(1, 2), (0, 3), (2, 4), (0, 1), (1, 5)]);
    expect(s2.sanTiers, [false, true, true]);
    expect(s2.dangroupLimits,
        [(0, 5), (1, 2), (0, 3), (2, 5), (0, 0), (1, 1), (3, 4), (0, 2)]);
    expect(s2.chkDangroup, true);
    expect(s2.chkRn, false);
    expect(s2.orphMin, 0);
    expect(s2.orphMax, 5);
    expect(s2.tailwxKindMin, 1);
    expect(s2.tailwxKindMax, 4);
    expect(s2.mod7Limits, List.filled(7, (0, 1)));
    expect(s2.tailMin, 2);
    expect(s2.tailMax, 4);
  });

  test('损坏的 JSON 字段回退默认值', () {
    final s = ShrinkSettings();
    s.updateFromJson({
      'acMin': 'bad',
      'chkZone': 'not-bool',
      'wxLimits': 42,
      'oddChecks': [true],
    });
    expect(s.acMin, 2); // 保持默认
    expect(s.chkZone, true);
    expect(s.wxLimits.length, 5);
    expect(s.oddChecks.length, 6);
  });

  test('parseInts 提取 1~35 且去重', () {
    expect(ShrinkSettings.parseInts('03 11 22'), {3, 11, 22});
    expect(ShrinkSettings.parseInts('a1,b35,c99,3'), {1, 35, 3});
    expect(ShrinkSettings.parseInts(''), isEmpty);
    expect(ShrinkSettings.parseInts('0 36'), isEmpty);
  });
}
