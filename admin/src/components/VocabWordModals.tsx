import { useState } from 'react';
import AssetUploadModal from './AssetUploadModal';
import { AssetUploadService } from '../services/AssetUploadService';

const GRADE_LEVELS = ['GRADE_4', 'GRADE_5', 'GRADE_6'];
const POS_OPTIONS = ['NOUN', 'VERB', 'ADJECTIVE'];

interface WordFormData {
  english_word: string;
  cebuano_meaning: string;
  part_of_speech: string;
  grade_level: string;
  example_sentence_english: string;
  example_sentence_cebuano: string;
  audio_asset_path: string;
  image_asset_path: string;
}

interface Props {
  initial?: Partial<WordFormData>;
  title: string;
  submitLabel: string;
  onSubmit: (data: WordFormData) => Promise<void>;
  onClose: () => void;
  submitting?: boolean;
  error?: string;
  lessonId: string;
  wordId?: string;
}

function emptyForm(): WordFormData {
  return {
    english_word: '',
    cebuano_meaning: '',
    part_of_speech: 'NOUN',
    grade_level: 'GRADE_4',
    example_sentence_english: '',
    example_sentence_cebuano: '',
    audio_asset_path: '',
    image_asset_path: '',
  };
}

function VocabWordForm({ initial, title, submitLabel, onSubmit, onClose, submitting, error, lessonId, wordId }: Props) {
  const [form, setForm] = useState<WordFormData>({ ...emptyForm(), ...initial });
  const [validationErrors, setValidationErrors] = useState<Record<string, string>>({});
  const [showUploadModal, setShowUploadModal] = useState(false);
  const [validating, setValidating] = useState(false);

  const validate = () => {
    const errs: Record<string, string> = {};
    if (!form.english_word.trim() || form.english_word.trim().length < 2) errs.english_word = 'English word must be at least 2 characters';
    if (!form.cebuano_meaning.trim() || form.cebuano_meaning.trim().length < 2) errs.cebuano_meaning = 'Cebuano meaning must be at least 2 characters';
    if (!form.example_sentence_english.trim() || form.example_sentence_english.trim().length < 10) errs.example_sentence_english = 'Example sentence must be at least 10 characters';
    return errs;
  };

  const handleSubmit = async () => {
    const errs = validate();
    if (Object.keys(errs).length) { setValidationErrors(errs); return; }

    setValidating(true);
    setValidationErrors({});
    let hasVerificationError = false;

    if (form.audio_asset_path) {
      if (form.audio_asset_path.startsWith('http://') || form.audio_asset_path.startsWith('https://')) {
        try {
          const res = await AssetUploadService.verifyUrl(form.audio_asset_path);
          if (!res.accessible) {
            setValidationErrors(prev => ({ ...prev, audio_asset_path: 'Audio file not found or inaccessible. Please verify the URL or upload it.' }));
            hasVerificationError = true;
          }
        } catch {
          setValidationErrors(prev => ({ ...prev, audio_asset_path: 'Failed to verify audio URL.' }));
          hasVerificationError = true;
        }
      }
    }

    if (form.image_asset_path) {
      if (form.image_asset_path.startsWith('http://') || form.image_asset_path.startsWith('https://')) {
        try {
          const res = await AssetUploadService.verifyUrl(form.image_asset_path);
          if (!res.accessible) {
            setValidationErrors(prev => ({ ...prev, image_asset_path: 'Image file not found or inaccessible. Please verify the URL or upload it.' }));
            hasVerificationError = true;
          }
        } catch {
          setValidationErrors(prev => ({ ...prev, image_asset_path: 'Failed to verify image URL.' }));
          hasVerificationError = true;
        }
      }
    }

    setValidating(false);

    if (hasVerificationError) return;

    await onSubmit(form);
  };

  const f = (key: keyof WordFormData) => ({
    value: form[key],
    onChange: (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
      setForm(prev => ({ ...prev, [key]: e.target.value }));
      setValidationErrors(ve => ({ ...ve, [key]: '' }));
    },
  });

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal modal--lg modal--xl" onClick={e => e.stopPropagation()}>
        <h2 className="modal__title">{title}</h2>
        {error && <div className="alert alert--error">{error}</div>}

        <div className="form-grid form-grid--2col">
          <div className="form-field">
            <label className="form-label">English Word *</label>
            <input className={`form-input ${validationErrors.english_word ? 'form-input--error' : ''}`} {...f('english_word')} placeholder="e.g. Pencil" autoFocus />
            {validationErrors.english_word && <span className="form-error">{validationErrors.english_word}</span>}
          </div>
          <div className="form-field">
            <label className="form-label">Cebuano Meaning *</label>
            <input className={`form-input ${validationErrors.cebuano_meaning ? 'form-input--error' : ''}`} {...f('cebuano_meaning')} placeholder="e.g. Lapis" />
            {validationErrors.cebuano_meaning && <span className="form-error">{validationErrors.cebuano_meaning}</span>}
          </div>
          <div className="form-field">
            <label className="form-label">Part of Speech *</label>
            <select className="form-select" {...f('part_of_speech')}>
              {POS_OPTIONS.map(p => <option key={p} value={p}>{p}</option>)}
            </select>
          </div>
          <div className="form-field">
            <label className="form-label">Grade Level *</label>
            <select className="form-select" {...f('grade_level')}>
              {GRADE_LEVELS.map(g => <option key={g} value={g}>{g.replace('_', ' ')}</option>)}
            </select>
          </div>
          <div className="form-field form-field--full">
            <label className="form-label">Example Sentence (English) *</label>
            <textarea className={`form-textarea ${validationErrors.example_sentence_english ? 'form-input--error' : ''}`} rows={2} {...f('example_sentence_english')} placeholder="I write with a pencil." />
            {validationErrors.example_sentence_english && <span className="form-error">{validationErrors.example_sentence_english}</span>}
          </div>
          <div className="form-field form-field--full">
            <label className="form-label">Example Sentence (Cebuano)</label>
            <textarea className="form-textarea" rows={2} {...f('example_sentence_cebuano')} placeholder="Nagsulat ko og lapis." />
          </div>
          <div className="form-field form-field--full" style={{ padding: '16px', background: 'var(--glass-bg)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--color-border)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
              <h3 style={{ fontSize: '1rem', margin: 0 }}>Media Assets</h3>
              <button type="button" className="btn btn--sm btn--ghost" onClick={() => setShowUploadModal(true)}>
                📤 Upload Assets
              </button>
            </div>
            
            <div className="form-grid form-grid--2col">
              <div className="form-field">
                <label className="form-label">Audio Path / URL</label>
                <input className={`form-input ${validationErrors.audio_asset_path ? 'form-input--error' : ''}`} {...f('audio_asset_path')} placeholder="assets/audio/lesson01_pencil.mp3" />
                {validationErrors.audio_asset_path && <span className="form-error">{validationErrors.audio_asset_path}</span>}
              </div>
              <div className="form-field">
                <label className="form-label">Image Path / URL</label>
                <input className={`form-input ${validationErrors.image_asset_path ? 'form-input--error' : ''}`} {...f('image_asset_path')} placeholder="assets/images/lesson01_pencil.png" />
                {validationErrors.image_asset_path && <span className="form-error">{validationErrors.image_asset_path}</span>}
              </div>
            </div>
          </div>
        </div>

        {showUploadModal && (
          <AssetUploadModal
            lessonId={lessonId}
            wordId={wordId}
            onClose={() => setShowUploadModal(false)}
            onUploadComplete={(audioUrl, imageUrl) => {
              if (audioUrl) setForm(prev => ({ ...prev, audio_asset_path: audioUrl }));
              if (imageUrl) setForm(prev => ({ ...prev, image_asset_path: imageUrl }));
            }}
          />
        )}

        <div className="modal__actions">
          <button className="btn btn--ghost" onClick={onClose} disabled={submitting || validating}>Cancel</button>
          <button className="btn btn--primary" onClick={handleSubmit} disabled={submitting || validating}>
            {(submitting || validating) ? <span className="spinner spinner--sm" /> : submitLabel}
          </button>
        </div>
      </div>
    </div>
  );
}

export function AddVocabularyModal(props: Omit<Props, 'title' | 'submitLabel'>) {
  return <VocabWordForm {...props} title="➕ Add Vocabulary Word" submitLabel="Add Word" />;
}

export function EditVocabularyModal(props: Omit<Props, 'title' | 'submitLabel'>) {
  return <VocabWordForm {...props} title="✏️ Edit Vocabulary Word" submitLabel="Save Changes" />;
}
