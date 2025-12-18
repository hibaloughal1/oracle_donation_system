CREATE OR REPLACE PACKAGE SECURITY_PKG AS

    -- =========================
    -- ROLE & SECURITY
    -- =========================
    FUNCTION has_role (
        p_user_id    IN Utilisateur.id_user%TYPE,
        p_code_role  IN Role.code_role%TYPE
    ) RETURN BOOLEAN;

    FUNCTION is_admin (
        p_user_id IN Utilisateur.id_user%TYPE
    ) RETURN BOOLEAN;

    FUNCTION get_main_role (
        p_user_id IN Utilisateur.id_user%TYPE
    ) RETURN Role.code_role%TYPE;

    -- =========================
    -- AUTHENTICATION
    -- =========================
    PROCEDURE SP_REGISTER_USER (
        p_nom        IN  VARCHAR2,
        p_email      IN  VARCHAR2,
        p_tel        IN  VARCHAR2,
        p_adresse    IN  VARCHAR2,
        p_password   IN  VARCHAR2,
        p_id_user    OUT Utilisateur.id_user%TYPE,
        p_status     OUT VARCHAR2,
        p_message    OUT VARCHAR2
    );

    PROCEDURE SP_LOGIN (
        p_email      IN  VARCHAR2,
        p_password   IN  VARCHAR2,
        p_id_user    OUT Utilisateur.id_user%TYPE,
        p_main_role  OUT Role.code_role%TYPE,
        p_status     OUT VARCHAR2,
        p_message    OUT VARCHAR2
    );

    -- =========================
    -- ORGANISATION & ACTIONS
    -- =========================
    PROCEDURE SP_CREATE_ORGANISATION (
        p_owner_id    IN  Utilisateur.id_user%TYPE,
        p_nom_org     IN  VARCHAR2,
        p_desc_org    IN  VARCHAR2,
        p_tel_org     IN  VARCHAR2,
        p_num_patente IN  VARCHAR2,
        p_lieu_org    IN  VARCHAR2,
        p_id_org      OUT Organisation.id_org%TYPE,
        p_status      OUT VARCHAR2,
        p_message     OUT VARCHAR2
    );

    PROCEDURE SP_CREATE_ACTION (
        p_user_id             IN  Utilisateur.id_user%TYPE,
        p_org_id              IN  Organisation.id_org%TYPE,
        p_titre_action        IN  VARCHAR2,
        p_desc_action         IN  VARCHAR2,
        p_affiche_action      IN  VARCHAR2,
        p_date_debut_action   IN  DATE,
        p_date_fin_action     IN  DATE,
        p_montant_objectif    IN  NUMBER,
        p_id_action           OUT Action_social.id_action%TYPE,
        p_status              OUT VARCHAR2,
        p_message             OUT VARCHAR2
    );

    PROCEDURE SP_UPDATE_ACTION_STATUS (
        p_user_id    IN  Utilisateur.id_user%TYPE,
        p_action_id  IN  Action_social.id_action%TYPE,
        p_new_status IN  VARCHAR2,
        p_status     OUT VARCHAR2,
        p_message    OUT VARCHAR2
    );

    -- =========================
    -- BESOINS & DONATIONS
    -- =========================
    PROCEDURE SP_ADD_NEED (
        p_user_id        IN  Utilisateur.id_user%TYPE,
        p_action_id      IN  Action_social.id_action%TYPE,
        p_nom_besoin     IN  VARCHAR2,
        p_description    IN  VARCHAR2,
        p_type_besoin    IN  VARCHAR2,
        p_unite_demande  IN  NUMBER,
        p_prix_unitaire  IN  NUMBER,
        p_id_besoin      OUT Besoin.id_besoin%TYPE,
        p_status         OUT VARCHAR2,
        p_message        OUT VARCHAR2
    );

    PROCEDURE SP_UPDATE_NEED_QTY (
        p_besoin_id  IN  Besoin.id_besoin%TYPE,
        p_delta      IN  NUMBER,
        p_status     OUT VARCHAR2,
        p_message    OUT VARCHAR2
    );

    PROCEDURE SP_MAKE_DONATION (
        p_donor_id    IN  Utilisateur.id_user%TYPE,
        p_besoin_id   IN  Besoin.id_besoin%TYPE,
        p_montant_don IN  NUMBER,
        p_preuve_don  IN  VARCHAR2,
        p_statut_don  IN  VARCHAR2 DEFAULT 'PENDING',
        p_id_don      OUT Don.id_don%TYPE,
        p_status      OUT VARCHAR2,
        p_message     OUT VARCHAR2
    );

END SECURITY_PKG;
/
SHOW ERRORS;
