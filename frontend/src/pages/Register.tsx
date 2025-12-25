import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'

const Register = () => {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [phone, setPhone] = useState('')
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const navigate = useNavigate()

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setError('')
    setSuccess('')

    try {
      const response = await fetch('/api/auth/register', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',  // <--- AJOUTE ÇA OBLIGATOIREMENT
        },
        body: JSON.stringify({ email, password, phone }),
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.detail || 'Erreur lors de l\'inscription')
      }

      setSuccess('Inscription réussie ! Redirection vers la connexion...')
      setTimeout(() => navigate('/'), 2000)
    } catch (err: any) {
      if (err.response?.data?.detail) {
        if (typeof err.response.data.detail === 'string') {
          setError(err.response.data.detail);
        } else if (Array.isArray(err.response.data.detail)) {
          // FastAPI renvoie parfois une liste d'erreurs
          setError(err.response.data.detail.map((e: any) => e.msg).join(', ') || 'Erreur de validation');
        } else {
          setError('Erreur lors de la connexion');
        }
      } else {
        setError(err.message || 'Erreur réseau ou serveur');
      }
    }
  }

  return (
    <div className="row justify-content-center mt-5">
      <div className="col-md-5 col-lg-4">
        <div className="card shadow">
          <div className="card-body p-4">
            <h3 className="card-title text-center mb-4">Inscription</h3>
            {error && <div className="alert alert-danger">{error}</div>}
            {success && <div className="alert alert-success">{success}</div>}
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
              <div className="mb-4">
                <label className="form-label">Téléphone</label>
                <input
                  type="tel"
                  className="form-control"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  required
                />
              </div>
              <button type="submit" className="btn btn-success w-100">
                S'inscrire
              </button>
            </form>
            <p className="text-center mt-3 mb-0">
              Déjà un compte ? <Link to="/">Se connecter</Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Register