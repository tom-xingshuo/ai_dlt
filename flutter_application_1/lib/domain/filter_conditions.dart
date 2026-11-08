/// 缩水条件过滤计算（移植自 utils/calcute_funcs.py 的 FilterConditions）。
///
/// 某项开关为 false 时跳过该项过滤; 字段语义与 Python 版一一对应。
library;

import '../data/constants.dart';

/// 连号统计: 返回 (2连号组数, 三连号及以上组数)。
(int, int) consecutiveStats(List<int> nums) {
  var two = 0, three = 0, run = 1;
  for (var i = 1; i < nums.length; i++) {
    if (nums[i] - nums[i - 1] == 1) {
      run++;
    } else {
      if (run == 2) {
        two++;
      } else if (run >= 3) {
        three++;
      }
      run = 1;
    }
  }
  if (run == 2) {
    two++;
  } else if (run >= 3) {
    three++;
  }
  return (two, three);
}

/// AC 值: 两两差绝对值去重个数 - (n-1)。
int acValue(List<int> nums) {
  final diffs = <int>{};
  for (var i = 0; i < nums.length; i++) {
    for (var j = i + 1; j < nums.length; j++) {
      diffs.add((nums[i] - nums[j]).abs());
    }
  }
  return diffs.length - (nums.length - 1);
}

class FilterConditions {
  bool sumFilter = true; // 和值区间开关
  int sumMin = 15, sumMax = 165;
  bool spanFilter = true; // 跨度区间开关
  int spanMin = 4, spanMax = 6; // 跨度范围
  int acMin = 0, acMax = 6;
  bool zoneFilter = true; // 龙头/中间/凤尾分区出号开关
  int zoneHeadMin = 1, zoneHeadMax = 3; // 龙头(01~13)出号个数
  int zoneMidMin = 1, zoneMidMax = 4; // 中间(09~26)出号个数
  int zoneTailMin = 1, zoneTailMax = 3; // 凤尾(24~35)出号个数
  bool wxFilter = true; // 五行(洛书)分区出号开关
  List<Range2> wxLimits = defaultLimits(5, 0, 3); // 金木水火土 出号个数范围
  bool yjFilter = true; // 五行(易经)分区出号开关
  List<Range2> yjLimits = List.of(kYJDefaults);
  bool fiveFilter = true; // 5分区出号开关
  List<Range2> fiveLimits = List.of(kFiveDefaults);
  bool fourFilter = true; // 4分区出号开关
  List<Range2> fourLimits = List.of(kFourDefaults);
  bool sevenFilter = true; // 7分区出号开关
  List<Range2> sevenLimits = List.of(kSevenDefaults);
  bool sevenSpanFilter = true; // 7分区跨区开关
  int sevenSpanMin = kSevenSpanDefault.$1, sevenSpanMax = kSevenSpanDefault.$2;
  bool edgeFilter = true; // 5区边缘码过滤开关
  int edgeMin = 0, edgeMax = 3; // 边缘码总个数范围
  bool edge7Filter = true; // 7区边缘码过滤开关
  int edge7Min = 0, edge7Max = 4;
  Set<int>? oddCounts; // 合法奇数个数, null 表示不过滤
  Set<int>? bigCounts; // 合法大号个数
  Set<int>? primeCounts; // 合法质数个数
  bool mod3Filter = true; // 012路出号开关
  List<Range2> mod3Limits = defaultLimits(3, 0, 5); // 0/1/2路 出号个数范围
  bool mod7Filter = true; // 除7余数出号开关
  List<Range2> mod7Limits = defaultLimits(7, 0, 2); // 余0~余6 每组出号个数范围
  bool mod7SpanFilter = true; // 余7跨区开关
  int mod7SpanMin = 2, mod7SpanMax = 4; // 覆盖余数组数范围
  bool conFilter = true; // 连号过滤开关
  int con2Min = 0, con2Max = 1; // 2连号组数范围
  int con3Min = 0, con3Max = 1; // 三连号及以上组数范围
  int tailMin = 1, tailMax = 5; // 尾数种类范围(无开关)
  bool tsumFilter = true; // 尾数之和过滤开关
  int tsumMin = 10, tsumMax = 34; // 尾数(个位)之和范围
  bool tailwxFilter = true; // 五行尾数过滤开关
  List<Range2> tailwxLimits = List.of(kTailWXDefaults); // 各五行尾出号个数范围
  int tailwxKindMin = 2, tailwxKindMax = 5; // 五行尾数种类范围
  bool waveFilter = true; // 红蓝绿波过滤开关
  List<Range2> waveLimits = List.of(kWaveDefaults); // 红蓝绿 各波出号个数范围
  bool sanFilter = true; // 三区间比开关
  List<bool> sanTiers = [true, false, false]; // 常态/偏态/极端 各档勾选
  List<Range2> sanLimits = defaultLimits(3, 0, 3); // 1~3区出号个数范围
  bool dangroupFilter = false; // 固定胆组开关(各组默认0~5=不过滤)
  List<Range2> dangroupLimits =
      defaultLimits(kDanGroups.length, 0, 5); // 每胆组出号个数范围
  Set<int> kill = {}; // 杀号
  Set<int> dan = {}; // 胆码
  Set<int>? prevDraw; // 上期号码
  bool rnFilter = true; // 重邻孤过滤开关(需填上期号码)
  int repMin = 0, repMax = 2; // 重号(上期开奖号)个数范围
  int nbrMin = 1, nbrMax = 3; // 邻号(上期号±1, 剔除重号)个数范围
  int orphMin = 1, orphMax = 4; // 孤号(非重非邻)个数范围

  /// 判断组合是否满足全部已启用条件。
  bool match(List<int> nums) {
    final numSet = nums.toSet();
    for (final n in nums) {
      if (kill.contains(n)) {
        return false;
      }
    }
    final ac = acValue(nums);
    if (ac < acMin || ac > acMax) {
      return false;
    }
    if (zoneFilter) {
      final h = nums.where((n) => n >= kZoneHead.$1 && n <= kZoneHead.$2).length;
      if (h < zoneHeadMin || h > zoneHeadMax) {
        return false;
      }
      final m = nums.where((n) => n >= kZoneMid.$1 && n <= kZoneMid.$2).length;
      if (m < zoneMidMin || m > zoneMidMax) {
        return false;
      }
      final t = nums.where((n) => n >= kZoneTail.$1 && n <= kZoneTail.$2).length;
      if (t < zoneTailMin || t > zoneTailMax) {
        return false;
      }
    }
    if (wxFilter) {
      for (var i = 0; i < kWXZones.length; i++) {
        final elements = kWXZones[i].elements;
        final cnt = nums.where(elements.contains).length;
        final (wmin, wmax) = wxLimits[i];
        if (cnt < wmin || cnt > wmax) {
          return false;
        }
      }
    }
    if (yjFilter) {
      for (var i = 0; i < kYJZones.length; i++) {
        final elements = kYJZones[i].elements;
        final cnt = nums.where(elements.contains).length;
        final (wmin, wmax) = yjLimits[i];
        if (cnt < wmin || cnt > wmax) {
          return false;
        }
      }
    }
    if (fourFilter) {
      for (var i = 0; i < kFourZones.length; i++) {
        final (lo, hi) = kFourZones[i];
        final cnt = nums.where((n) => n >= lo && n <= hi).length;
        final (fmin, fmax) = fourLimits[i];
        if (cnt < fmin || cnt > fmax) {
          return false;
        }
      }
    }
    if (fiveFilter) {
      for (var i = 0; i < kFiveZones.length; i++) {
        final (lo, hi) = kFiveZones[i];
        final cnt = nums.where((n) => n >= lo && n <= hi).length;
        final (fmin, fmax) = fiveLimits[i];
        if (cnt < fmin || cnt > fmax) {
          return false;
        }
      }
    }
    if (sevenFilter) {
      for (var i = 0; i < kSevenZones.length; i++) {
        final (lo, hi) = kSevenZones[i];
        final cnt = nums.where((n) => n >= lo && n <= hi).length;
        final (smin, smax) = sevenLimits[i];
        if (cnt < smin || cnt > smax) {
          return false;
        }
      }
    }
    if (sevenSpanFilter) {
      final zonesHit =
          kSevenZones.where((z) => nums.any((n) => n >= z.$1 && n <= z.$2)).length;
      if (zonesHit < sevenSpanMin || zonesHit > sevenSpanMax) {
        return false;
      }
    }
    if (edgeFilter) {
      var total = 0;
      for (final n in nums) {
        if (kEdgeNums.contains(n)) {
          total++;
        }
      }
      if (total < edgeMin || total > edgeMax) {
        return false;
      }
      // 每个分区的边缘码(首尾号)最多1个
      for (final (lo, hi) in kFiveZones) {
        final both = (numSet.contains(lo) ? 1 : 0) + (numSet.contains(hi) ? 1 : 0);
        if (both > 1) {
          return false;
        }
      }
    }
    if (edge7Filter) {
      var total = 0;
      for (final n in nums) {
        if (kEdge7Nums.contains(n)) {
          total++;
        }
      }
      if (total < edge7Min || total > edge7Max) {
        return false;
      }
      for (final (lo, hi) in kSevenZones) {
        final both = (numSet.contains(lo) ? 1 : 0) + (numSet.contains(hi) ? 1 : 0);
        if (both > 1) {
          return false;
        }
      }
    }

    if (sumFilter) {
      final s = nums.fold<int>(0, (a, b) => a + b);
      if (s < sumMin || s > sumMax) {
        return false;
      }
    }
    final span = nums.last - nums.first;
    if (spanFilter) {
      if (span < spanMin || span > spanMax) {
        return false;
      }
    }

    if (oddCounts != null) {
      final odd = nums.where((n) => n.isOdd).length;
      if (!oddCounts!.contains(odd)) {
        return false;
      }
    }
    if (bigCounts != null) {
      final big = nums.where((n) => n >= kBigBoundary).length;
      if (!bigCounts!.contains(big)) {
        return false;
      }
    }
    if (primeCounts != null) {
      final prime = nums.where(kPrimes.contains).length;
      if (!primeCounts!.contains(prime)) {
        return false;
      }
    }

    if (mod3Filter) {
      final mod3 = List<int>.filled(3, 0);
      for (final n in nums) {
        mod3[n % 3]++;
      }
      for (var i = 0; i < 3; i++) {
        final (lo, hi) = mod3Limits[i];
        if (mod3[i] < lo || mod3[i] > hi) {
          return false;
        }
      }
    }

    if (mod7Filter || mod7SpanFilter) {
      final mod7 = List<int>.filled(7, 0);
      for (final n in nums) {
        mod7[n % 7]++;
      }
      if (mod7Filter) {
        for (var i = 0; i < 7; i++) {
          final (lo, hi) = mod7Limits[i];
          if (mod7[i] < lo || mod7[i] > hi) {
            return false;
          }
        }
      }
      if (mod7SpanFilter) {
        final zonesHit = mod7.where((c) => c > 0).length;
        if (zonesHit < mod7SpanMin || zonesHit > mod7SpanMax) {
          return false;
        }
      }
    }

    final (twoGroups, threeGroups) = consecutiveStats(nums);
    if (conFilter) {
      if (twoGroups < con2Min || twoGroups > con2Max) {
        return false;
      }
      if (threeGroups < con3Min || threeGroups > con3Max) {
        return false;
      }
    }

    final tails = nums.map((n) => n % 10).toSet().length;
    if (tails < tailMin || tails > tailMax) {
      return false;
    }
    if (tsumFilter) {
      final tsum = nums.fold<int>(0, (a, n) => a + n % 10);
      if (tsum < tsumMin || tsum > tsumMax) {
        return false;
      }
    }
    if (tailwxFilter) {
      var violations = 0;
      var kinds = 0;
      for (var i = 0; i < kTailWX.length; i++) {
        final tset = kTailWX[i].elements;
        final cnt = nums.where((n) => tset.contains(n % 10)).length;
        final (kmin, kmax) = tailwxLimits[i];
        if (kmin <= cnt && cnt <= kmax) {
          if (cnt > 0) {
            kinds++;
          }
        } else {
          violations++;
        }
      }
      if (kinds < tailwxKindMin || kinds > tailwxKindMax) {
        violations++;
      }
      if (violations > 0) {
        return false;
      }
    }
    if (waveFilter) {
      for (var i = 0; i < kWaveZones.length; i++) {
        final elements = kWaveZones[i].elements;
        final cnt = nums.where(elements.contains).length;
        final (wmin, wmax) = waveLimits[i];
        if (cnt < wmin || cnt > wmax) {
          return false;
        }
      }
    }
    if (sanFilter) {
      final counts = (
        nums.where((n) => n >= kSanRanges[0].$1 && n <= kSanRanges[0].$2).length,
        nums.where((n) => n >= kSanRanges[1].$1 && n <= kSanRanges[1].$2).length,
        nums.where((n) => n >= kSanRanges[2].$1 && n <= kSanRanges[2].$2).length,
      );
      final allowed = <Pattern3>[];
      for (var t = 0; t < kSanPatterns.length; t++) {
        if (t < sanTiers.length && sanTiers[t]) {
          allowed.addAll(kSanPatterns[t]);
        }
      }
      if (allowed.isNotEmpty && !allowed.contains(counts)) {
        return false;
      }
      for (var i = 0; i < 3; i++) {
        final (lo, hi) = sanLimits[i];
        final cnt = [counts.$1, counts.$2, counts.$3][i];
        if (cnt < lo || cnt > hi) {
          return false;
        }
      }
    }
    if (dangroupFilter) {
      for (var i = 0; i < kDanGroups.length; i++) {
        final group = kDanGroups[i].toSet();
        final cnt = nums.where(group.contains).length;
        final (gmin, gmax) = dangroupLimits[i];
        if (cnt < gmin || cnt > gmax) {
          return false;
        }
      }
    }

    if (dan.isNotEmpty && !numSet.containsAll(dan)) {
      return false;
    }

    if (rnFilter && prevDraw != null) {
      var rep = 0, nbr = 0;
      for (final n in nums) {
        if (prevDraw!.contains(n)) {
          rep++;
        } else if (prevDraw!.contains(n - 1) || prevDraw!.contains(n + 1)) {
          nbr++;
        }
      }
      if (rep < repMin || rep > repMax) {
        return false;
      }
      if (nbr < nbrMin || nbr > nbrMax) {
        return false;
      }
      final orph = 5 - rep - nbr;
      if (orph < orphMin || orph > orphMax) {
        return false;
      }
    }

    return true;
  }
}
