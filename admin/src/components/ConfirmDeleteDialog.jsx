export default function ConfirmDeleteDialog({
  title,
  message,
  confirmLabel = 'Delete',
  onConfirm,
  onCancel,
  danger = true,
  loading = false,
}) {
  return (
    <div className="modal-overlay" onClick={onCancel}>
      <div className="modal modal--sm" onClick={e => e.stopPropagation()}>
        <div className="modal__icon">{danger ? '🗑️' : '⚠️'}</div>
        <h2 className="modal__title">{title}</h2>
        <p className="modal__note">{message}</p>
        <div className="modal__actions">
          <button className="btn btn--ghost" onClick={onCancel} disabled={loading}>
            Cancel
          </button>
          <button
            className={`btn ${danger ? 'btn--danger' : 'btn--primary'}`}
            onClick={onConfirm}
            disabled={loading}
          >
            {loading ? <span className="spinner spinner--sm" /> : confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}
