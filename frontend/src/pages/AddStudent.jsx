import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import StudentForm from '../components/StudentForm';
import { createStudent } from '../services/studentService';

function AddStudent() {
  const navigate = useNavigate();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const handleSubmit = async (student) => {
    setBusy(true);
    setError('');
    setSuccess('');
    try {
      const created = await createStudent(student);
      setSuccess(`Student "${created.name}" created successfully.`);
      setTimeout(() => navigate('/'), 800);
    } catch (err) {
      const apiErrors = err.response?.data?.errors;
      if (Array.isArray(apiErrors) && apiErrors.length > 0) {
        setError(apiErrors.join(' | '));
      } else {
        setError(err.response?.data?.message || err.message || 'Failed to create student');
      }
    } finally {
      setBusy(false);
    }
  };

  return (
    <section className="panel">
      <div className="panel-header">
        <h1>Add New Students</h1>
      </div>

      {error && <p className="status-message error">{error}</p>}
      {success && <p className="status-message success">{success}</p>}

      <StudentForm onSubmit={handleSubmit} submitLabel="Save" busy={busy} />
    </section>
  );
}

export default AddStudent;
