import { useEffect, useState, type ReactNode } from 'react';
import type { Range } from '../core/types';

interface SpinProps {
  value: number;
  min: number;
  max: number;
  onChange: (v: number) => void;
  title?: string;
}

/** 紧凑数字输入框(与 PyQt 版的窄输入框一致)。 */
export function Spin({ value, min, max, onChange, title }: SpinProps) {
  const [text, setText] = useState(String(value));
  const [focused, setFocused] = useState(false);

  useEffect(() => {
    if (!focused) setText(String(value));
  }, [value, focused]);

  return (
    <input
      className="spin"
      type="number"
      inputMode="numeric"
      min={min}
      max={max}
      value={text}
      title={title}
      onFocus={() => setFocused(true)}
      onChange={(e) => {
        const t = e.target.value;
        setText(t);
        if (t === '') return;
        const v = Number(t);
        if (Number.isFinite(v)) onChange(v);
      }}
      onBlur={() => {
        setFocused(false);
        let v = Number(text);
        if (!Number.isFinite(v)) v = value;
        v = Math.min(max, Math.max(min, Math.round(v)));
        onChange(v);
        setText(String(v));
      }}
    />
  );
}

interface RangeRowProps {
  label: string;
  value: Range;
  min?: number;
  max?: number;
  onChange: (side: 0 | 1, v: number) => void;
  extra?: ReactNode;
  labelWidth?: number;
}

export function RangeRow({ label, value, min = 0, max = 5, onChange, extra, labelWidth }: RangeRowProps) {
  return (
    <div className="row">
      <span className="lbl" style={labelWidth ? { width: labelWidth } : undefined} title={label}>
        {label}
      </span>
      <Spin value={value[0]} min={min} max={max} onChange={(v) => onChange(0, v)} />
      <span className="tilde">~</span>
      <Spin value={value[1]} min={min} max={max} onChange={(v) => onChange(1, v)} />
      {extra}
    </div>
  );
}

interface CheckFieldProps {
  checked: boolean;
  onChange: (v: boolean) => void;
  children: ReactNode;
  title?: string;
}

export function CheckField({ checked, onChange, children, title }: CheckFieldProps) {
  return (
    <label className="check" title={title}>
      <input type="checkbox" checked={checked} onChange={(e) => onChange(e.target.checked)} />
      <span>{children}</span>
    </label>
  );
}

interface LimitRowsProps {
  labels: ReactNode[];
  limits: Range[];
  min?: number;
  max?: number;
  onChange: (i: number, side: 0 | 1, v: number) => void;
}

export function LimitRows({ labels, limits, min = 0, max = 5, onChange }: LimitRowsProps) {
  return (
    <>
      {limits.map((r, i) => (
        <div className="row" key={i}>
          <span className="lbl">{labels[i]}</span>
          <Spin value={r[0]} min={min} max={max} onChange={(v) => onChange(i, 0, v)} />
          <span className="tilde">~</span>
          <Spin value={r[1]} min={min} max={max} onChange={(v) => onChange(i, 1, v)} />
        </div>
      ))}
    </>
  );
}

interface RatioGroupProps {
  title: string;
  checks: boolean[];
  onToggle: (i: number) => void;
  tip?: string;
}

/** 比例组: 6 个复选框, 标签为 "k:5-k"(如 2:3)。 */
export function RatioGroup({ title, checks, onToggle, tip }: RatioGroupProps) {
  return (
    <div className="ratio-group" title={tip}>
      <span className="group-caption">{title}</span>
      <div className="checks">
        {checks.map((c, i) => (
          <label className="check" key={i}>
            <input type="checkbox" checked={c} onChange={() => onToggle(i)} />
            <span>{i}:{5 - i}</span>
          </label>
        ))}
      </div>
    </div>
  );
}
