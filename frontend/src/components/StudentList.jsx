import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { deleteStudent, getAllStudents } from '../services/studentService';
import StudentTable from './StudentTable';

function StudentList() {
  const [students, setStudents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [deletingId, setDeletingId] = useState(null);

  const loadStudents = async () => {
    setLoading(true);
    setError('');
    try {
      const data = await getAllStudents();
      setStudents(data);
    } catch (err) {
      const message = err.response?.data?.message || err.message || 'Failed to load students';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadStudents();
  }, []);

  const handleDelete = async (id) => {
    const confirmed = window.confirm(`Delete student with ID ${id}?`);
    if (!confirmed) {
      return;
    }

    setDeletingId(id);
    setError('');
    setSuccess('');
    try {
      await deleteStudent(id);
      setSuccess(`Student ${id} deleted successfully.`);
      await loadStudents();
    } catch (err) {
      const message = err.response?.data?.message || err.message || 'Failed to delete student';
      setError(message);
    } finally {
      setDeletingId(null);
    }
  };

  const uniqueCourses = new Set(students.map((student) => student.course)).size;

  return (
    <>
      <div className="hero-band">
        <div className="hero-copy">
          <p className="eyebrow">Academic operations</p>
          <h1>Student roster</h1>
          <p>
            A clear workspace to enroll students, update records, and keep your course list accurate.
          </p>
        </div>
        <div className="hero-metrics">
          <div className="stat-chip">
            <strong>{loading ? '—' : students.length}</strong>
            <span>Students</span>
          </div>
          <div className="stat-chip accent">
            <strong>{loading ? '—' : uniqueCourses}</strong>
            <span>Courses</span>
          </div>
        </div>
      </div>

      <section className="page-section">
        <div className="page-header">
          <div>
            <h2>All student records</h2>
            <p className="page-subtitle">Search-ready list with edit and delete actions.</p>
          </div>
          <Link to="/add" className="btn btn-primary">
            Add Student
          </Link>
        </div>

        {loading && (
          <div className="loading-block" aria-live="polite" aria-label="Loading students">
            <div className="skeleton-row" />
            <div className="skeleton-row" />
            <div className="skeleton-row" />
          </div>
        )}

        {error && (
          <div className="status-message error status-row">
            <span>{error}. Ensure the backend is running at http://localhost:8080</span>
            <button type="button" className="btn btn-secondary btn-small" onClick={loadStudents}>
              Retry
            </button>
          </div>
        )}

        {success && <p className="status-message success">{success}</p>}

        {!loading && !error && (
          <StudentTable students={students} onDelete={handleDelete} deletingId={deletingId} />
        )}
      </section>
    </>
  );
}

export default StudentList;
