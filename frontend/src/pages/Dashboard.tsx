import { useEffect, useState } from 'react'


interface Campaign {
  ID: number
  NAME: string
  DESCRIPTION?: string
  START_DATE: string
  END_DATE: string
}

const Dashboard = () => {
  const [campaigns, setCampaigns] = useState<Campaign[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    const fetchCampaigns = async () => {
      try {
        const response = await fetch('/api/actions', {
          headers: {
            Authorization: `Bearer ${localStorage.getItem('token')}`,
          },
        })

        if (!response.ok) throw new Error('Impossible de charger les campagnes')

        const data = await response.json()
        setCampaigns(data)
      } catch (err: any) {
        setError(err.message)
      } finally {
        setLoading(false)
      }
    }

    fetchCampaigns()
  }, [])

  if (loading) return <p className="text-center">Chargement des campagnes...</p>
  if (error) return <div className="alert alert-danger">{error}</div>

  return (
    <div>
      <h2 className="mb-4">Campagnes Actives</h2>
      {campaigns.length === 0 ? (
        <p>Aucune campagne active pour le moment.</p>
      ) : (
        <div className="row">
          {campaigns.map((camp) => (
            <div key={camp.ID} className="col-md-6 col-lg-4 mb-4">
              <div className="card h-100 shadow-sm card-fade">
                <div className="card-body">
                  <h5 className="card-title">{camp.NAME}</h5>
                  <p className="card-text">
                    {camp.DESCRIPTION || 'Pas de description disponible.'}
                  </p>
                  <p className="text-muted small">
                    <strong>Dates :</strong> {camp.START_DATE} → {camp.END_DATE}
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

export default Dashboard