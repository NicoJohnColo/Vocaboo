export default function UploadProgressBar({ progress, statusText, isError }) {
  const clampedProgress = Math.max(0, Math.min(100, progress));
  
  return (
    <div style={{ marginBottom: 16 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4, fontSize: '0.8rem' }}>
        <span style={{ color: isError ? 'var(--color-danger)' : 'var(--color-text-muted)' }}>
          {statusText || (clampedProgress === 100 ? 'Complete' : 'Uploading...')}
        </span>
        <span style={{ color: 'var(--color-text-muted)', fontFamily: 'JetBrains Mono, monospace' }}>
          {clampedProgress}%
        </span>
      </div>
      <div style={{ 
        height: 6, 
        backgroundColor: 'var(--glass-bg)', 
        borderRadius: 3, 
        overflow: 'hidden' 
      }}>
        <div style={{
          height: '100%',
          width: `${clampedProgress}%`,
          backgroundColor: isError ? 'var(--color-danger)' : 'var(--color-accent-1)',
          transition: 'width 0.3s ease'
        }} />
      </div>
    </div>
  );
}
