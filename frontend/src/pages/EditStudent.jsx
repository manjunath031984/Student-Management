import { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import StudentForm from '../components/StudentForm';
import { getStudentById, updateStudent } from '../services/studentService';

function EditStudent() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [student, setStudent] = useState(null);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    const loadStudent = async () => {
      setLoading(true);
      setError('');
      try {
        const data = await getStudentById(id);
        setStudent(data);
      } catch (err) {
        setError(err.response?.data?.message || err.message || 'Failed to load student');
      } finally {
        setLoading(false);
      }
    };

    loadStudent();
  }, [id]);

  const handleSubmit = async (values) => {
    setBusy(true);
    setError('');
    setSuccess('');
    try {
      const updated = await updateStudent(id, values);
      setSuccess(`Student "${updated.name}" updated successfully.`);
      setTimeout(() => navigate('/'), 800);
    } catch (err) {
      const apiErrors = err.response?.data?.errors;
      if (Array.isArray(apiErrors) && apiErrors.length > 0) {
        setError(apiErrors.join(' | '));
      } else {
        setError(err.response?.data?.message || err.message || 'Failed to update student');
      }
    } finally {
      setBusy(false);
    }
  };

  return (
    <section className="panel">
      <div className="panel-header">
        <h1>Edit Student</h1>
      </div>

      {loading && (
        <div className="loading-block" aria-live="polite">
          <div className="skeleton-row" />
          <div className="skeleton-row" />
          <div className="skeleton-row" />
        </div>
      )}

      {error && <p className="status-message error">{error}</p>}
      {success && <p className="status-message success">{success}</p>}

      {!loading && student && (
        <StudentForm
          initialValues={student}
          onSubmit={handleSubmit}
          submitLabel="Save"
          busy={busy}
        />
      )}
    </section>
  );
}

export default EditStudent;
