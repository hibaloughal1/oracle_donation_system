import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'

function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const navigate = useNavigate()

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setError('')
  
    const formData = new FormData()
    formData.append('username', email)
    formData.append('password', password)
  
    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      })
  
      const data = await response.json()
  
      if (!response.ok) {
        throw new Error(data.detail || 'Identifiants incorrects')
      }
  
      localStorage.setItem('token', data.access_token)
      localStorage.setItem('role', data.role || 'USER')
      navigate('/dashboard')
    } catch (err: any) {
      setError(err.message || 'Erreur lors de la connexion')
    }
  }

  return (
    <div className="row justify-content-center mt-5 fade-in">
      <div className="col-md-6">
        <h2 className="text-center mb-4">Connexion</h2>
        {error && <div className="alert alert-danger">{error}</div>}
        <form onSubmit={handleSubmit}>
          <div className="mb-3">
            <label className="form-label">Email</label>
            <input
              type="email"
              className="form-control"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>
          <div className="mb-3">
            <label className="form-label">Mot de passe</label>
            <input
              type="password"
              className="form-control"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>
          <button type="submit" className="btn btn-primary w-100">
            Se connecter
          </button>
        </form>
        <p className="text-center mt-3">
          Pas de compte ? <Link to="/register">S'inscrire ici</Link>
        </p>
      </div>
    </div>
  )
}

export default Login