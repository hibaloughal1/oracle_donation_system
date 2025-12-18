CREATE OR REPLACE PACKAGE REPORTING_PKG
AS
    -- ==========================================================================
    -- Type global pour tous les curseurs de référence (SYS_REFCURSOR)
    -- ==========================================================================
    TYPE t_ref_cursor IS REF CURSOR;

    -- ==========================================================================
    -- 1. Fonctions KPI (Key Performance Indicators)
    --    Toutes les fonctions incluent p_user_id pour la sécurité basée sur les rôles.
    --    Elles retournent 0 si aucune donnée n'est trouvée (gestion de NO_DATA_FOUND).
    -- ==========================================================================

    -- Fonction pour obtenir le montant total des dons validés.
    FUNCTION rpt_get_total_donations_amount (
        p_user_id       IN NUMBER,
        p_start_date    IN DATE DEFAULT NULL,
        p_end_date      IN DATE DEFAULT NULL
    ) RETURN NUMBER;

    -- Fonction pour obtenir le nombre total de donateurs uniques.
    FUNCTION rpt_get_total_donors_count (
        p_user_id       IN NUMBER,
        p_start_date    IN DATE DEFAULT NULL,
        p_end_date      IN DATE DEFAULT NULL
    ) RETURN NUMBER;

    -- Fonction pour obtenir le nombre de campagnes actives (statut 'ACTIVE').
    FUNCTION rpt_get_active_campaigns_count (
        p_user_id       IN NUMBER
    ) RETURN NUMBER;

    -- Fonction pour obtenir le taux de complétion moyen des objectifs de campagne (en pourcentage).
    FUNCTION rpt_get_avg_campaign_completion_rate (
        p_user_id       IN NUMBER
    ) RETURN NUMBER;

    -- ==========================================================================
    -- 2. Procédures de Reporting (Retournent un SYS_REFCURSOR)
    --    Utilisées pour les tableaux de bord et les graphiques.
    -- ==========================================================================

    -- Procédure pour obtenir l'historique des dons avec filtres.
    PROCEDURE rpt_get_donation_history (
        p_user_id       IN NUMBER,
        p_start_date    IN DATE DEFAULT NULL,
        p_end_date      IN DATE DEFAULT NULL,
        p_statut_don    IN VARCHAR2 DEFAULT NULL,
        p_organisation_id IN NUMBER DEFAULT NULL,
        p_action_id     IN NUMBER DEFAULT NULL,
        p_result_cursor OUT t_ref_cursor
    );

    -- Procédure pour obtenir le résumé mensuel des dons (montant et nombre).
    PROCEDURE rpt_get_monthly_donations_summary (
        p_user_id       IN NUMBER,
        p_year          IN NUMBER DEFAULT NULL, -- Année spécifique, par défaut l'année en cours
        p_result_cursor OUT t_ref_cursor
    );

    -- Procédure pour obtenir le classement des organisations par montant de dons reçus.
    PROCEDURE rpt_get_org_ranking_by_donations (
        p_user_id       IN NUMBER,
        p_start_date    IN DATE DEFAULT NULL,
        p_end_date      IN DATE DEFAULT NULL,
        p_result_cursor OUT t_ref_cursor
    );

    -- Procédure pour obtenir les détails de l'activité d'une campagne spécifique.
    PROCEDURE rpt_get_campaign_activity (
        p_user_id       IN NUMBER,
        p_action_id     IN NUMBER,
        p_result_cursor OUT t_ref_cursor
    );

    -- Procédure pour obtenir l'historique des dons d'un donateur spécifique (pour l'interface DONOR).
    PROCEDURE rpt_get_donor_personal_history (
        p_user_id       IN NUMBER, -- Doit être l'ID du donateur
        p_start_date    IN DATE DEFAULT NULL,
        p_end_date      IN DATE DEFAULT NULL,
        p_result_cursor OUT t_ref_cursor
    );

END REPORTING_PKG;
/
