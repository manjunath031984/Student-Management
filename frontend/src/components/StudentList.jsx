import { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { deleteStudent, getAllStudents } from '../services/studentService';
import StudentTable from './StudentTable';

function StudentList({ searchValue = '' }) {
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

  const filteredStudents = useMemo(() => {
    const query = searchValue.trim().toLowerCase();
    if (!query) {
      return students;
    }
    return students.filter((student) =>
      [student.name, student.email, student.course, String(student.id)]
        .join(' ')
        .toLowerCase()
        .includes(query)
    );
  }, [students, searchValue]);

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

  return (
    <section className="panel">
      <div className="panel-header">
        <div>
          <h1>All Students</h1>
          <p className="panel-subtitle">View, edit, or remove student records.</p>
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
        <StudentTable students={filteredStudents} onDelete={handleDelete} deletingId={deletingId} />
      )}
    </section>
  );
}

export default StudentList;
