import type { AdminVocabularyWord } from '../services/VocabularyService';

const POS_COLORS: Record<string, string> = {
  NOUN: 'pos--noun',
  VERB: 'pos--verb',
  ADJECTIVE: 'pos--adjective',
};

interface Props {
  words: AdminVocabularyWord[];
  lessonTitle: string;
  onAdd: () => void;
  onEdit: (word: AdminVocabularyWord) => void;
  onDelete: (word: AdminVocabularyWord) => void;
  onBulkImport: () => void;
  onConfusablePairs: () => void;
  loading?: boolean;
}

export default function VocabularyTable({
  words, lessonTitle, onAdd, onEdit, onDelete, onBulkImport, onConfusablePairs, loading
}: Props) {
  return (
    <div>
      <div className="table-toolbar">
        <span className="toolbar-label">📚 {lessonTitle}</span>
        <div style={{ display: 'flex', gap: 8, marginLeft: 'auto' }}>
          <button id="confusable-pairs-btn" className="btn btn--ghost btn--sm" onClick={onConfusablePairs}>
            🔗 Confusable Pairs
          </button>
          <button className="btn btn--ghost btn--sm" onClick={onBulkImport}>
            📥 Bulk Import CSV
          </button>
          <button id="add-word-btn" className="btn btn--primary btn--sm" onClick={onAdd}>
            + Add Word
          </button>
        </div>
      </div>

      {loading ? (
        <div className="auth-loading" style={{ minHeight: 200 }}><div className="spinner" /></div>
      ) : (
        <div className="accounts-table-wrap">
          <table className="accounts-table">
            <thead>
              <tr>
                <th>#</th>
                <th>English</th>
                <th>Cebuano</th>
                <th>POS</th>
                <th>Grade</th>
                <th>Example (EN)</th>
                <th>Example (CEB)</th>
                <th>Audio</th>
                <th>Image</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {words.length === 0 && (
                <tr>
                  <td colSpan={10} style={{ textAlign: 'center', color: 'var(--color-text-muted)', padding: '40px' }}>
                    No words yet. Click <strong>+ Add Word</strong> or <strong>Bulk Import CSV</strong>.
                  </td>
                </tr>
              )}
              {words.map(w => (
                <tr key={w.word_id}>
                  <td className="text-muted" style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: '0.8rem' }}>
                    {w.word_order}
                  </td>
                  <td style={{ fontWeight: 600 }}>{w.english_word}</td>
                  <td className="text-muted">{w.cebuano_meaning}</td>
                  <td>
                    {w.part_of_speech ? (
                      <span className={`pos-badge ${POS_COLORS[w.part_of_speech] ?? ''}`}>
                        {w.part_of_speech}
                      </span>
                    ) : (
                      <span className="text-muted" style={{ opacity: 0.4 }}>—</span>
                    )}
                  </td>
                  <td className="text-muted">{w.grade_level?.replace('_', ' ')}</td>
                  <td className="text-muted" style={{ fontSize: '0.8rem', maxWidth: 200 }}>
                    <span title={w.example_sentence_english} style={{ display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
                      {w.example_sentence_english}
                    </span>
                  </td>
                  <td className="text-muted" style={{ fontSize: '0.8rem', maxWidth: 200 }}>
                    {w.example_sentence_cebuano ? (
                      <span title={w.example_sentence_cebuano} style={{ display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
                        {w.example_sentence_cebuano}
                      </span>
                    ) : <span style={{ opacity: 0.4 }}>—</span>}
                  </td>
                  <td>
                    {w.audio_asset_path
                      ? <span title={w.audio_asset_path} className="asset-indicator asset-indicator--ok">🔊</span>
                      : <span className="asset-indicator asset-indicator--missing">—</span>}
                  </td>
                  <td>
                    {w.image_asset_path
                      ? <span title={w.image_asset_path} className="asset-indicator asset-indicator--ok">🖼️</span>
                      : <span className="asset-indicator asset-indicator--missing">—</span>}
                  </td>
                  <td className="actions-cell">
                    <button className="btn btn--sm btn--ghost" onClick={() => onEdit(w)}>✏️</button>
                    <button className="btn btn--sm btn--danger-ghost" onClick={() => onDelete(w)}>🗑️</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      {!loading && (
        <div className="table-meta">{words.length} word{words.length !== 1 ? 's' : ''} in this lesson</div>
      )}
    </div>
  );
}
