import { useCallback, useState } from 'react';

export default function FileUploadDropZone({ accept, maxSizeMB, onFileSelect, label, disabled }) {
  const [isDragOver, setIsDragOver] = useState(false);
  const [error, setError] = useState(null);

  const validateAndSelect = (file) => {
    setError(null);
    const maxBytes = maxSizeMB * 1024 * 1024;
    
    // Check size
    if (file.size > maxBytes) {
      setError(`File exceeds the ${maxSizeMB}MB limit.`);
      return;
    }

    // Basic MIME type check
    const acceptedTypes = accept.split(',').map(t => t.trim());
    if (acceptedTypes.length > 0 && accept !== '*') {
      const isValidType = acceptedTypes.some(type => {
        if (type.startsWith('.')) {
          return file.name.toLowerCase().endsWith(type.toLowerCase());
        }
        if (type.endsWith('/*')) {
          return file.type.startsWith(type.replace('/*', '/'));
        }
        return file.type === type;
      });

      if (!isValidType) {
        setError(`Invalid file type. Allowed types: ${accept}`);
        return;
      }
    }

    onFileSelect(file);
  };

  const handleDragOver = useCallback((e) => {
    e.preventDefault();
    if (!disabled) setIsDragOver(true);
  }, [disabled]);

  const handleDragLeave = useCallback((e) => {
    e.preventDefault();
    setIsDragOver(false);
  }, []);

  const handleDrop = useCallback((e) => {
    e.preventDefault();
    setIsDragOver(false);
    if (disabled) return;

    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      validateAndSelect(e.dataTransfer.files[0]);
    }
  }, [disabled, maxSizeMB, accept]);

  const handleFileChange = (e) => {
    if (e.target.files && e.target.files.length > 0) {
      validateAndSelect(e.target.files[0]);
    }
  };

  return (
    <div className="file-dropzone-container" style={{ marginBottom: 16 }}>
      <label className="form-label">{label}</label>
      <div
        style={{
          border: `2px dashed ${isDragOver ? 'var(--color-accent-1)' : 'var(--color-border)'}`,
          borderRadius: 'var(--radius-sm)',
          padding: '24px',
          textAlign: 'center',
          backgroundColor: isDragOver ? 'rgba(37, 99, 235, 0.06)' : 'var(--glass-bg)',
          cursor: disabled ? 'not-allowed' : 'pointer',
          transition: 'all 0.2s ease',
          opacity: disabled ? 0.6 : 1
        }}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
      >
        <input
          type="file"
          accept={accept}
          onChange={handleFileChange}
          disabled={disabled}
          style={{ display: 'none' }}
          id={`file-upload-${label.replace(/\s+/g, '-')}`}
        />
        <label htmlFor={`file-upload-${label.replace(/\s+/g, '-')}`} style={{ cursor: disabled ? 'not-allowed' : 'pointer', display: 'block' }}>
          <div style={{ marginBottom: '8px', color: 'var(--color-text-muted)' }}>
            <strong>Choose a file</strong> or drag it here
          </div>
          <div style={{ fontSize: '0.8rem', color: 'var(--color-text-muted)', opacity: 0.7 }}>
            Accepts: {accept} | Max: {maxSizeMB}MB
          </div>
        </label>
      </div>
      {error && <div style={{ color: 'var(--color-danger)', fontSize: '0.8rem', marginTop: '4px' }}>{error}</div>}
    </div>
  );
}
