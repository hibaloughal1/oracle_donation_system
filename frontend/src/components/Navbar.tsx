import { Link, useNavigate } from 'react-router-dom'

const Navbar = () => {
  const navigate = useNavigate()
  const token = localStorage.getItem('token')

  const handleLogout = () => {
    localStorage.removeItem('token')
    localStorage.removeItem('role')
    navigate('/')
  }

  return (
    <nav className="navbar navbar-expand-lg navbar-dark bg-primary mb-4">
      <div className="container-fluid">
        <Link className="navbar-brand" to="/">Système de Dons</Link>
        {token && (
          <div className="d-flex align-items-center ms-auto">
            <Link className="nav-link text-white me-4" to="/dashboard">Campagnes</Link>
            <Link className="nav-link text-white me-4" to="/donations">Faire un don</Link>
            <button className="btn btn-outline-light" onClick={handleLogout}>
              Déconnexion
            </button>
          </div>
        )}
      </div>
    </nav>
  )
}

export default Navbar