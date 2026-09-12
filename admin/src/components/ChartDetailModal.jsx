import React, { useState, useMemo } from 'react';

/**
 * Format a YYYY-MM-DD or date string to a short human-readable format (e.g. "Jun 06" or "Wed, Jun 06").
 */
function formatDate(dateStr, includeWeekday = false) {
  if (!dateStr) return '';
  try {
    const parts = dateStr.split('-');
    if (parts.length === 3) {
      const d = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
      if (includeWeekday) {
        return d.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' });
      }
      return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    }
    const d = new Date(dateStr);
    return includeWeekday
      ? d.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' })
      : d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  } catch {
    return dateStr;
  }
}

export default function ChartDetailModal({ chart, onClose }) {
  if (!chart) return null;

  const {
    title = 'Trend Analytics',
    subtitle = 'Historical progression over time',
    label = 'Value',
    data = [],
    color = '#2563eb',
    unit = '%',
    icon,
  } = chart;

  // Internal time range filter: 'all', '90d', '30d', '14d', '7d'
  const [rangeFilter, setRangeFilter] = useState('all');
  const [viewTab, setViewTab] = useState('chart'); // 'chart' | 'table'
  const [hoveredIndex, setHoveredIndex] = useState(null);

  // Filtered dataset based on internal range selector
  const filteredData = useMemo(() => {
    if (!data || data.length === 0) return [];
    if (rangeFilter === '7d') return data.slice(-7);
    if (rangeFilter === '14d') return data.slice(-14);
    if (rangeFilter === '30d') return data.slice(-30);
    if (rangeFilter === '90d') return data.slice(-90);
    return data;
  }, [data, rangeFilter]);

  // Statistics
  const stats = useMemo(() => {
    if (!filteredData || filteredData.length === 0) {
      return { avg: 0, min: 0, max: 0, latest: 0, minDate: '', maxDate: '', latestDate: '', count: 0 };
    }
    const vals = filteredData.map(d => Number(d.value ?? 0));
    const sum = vals.reduce((acc, v) => acc + v, 0);
    const avg = sum / (vals.length || 1);

    let maxVal = -Infinity, minVal = Infinity;
    let maxDate = '', minDate = '';

    filteredData.forEach(d => {
      const v = Number(d.value ?? 0);
      if (v > maxVal) { maxVal = v; maxDate = d.date; }
      if (v < minVal) { minVal = v; minDate = d.date; }
    });

    const latestItem = filteredData[filteredData.length - 1];
    const latestVal = Number(latestItem?.value ?? 0);
    const latestDate = latestItem?.date ?? '';

    return {
      avg,
      min: minVal === Infinity ? 0 : minVal,
      max: maxVal === -Infinity ? 0 : maxVal,
      latest: latestVal,
      minDate,
      maxDate,
      latestDate,
      count: filteredData.length,
    };
  }, [filteredData]);

  // SVG Chart Geometry
  const W = 940;
  const H = 290;
  const PX = 60;
  const PY = 28;

  const values = filteredData.map(d => Number(d.value ?? 0));
  const rawMin = Math.min(...(values.length ? values : [0]));
  const rawMax = Math.max(...(values.length ? values : [1]));

  // Benchmark range bounds
  let chartMin = unit === '%' ? Math.max(0, Math.floor(rawMin / 10) * 10 - 10) : Math.max(0, rawMin);
  let chartMax = unit === '%' ? 100 : Math.ceil(rawMax * 1.15) || 10;
  if (chartMax <= chartMin) chartMax = chartMin + 10;
  const range = chartMax - chartMin || 1;

  const getX = (i) => PX + (i / Math.max(1, filteredData.length - 1)) * (W - 2 * PX);
  const getY = (v) => H - PY - (((v ?? 0) - chartMin) / range) * (H - 2 * PY);

  const linePts = filteredData.map((d, i) => `${getX(i)},${getY(d.value ?? 0)}`).join(' ');
  const areaPath = filteredData.length > 0 ? [
    `M ${getX(0)},${H - PY}`,
    ...filteredData.map((d, i) => `L ${getX(i)},${getY(d.value ?? 0)}`),
    `L ${getX(filteredData.length - 1)},${H - PY}`,
    'Z',
  ].join(' ') : '';

  // X-axis label stride (keep 6 to 9 labels so they never collide)
  const maxLabels = 8;
  const stride = Math.max(1, Math.floor(filteredData.length / maxLabels));

  // Y-axis 5 ticks
  const yTicks = [0, 0.25, 0.5, 0.75, 1].map(fraction => {
    const val = chartMin + fraction * (chartMax - chartMin);
    const yPos = H - PY - fraction * (H - 2 * PY);
    return { val, yPos };
  });

  const activeHover = hoveredIndex !== null && filteredData[hoveredIndex] ? filteredData[hoveredIndex] : null;
  const activeHoverX = hoveredIndex !== null ? getX(hoveredIndex) : 0;
  const activeHoverY = hoveredIndex !== null && activeHover ? getY(activeHover.value ?? 0) : 0;

  const handleSvgMouseMove = (e) => {
    if (!filteredData.length) return;
    const rect = e.currentTarget.getBoundingClientRect();
    const clientX = e.clientX - rect.left;
    const svgX = (clientX / rect.width) * W;
    const clampedX = Math.max(PX, Math.min(W - PX, svgX));
    const ratio = (clampedX - PX) / (W - 2 * PX);
    const nearestIdx = Math.round(ratio * (filteredData.length - 1));
    setHoveredIndex(Math.max(0, Math.min(filteredData.length - 1, nearestIdx)));
  };

  const handleSvgMouseLeave = () => {
    setHoveredIndex(null);
  };

  return (
    <div className="modal-overlay" onClick={onClose} style={{ zIndex: 1100, padding: 16 }}>
      <div
        className="modal modal--2xl"
        onClick={(e) => e.stopPropagation()}
        style={{
          width: '95vw',
          maxWidth: '1120px',
          maxHeight: '92vh',
          display: 'flex',
          flexDirection: 'column',
          padding: '24px 28px',
          gap: 18,
          borderRadius: 20,
          boxShadow: '0 25px 60px -12px rgba(15, 23, 42, 0.25), 0 0 0 1px var(--color-border)',
        }}
      >
        {/* Modal Header */}
        <div className="modal__header" style={{ margin: 0, alignItems: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div
              style={{
                width: 44,
                height: 44,
                borderRadius: 12,
                background: `${color}15`,
                border: `1.5px solid ${color}35`,
                display: 'grid',
                placeItems: 'center',
                color: color,
                flexShrink: 0,
              }}
            >
              {icon || (
                <svg width="22" height="22" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round">
                  <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
                </svg>
              )}
            </div>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <h2 className="modal__title" style={{ margin: 0, fontSize: '1.25rem', fontWeight: 800 }}>
                  {title}
                </h2>
                <span
                  style={{
                    fontSize: '0.72rem',
                    fontWeight: 700,
                    padding: '3px 10px',
                    borderRadius: 20,
                    background: `${color}15`,
                    color: color,
                    border: `1px solid ${color}30`,
                    textTransform: 'uppercase',
                    letterSpacing: '0.04em',
                  }}
                >
                  Expanded View
                </span>
              </div>
              <p className="modal__subtitle" style={{ margin: '3px 0 0 0', fontSize: '0.82rem' }}>
                {subtitle} · Showing {filteredData.length} records
              </p>
            </div>
          </div>

          <button
            type="button"
            className="modal__close-btn"
            onClick={onClose}
            aria-label="Close"
            style={{
              width: 36,
              height: 36,
              borderRadius: 10,
              display: 'grid',
              placeItems: 'center',
              fontSize: '1.2rem',
            }}
          >
            ✕
          </button>
        </div>

        {/* Controls Toolbar: Time Range Pills & View Toggle */}
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            flexWrap: 'wrap',
            gap: 12,
            padding: '10px 14px',
            background: 'var(--color-surface-2)',
            borderRadius: 14,
            border: '1px solid var(--color-border)',
          }}
        >
          {/* Range filter buttons */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--color-text-dim)', marginRight: 4 }}>
              Zoom Range:
            </span>
            {[
              { id: '7d', label: '7 Days' },
              { id: '14d', label: '14 Days' },
              { id: '30d', label: '30 Days' },
              { id: '90d', label: '90 Days' },
              { id: 'all', label: 'All Time' },
            ].map(r => {
              const active = rangeFilter === r.id;
              return (
                <button
                  key={r.id}
                  type="button"
                  onClick={() => setRangeFilter(r.id)}
                  style={{
                    padding: '5px 12px',
                    borderRadius: 8,
                    fontSize: '0.78rem',
                    fontWeight: active ? 700 : 500,
                    border: active ? `1.5px solid ${color}` : '1px solid var(--color-border)',
                    background: active ? `${color}18` : 'var(--color-surface)',
                    color: active ? color : 'var(--color-text-muted)',
                    cursor: 'pointer',
                    transition: 'all 0.15s ease',
                  }}
                >
                  {r.label}
                </button>
              );
            })}
          </div>

          {/* View Tab Toggle (Chart vs Data Table) */}
          <div style={{ display: 'flex', background: 'var(--color-surface)', borderRadius: 10, padding: 3, border: '1px solid var(--color-border)' }}>
            <button
              type="button"
              onClick={() => setViewTab('chart')}
              style={{
                padding: '4px 14px',
                borderRadius: 7,
                fontSize: '0.78rem',
                fontWeight: 600,
                border: 'none',
                background: viewTab === 'chart' ? color : 'transparent',
                color: viewTab === 'chart' ? '#fff' : 'var(--color-text-muted)',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: 6,
                transition: 'all 0.15s ease',
              }}
            >
              📈 Large Chart
            </button>
            <button
              type="button"
              onClick={() => setViewTab('table')}
              style={{
                padding: '4px 14px',
                borderRadius: 7,
                fontSize: '0.78rem',
                fontWeight: 600,
                border: 'none',
                background: viewTab === 'table' ? color : 'transparent',
                color: viewTab === 'table' ? '#fff' : 'var(--color-text-muted)',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: 6,
                transition: 'all 0.15s ease',
              }}
            >
              📋 Data Log ({filteredData.length})
            </button>
          </div>
        </div>

        {/* Summary Metric Stats Row */}
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(170px, 1fr))',
            gap: 12,
          }}
        >
          <div style={{ padding: '12px 16px', background: 'var(--color-surface-2)', borderRadius: 12, border: '1px solid var(--color-border)' }}>
            <div style={{ fontSize: '0.74rem', color: 'var(--color-text-dim)', fontWeight: 600, textTransform: 'uppercase' }}>Period Average</div>
            <div style={{ fontSize: '1.35rem', fontWeight: 800, color: 'var(--color-text-main)', marginTop: 2 }}>
              {stats.avg.toFixed(1)}{unit}
            </div>
            <div style={{ fontSize: '0.72rem', color: 'var(--color-text-dim)', marginTop: 2 }}>Across {stats.count} recorded days</div>
          </div>

          <div style={{ padding: '12px 16px', background: 'var(--color-surface-2)', borderRadius: 12, border: '1px solid var(--color-border)' }}>
            <div style={{ fontSize: '0.74rem', color: 'var(--color-text-dim)', fontWeight: 600, textTransform: 'uppercase' }}>Peak / Highest</div>
            <div style={{ fontSize: '1.35rem', fontWeight: 800, color: '#10b981', marginTop: 2 }}>
              {stats.max.toFixed(0)}{unit}
            </div>
            <div style={{ fontSize: '0.72rem', color: 'var(--color-text-dim)', marginTop: 2 }}>{formatDate(stats.maxDate) || 'N/A'}</div>
          </div>

          <div style={{ padding: '12px 16px', background: 'var(--color-surface-2)', borderRadius: 12, border: '1px solid var(--color-border)' }}>
            <div style={{ fontSize: '0.74rem', color: 'var(--color-text-dim)', fontWeight: 600, textTransform: 'uppercase' }}>Lowest Point</div>
            <div style={{ fontSize: '1.35rem', fontWeight: 800, color: stats.min < 70 && unit === '%' ? '#ef4444' : 'var(--color-text-main)', marginTop: 2 }}>
              {stats.min.toFixed(0)}{unit}
            </div>
            <div style={{ fontSize: '0.72rem', color: 'var(--color-text-dim)', marginTop: 2 }}>{formatDate(stats.minDate) || 'N/A'}</div>
          </div>

          <div style={{ padding: '12px 16px', background: 'var(--color-surface-2)', borderRadius: 12, border: '1px solid var(--color-border)' }}>
            <div style={{ fontSize: '0.74rem', color: 'var(--color-text-dim)', fontWeight: 600, textTransform: 'uppercase' }}>Latest Value</div>
            <div style={{ fontSize: '1.35rem', fontWeight: 800, color: color, marginTop: 2 }}>
              {stats.latest.toFixed(0)}{unit}
            </div>
            <div style={{ fontSize: '0.72rem', color: 'var(--color-text-dim)', marginTop: 2 }}>{formatDate(stats.latestDate) || 'Latest point'}</div>
          </div>
        </div>

        {/* Content View: Chart or Table */}
        {viewTab === 'chart' ? (
          <div
            style={{
              position: 'relative',
              background: 'var(--color-surface)',
              borderRadius: 16,
              border: '1px solid var(--color-border)',
              padding: '16px 20px 20px 20px',
              userSelect: 'none',
            }}
          >
            {/* Top Indicator */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ width: 10, height: 10, borderRadius: '50%', background: color }} />
                <span style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--color-text-main)' }}>{label}</span>
                <span style={{ fontSize: '0.75rem', color: 'var(--color-text-dim)' }}>
                  (Hover over any point to inspect exact day telemetry)
                </span>
              </div>
              {activeHover && (
                <div
                  style={{
                    background: `${color}18`,
                    border: `1px solid ${color}40`,
                    padding: '4px 12px',
                    borderRadius: 20,
                    fontSize: '0.8rem',
                    fontWeight: 700,
                    color: color,
                    display: 'flex',
                    alignItems: 'center',
                    gap: 6,
                  }}
                >
                  📅 {formatDate(activeHover.date, true)}:
                  <span style={{ fontSize: '0.9rem' }}>{Number(activeHover.value ?? 0).toFixed(0)}{unit}</span>
                </div>
              )}
            </div>

            {/* SVG Chart */}
            <div style={{ position: 'relative', width: '100%', overflow: 'hidden' }}>
              <svg
                viewBox={`0 0 ${W} ${H}`}
                style={{ width: '100%', height: 'auto', display: 'block', cursor: 'crosshair' }}
                onMouseMove={handleSvgMouseMove}
                onMouseLeave={handleSvgMouseLeave}
              >
                <defs>
                  <linearGradient id={`detail-grad-${color.replace('#', '')}`} x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor={color} stopOpacity="0.28" />
                    <stop offset="90%" stopColor={color} stopOpacity="0.01" />
                  </linearGradient>
                  <filter id="glow-filter" x="-20%" y="-20%" width="140%" height="140%">
                    <feDropShadow dx="0" dy="2" stdDeviation="3" floodColor={color} floodOpacity="0.35" />
                  </filter>
                </defs>

                {/* Horizontal benchmark gridlines & Y labels */}
                {yTicks.map((tick, idx) => (
                  <g key={idx}>
                    <line
                      x1={PX}
                      y1={tick.yPos}
                      x2={W - PX}
                      y2={tick.yPos}
                      stroke="var(--color-border)"
                      strokeWidth="1"
                      strokeDasharray="4 5"
                      opacity="0.75"
                    />
                    <text
                      x={PX - 12}
                      y={tick.yPos + 4}
                      textAnchor="end"
                      fontSize="10"
                      fontWeight="600"
                      fill="var(--color-text-dim)"
                      fontFamily="Inter, sans-serif"
                    >
                      {tick.val.toFixed(0)}{unit}
                    </text>
                  </g>
                ))}

                {/* Area Gradient */}
                {areaPath && <path d={areaPath} fill={`url(#detail-grad-${color.replace('#', '')})`} />}

                {/* Main Line */}
                {linePts && (
                  <polyline
                    fill="none"
                    stroke={color}
                    strokeWidth="3.2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    filter="url(#glow-filter)"
                    points={linePts}
                  />
                )}

                {/* X-axis date labels (cleanly spaced) */}
                {filteredData.map((d, i) => {
                  const shouldShow = i === 0 || i === filteredData.length - 1 || i % stride === 0;
                  if (!shouldShow) return null;
                  const x = getX(i);
                  return (
                    <text
                      key={i}
                      x={x}
                      y={H - 6}
                      textAnchor="middle"
                      fontSize="10.5"
                      fontWeight="600"
                      fill="var(--color-text-dim)"
                      fontFamily="Inter, sans-serif"
                    >
                      {formatDate(d.date)}
                    </text>
                  );
                })}

                {/* Discrete points for short ranges (<= 25 items) to keep it clean and uncrowded */}
                {filteredData.length <= 25 && filteredData.map((d, i) => {
                  const x = getX(i);
                  const y = getY(d.value ?? 0);
                  const isHovered = hoveredIndex === i;
                  return (
                    <circle
                      key={i}
                      cx={x}
                      cy={y}
                      r={isHovered ? 6 : 3.5}
                      fill={isHovered ? '#fff' : color}
                      stroke={color}
                      strokeWidth={isHovered ? 3 : 2}
                      style={{ transition: 'all 0.15s ease' }}
                    />
                  );
                })}

                {/* Active Hover Crosshair & Concentric Indicator */}
                {hoveredIndex !== null && activeHover && (
                  <g>
                    {/* Vertical dashed crosshair line */}
                    <line
                      x1={activeHoverX}
                      y1={PY}
                      x2={activeHoverX}
                      y2={H - PY}
                      stroke={color}
                      strokeWidth="1.5"
                      strokeDasharray="3 3"
                    />
                    {/* Outer glow ring */}
                    <circle
                      cx={activeHoverX}
                      cy={activeHoverY}
                      r="9"
                      fill={color}
                      fillOpacity="0.25"
                    />
                    {/* Inner point */}
                    <circle
                      cx={activeHoverX}
                      cy={activeHoverY}
                      r="4.5"
                      fill="#fff"
                      stroke={color}
                      strokeWidth="3"
                    />
                  </g>
                )}
              </svg>
            </div>
          </div>
        ) : (
          /* Table View: Complete granular daily telemetry */
          <div
            style={{
              maxHeight: 340,
              overflowY: 'auto',
              borderRadius: 14,
              border: '1px solid var(--color-border)',
              background: 'var(--color-surface)',
            }}
          >
            <table className="accounts-table" style={{ margin: 0 }}>
              <thead>
                <tr>
                  <th style={{ position: 'sticky', top: 0, background: 'var(--color-surface-2)', zIndex: 2 }}>Date</th>
                  <th style={{ position: 'sticky', top: 0, background: 'var(--color-surface-2)', zIndex: 2 }}>{label}</th>
                  <th style={{ position: 'sticky', top: 0, background: 'var(--color-surface-2)', zIndex: 2 }}>Performance vs Avg ({stats.avg.toFixed(1)}{unit})</th>
                  <th style={{ position: 'sticky', top: 0, background: 'var(--color-surface-2)', zIndex: 2 }}>Assessment</th>
                </tr>
              </thead>
              <tbody>
                {filteredData.slice().reverse().map((item, idx) => {
                  const val = Number(item.value ?? 0);
                  const diff = val - stats.avg;
                  const isPositive = diff >= 0;
                  return (
                    <tr key={idx}>
                      <td style={{ fontWeight: 600, color: 'var(--color-text-main)' }}>
                        {formatDate(item.date, true)}
                      </td>
                      <td style={{ fontWeight: 800, color: color, fontSize: '0.95rem' }}>
                        {val.toFixed(0)}{unit}
                      </td>
                      <td>
                        <span
                          style={{
                            fontWeight: 700,
                            fontSize: '0.8rem',
                            color: isPositive ? '#10b981' : '#ef4444',
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: 3,
                          }}
                        >
                          {isPositive ? '▲ +' : '▼ '}
                          {diff.toFixed(1)}{unit}
                        </span>
                      </td>
                      <td>
                        {unit === '%' ? (
                          val >= 90 ? (
                            <span className="badge badge--success">🌟 Mastery (90%+)</span>
                          ) : val >= 70 ? (
                            <span className="badge badge--primary">👍 Good (70–89%)</span>
                          ) : (
                            <span className="badge badge--danger">⚠️ Needs Support (&lt;70%)</span>
                          )
                        ) : (
                          val >= 50 ? (
                            <span className="badge badge--success">🚀 High Activity ({val})</span>
                          ) : val > 0 ? (
                            <span className="badge badge--neutral">✓ Active ({val})</span>
                          ) : (
                            <span className="badge badge--muted">0 completions</span>
                          )
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}

        {/* Modal Footer */}
        <div style={{ display: 'flex', justifyContent: 'flex-end', paddingTop: 6 }}>
          <button
            type="button"
            className="btn btn--secondary"
            onClick={onClose}
            style={{ fontWeight: 600, padding: '8px 20px', borderRadius: 10 }}
          >
            Close View
          </button>
        </div>
      </div>
    </div>
  );
}
