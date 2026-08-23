import { useState } from 'react';
import FileUploadDropZone from './FileUploadDropZone';
import UploadProgressBar from './UploadProgressBar';
import FilePreviewWidget from './FilePreviewWidget';
import { AssetUploadService } from '../services/AssetUploadService';

export default function AssetUploadModal({ lessonId, wordId, onClose, onUploadComplete }) {
  const [audioUrl, setAudioUrl] = useState(null);
  const [imageUrl, setImageUrl] = useState(null);

  const [audioUploading, setAudioUploading] = useState(false);
  const [audioProgress, setAudioProgress] = useState(0);
  const [audioError, setAudioError] = useState(null);

  const [imageUploading, setImageUploading] = useState(false);
  const [imageProgress, setImageProgress] = useState(0);
  const [imageError, setImageError] = useState(null);

  const handleUpload = async (file, type) => {
    const setUploading = type === 'AUDIO' ? setAudioUploading : setImageUploading;
    const setProgress = type === 'AUDIO' ? setAudioProgress : setImageProgress;
    const setError = type === 'AUDIO' ? setAudioError : setImageError;
    const setUrl = type === 'AUDIO' ? setAudioUrl : setImageUrl;

    try {
      setUploading(true);
      setProgress(10);
      setError(null);

      const progressInterval = setInterval(() => {
        setProgress(p => (p < 90 ? p + 10 : p));
      }, 100);

      const res = await AssetUploadService.uploadFile(file, type, lessonId, wordId);

      clearInterval(progressInterval);
      setProgress(100);
      setUrl(res.asset_url);
    } catch (err) {
      setProgress(0);
      setError(err?.message || 'Upload failed');
    } finally {
      setUploading(false);
    }
  };

  const handleSave = () => {
    onUploadComplete(audioUrl, imageUrl);
    onClose();
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" style={{ width: 600, maxWidth: '95%' }} onClick={e => e.stopPropagation()}>
        <h2 className="modal__title">Upload Audio & Image</h2>
        <p className="modal__note">Upload media assets to store them securely. Supported formats: MP3/WAV (&lt;5MB) and PNG/JPG (&lt;6MB).</p>

        <div style={{ marginTop: 24, paddingBottom: 24, borderBottom: '1px solid var(--color-border)' }}>
          <h3 style={{ fontSize: '1rem', marginBottom: 16 }}>Audio Asset</h3>
          {!audioUrl ? (
            <FileUploadDropZone
              accept="audio/mpeg,audio/wav,audio/wave,audio/x-wav,audio/mp3,.mp3,.wav"
              maxSizeMB={5}
              label="Audio (MP3/WAV, <5MB)"
              disabled={audioUploading}
              onFileSelect={file => handleUpload(file, 'AUDIO')}
            />
          ) : null}

          {audioUploading && (
            <UploadProgressBar progress={audioProgress} statusText="⏳ Uploading Audio..." />
          )}
          {audioError && (
            <UploadProgressBar progress={100} isError statusText={`Error: ${audioError}`} />
          )}

          {audioUrl && !audioUploading && (
            <FilePreviewWidget type="AUDIO" url={audioUrl} />
          )}
        </div>

        <div style={{ marginTop: 24, marginBottom: 24 }}>
          <h3 style={{ fontSize: '1rem', marginBottom: 16 }}>Image Asset</h3>
          {!imageUrl ? (
            <FileUploadDropZone
              accept="image/png,image/jpeg"
              maxSizeMB={6}
              label="Image (PNG/JPG, <6MB)"
              disabled={imageUploading}
              onFileSelect={file => handleUpload(file, 'IMAGE')}
            />
          ) : null}

          {imageUploading && (
            <UploadProgressBar progress={imageProgress} statusText="⏳ Uploading Image..." />
          )}
          {imageError && (
            <UploadProgressBar progress={100} isError statusText={`Error: ${imageError}`} />
          )}

          {imageUrl && !imageUploading && (
            <FilePreviewWidget type="IMAGE" url={imageUrl} />
          )}
        </div>

        <div className="modal__actions">
          <button className="btn btn--ghost" onClick={onClose}>Cancel</button>
          <button 
            className="btn btn--primary" 
            onClick={handleSave}
            disabled={audioUploading || imageUploading}
          >
            Save & Close
          </button>
        </div>
      </div>
    </div>
  );
}
