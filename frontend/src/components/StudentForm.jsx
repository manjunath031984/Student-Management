import { useState } from 'react';
import { Link } from 'react-router-dom';

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const emptyForm = {
  name: '',
  email: '',
  course: '',
  age: '',
};

function StudentForm({ initialValues, onSubmit, submitLabel, busy, cancelTo = '/' }) {
  const [form, setForm] = useState({
    ...emptyForm,
    ...initialValues,
    age: initialValues?.age !== undefined && initialValues?.age !== null
      ? String(initialValues.age)
      : '',
  });
  const [errors, setErrors] = useState({});

  const handleChange = (event) => {
    const { name, value } = event.target;
    setForm((prev) => ({ ...prev, [name]: value }));
    setErrors((prev) => ({ ...prev, [name]: undefined }));
  };

  const validate = () => {
    const nextErrors = {};

    const name = form.name.trim();
    const email = form.email.trim();
    const course = form.course.trim();
    const ageValue = form.age === '' ? NaN : Number(form.age);

    if (!name) {
      nextErrors.name = 'Name is required';
    } else if (name.length > 100) {
      nextErrors.name = 'Name must not exceed 100 characters';
    }

    if (!email) {
      nextErrors.email = 'Email is required';
    } else if (!EMAIL_PATTERN.test(email)) {
      nextErrors.email = 'Email must be a valid email address';
    } else if (email.length > 150) {
      nextErrors.email = 'Email must not exceed 150 characters';
    }

    if (!course) {
      nextErrors.course = 'Course is required';
    } else if (course.length > 100) {
      nextErrors.course = 'Course must not exceed 100 characters';
    }

    if (form.age === '') {
      nextErrors.age = 'Age is required';
    } else if (!Number.isInteger(ageValue) || ageValue < 1 || ageValue > 100) {
      nextErrors.age = 'Age must be between 1 and 100';
    }

    setErrors(nextErrors);
    return Object.keys(nextErrors).length === 0;
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    if (!validate()) {
      return;
    }

    await onSubmit({
      name: form.name.trim(),
      email: form.email.trim(),
      course: form.course.trim(),
      age: Number(form.age),
    });
  };

  return (
    <form className="student-form" onSubmit={handleSubmit} noValidate>
      <div className="form-grid">
        <div className={`form-field full ${errors.name ? 'has-error' : ''}`}>
          <label htmlFor="name">Full name</label>
          <input
            id="name"
            name="name"
            type="text"
            placeholder="e.g. Rahul Sharma"
            value={form.name}
            onChange={handleChange}
            maxLength={100}
            disabled={busy}
          />
          {errors.name ? <p className="field-error">{errors.name}</p> : <p className="hint">Maximum 100 characters</p>}
        </div>

        <div className={`form-field full ${errors.email ? 'has-error' : ''}`}>
          <label htmlFor="email">Email address</label>
          <input
            id="email"
            name="email"
            type="email"
            placeholder="e.g. rahul.sharma@example.com"
            value={form.email}
            onChange={handleChange}
            maxLength={150}
            disabled={busy}
          />
          {errors.email ? <p className="field-error">{errors.email}</p> : <p className="hint">We use this for student contact</p>}
        </div>

        <div className={`form-field ${errors.course ? 'has-error' : ''}`}>
          <label htmlFor="course">Course</label>
          <input
            id="course"
            name="course"
            type="text"
            placeholder="e.g. Computer Science"
            value={form.course}
            onChange={handleChange}
            maxLength={100}
            disabled={busy}
          />
          {errors.course && <p className="field-error">{errors.course}</p>}
        </div>

        <div className={`form-field ${errors.age ? 'has-error' : ''}`}>
          <label htmlFor="age">Age</label>
          <input
            id="age"
            name="age"
            type="number"
            min="1"
            max="100"
            placeholder="18"
            value={form.age}
            onChange={handleChange}
            disabled={busy}
          />
          {errors.age ? <p className="field-error">{errors.age}</p> : <p className="hint">Between 1 and 100</p>}
        </div>
      </div>

      <div className="form-actions">
        <button type="submit" className="btn btn-primary" disabled={busy}>
          {busy ? 'Saving...' : submitLabel}
        </button>
        <Link to={cancelTo} className="btn btn-secondary">
          Cancel
        </Link>
      </div>
    </form>
  );
}

export default StudentForm;
