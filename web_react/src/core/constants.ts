import type { Range } from './types';

export interface NamedZone {
  name: string;
  nums: number[];
}

export const PRIMES = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31];
export const BIG_BOUNDARY = 18; // 1~17 为小, 18~35 为大

// 龙头/中间/凤尾分区(区间可重叠)
export const ZONE_HEAD: Range = [1, 13];
export const ZONE_MID: Range = [9, 26];
export const ZONE_TAIL: Range = [24, 35];

// 五行(洛书): 尾数1/6=水 2/7=火 3/8=木 4/9=金 5/0=土
export const WX_ZONES: NamedZone[] = [
  { name: '金', nums: [4, 14, 24, 34, 9, 19, 29] },
  { name: '木', nums: [3, 13, 23, 33, 8, 18, 28] },
  { name: '水', nums: [1, 11, 21, 31, 6, 16, 26] },
  { name: '火', nums: [2, 12, 22, 32, 7, 17, 27] },
  { name: '土', nums: [5, 15, 25, 35, 10, 20, 30] },
];

// 五行(易经), 覆盖1~35且组间不重叠
export const YJ_ZONES: NamedZone[] = [
  { name: '金', nums: [9, 10, 21, 22, 33, 34] },
  { name: '木', nums: [3, 4, 15, 16, 27, 28] },
  { name: '水', nums: [1, 12, 13, 24, 25] },
  { name: '火', nums: [6, 7, 18, 19, 30, 31] },
  { name: '土', nums: [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35] },
];
export const YJ_DEFAULTS: Range[] = [[0, 3], [0, 3], [0, 3], [0, 3], [1, 4]];

// 五行尾数(按个位尾数)
export const TAIL_WX: NamedZone[] = [
  { name: '金尾', nums: [4, 9] },
  { name: '木尾', nums: [3, 8] },
  { name: '水尾', nums: [1, 6] },
  { name: '火尾', nums: [2, 7] },
  { name: '土尾', nums: [0, 5] },
];
export const TAIL_WX_DEFAULTS: Range[] = [[0, 1], [0, 1], [0, 1], [0, 1], [1, 2]];

// 尾数红蓝绿: 红1,2,7,8 / 蓝3,4,9,0 / 绿5,6
export const TAIL_COLOR: NamedZone[] = [
  { name: '红尾', nums: [1, 2, 7, 8] },
  { name: '蓝尾', nums: [3, 4, 9, 0] },
  { name: '绿尾', nums: [5, 6] },
];
export const TAIL_COLOR_DEFAULTS: Range[] = [[0, 5], [0, 5], [0, 5]];

// 红蓝绿波(双色球波色划分)
export const WAVE_ZONES: NamedZone[] = [
  { name: '红', nums: [1, 2, 7, 8, 12, 13, 18, 19, 23, 24, 29, 30] },
  { name: '蓝', nums: [3, 4, 9, 10, 14, 15, 20, 25, 26, 31, 34, 35] },
  { name: '绿', nums: [5, 6, 11, 16, 17, 21, 22, 27, 28, 32, 33] },
];
export const WAVE_DEFAULTS: Range[] = [[0, 3], [0, 3], [0, 3]];

// 三区间比: 1区01~11 / 2区12~22 / 3区23~35
export const SAN_RANGES: Range[] = [[1, 11], [12, 22], [23, 35]];
export const SAN_PATTERNS: Array<Array<[number, number, number]>> = [
  [[2, 2, 1], [2, 1, 2], [1, 2, 2], [3, 2, 1], [1, 3, 1], [1, 1, 3]], // 一次选(常态)
  [[3, 2, 0], [3, 0, 2], [2, 3, 0], [0, 3, 2], [2, 0, 3], [0, 2, 3]], // 二次选(偏态)
  [[5, 0, 0], [0, 5, 0], [0, 0, 5]], // 三次选(极端)
];
export const SAN_TIER_NAMES = ['一次选(常态)', '二次选(偏态)', '三次选(极端)'];
export const SAN_ALL_PATTERNS = SAN_PATTERNS.flat(); // 15种比例平铺

// 固定胆组
export const DAN_GROUPS: number[][] = [
  [5, 15, 25, 35, 10, 20, 30],
  [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
  [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35],
  [7, 14, 21, 28, 35, 1, 8, 15, 22, 29],
  [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35],
  [1, 2, 7, 8, 12, 13, 18, 19, 23, 24, 29, 30],
  [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31],
  [1, 4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20, 21, 22, 24, 25, 26, 27, 28, 30, 32, 33, 34, 35],
];

// 4分区(十位段)
export const FOUR_ZONES: Range[] = [[1, 9], [10, 19], [20, 29], [30, 35]];
export const FOUR_DEFAULTS: Range[] = [[0, 3], [0, 2], [0, 2], [0, 3]];

// 5分区: 每区7个连续号
export const FIVE_ZONES: Range[] = [[1, 7], [8, 14], [15, 21], [22, 28], [29, 35]];
export const FIVE_DEFAULTS: Range[] = [[0, 3], [0, 2], [0, 3], [0, 3], [0, 3]];
export const EDGE_NUMS = [1, 7, 8, 14, 15, 21, 22, 28, 29, 35];

// 7分区: 每区5个连续号
export const SEVEN_ZONES: Range[] = [
  [1, 5], [6, 10], [11, 15], [16, 20], [21, 25], [26, 30], [31, 35],
];
export const SEVEN_DEFAULTS: Range[] = [
  [0, 3], [0, 2], [0, 2], [0, 2], [0, 2], [0, 2], [0, 3],
];
export const SEVEN_SPAN_DEFAULT: Range = [2, 4];
export const EDGE7_NUMS = [1, 5, 6, 10, 11, 15, 16, 20, 21, 25, 26, 30, 31, 35];
