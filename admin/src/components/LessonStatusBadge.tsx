interface Props {
  status: string;
}

const STATUS_CONFIG: Record<string, { label: string; cls: string }> = {
  DRAFT:     { label: 'Draft',     cls: 'badge--draft' },
  PUBLISHED: { label: 'Published', cls: 'badge--published' },
  ARCHIVED:  { label: 'Archived',  cls: 'badge--archived' },
};

export default function LessonStatusBadge({ status }: Props) {
  const cfg = STATUS_CONFIG[status] ?? { label: status, cls: '' };
  return <span className={`status-badge ${cfg.cls}`}>{cfg.label}</span>;
}
