/// 缩水过滤常量定义（移植自 utils/calcute_funcs.py）。
library;

/// 区间对 (lo, hi)。
typedef Range2 = (int, int);

/// 三元分布 (a, b, c)，用于三区间比形态。
typedef Pattern3 = (int, int, int);

/// 带名称的号码分区。
class NamedZone {
  final String name;
  final Set<int> elements;

  const NamedZone(this.name, this.elements);
}

const Set<int> kPrimes = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31};

/// 1~17 为小, 18~35 为大。
const int kBigBoundary = 18;

// 龙头/中间/凤尾分区定义(区间可重叠, 同一号码计入其所属的每个分区)
const Range2 kZoneHead = (1, 13); // 龙头 01~13
const Range2 kZoneMid = (9, 26); // 中间 09~26
const Range2 kZoneTail = (24, 35); // 凤尾 24~35

/// 五行(洛书)分区: 尾数1/6=水 2/7=火 3/8=木 4/9=金 5/0=土, 共5组各7个号, 组间不重叠
const List<NamedZone> kWXZones = [
  NamedZone('金', {4, 14, 24, 34, 9, 19, 29}),
  NamedZone('木', {3, 13, 23, 33, 8, 18, 28}),
  NamedZone('水', {1, 11, 21, 31, 6, 16, 26}),
  NamedZone('火', {2, 12, 22, 32, 7, 17, 27}),
  NamedZone('土', {5, 15, 25, 35, 10, 20, 30}),
];

/// 五行(易经)分区(与洛书分法不同): 覆盖1~35, 组间不重叠; 默认金木水火土出号0~3, 土1~4
const List<NamedZone> kYJZones = [
  NamedZone('金', {9, 10, 21, 22, 33, 34}),
  NamedZone('木', {3, 4, 15, 16, 27, 28}),
  NamedZone('水', {1, 12, 13, 24, 25}),
  NamedZone('火', {6, 7, 18, 19, 30, 31}),
  NamedZone('土', {2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35}),
];

const List<Range2> kYJDefaults = [
  (0, 3), (0, 3), (0, 3), (0, 3), (1, 4),
];

/// 五行尾数: 按个位尾数分五行(金4,9/木3,8/水1,6/火2,7/土0,5); 默认金木水火尾0~1, 土尾1~2
const List<NamedZone> kTailWX = [
  NamedZone('金尾', {4, 9}),
  NamedZone('木尾', {3, 8}),
  NamedZone('水尾', {1, 6}),
  NamedZone('火尾', {2, 7}),
  NamedZone('土尾', {0, 5}),
];

const List<Range2> kTailWXDefaults = [
  (0, 1), (0, 1), (0, 1), (0, 1), (1, 2),
];

/// 红蓝绿波(双色球波色划分): 红/蓝各12个号, 绿11个号
const List<NamedZone> kWaveZones = [
  NamedZone('红', {1, 2, 7, 8, 12, 13, 18, 19, 23, 24, 29, 30}),
  NamedZone('蓝', {3, 4, 9, 10, 14, 15, 20, 25, 26, 31, 34, 35}),
  NamedZone('绿', {5, 6, 11, 16, 17, 21, 22, 27, 28, 32, 33}),
];

const List<Range2> kWaveDefaults = [(0, 3), (0, 3), (0, 3)];

/// 三区间比: 1区01~11 / 2区12~22 / 3区23~35; 各档为允许的(1区:2区:3区)分布
const List<Range2> kSanRanges = [(1, 11), (12, 22), (23, 35)];

const List<List<Pattern3>> kSanPatterns = [
  // 一次选(常态)
  [(2, 2, 1), (2, 1, 2), (1, 2, 2), (3, 2, 1), (1, 3, 1), (1, 1, 3)],
  // 二次选(偏态)
  [(3, 2, 0), (3, 0, 2), (2, 3, 0), (0, 3, 2), (2, 0, 3), (0, 2, 3)],
  // 三次选(极端)
  [(5, 0, 0), (0, 5, 0), (0, 0, 5)],
];

const List<String> kSanTierNames = ['一次选(常态)', '二次选(偏态)', '三次选(极端)'];

/// 固定胆组: 8组预定义号码集合, 每组可设出号个数范围(默认0~5=不过滤)
const List<List<int>> kDanGroups = [
  [5, 15, 25, 35, 10, 20, 30],
  [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
  [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35],
  [7, 14, 21, 28, 35, 1, 8, 15, 22, 29],
  [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35],
  [1, 2, 7, 8, 12, 13, 18, 19, 23, 24, 29, 30],
  [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31],
  [1, 4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20, 21, 22, 24, 25, 26, 27, 28, 30,
   32, 33, 34, 35],
];

/// 5分区: 每区7个连续号, 组间不重叠; 默认2区最多出2个, 其余0~3
const List<Range2> kFiveZones = [(1, 7), (8, 14), (15, 21), (22, 28), (29, 35)];
const List<Range2> kFiveDefaults = [(0, 3), (0, 2), (0, 3), (0, 3), (0, 3)];

/// 4分区(十位段): 0区01~09 / 1区10~19 / 2区20~29 / 3区30~35, 组间不重叠
const List<Range2> kFourZones = [(1, 9), (10, 19), (20, 29), (30, 35)];
const List<Range2> kFourDefaults = [(0, 3), (0, 2), (0, 2), (0, 3)];

/// 5区边缘码: 各分区首尾号(每分区边缘码最多1个)
const Set<int> kEdgeNums = {1, 7, 8, 14, 15, 21, 22, 28, 29, 35};

/// 7区边缘码: 各分区首尾号(每分区边缘码最多1个)
const Set<int> kEdge7Nums = {1, 5, 6, 10, 11, 15, 16, 20, 21, 25, 26, 30, 31, 35};

/// 7分区: 每区5个连续号, 组间不重叠; 默认1区/7区最多3个, 其余最多2个
const List<Range2> kSevenZones = [
  (1, 5), (6, 10), (11, 15), (16, 20), (21, 25), (26, 30), (31, 35),
];
const List<Range2> kSevenDefaults = [
  (0, 3), (0, 2), (0, 2), (0, 2), (0, 2), (0, 2), (0, 3),
];

/// 7分区跨区: 5个号覆盖的分区数范围
const Range2 kSevenSpanDefault = (2, 4);

/// 生成 n 组相同默认区间。
List<Range2> defaultLimits(int n, int lo, int hi) =>
    List.filled(n, (lo, hi));
