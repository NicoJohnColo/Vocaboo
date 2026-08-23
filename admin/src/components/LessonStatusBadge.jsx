const STATUS_CONFIG = {
  DRAFT:     { label: 'Draft',     cls: 'badge--draft' },
  PUBLISHED: { label: 'Published', cls: 'badge--published' },
  ARCHIVED:  { label: 'Archived',  cls: 'badge--archived' },
};

export default function LessonStatusBadge({ status }) {
  const cfg = STATUS_CONFIG[status] ?? { label: status, cls: '' };
  return <span className={`status-badge ${cfg.cls}`}>{cfg.label}</span>;
}
