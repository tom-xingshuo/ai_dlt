import { memo, useCallback, useEffect, useMemo, useState } from 'react';
import { FilterPage, TAB_NAMES, type SetCfg } from './components/tabs';
import { acValue, buildMatcher } from './core/filterConditions';
import { defaultSettings } from './core/defaults';
import { generateGroups } from './core/fullData';
import type { Settings } from './core/types';

const STORAGE_KEY = 'shrink_tool_react_settings_v1';
const PREVIEW_ROWS = 2000;
const SAVE_FILENAME = 'front_numbers_shrunk.txt';
const LOTTERY_URL = '/lottery-api/gateway/lottery/getHistoryPageListV1.qry'
  + '?gameNo=85&provinceId=0&pageSize=1&isVerify=1&pageNo=1';

const pad2 = (n: number) => String(n).padStart(2, '0');

function loadSettings(): Settings {
  const base = defaultSettings();
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return base;
    return { ...base, ...(JSON.parse(raw) as Partial<Settings>) };
  } catch {
    return base;
  }
}

const ResultTable = memo(function ResultTable({ results }: { results: number[][] }) {
  const rows = results.slice(0, PREVIEW_ROWS);
  return (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>
            {['号码1', '号码2', '号码3', '号码4', '号码5'].map((h) => <th key={h}>{h}</th>)}
          </tr>
        </thead>
        <tbody>
          {rows.map((nums, i) => (
            <tr key={i}>
              {nums.map((n) => <td key={n}>{pad2(n)}</td>)}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
});

export default function App() {
  const [cfg, setCfg] = useState<Settings>(loadSettings);
  const [tab, setTab] = useState(0);
  const [groups, setGroups] = useState<number[][]>([]);
  const [results, setResults] = useState<number[][]>([]);
  const [status, setStatus] = useState('请先载入数据');
  const [latest, setLatest] = useState('最新开奖: 未获取');
  const [latestBusy, setLatestBusy] = useState(false);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(cfg));
    } catch {
      // 存储不可用时忽略, 不影响筛选
    }
  }, [cfg]);

  const loadData = useCallback(() => {
    const data = generateGroups();
    setGroups(data);
    setResults([]);
    setStatus(`已载入 ${data.length} 组号码: (全量数据)`);
  }, []);

  const fetchLatest = useCallback(async () => {
    setLatestBusy(true);
    setLatest('最新开奖: 获取中...');
    try {
      const res = await fetch(LOTTERY_URL);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      const item = data?.value?.lastPoolDraw;
      const all = String(item?.lotteryDrawResult ?? '').trim().split(/\s+/).map(Number);
      const front = all.slice(0, 5);
      const back = all.slice(5, 7);
      if (front.length !== 5 || !front.every((n) => n >= 1 && n <= 35)) throw new Error('bad payload');
      setLatest(
        `最新开奖: 第${item.lotteryDrawNum}期(${item.lotteryDrawTime})  `
        + `${front.map(pad2).join(' ')} + ${back.map(pad2).join(' ')}  (AC值: ${acValue(front)})`,
      );
    } catch {
      setLatest('最新开奖: 获取失败(请检查网络)');
    } finally {
      setLatestBusy(false);
    }
  }, []);

  useEffect(() => {
    loadData();
    fetchLatest();
  }, [loadData, fetchLatest]);

  const onShrink = () => {
    if (!groups.length) {
      setStatus('请先载入数据');
      return;
    }
    setStatus('正在缩水...');
    // 让界面先显示提示, 再执行过滤
    window.setTimeout(() => {
      const matcher = buildMatcher(cfg);
      const start = performance.now();
      const matched: number[][] = [];
      for (const g of groups) if (matcher(g)) matched.push(g);
      const elapsed = (performance.now() - start) / 1000;
      setResults(matched);
      const note = matched.length <= PREVIEW_ROWS ? '' : `（表格仅预览前 ${PREVIEW_ROWS} 行）`;
      setStatus(
        `共 ${groups.length} 组 → 条件过滤 ${matched.length} 组, `
        + `最终 ${matched.length} 组, 耗时 ${elapsed.toFixed(2)} 秒 ${note}`,
      );
    }, 30);
  };

  const onSave = () => {
    if (!results.length) {
      setStatus('没有可保存的结果, 请先缩水');
      return;
    }
    const lines: string[] = [
      `大乐透前区缩水结果（${results.length}组，5/35）`,
      '-'.repeat(40),
    ];
    results.forEach((nums, i) => {
      lines.push(`${String(i + 1).padStart(4, '0')}: ${nums.map(pad2).join(' ')}`);
    });
    const blob = new Blob([lines.join('\n') + '\n'], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = SAVE_FILENAME;
    a.click();
    URL.revokeObjectURL(url);
    setStatus(`已导出 ${results.length} 组到 ${SAVE_FILENAME}`);
  };

  const onReset = () => {
    setCfg(defaultSettings());
    setStatus('条件已重置');
  };

  const tabPage = useMemo(
    () => <FilterPage index={tab} cfg={cfg} setCfg={setCfg as SetCfg} />,
    [tab, cfg],
  );

  return (
    <div className="app">
      <header className="app-header">
        <h1>大乐透前区缩水工具</h1>
        <span className="subtitle">C(35,5) = 324632 组全量数据 · 纯前端筛选</span>
      </header>

      <section className="card">
        <div className="source-row">
          <span className="source-label">全量数据(324632组)</span>
          <button className="btn" onClick={loadData}>重新载入</button>
        </div>
        <div className="source-row">
          <span className="latest-label">{latest}</span>
          <button className="btn" onClick={fetchLatest} disabled={latestBusy}>刷新</button>
        </div>
      </section>

      <section className="card filter-card">
        <div className="tabs">
          {TAB_NAMES.map((name, i) => (
            <button
              key={name}
              className={i === tab ? 'tab-btn active' : 'tab-btn'}
              onClick={() => setTab(i)}
            >
              {name}
            </button>
          ))}
        </div>
        <div className="tab-panel">{tabPage}</div>
      </section>

      <div className="actions">
        <button className="btn primary" onClick={onShrink}>开始缩水</button>
        <button className="btn" onClick={onSave}>保存结果</button>
        <button className="btn" onClick={onReset}>重置条件</button>
      </div>

      <div className="status">{status}</div>

      <ResultTable results={results} />
    </div>
  );
}
