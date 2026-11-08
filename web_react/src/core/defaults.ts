import {
  DAN_GROUPS, FIVE_DEFAULTS, FOUR_DEFAULTS, SEVEN_DEFAULTS,
  TAIL_COLOR_DEFAULTS, TAIL_WX_DEFAULTS, WAVE_DEFAULTS, YJ_DEFAULTS,
} from './constants';
import type { Range, Settings } from './types';

/** 界面默认条件, 与 shrink_tool.py 构造时的初始值一致。 */
export function defaultSettings(): Settings {
  return {
    killText: '',
    acMin: 2,
    acMax: 6,
    zoneFilter: true,
    zoneHead: [1, 3],
    zoneMid: [1, 4],
    zoneTail: [1, 3],
    sumFilter: true,
    sumMin: 70,
    sumMax: 110,
    spanFilter: true,
    spanMin: 4,
    spanMax: 6,
    odd: [false, false, false, false, false, false],
    big: [false, false, false, false, false, false],
    prime: [false, false, false, false, false, false],

    wxFilter: true,
    wxLimits: [[0, 3], [0, 3], [0, 3], [0, 3], [0, 3]],
    yjFilter: true,
    yjLimits: YJ_DEFAULTS.map((r) => [...r] as Range),

    tailwxFilter: true,
    tailwxLimits: TAIL_WX_DEFAULTS.map((r) => [...r] as Range),
    tailwxKind: [2, 5],

    tailcolorFilter: true,
    tailcolorLimits: TAIL_COLOR_DEFAULTS.map((r) => [...r] as Range),

    fourFilter: true,
    fourLimits: FOUR_DEFAULTS.map((r) => [...r] as Range),
    fiveFilter: true,
    fiveLimits: FIVE_DEFAULTS.map((r) => [...r] as Range),
    edgeFilter: true,
    edge: [0, 3],
    sevenFilter: true,
    sevenLimits: SEVEN_DEFAULTS.map((r) => [...r] as Range),
    sevenSpanFilter: true,
    sevenSpanMin: 2,
    sevenSpanMax: 4,
    edge7Filter: true,
    edge7: [0, 4],

    waveFilter: true,
    waveLimits: WAVE_DEFAULTS.map((r) => [...r] as Range),

    sanFilter: true,
    sanPatterns: [
      true, true, true, true, true, true,
      false, false, false, false, false, false,
      false, false, false,
    ],
    sanLimits: [[0, 3], [0, 3], [0, 3]],

    mod3Filter: true,
    mod3Limits: [[0, 5], [0, 5], [0, 5]],
    mod7Filter: true,
    mod7Limits: Array.from({ length: 7 }, () => [0, 2] as Range),
    mod7SpanFilter: true,
    mod7SpanMin: 2,
    mod7SpanMax: 4,
    conFilter: true,
    con2: [0, 1],
    con3: [0, 1],
    tail: [1, 5],
    tsumFilter: true,
    tsum: [10, 34],

    danText: '',
    prevText: '',
    rnFilter: true,
    rep: [0, 2],
    nbr: [1, 3],
    orph: [1, 4],

    dangroupFilter: false,
    dangroupLimits: DAN_GROUPS.map(() => [0, 5] as Range),
  };
}
