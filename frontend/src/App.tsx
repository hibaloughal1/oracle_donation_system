import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import Login from './pages/Login.tsx'
import Register from './pages/Register.tsx'
import Dashboard from './pages/Dashboard.tsx'
import Donations from './pages/Donations.tsx'
import Navbar from './components/Navbar.tsx'

function App() {
  const token = localStorage.getItem('token')

  return (
    <BrowserRouter>
      <Navbar />
      <div className="container mt-4">
        <Routes>
          <Route path="/" element={!token ? <Login /> : <Navigate to="/dashboard" />} />
          <Route path="/register" element={<Register />} />
          <Route path="/dashboard" element={token ? <Dashboard /> : <Navigate to="/" />} />
          <Route path="/donations" element={token ? <Donations /> : <Navigate to="/" />} />
        </Routes>
      </div>
    </BrowserRouter>
  )
}

export default App