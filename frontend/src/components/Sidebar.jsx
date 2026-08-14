import { NavLink } from 'react-router-dom';

function Sidebar() {
  return (
    <aside className="sidebar">
      <div className="sidebar-brand">
        <span className="sidebar-logo" aria-hidden="true">
          <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" strokeWidth="1.8">
            <path d="M2 8.5 12 4l10 4.5-10 4.5L2 8.5Z" />
            <path d="M6 10.8v4.2c0 1.4 2.7 3 6 3s6-1.6 6-3v-4.2" />
            <path d="M22 8.5v6" />
          </svg>
        </span>
        <span className="sidebar-brand-text">EDUCATION</span>
      </div>

      <nav className="sidebar-nav" aria-label="Main">
        <NavLink to="/" end className={({ isActive }) => (isActive ? 'sidebar-link active' : 'sidebar-link')}>
          <span className="sidebar-icon" aria-hidden="true">
            <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="1.8">
              <path d="M4 11.5 12 5l8 6.5V20a1 1 0 0 1-1 1h-5v-6H10v6H5a1 1 0 0 1-1-1v-8.5Z" />
            </svg>
          </span>
          Students
        </NavLink>

        <NavLink to="/add" className={({ isActive }) => (isActive ? 'sidebar-link active' : 'sidebar-link')}>
          <span className="sidebar-icon" aria-hidden="true">
            <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="1.8">
              <path d="M12 5v14M5 12h14" />
            </svg>
          </span>
          Add Student
        </NavLink>
      </nav>

      <div className="sidebar-footer">
        <p>Student Management</p>
        <span>Localhost learning app</span>
      </div>
    </aside>
  );
}

export default Sidebar;
