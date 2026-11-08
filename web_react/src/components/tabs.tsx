import type { Dispatch, ReactNode, SetStateAction } from 'react';
import {
  DAN_GROUPS, EDGE7_NUMS, EDGE_NUMS, FIVE_ZONES, FOUR_ZONES,
  SAN_PATTERNS, SAN_RANGES, SAN_TIER_NAMES, SEVEN_ZONES, TAIL_COLOR,
  TAIL_WX, WAVE_ZONES, WX_ZONES, YJ_ZONES, type NamedZone,
} from '../core/constants';
import type { Range, Settings } from '../core/types';
import { CheckField, LimitRows, RangeRow, RatioGroup, Spin } from './controls';

export type SetCfg = Dispatch<SetStateAction<Settings>>;

type LimitKey =
  | 'wxLimits' | 'yjLimits' | 'tailwxLimits' | 'tailcolorLimits'
  | 'fourLimits' | 'fiveLimits' | 'sevenLimits' | 'waveLimits'
  | 'sanLimits' | 'mod3Limits' | 'mod7Limits' | 'dangroupLimits';

type RangeKey =
  | 'zoneHead' | 'zoneMid' | 'zoneTail' | 'edge' | 'edge7'
  | 'con2' | 'con3' | 'tail' | 'tsum' | 'rep' | 'nbr' | 'orph' | 'tailwxKind';

interface Helpers {
  patch: (p: Partial<Settings>) => void;
  setLimit: (key: LimitKey, i: number, side: 0 | 1, v: number) => void;
  setRange: (key: RangeKey, side: 0 | 1, v: number) => void;
  toggleArr: (key: 'odd' | 'big' | 'prime' | 'sanPatterns', i: number) => void;
}

function buildHelpers(setCfg: SetCfg): Helpers {
  const patch = (p: Partial<Settings>) => setCfg((s) => ({ ...s, ...p }));
  const setLimit = (key: LimitKey, i: number, side: 0 | 1, v: number) =>
    setCfg((s) => {
      const arr = (s[key] as Range[]).map((r, j) =>
        j === i ? ((side === 0 ? [v, r[1]] : [r[0], v]) as Range) : r);
      return { ...s, [key]: arr } as Settings;
    });
  const setRange = (key: RangeKey, side: 0 | 1, v: number) =>
    setCfg((s) => {
      const r = s[key] as Range;
      return { ...s, [key]: (side === 0 ? [v, r[1]] : [r[0], v]) as Range } as Settings;
    });
  const toggleArr = (key: 'odd' | 'big' | 'prime' | 'sanPatterns', i: number) =>
    setCfg((s) => {
      const arr = [...s[key]];
      arr[i] = !arr[i];
      return { ...s, [key]: arr } as Settings;
    });
  return { patch, setLimit, setRange, toggleArr };
}

const pad2 = (n: number) => String(n).padStart(2, '0');

interface NamedZonePageProps {
  title: string;
  tip: string;
  zones: NamedZone[];
  filter: boolean;
  onFilter: (v: boolean) => void;
  limits: Range[];
  onChange: (i: number, side: 0 | 1, v: number) => void;
  pad: boolean;
  suffix: string;
  extra?: ReactNode;
}

function NamedZonePage({
  title, tip, zones, filter, onFilter, limits, onChange, pad, suffix, extra,
}: NamedZonePageProps) {
  return (
    <div className="page">
      <CheckField checked={filter} onChange={onFilter} title={tip}>{title}</CheckField>
      <LimitRows
        labels={zones.map((z) =>
          `${z.name}(${z.nums.slice().sort((a, b) => a - b).map(pad ? pad2 : String).join(',')})${suffix}`)}
        limits={limits}
        onChange={onChange}
      />
      {extra}
    </div>
  );
}

export function FilterPage({ index, cfg, setCfg }: { index: number; cfg: Settings; setCfg: SetCfg }) {
  const h = buildHelpers(setCfg);

  switch (index) {
    // ---- ① 杀号/区间与比例 ----
    case 0:
      return (
        <div className="page">
          <div className="row">
            <span className="lbl">杀号(排除):</span>
            <input
              className="text-input w-kill"
              placeholder="如: 03 11 22"
              value={cfg.killText}
              onChange={(e) => h.patch({ killText: e.target.value })}
            />
          </div>
          <RangeRow
            label="AC值区间:"
            value={[cfg.acMin, cfg.acMax]}
            min={0}
            max={6}
            onChange={(side, v) => h.patch(side === 0 ? { acMin: v } : { acMax: v })}
          />
          <CheckField
            checked={cfg.zoneFilter}
            onChange={(v) => h.patch({ zoneFilter: v })}
            title={'龙头01~13 / 中间09~26 / 凤尾24~35, 区间可重叠\n号码09~13同时计入龙头与中间, 24~26同时计入中间与凤尾'}
          >
            龙头-中间-凤尾分区出号(启用)
          </CheckField>
          <RangeRow label="龙头 01~13 出号:" value={cfg.zoneHead}
            onChange={(side, v) => h.setRange('zoneHead', side, v)} />
          <RangeRow label="中间 09~26 出号:" value={cfg.zoneMid}
            onChange={(side, v) => h.setRange('zoneMid', side, v)} />
          <RangeRow label="凤尾 24~35 出号:" value={cfg.zoneTail}
            onChange={(side, v) => h.setRange('zoneTail', side, v)} />
          <RangeRow
            label="和值区间:"
            value={[cfg.sumMin, cfg.sumMax]}
            min={15}
            max={165}
            onChange={(side, v) => h.patch(side === 0 ? { sumMin: v } : { sumMax: v })}
            extra={<CheckField checked={cfg.sumFilter} onChange={(v) => h.patch({ sumFilter: v })}>启用</CheckField>}
          />
          <RangeRow
            label="跨度区间:"
            value={[cfg.spanMin, cfg.spanMax]}
            min={4}
            max={34}
            onChange={(side, v) => h.patch(side === 0 ? { spanMin: v } : { spanMax: v })}
            extra={<CheckField checked={cfg.spanFilter} onChange={(v) => h.patch({ spanFilter: v })}>启用</CheckField>}
          />
          <RatioGroup title="奇数个数(奇:偶)" checks={cfg.odd} onToggle={(i) => h.toggleArr('odd', i)} />
          <RatioGroup title="大号个数(大:小)" checks={cfg.big} onToggle={(i) => h.toggleArr('big', i)}
            tip="大号 ≥ 18, 全不勾=不过滤" />
          <RatioGroup title="质数个数(质:合)" checks={cfg.prime} onToggle={(i) => h.toggleArr('prime', i)}
            tip="质数: 2,3,5,7,11,13,17,19,23,29,31" />
        </div>
      );

    // ---- ② 五行(洛书) ----
    case 1:
      return (
        <NamedZonePage
          title="五行(洛书)分区出号(启用)"
          tip={'尾数1/6=水, 2/7=火, 3/8=木, 4/9=金, 5/0=土, 每组7个号, 组间不重叠'}
          zones={WX_ZONES}
          filter={cfg.wxFilter}
          onFilter={(v) => h.patch({ wxFilter: v })}
          limits={cfg.wxLimits}
          onChange={(i, side, v) => h.setLimit('wxLimits', i, side, v)}
          pad
          suffix=" 出号:"
        />
      );

    // ---- ③ 五行(易经) ----
    case 2:
      return (
        <NamedZonePage
          title="五行(易经)分区出号(启用)"
          tip="金木水火土五组(与洛书分法不同), 覆盖1~35, 组间不重叠"
          zones={YJ_ZONES}
          filter={cfg.yjFilter}
          onFilter={(v) => h.patch({ yjFilter: v })}
          limits={cfg.yjLimits}
          onChange={(i, side, v) => h.setLimit('yjLimits', i, side, v)}
          pad
          suffix=" 出号:"
        />
      );

    // ---- ④ 五行尾数 ----
    case 3:
      return (
        <div className="page">
          <CheckField
            checked={cfg.tailwxFilter}
            onChange={(v) => h.patch({ tailwxFilter: v })}
            title={'按个位尾数分五行: 金(4,9) 木(3,8) 水(1,6) 火(2,7) 土(0,5)\n各五行尾的出号个数及种类数均须落在设定范围内'}
          >
            五行尾数过滤(启用)
          </CheckField>
          <LimitRows
            labels={TAIL_WX.map((z) => `${z.name}(${z.nums.slice().sort((a, b) => a - b).join(',')}):`)}
            limits={cfg.tailwxLimits}
            onChange={(i, side, v) => h.setLimit('tailwxLimits', i, side, v)}
          />
          <RangeRow label="五行尾数种类:" value={cfg.tailwxKind} min={1} max={5}
            onChange={(side, v) => h.setRange('tailwxKind', side, v)} />
        </div>
      );

    // ---- ⑤ 尾数红蓝绿 ----
    case 4:
      return (
        <NamedZonePage
          title="尾数红蓝绿过滤(启用)"
          tip={'尾数=号码的个位数\n红尾: 1,2,7,8   蓝尾: 3,4,9,0   绿尾: 5,6\n分别统计尾数属于各色的号码个数, 须落在设定范围内'}
          zones={TAIL_COLOR}
          filter={cfg.tailcolorFilter}
          onFilter={(v) => h.patch({ tailcolorFilter: v })}
          limits={cfg.tailcolorLimits}
          onChange={(i, side, v) => h.setLimit('tailcolorLimits', i, side, v)}
          pad={false}
          suffix="出号:"
        />
      );

    // ---- ⑥ 4分区 ----
    case 5:
      return (
        <div className="page">
          <CheckField checked={cfg.fourFilter} onChange={(v) => h.patch({ fourFilter: v })}
            title="0区01~09 / 1区10~19 / 2区20~29 / 3区30~35">
            4分区出号(启用)
          </CheckField>
          <LimitRows
            labels={FOUR_ZONES.map(([lo, hi], i) => `${i}区 ${pad2(lo)}~${pad2(hi)} 出号:`)}
            limits={cfg.fourLimits}
            onChange={(i, side, v) => h.setLimit('fourLimits', i, side, v)}
          />
        </div>
      );

    // ---- ⑦ 5分区 ----
    case 6:
      return (
        <div className="page">
          <CheckField checked={cfg.fiveFilter} onChange={(v) => h.patch({ fiveFilter: v })}
            title="1区01~07 / 2区08~14 / 3区15~21 / 4区22~28 / 5区29~35, 每区7个号">
            5分区出号(启用)
          </CheckField>
          <LimitRows
            labels={FIVE_ZONES.map(([lo, hi], i) => `${i + 1}区 ${pad2(lo)}~${pad2(hi)} 出号:`)}
            limits={cfg.fiveLimits}
            onChange={(i, side, v) => h.setLimit('fiveLimits', i, side, v)}
          />
          <CheckField checked={cfg.edgeFilter} onChange={(v) => h.patch({ edgeFilter: v })}
            title={`边缘码=各分区首尾号: ${EDGE_NUMS.map(pad2).join(',')}\n每个分区的边缘码最多1个`}>
            5区边缘码出号(启用)
          </CheckField>
          <RangeRow label="边缘码出号个数:" value={cfg.edge}
            onChange={(side, v) => h.setRange('edge', side, v)} />
        </div>
      );

    // ---- ⑧ 红蓝绿波 ----
    case 7:
      return (
        <NamedZonePage
          title="红蓝绿波过滤(启用)"
          tip="按波色统计出号个数, 须落在设定范围内"
          zones={WAVE_ZONES}
          filter={cfg.waveFilter}
          onFilter={(v) => h.patch({ waveFilter: v })}
          limits={cfg.waveLimits}
          onChange={(i, side, v) => h.setLimit('waveLimits', i, side, v)}
          pad
          suffix="波出号:"
        />
      );

    // ---- ⑨ 7分区与跨区 ----
    case 8:
      return (
        <div className="page">
          <CheckField checked={cfg.sevenFilter} onChange={(v) => h.patch({ sevenFilter: v })}
            title="1区01~05 / 2区06~10 / ... / 7区31~35, 每区5个号">
            7分区出号(启用)
          </CheckField>
          <LimitRows
            labels={SEVEN_ZONES.map(([lo, hi], i) => `${i + 1}区 ${pad2(lo)}~${pad2(hi)} 出号:`)}
            limits={cfg.sevenLimits}
            onChange={(i, side, v) => h.setLimit('sevenLimits', i, side, v)}
          />
          <CheckField checked={cfg.sevenSpanFilter} onChange={(v) => h.patch({ sevenSpanFilter: v })}
            title="统计5个号覆盖的分区数(1~5), 须落在设定范围内">
            7分区跨区条件(启用)
          </CheckField>
          <RangeRow
            label="跨区范围(覆盖分区数):"
            value={[cfg.sevenSpanMin, cfg.sevenSpanMax]}
            min={1}
            max={5}
            onChange={(side, v) => h.patch(side === 0 ? { sevenSpanMin: v } : { sevenSpanMax: v })}
          />
          <CheckField checked={cfg.edge7Filter} onChange={(v) => h.patch({ edge7Filter: v })}
            title={`边缘码=各分区首尾号: ${EDGE7_NUMS.map(pad2).join(',')}\n每个分区的边缘码最多1个`}>
            7区边缘码出号(启用)
          </CheckField>
          <RangeRow label="边缘码出号个数:" value={cfg.edge7}
            onChange={(side, v) => h.setRange('edge7', side, v)} />
        </div>
      );

    // ---- ⑩ 三区间比 ----
    case 9: {
      const starts: number[] = [];
      let acc = 0;
      for (const tier of SAN_PATTERNS) {
        starts.push(acc);
        acc += tier.length;
      }
      return (
        <div className="page">
          <CheckField
            checked={cfg.sanFilter}
            onChange={(v) => h.patch({ sanFilter: v })}
            title={'1区01~11 / 2区12~22 / 3区23~35\n勾选各档允许的(1区:2区:3区)比例, 可多选, 全不勾=不按比例过滤'}
          >
            三区间比过滤(启用)
          </CheckField>
          {SAN_PATTERNS.map((patterns, t) => (
            <div className="row" key={t}>
              <span className="lbl">{SAN_TIER_NAMES[t]}:</span>
              <div className="checks">
                {patterns.map((p, j) => (
                  <label className="check" key={j}>
                    <input
                      type="checkbox"
                      checked={cfg.sanPatterns[starts[t] + j]}
                      onChange={() => h.toggleArr('sanPatterns', starts[t] + j)}
                    />
                    <span>{p.join(':')}</span>
                  </label>
                ))}
              </div>
            </div>
          ))}
          <LimitRows
            labels={SAN_RANGES.map(([lo, hi], i) => `${i + 1}区 ${pad2(lo)}~${pad2(hi)} 出号:`)}
            limits={cfg.sanLimits}
            onChange={(i, side, v) => h.setLimit('sanLimits', i, side, v)}
          />
        </div>
      );
    }

    // ---- ⑪ 余数与结构 ----
    case 10:
      return (
        <div className="page">
          <CheckField checked={cfg.mod3Filter} onChange={(v) => h.patch({ mod3Filter: v })}
            title="0路=03,06,...,33; 1路=01,04,...,34; 2路=02,05,...,35">
            012路出号(启用)
          </CheckField>
          <LimitRows
            labels={[0, 1, 2].map((i) => `${i}路`)}
            limits={cfg.mod3Limits}
            onChange={(i, side, v) => h.setLimit('mod3Limits', i, side, v)}
          />
          <CheckField checked={cfg.mod7Filter} onChange={(v) => h.patch({ mod7Filter: v })}
            title="余0~余6共7组, 每组5个号, 每组出号个数须落在设定范围内">
            除7余数出号(启用)
          </CheckField>
          <LimitRows
            labels={[0, 1, 2, 3, 4, 5, 6].map((i) => {
              const nums = Array.from({ length: 35 }, (_, k) => k + 1).filter((n) => n % 7 === i);
              return <span title={`每组号码: ${nums.map(pad2).join(', ')}`}>余{i}</span>;
            })}
            limits={cfg.mod7Limits}
            min={0}
            max={5}
            onChange={(i, side, v) => h.setLimit('mod7Limits', i, side, v)}
          />
          <CheckField checked={cfg.mod7SpanFilter} onChange={(v) => h.patch({ mod7SpanFilter: v })}
            title="统计5个号覆盖的余数组数(1~5), 须落在设定范围内">
            余7跨区条件(启用)
          </CheckField>
          <RangeRow
            label="跨区范围(覆盖余数组数):"
            value={[cfg.mod7SpanMin, cfg.mod7SpanMax]}
            min={1}
            max={5}
            onChange={(side, v) => h.patch(side === 0 ? { mod7SpanMin: v } : { mod7SpanMax: v })}
          />
          <CheckField checked={cfg.conFilter} onChange={(v) => h.patch({ conFilter: v })}
            title="2连号组数=长度恰为2的连号段个数; 三连号组数=长度>=3的连号段个数">
            连号过滤(启用)
          </CheckField>
          <RangeRow label="2连号组数:" value={cfg.con2}
            onChange={(side, v) => h.setRange('con2', side, v)} />
          <RangeRow label="三连号组数:" value={cfg.con3}
            onChange={(side, v) => h.setRange('con3', side, v)} />
          <RangeRow label="尾数种类:" value={cfg.tail} min={1} max={5}
            onChange={(side, v) => h.setRange('tail', side, v)} />
          <CheckField checked={cfg.tsumFilter} onChange={(v) => h.patch({ tsumFilter: v })}
            title="5个号码的个位数相加, 如 08,12,15,29,30 → 8+2+5+9+0=24">
            尾数之和过滤(启用)
          </CheckField>
          <RangeRow label="尾数和范围:" value={cfg.tsum} min={0} max={45}
            onChange={(side, v) => h.setRange('tsum', side, v)} />
        </div>
      );

    // ---- ⑫ 号码限定 ----
    case 11:
      return (
        <div className="page">
          <div className="row">
            <span className="lbl">胆码(必含):</span>
            <input
              className="text-input w-dan"
              placeholder="如: 07 18"
              value={cfg.danText}
              onChange={(e) => h.patch({ danText: e.target.value })}
            />
          </div>
          <div className="row">
            <span className="lbl">上期号码:</span>
            <input
              className="text-input w-prev"
              placeholder="如: 04 13 19 29 31 (留空=不使用重邻孤)"
              value={cfg.prevText}
              onChange={(e) => h.patch({ prevText: e.target.value })}
            />
          </div>
          <CheckField checked={cfg.rnFilter} onChange={(v) => h.patch({ rnFilter: v })}
            title="重号=上期开奖号码; 邻号=上期号码左右相邻(±1, 已剔除重号); 孤号=既非重号也非邻号的号码。上期号码留空=不过滤">
            重邻孤过滤(启用)
          </CheckField>
          <RangeRow label="重号个数:" value={cfg.rep} onChange={(side, v) => h.setRange('rep', side, v)} />
          <RangeRow label="邻号个数:" value={cfg.nbr} onChange={(side, v) => h.setRange('nbr', side, v)} />
          <RangeRow label="孤号个数:" value={cfg.orph} onChange={(side, v) => h.setRange('orph', side, v)} />
        </div>
      );

    // ---- ⑬ 固定胆组 ----
    case 12:
      return (
        <div className="page">
          <CheckField checked={cfg.dangroupFilter} onChange={(v) => h.patch({ dangroupFilter: v })}
            title="8组预定义号码集合, 每组设置该组号码的出现个数范围; 0~5=该组不限制">
            固定胆组过滤(启用)
          </CheckField>
          <LimitRows
            labels={DAN_GROUPS.map((g, i) => {
              const text = g.slice().sort((a, b) => a - b).map(pad2).join(',');
              return <span title={text}>{`胆组${i + 1}: ${text.slice(0, 11)}…`}</span>;
            })}
            limits={cfg.dangroupLimits}
            onChange={(i, side, v) => h.setLimit('dangroupLimits', i, side, v)}
          />
        </div>
      );

    default:
      return null;
  }
}

export const TAB_NAMES = [
  '杀号/区间与比例', '五行(洛书)', '五行(易经)', '五行尾数', '尾数红蓝绿',
  '4分区', '5分区', '红蓝绿波', '7分区与跨区', '三区间比', '余数与结构',
  '号码限定', '固定胆组',
];
