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

function getFilenameFromResponse(res, defaultName) {
  const disposition = res.headers.get('Content-Disposition');
  if (disposition && disposition.includes('filename=')) {
    const match = disposition.match(/filename="?([^";]+)"?/);
    if (match && match[1]) {
      return match[1].trim();
    }
  }
  return defaultName;
}

async function handleResponseError(res, defaultMsg) {
  let serverMsg = '';
  try {
    const text = await res.text();
    if (text) {
      try {
        const json = JSON.parse(text);
        serverMsg = json.message || json.error || json.details || '';
      } catch {
        serverMsg = text.length < 200 ? text : '';
      }
    }
  } catch {
    // Ignore body reading error
  }

  if (res.status === 403) {
    throw new Error(serverMsg || 'Access denied: Teachers can only export their own classes, and Administrators can only export global school-wide reports.');
  }
  if (res.status === 400) {
    throw new Error(serverMsg || 'Invalid report request or student is not actively enrolled in the specified classroom.');
  }
  if (res.status === 404) {
    throw new Error(serverMsg || 'The requested class, student, or curriculum report resource was not found.');
  }
  throw new Error(serverMsg ? `${defaultMsg}: ${serverMsg}` : defaultMsg);
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

    if (!res.ok) await handleResponseError(res, 'Failed to download class report');

    const ext = format.toLowerCase() === 'pdf' ? 'pdf' : 'csv';
    const defaultName = `class_performance_report_${sectionId ? 'class' : 'all_classes'}.${ext}`;
    const filename = getFilenameFromResponse(res, defaultName);

    const blob = await res.blob();
    triggerBlobDownload(blob, filename);
  },

  /**
   * Download Individual Student Report Card
   */
  async downloadIndividualReport(learnerId, format = 'pdf', classId = null) {
    const token = AuthService.getToken();
    const query = new URLSearchParams({ format });
    if (classId) query.append('classId', classId);

    const res = await fetch(`${BASE_URL}/api/admin/reports/individual/${learnerId}?${query.toString()}`, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    });

    if (!res.ok) await handleResponseError(res, 'Failed to download student report card');

    const ext = format.toLowerCase() === 'pdf' ? 'pdf' : 'csv';
    const defaultName = `student_report_${learnerId}_${classId ? 'class' : 'all_classes'}.${ext}`;
    const filename = getFilenameFromResponse(res, defaultName);

    const blob = await res.blob();
    triggerBlobDownload(blob, filename);
  },

  /**
   * Download Word Performance & Curriculum Report
   */
  async downloadWordPerformanceReport(format = 'csv', sectionId = null, lessonId = null, categoryId = null) {
    const token = AuthService.getToken();
    const query = new URLSearchParams({ format });
    if (sectionId) query.append('sectionId', sectionId);
    if (lessonId) query.append('lessonId', lessonId);
    if (categoryId) query.append('categoryId', categoryId);

    const res = await fetch(`${BASE_URL}/api/admin/reports/word-performance?${query.toString()}`, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    });

    if (!res.ok) await handleResponseError(res, 'Failed to download word performance report');

    const ext = format.toLowerCase() === 'pdf' ? 'pdf' : 'csv';
    const defaultName = `word_performance_${sectionId ? 'class' : 'all_classes'}.${ext}`;
    const filename = getFilenameFromResponse(res, defaultName);

    const blob = await res.blob();
    triggerBlobDownload(blob, filename);
  },
};
