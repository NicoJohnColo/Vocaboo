import { AuthService } from './AuthService';

const BASE_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:8081';

function triggerBlobDownload(blob, filename) {
  const url = window.URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  window.URL.revokeObjectURL(url);
}

export const ReportService = {
  /**
   * Download Class Performance Report
   */
  async downloadClassReport(format = 'csv', sectionId = null, gradeLevel = null) {
    const token = AuthService.getToken();
    const query = new URLSearchParams({ format });
    if (sectionId) query.append('sectionId', sectionId);
    if (gradeLevel) query.append('gradeLevel', gradeLevel);

    const res = await fetch(`${BASE_URL}/api/admin/reports/class?${query.toString()}`, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    });

    if (!res.ok) throw new Error('Failed to download class report');

    const blob = await res.blob();
    const ext = format.toLowerCase() === 'pdf' ? 'pdf' : 'csv';
    triggerBlobDownload(blob, `class_performance_report.${ext}`);
  },

  /**
   * Download Individual Student Report Card
   */
  async downloadIndividualReport(learnerId, format = 'pdf') {
    const token = AuthService.getToken();
    const query = new URLSearchParams({ format });

    const res = await fetch(`${BASE_URL}/api/admin/reports/individual/${learnerId}?${query.toString()}`, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    });

    if (!res.ok) throw new Error('Failed to download student report card');

    const blob = await res.blob();
    const ext = format.toLowerCase() === 'pdf' ? 'pdf' : 'csv';
    triggerBlobDownload(blob, `student_report_${learnerId}.${ext}`);
  },

  /**
   * Download Word Performance & Curriculum Report
   */
  async downloadWordPerformanceReport(format = 'csv', sectionId = null, lessonId = null) {
    const token = AuthService.getToken();
    const query = new URLSearchParams({ format });
    if (sectionId) query.append('sectionId', sectionId);
    if (lessonId) query.append('lessonId', lessonId);

    const res = await fetch(`${BASE_URL}/api/admin/reports/word-performance?${query.toString()}`, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    });

    if (!res.ok) throw new Error('Failed to download word performance report');

    const blob = await res.blob();
    const ext = format.toLowerCase() === 'pdf' ? 'pdf' : 'csv';
    triggerBlobDownload(blob, `word_performance_report.${ext}`);
  },
};
