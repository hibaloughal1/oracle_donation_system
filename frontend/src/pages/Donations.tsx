import { useState } from 'react'

const Donations = () => {
  const [besoinId, setBesoinId] = useState('')
  const [amount, setAmount] = useState('')
  const [message, setMessage] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setMessage('')
    setLoading(true)

    try {
      const response = await fetch('/api/donations', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${localStorage.getItem('token')}`,
        },
        body: JSON.stringify({
          besoin_id: parseInt(besoinId),
          amount: parseFloat(amount),
        }),
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.detail || 'Erreur lors du don')
      }

      setMessage('Don effectué avec succès ! Merci infiniment ❤️')
      setBesoinId('')
      setAmount('')
    } catch (err: any) {
      setMessage('Erreur : ' + (err.message || 'Vérifiez les données'))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="row justify-content-center mt-5">
      <div className="col-md-6 col-lg-5">
        <div className="card shadow">
          <div className="card-body p-4">
            <h3 className="card-title text-center mb-4">Faire un don</h3>
            {message && (
              <div className={`alert ${message.includes('succès') ? 'alert-success' : 'alert-danger'}`}>
                {message}
              </div>
            )}
            <form onSubmit={handleSubmit}>
              <div className="mb-3">
                <label className="form-label">ID du besoin (voir dans les campagnes ou SQL Developer)</label>
                <input
                  type="number"
                  className="form-control"
                  value={besoinId}
                  onChange={(e) => setBesoinId(e.target.value)}
                  required
                  min="1"
                />
              </div>
              <div className="mb-4">
                <label className="form-label">Montant (en DH)</label>
                <input
                  type="number"
                  step="0.01"
                  className="form-control"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  required
                  min="1"
                />
              </div>
              <button type="submit" className="btn btn-success w-100" disabled={loading}>
                {loading ? 'Traitement...' : 'Donner'}
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Donations