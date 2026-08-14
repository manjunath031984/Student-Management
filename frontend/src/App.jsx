import { BrowserRouter, Navigate, Route, Routes, useLocation } from 'react-router-dom';
import { useState } from 'react';
import Sidebar from './components/Sidebar';
import Topbar from './components/Topbar';
import Home from './pages/Home';
import AddStudent from './pages/AddStudent';
import EditStudent from './pages/EditStudent';

function AppLayout() {
  const location = useLocation();
  const [searchValue, setSearchValue] = useState('');
  const showSearch = location.pathname === '/';

  return (
    <div className="app-shell">
      <Sidebar />
      <div className="app-content">
        <Topbar
          showSearch={showSearch}
          searchValue={searchValue}
          onSearchChange={setSearchValue}
        />
        <main className="app-main">
          <Routes>
            <Route path="/" element={<Home searchValue={searchValue} />} />
            <Route path="/add" element={<AddStudent />} />
            <Route path="/edit/:id" element={<EditStudent />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </main>
      </div>
    </div>
  );
}

function App() {
  return (
    <BrowserRouter>
      <AppLayout />
    </BrowserRouter>
  );
}

export default App;
