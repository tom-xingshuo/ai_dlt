import {
  BIG_BOUNDARY, DAN_GROUPS, EDGE7_NUMS, EDGE_NUMS, FIVE_ZONES,
  FOUR_ZONES, PRIMES, SAN_ALL_PATTERNS, SAN_RANGES, SEVEN_ZONES,
  TAIL_COLOR, TAIL_WX, WAVE_ZONES, WX_ZONES, YJ_ZONES,
  ZONE_HEAD, ZONE_MID, ZONE_TAIL,
} from './constants';
import type { Range, Settings } from './types';

/** 解析空格/逗号分隔的号码, 仅保留 1~35。 */
export function parseNums(text: string): number[] {
  const seen = new Set<number>();
  const out: number[] = [];
  for (const m of text.matchAll(/\d+/g)) {
    const n = Number(m[0]);
    if (n >= 1 && n <= 35 && !seen.has(n)) {
      seen.add(n);
      out.push(n);
    }
  }
  return out.sort((a, b) => a - b);
}

/** AC 值: 两两差绝对值去重个数 - (n-1)。 */
export function acValue(nums: number[]): number {
  const seen = new Uint8Array(35);
  let count = 0;
  for (let i = 0; i < nums.length - 1; i += 1) {
    for (let j = i + 1; j < nums.length; j += 1) {
      const d = nums[j] - nums[i];
      if (!seen[d]) {
        seen[d] = 1;
        count += 1;
      }
    }
  }
  return count - (nums.length - 1);
}

/** 返回 [2连号组数, 三连号及以上组数]。 */
export function consecutiveStats(nums: number[]): [number, number] {
  let two = 0;
  let three = 0;
  let run = 1;
  for (let i = 0; i < nums.length - 1; i += 1) {
    if (nums[i + 1] - nums[i] === 1) {
      run += 1;
    } else {
      if (run === 2) two += 1;
      else if (run >= 3) three += 1;
      run = 1;
    }
  }
  if (run === 2) two += 1;
  else if (run >= 3) three += 1;
  return [two, three];
}

function flagSet(nums: number[]): Uint8Array {
  const f = new Uint8Array(36);
  for (const n of nums) f[n] = 1;
  return f;
}

function countInFlags(f: Uint8Array, nums: number[]): number {
  let c = 0;
  for (const n of nums) c += f[n];
  return c;
}

function countTails(f: Uint8Array, nums: number[]): number {
  let c = 0;
  for (const n of nums) c += f[n % 10];
  return c;
}

function countInRange([lo, hi]: Range, nums: number[]): number {
  let c = 0;
  for (const n of nums) if (n >= lo && n <= hi) c += 1;
  return c;
}

/** 与 calcute_funcs.FilterConditions.match 等价的匹配函数。 */
export function buildMatcher(cfg: Settings): (nums: number[]) => boolean {
  const kill = flagSet(parseNums(cfg.killText));
  const dan = parseNums(cfg.danText);
  const prev = parseNums(cfg.prevText);
  const prevFlags = prev.length ? flagSet(prev) : null;

  const wxFlags = WX_ZONES.map((z) => flagSet(z.nums));
  const yjFlags = YJ_ZONES.map((z) => flagSet(z.nums));
  const waveFlags = WAVE_ZONES.map((z) => flagSet(z.nums));
  const tailWxFlags = TAIL_WX.map((z) => flagSet(z.nums));
  const tailColorFlags = TAIL_COLOR.map((z) => flagSet(z.nums));
  const danFlags = DAN_GROUPS.map((g) => flagSet(g));

  const primeFlags = flagSet(PRIMES);
  const edgeFlags = flagSet(EDGE_NUMS);
  const edge7Flags = flagSet(EDGE7_NUMS);

  const oddAllowed = cfg.odd.some(Boolean);
  const bigAllowed = cfg.big.some(Boolean);
  const primeAllowed = cfg.prime.some(Boolean);

  const sanAllowed = new Set(
    SAN_ALL_PATTERNS.filter((_, i) => cfg.sanPatterns[i])
      .map((p) => `${p[0]},${p[1]},${p[2]}`),
  );

  return (nums: number[]): boolean => {
    for (const n of nums) if (kill[n]) return false;

    const ac = acValue(nums);
    if (ac < cfg.acMin || ac > cfg.acMax) return false;

    if (cfg.zoneFilter) {
      const h = countInRange(ZONE_HEAD, nums);
      if (h < cfg.zoneHead[0] || h > cfg.zoneHead[1]) return false;
      const m = countInRange(ZONE_MID, nums);
      if (m < cfg.zoneMid[0] || m > cfg.zoneMid[1]) return false;
      const t = countInRange(ZONE_TAIL, nums);
      if (t < cfg.zoneTail[0] || t > cfg.zoneTail[1]) return false;
    }

    if (cfg.wxFilter) {
      for (let i = 0; i < wxFlags.length; i += 1) {
        const c = countInFlags(wxFlags[i], nums);
        if (c < cfg.wxLimits[i][0] || c > cfg.wxLimits[i][1]) return false;
      }
    }

    if (cfg.yjFilter) {
      for (let i = 0; i < yjFlags.length; i += 1) {
        const c = countInFlags(yjFlags[i], nums);
        if (c < cfg.yjLimits[i][0] || c > cfg.yjLimits[i][1]) return false;
      }
    }

    if (cfg.fourFilter) {
      for (let i = 0; i < FOUR_ZONES.length; i += 1) {
        const c = countInRange(FOUR_ZONES[i], nums);
        if (c < cfg.fourLimits[i][0] || c > cfg.fourLimits[i][1]) return false;
      }
    }

    if (cfg.fiveFilter) {
      for (let i = 0; i < FIVE_ZONES.length; i += 1) {
        const c = countInRange(FIVE_ZONES[i], nums);
        if (c < cfg.fiveLimits[i][0] || c > cfg.fiveLimits[i][1]) return false;
      }
    }

    if (cfg.sevenFilter) {
      for (let i = 0; i < SEVEN_ZONES.length; i += 1) {
        const c = countInRange(SEVEN_ZONES[i], nums);
        if (c < cfg.sevenLimits[i][0] || c > cfg.sevenLimits[i][1]) return false;
      }
    }

    if (cfg.sevenSpanFilter) {
      let zonesHit = 0;
      for (const [lo, hi] of SEVEN_ZONES) {
        if (nums.some((n) => n >= lo && n <= hi)) zonesHit += 1;
      }
      if (zonesHit < cfg.sevenSpanMin || zonesHit > cfg.sevenSpanMax) return false;
    }

    if (cfg.edgeFilter) {
      const c = countInFlags(edgeFlags, nums);
      if (c < cfg.edge[0] || c > cfg.edge[1]) return false;
      const f = flagSet(nums);
      for (const [lo, hi] of FIVE_ZONES) {
        if (f[lo] && f[hi]) return false; // 每个分区的边缘码最多1个
      }
    }

    if (cfg.edge7Filter) {
      const c = countInFlags(edge7Flags, nums);
      if (c < cfg.edge7[0] || c > cfg.edge7[1]) return false;
      const f = flagSet(nums);
      for (const [lo, hi] of SEVEN_ZONES) {
        if (f[lo] && f[hi]) return false;
      }
    }

    if (cfg.sumFilter) {
      let sum = 0;
      for (const n of nums) sum += n;
      if (sum < cfg.sumMin || sum > cfg.sumMax) return false;
    }

    const span = nums[nums.length - 1] - nums[0];
    if (cfg.spanFilter && (span < cfg.spanMin || span > cfg.spanMax)) return false;

    if (oddAllowed || bigAllowed || primeAllowed) {
      let odd = 0;
      let big = 0;
      let prime = 0;
      for (const n of nums) {
        odd += n % 2;
        if (n >= BIG_BOUNDARY) big += 1;
        prime += primeFlags[n];
      }
      if (oddAllowed && !cfg.odd[odd]) return false;
      if (bigAllowed && !cfg.big[big]) return false;
      if (primeAllowed && !cfg.prime[prime]) return false;
    }

    const mod3 = [0, 0, 0];
    const mod7 = [0, 0, 0, 0, 0, 0, 0];
    for (const n of nums) {
      mod3[n % 3] += 1;
      mod7[n % 7] += 1;
    }
    if (cfg.mod3Filter) {
      for (let i = 0; i < 3; i += 1) {
        if (mod3[i] < cfg.mod3Limits[i][0] || mod3[i] > cfg.mod3Limits[i][1]) return false;
      }
    }
    if (cfg.mod7Filter) {
      for (let i = 0; i < 7; i += 1) {
        if (mod7[i] < cfg.mod7Limits[i][0] || mod7[i] > cfg.mod7Limits[i][1]) return false;
      }
    }
    if (cfg.mod7SpanFilter) {
      const zonesHit = mod7.filter((c) => c > 0).length;
      if (zonesHit < cfg.mod7SpanMin || zonesHit > cfg.mod7SpanMax) return false;
    }

    if (cfg.conFilter) {
      const [two, three] = consecutiveStats(nums);
      if (two < cfg.con2[0] || two > cfg.con2[1]) return false;
      if (three < cfg.con3[0] || three > cfg.con3[1]) return false;
    }

    const tailSeen = new Uint8Array(10);
    let tailKinds = 0;
    for (const n of nums) {
      const t = n % 10;
      if (!tailSeen[t]) {
        tailSeen[t] = 1;
        tailKinds += 1;
      }
    }
    if (tailKinds < cfg.tail[0] || tailKinds > cfg.tail[1]) return false;

    if (cfg.tsumFilter) {
      let tsum = 0;
      for (const n of nums) tsum += n % 10;
      if (tsum < cfg.tsum[0] || tsum > cfg.tsum[1]) return false;
    }

    if (cfg.tailwxFilter) {
      let violations = 0;
      let kinds = 0;
      for (let i = 0; i < tailWxFlags.length; i += 1) {
        const c = countTails(tailWxFlags[i], nums);
        if (c >= cfg.tailwxLimits[i][0] && c <= cfg.tailwxLimits[i][1]) {
          if (c) kinds += 1;
        } else {
          violations += 1;
        }
      }
      if (kinds < cfg.tailwxKind[0] || kinds > cfg.tailwxKind[1]) violations += 1;
      if (violations) return false;
    }

    if (cfg.tailcolorFilter) {
      for (let i = 0; i < tailColorFlags.length; i += 1) {
        const c = countTails(tailColorFlags[i], nums);
        if (c < cfg.tailcolorLimits[i][0] || c > cfg.tailcolorLimits[i][1]) return false;
      }
    }

    if (cfg.waveFilter) {
      for (let i = 0; i < waveFlags.length; i += 1) {
        const c = countInFlags(waveFlags[i], nums);
        if (c < cfg.waveLimits[i][0] || c > cfg.waveLimits[i][1]) return false;
      }
    }

    if (cfg.sanFilter) {
      const counts: [number, number, number] = [
        countInRange(SAN_RANGES[0], nums),
        countInRange(SAN_RANGES[1], nums),
        countInRange(SAN_RANGES[2], nums),
      ];
      if (sanAllowed.size && !sanAllowed.has(counts.join(','))) return false;
      for (let i = 0; i < 3; i += 1) {
        if (counts[i] < cfg.sanLimits[i][0] || counts[i] > cfg.sanLimits[i][1]) return false;
      }
    }

    if (cfg.dangroupFilter) {
      for (let i = 0; i < danFlags.length; i += 1) {
        const c = countInFlags(danFlags[i], nums);
        if (c < cfg.dangroupLimits[i][0] || c > cfg.dangroupLimits[i][1]) return false;
      }
    }

    if (dan.length) {
      const f = flagSet(nums);
      for (const n of dan) if (!f[n]) return false;
    }

    if (cfg.rnFilter && prevFlags) {
      let rep = 0;
      let nbr = 0;
      for (const n of nums) {
        if (prevFlags[n]) rep += 1;
        else if (prevFlags[n - 1] || prevFlags[n + 1]) nbr += 1;
      }
      if (rep < cfg.rep[0] || rep > cfg.rep[1]) return false;
      if (nbr < cfg.nbr[0] || nbr > cfg.nbr[1]) return false;
      const orph = 5 - rep - nbr;
      if (orph < cfg.orph[0] || orph > cfg.orph[1]) return false;
    }

    return true;
  };
}
