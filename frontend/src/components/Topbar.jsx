function Topbar({ searchValue = '', onSearchChange, showSearch = true }) {
  return (
    <header className="topbar">
      {showSearch ? (
        <label className="topbar-search">
          <span className="topbar-search-icon" aria-hidden="true">
            <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="1.8">
              <circle cx="11" cy="11" r="7" />
              <path d="m20 20-3.5-3.5" />
            </svg>
          </span>
          <input
            type="search"
            placeholder="Search..."
            value={searchValue}
            onChange={(event) => onSearchChange?.(event.target.value)}
            aria-label="Search students"
          />
        </label>
      ) : (
        <div className="topbar-spacer" />
      )}

      <div className="topbar-right">
        <button type="button" className="topbar-icon-btn" aria-label="Messages" title="Messages">
          <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="1.8">
            <rect x="3" y="5" width="18" height="14" rx="2" />
            <path d="m4 7 8 6 8-6" />
          </svg>
        </button>
        <button type="button" className="topbar-icon-btn" aria-label="Notifications" title="Notifications">
          <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="1.8">
            <path d="M6 9a6 6 0 0 1 12 0c0 7 3 7 3 7H3s3 0 3-7" />
            <path d="M10 19a2 2 0 0 0 4 0" />
          </svg>
        </button>
        <div className="topbar-user">
          <span className="topbar-avatar" aria-hidden="true">
            A
          </span>
          <div className="topbar-user-meta">
            <strong>Admin</strong>
            <span>Local User</span>
          </div>
        </div>
      </div>
    </header>
  );
}

export default Topbar;
