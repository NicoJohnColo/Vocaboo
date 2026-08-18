// import React

interface Props {
  type: 'AUDIO' | 'IMAGE';
  url: string;
}

export default function FilePreviewWidget({ type, url }: Props) {
  if (!url) return null;

  return (
    <div style={{ marginTop: 8, marginBottom: 16, padding: 12, backgroundColor: 'var(--glass-bg)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--color-border)' }}>
      <div style={{ fontSize: '0.8rem', color: 'var(--color-text-muted)', marginBottom: 8, display: 'flex', justifyContent: 'space-between' }}>
        <span>Preview</span>
        <span style={{ color: 'var(--color-success)' }}>✓ Ready</span>
      </div>

      {type === 'IMAGE' ? (
        <div style={{ textAlign: 'center' }}>
          <img src={url} alt="Preview" style={{ maxWidth: '100%', maxHeight: 150, borderRadius: 4, objectFit: 'contain' }} />
        </div>
      ) : (
        <audio controls src={url} style={{ width: '100%', height: 36, outline: 'none' }} />
      )}

      <div style={{ marginTop: 8, fontSize: '0.75rem', color: 'var(--color-text-muted)', wordBreak: 'break-all' }}>
        URL: <a href={url} target="_blank" rel="noreferrer" style={{ color: 'var(--color-accent-2)' }}>{url}</a>
      </div>
    </div>
  );
}
