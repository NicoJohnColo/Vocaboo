import { useState } from 'react';
import AssetUploadModal from './AssetUploadModal';

const GRADE_LEVELS = ['GRADE_4', 'GRADE_5', 'GRADE_6'];
const POS_OPTIONS = ['NOUN', 'VERB', 'ADJECTIVE'];

function emptyForm() {
  return {
    english_word: '',
    cebuano_meaning: '',
    part_of_speech: 'NOUN',
    grade_level: 'GRADE_4',
    example_sentence_english: '',
    example_sentence_cebuano: '',
    audio_asset_path: '',
    image_asset_path: '',
    eligible_activity_types: 'MULTIPLE_CHOICE;FILL_IN_BLANK;MATCHING;WORD_SCRAMBLE;TRUE_OR_FALSE;HINT_TO_WORD',
    distractor_pool: '',
    fill_blank_sentence: '',
    tile_sentence: '',
    explanation_text: '',
    hint_definition: '',
    hint_cebuano_sentence: '',
    audio_text_cebuano: '',
    audio_text_english: '',
    phonological_tip_key: '',
    is_confusable_pair_member: false,
  };
}

function VocabWordForm({ initial, title, submitLabel, onSubmit, onClose, submitting, error, lessonId, wordId }) {
  const [form, setForm] = useState({ ...emptyForm(), ...initial });
  const [validationErrors, setValidationErrors] = useState({});
  const [showUploadModal, setShowUploadModal] = useState(false);

  const validate = () => {
    const errs = {};
    if (!form.english_word.trim() || form.english_word.trim().length < 2) errs.english_word = 'English word must be at least 2 characters';
    if (!form.cebuano_meaning.trim() || form.cebuano_meaning.trim().length < 2) errs.cebuano_meaning = 'Cebuano meaning must be at least 2 characters';
    if (!form.example_sentence_english.trim() || form.example_sentence_english.trim().length < 10) errs.example_sentence_english = 'Example sentence must be at least 10 characters';
    return errs;
  };

  const handleSubmit = async () => {
    const errs = validate();
    if (Object.keys(errs).length) { setValidationErrors(errs); return; }
    await onSubmit(form);
  };

  const f = (key) => ({
    value: form[key],
    onChange: (e) => {
      setForm(prev => ({ ...prev, [key]: e.target.type === 'checkbox' ? e.target.checked : e.target.value }));
      setValidationErrors(ve => ({ ...ve, [key]: '' }));
    },
    ...(typeof form[key] === 'boolean' ? { checked: form[key] } : {})
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
              {GRADE_LEVELS.map(g => <option key={g} value={g}>{g.replace('GRADE_', 'Grade ')}</option>)}
            </select>
          </div>
          <div className="form-field form-field--full">
            <label className="form-label">Eligible Activity Types (semicolon-separated)</label>
            <input className="form-input" {...f('eligible_activity_types')} placeholder="e.g. MULTIPLE_CHOICE;FILL_IN_BLANK" />
            <span style={{fontSize: '0.8rem', color: 'var(--color-text-dim)', marginTop: '4px'}}>
              Available: MULTIPLE_CHOICE, FILL_IN_BLANK, MATCHING, WORD_SCRAMBLE, TRUE_OR_FALSE, IMAGE_LABELING, SENTENCE_ARRANGEMENT, HINT_TO_WORD
            </span>
          </div>

          <div className="form-field form-field--full" style={{ padding: '16px', background: 'var(--glass-bg)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--color-border)', marginTop: '8px' }}>
            <h3 style={{ fontSize: '1rem', margin: '0 0 16px 0', color: 'var(--color-primary)' }}>Activity Content Fields</h3>
            <div className="form-grid form-grid--2col">
              <div className="form-field form-field--full">
                <label className="form-label">Distractor Pool (comma-separated)</label>
                <input className="form-input" {...f('distractor_pool')} placeholder="e.g. eraser,ruler,scissors" />
                <span style={{fontSize: '0.8rem', color: 'var(--color-text-dim)', marginTop: '4px'}}>Wrong answers for multiple choice & wrong word for True/False sentences.</span>
              </div>
              <div className="form-field form-field--full">
                <label className="form-label">Fill-in-the-Blank Sentence</label>
                <input className="form-input" {...f('fill_blank_sentence')} placeholder="I write with a {BLANK}." />
              </div>
              <div className="form-field form-field--full">
                <label className="form-label">Tile Arrangement Sentence</label>
                <input className="form-input" {...f('tile_sentence')} placeholder="The girl is young" />
              </div>
              <div className="form-field form-field--full">
                <label className="form-label">Explanation Text (Shown at LEARNING tier)</label>
                <input className="form-input" {...f('explanation_text')} placeholder="e.g. It starts with p..." />
              </div>
              <div className="form-field form-field--full">
                <label className="form-label">Hint Definition / Synonym Clue (For Hint-to-Word at FAMILIAR/PROFICIENT)</label>
                <input className="form-input" {...f('hint_definition')} placeholder="e.g. a tool with graphite used for writing" />
              </div>
              <div className="form-field form-field--full">
                <label className="form-label">Hint Cebuano Sentence Clue (For Hint-to-Word at LEARNING tier)</label>
                <input className="form-input" {...f('hint_cebuano_sentence')} placeholder="e.g. Usa ka gamit nga may carbon para isulat" />
              </div>
              <div className="form-field">
                <label className="form-label">Phonological Tip Key</label>
                <input className="form-input" {...f('phonological_tip_key')} placeholder="e.g. TH_SOUND" />
              </div>
              <div className="form-field" style={{ display: 'flex', alignItems: 'center', gap: '8px', paddingTop: '28px' }}>
                <input type="checkbox" id="confusablePair" {...f('is_confusable_pair_member')} />
                <label htmlFor="confusablePair" className="form-label" style={{ marginBottom: 0 }}>Is Confusable Pair Member?</label>
              </div>
            </div>
          </div>

          <div className="form-field form-field--full" style={{ padding: '16px', background: 'var(--glass-bg)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--color-border)', marginTop: '8px' }}>
            <h3 style={{ fontSize: '1rem', margin: '0 0 16px 0', color: 'var(--color-primary)' }}>TTS Engine Overrides</h3>
            <div className="form-grid form-grid--2col">
              <div className="form-field form-field--full">
                <label className="form-label">Audio Text (Cebuano Override)</label>
                <input className="form-input" {...f('audio_text_cebuano')} placeholder="Optional custom text for Cebuano TTS" />
              </div>
              <div className="form-field form-field--full">
                <label className="form-label">Audio Text (English Override)</label>
                <input className="form-input" {...f('audio_text_english')} placeholder="Optional custom text for English TTS" />
              </div>
            </div>
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
          <button className="btn btn--ghost" onClick={onClose} disabled={submitting}>Cancel</button>
          <button className="btn btn--primary" onClick={handleSubmit} disabled={submitting}>
            {submitting ? <span className="spinner spinner--sm" /> : submitLabel}
          </button>
        </div>
      </div>
    </div>
  );
}

export function AddVocabularyModal(props) {
  return <VocabWordForm {...props} title="➕ Add Vocabulary Word" submitLabel="Add Word" />;
}

export function EditVocabularyModal(props) {
  return <VocabWordForm {...props} title="✏️ Edit Vocabulary Word" submitLabel="Save Changes" />;
}
