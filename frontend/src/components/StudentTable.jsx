import { Link } from 'react-router-dom';

function StudentTable({ students, onDelete, deletingId }) {
  if (!students.length) {
    return (
      <div className="empty-state">
        <div className="empty-illustration" aria-hidden="true" />
        <h2>Build your student roster</h2>
        <p>No students yet. Add the first record to begin managing enrollments.</p>
        <Link to="/add" className="btn btn-primary">
          Add your first student
        </Link>
      </div>
    );
  }

  return (
    <>
      <div className="table-toolbar">
        <p>
          Showing <strong>{students.length}</strong> student{students.length === 1 ? '' : 's'}
        </p>
      </div>
      <div className="table-wrap">
        <table className="student-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>Email</th>
              <th>Course</th>
              <th>Age</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {students.map((student) => (
              <tr key={student.id}>
                <td className="id-cell">#{student.id}</td>
                <td className="student-name">{student.name}</td>
                <td className="student-email">{student.email}</td>
                <td>
                  <span className="course-pill">{student.course}</span>
                </td>
                <td className="age-cell">{student.age}</td>
                <td className="actions">
                  <Link to={`/edit/${student.id}`} className="btn btn-ghost btn-small">
                    Edit
                  </Link>
                  <button
                    type="button"
                    className="btn btn-danger btn-small"
                    onClick={() => onDelete(student.id)}
                    disabled={deletingId === student.id}
                  >
                    {deletingId === student.id ? 'Deleting...' : 'Delete'}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}

export default StudentTable;
