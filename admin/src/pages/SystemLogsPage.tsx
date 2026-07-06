import { useState, useCallback } from 'react';
import AdminNav from '../components/AdminNav';
import { apiFetch } from '../services/AuthService';

type LogLevel = 'ERROR' | 'WARN' | 'INFO' | 'DEBUG' | '';

interface LogResponse {
  lines: string[];
  total: number;
  returned: number;
  note?: string;
}

const LEVEL_COLORS: Record<string, string> = {
  ERROR: '#ef9a9a',
  WARN:  '#ffcc80',
  INFO:  '#80cbc4',
  DEBUG: '#90caf9',
  METRIC:'#ce93d8',
};

function colorize(line: string): { color: string; text: string } {
  for (const [key, color] of Object.entries(LEVEL_COLORS)) {
    if (line.includes(key) || line.includes(`[${key}]`)) {
      return { color, text: line };
    }
  }
  return { color: 'var(--color-text-muted)', text: line };
}

export default function SystemLogsPage() {
  const [level, setLevel]       = useState<LogLevel>('');
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate]     = useState('');
  const [limit, setLimit]       = useState(200);
  const [result, setResult]     = useState<LogResponse | null>(null);
  const [loading, setLoading]   = useState(false);
  const [error, setError]       = useState('');

  const fetchLogs = useCallback(async () => {
    setLoading(true);
    setError('');
    const params = new URLSearchParams();
    if (level)    params.set('level', level);
    if (fromDate) params.set('from_date', fromDate);
    if (toDate)   params.set('to_date', toDate);
    params.set('limit', String(limit));

    try {
      const res = await apiFetch(`/api/admin/logs?${params.toString()}`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data: LogResponse = await res.json();
      setResult(data);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to fetch logs.');
    } finally {
      setLoading(false);
    }
  }, [level, fromDate, toDate, limit]);

  return (
    <div className="admin-layout">
      <AdminNav />
      <main className="admin-main">
        <header className="admin-main__header">
          <div>
            <h1 className="admin-main__title">System Logs</h1>
            <p className="admin-main__subtitle">View backend application logs</p>
          </div>
        </header>

        {/* Filters */}
        <div className="log-filters">
          <div className="log-filters__field">
            <label className="login-form__label">Level</label>
            <select
              id="log-level-select"
              className="log-filters__select"
              value={level}
              onChange={e => setLevel(e.target.value as LogLevel)}
            >
              <option value="">All Levels</option>
              <option value="ERROR">ERROR</option>
              <option value="WARN">WARN</option>
              <option value="INFO">INFO</option>
              <option value="DEBUG">DEBUG</option>
            </select>
          </div>
          <div className="log-filters__field">
            <label className="login-form__label">From Date</label>
            <input
              id="log-from-date"
              type="date"
              className="log-filters__input"
              value={fromDate}
              onChange={e => setFromDate(e.target.value)}
            />
          </div>
          <div className="log-filters__field">
            <label className="login-form__label">To Date</label>
            <input
              id="log-to-date"
              type="date"
              className="log-filters__input"
              value={toDate}
              onChange={e => setToDate(e.target.value)}
            />
          </div>
          <div className="log-filters__field">
            <label className="login-form__label">Limit</label>
            <select
              id="log-limit-select"
              className="log-filters__select"
              value={limit}
              onChange={e => setLimit(Number(e.target.value))}
            >
              {[100, 200, 500, 1000].map(n => <option key={n} value={n}>{n} lines</option>)}
            </select>
          </div>
          <button
            id="fetch-logs-btn"
            className="btn btn--primary log-filters__btn"
            onClick={fetchLogs}
            disabled={loading}
          >
            {loading ? <span className="spinner spinner--sm" /> : 'Fetch Logs'}
          </button>
        </div>

        {error && <div className="alert alert--error">{error}</div>}

        {result && (
          <>
            <div className="log-meta">
              Showing <strong>{result.returned}</strong> of <strong>{result.total}</strong> matching lines.
              {result.note && <span className="text-muted"> ({result.note})</span>}
            </div>
            <div className="log-output" role="log" aria-live="polite">
              {result.lines.length === 0 ? (
                <div className="log-output__empty">No log lines matched your filters.</div>
              ) : (
                result.lines.map((line, i) => {
                  const { color, text } = colorize(line);
                  return (
                    <div key={i} className="log-line" style={{ color }}>
                      {text}
                    </div>
                  );
                })
              )}
            </div>
          </>
        )}

        {!result && !loading && (
          <div className="coming-soon" style={{ marginTop: 24 }}>
            <div className="coming-soon__icon">📋</div>
            <h2 className="coming-soon__title">Select Filters &amp; Fetch Logs</h2>
            <p className="coming-soon__text">
              Use the filters above to query the backend application logs.
              Logs are read from <code style={{ fontFamily: 'monospace' }}>logs/app.log</code> in production.
            </p>
          </div>
        )}
      </main>
    </div>
  );
}
