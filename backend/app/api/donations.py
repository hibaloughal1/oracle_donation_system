@router.post("/")
def donate(data: DonationCreate, user=Depends(get_current_user)):
    cur.callproc("SECURITY_PKG.SP_MAKE_DONATION", [
        user["user_id"],
        data.besoin_id,
        data.montant,
        data.preuve,
        "PENDING",
        p_id_don,
        p_status,
        p_message
    ])


