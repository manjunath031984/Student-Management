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
    <>
      <div className="hero-band">
        <div className="hero-copy">
          <p className="eyebrow">New enrollment</p>
          <h1>Add a student</h1>
          <p>Capture name, email, course, and age to create a complete student profile.</p>
        </div>
        <div className="hero-metrics">
          <div className="stat-chip">
            <strong>+</strong>
            <span>Create</span>
          </div>
          <div className="stat-chip accent">
            <strong>4</strong>
            <span>Fields</span>
          </div>
        </div>
      </div>

      <section className="page-section narrow">
        <div className="page-header">
          <div>
            <h2>Student details</h2>
            <p className="page-subtitle">All fields are required before saving.</p>
          </div>
        </div>

        {error && <p className="status-message error">{error}</p>}
        {success && <p className="status-message success">{success}</p>}

        <StudentForm onSubmit={handleSubmit} submitLabel="Create Student" busy={busy} />
      </section>
    </>
  );
}

export default AddStudent;
