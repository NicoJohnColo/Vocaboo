const STATUS_CONFIG = {
  DRAFT:     { label: 'Draft',     cls: 'status-pill--warning',  icon: '✏️' },
  PUBLISHED: { label: 'Published', cls: 'status-pill--success',  icon: '✅' },
  ARCHIVED:  { label: 'Archived',  cls: 'status-pill--neutral',  icon: '📦' },
};

export default function LessonStatusBadge({ status }) {
  const cfg = STATUS_CONFIG[status] ?? { label: status, cls: 'status-pill--neutral', icon: '•' };
  return (
    <span className={`status-pill ${cfg.cls}`}>
      {cfg.label}
    </span>
  );
}
