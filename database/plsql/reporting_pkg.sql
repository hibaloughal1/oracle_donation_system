CREATE OR REPLACE PACKAGE BODY REPORTING_PKG
AS
    -- ==========================================================================
    -- Fonctions privées pour la gestion des rôles et de la sécurité
    -- ==========================================================================

    -- Fonction pour déterminer le rôle principal de l'utilisateur (ADMIN, ORGANISATION, DONOR)
    FUNCTION get_user_role (p_user_id IN NUMBER)
        RETURN VARCHAR2
    IS
        v_role_code Role.code_role%TYPE;
    BEGIN
        -- Priorité: ADMIN > ORGANISATION > DONOR
        BEGIN
            SELECT r.code_role
            INTO v_role_code
            FROM User_Role ur
            JOIN Role r ON ur.id_role = r.id_role
            WHERE ur.id_user = p_user_id
            AND r.code_role IN ('ADMIN', 'ORGANISATION', 'DONOR')
            ORDER BY CASE r.code_role
                         WHEN 'ADMIN' THEN 1
                         WHEN 'ORGANISATION' THEN 2
                         WHEN 'DONOR' THEN 3
                         ELSE 4
                     END
            FETCH FIRST 1 ROWS ONLY;

            RETURN v_role_code;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- Si l'utilisateur n'a pas de rôle explicite, on peut le considérer comme un simple utilisateur (DONOR par défaut)
                RETURN 'DONOR';
        END;
    END get_user_role;

    -- Fonction pour obtenir l'ID de l'organisation si l'utilisateur est un propriétaire d'organisation
    FUNCTION get_org_id_for_user (p_user_id IN NUMBER)
        RETURN NUMBER
    IS
        v_org_id Organisation.id_org%TYPE;
    BEGIN
        BEGIN
            SELECT id_org
            INTO v_org_id
            FROM Organisation
            WHERE id_user_owner = p_user_id
            FETCH FIRST 1 ROWS ONLY;

            RETURN v_org_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN NULL;
        END;
    END get_org_id_for_user;

    -- ==========================================================================
    -- 1. Implémentation des Fonctions KPI
    -- ==========================================================================

    -- Fonction pour obtenir le montant total des dons validés.
    FUNCTION rpt_get_total_donations_amount (
        p_user_id       IN NUMBER,
        p_start_date    IN DATE DEFAULT NULL,
        p_end_date      IN DATE DEFAULT NULL
    ) RETURN NUMBER
    IS
        v_total_amount NUMBER := 0;
        v_role         VARCHAR2(30) := get_user_role(p_user_id);
        v_org_id       NUMBER := get_org_id_for_user(p_user_id);
    BEGIN
        SELECT NVL(SUM(d.montant_don), 0)
        INTO v_total_amount
        FROM Don d
        JOIN Besoin b ON d.id_besoin = b.id_besoin
        JOIN Action_social a ON b.id_action = a.id_action
        WHERE d.statut_don = 'VALIDÉ'
          AND d.date_don BETWEEN NVL(p_start_date, d.date_don) AND NVL(p_end_date, d.date_don)
          AND (
                v_role = 'ADMIN'
             OR (v_role = 'ORGANISATION' AND a.id_org = v_org_id)
             OR (v_role = 'DONOR' AND d.id_donateur = p_user_id)
              );

        RETURN v_total_amount;
    EXCEPTION
        WHEN OTHERS THEN
            -- En cas d'erreur, retourne 0 au lieu de lever une exception
            RETURN 0;
    END rpt_get_total_donations_amount;

    -- Fonction pour obtenir le nombre total de donateurs uniques.
    FUNCTION rpt_get_total_donors_count (
        p_user_id       IN NUMBER,
        p_start_date    IN DATE DEFAULT NULL,
        p_end_date      IN DATE DEFAULT NULL
    ) RETURN NUMBER
    IS
        v_total_count NUMBER := 0;
        v_role        VARCHAR2(30) := get_user_role(p_user_id);
        v_org_id      NUMBER := get_org_id_for_user(p_user_id);
    BEGIN
        SELECT COUNT(DISTINCT d.id_donateur)
        INTO v_total_count
        FROM Don d
        JOIN Besoin b ON d.id_besoin = b.id_besoin
        JOIN Action_social a ON b.id_action = a.id_action
        WHERE d.statut_don = 'VALIDÉ'
          AND d.date_don BETWEEN NVL(p_start_date, d.date_don) AND NVL(p_end_date, d.date_don)
          AND (
                v_role = 'ADMIN'
             OR (v_role = 'ORGANISATION' AND a.id_org = v_org_id)
             OR (v_role = 'DONOR' AND d.id_donateur = p_user_id) -- Un donateur voit son propre compte
              );

        RETURN v_total_count;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END rpt_get_total_donors_count;

    -- Fonction pour obtenir le nombre de campagnes actives (statut 'ACTIVE').
    FUNCTION rpt_get_active_campaigns_count (
        p_user_id       IN NUMBER
    ) RETURN NUMBER
    IS
        v_total_count NUMBER := 0;
        v_role        VARCHAR2(30) := get_user_role(p_user_id);
        v_org_id      NUMBER := get_org_id_for_user(p_user_id);
    BEGIN
        SELECT COUNT(id_action)
        INTO v_total_count
        FROM Action_social a
        WHERE a.statut_action = 'ACTIVE'
          AND (
                v_role = 'ADMIN'
             OR (v_role = 'ORGANISATION' AND a.id_org = v_org_id)
             OR (v_role = 'DONOR' AND 1=1) -- Les donateurs peuvent voir toutes les campagnes actives
              );

        RETURN v_total_count;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END rpt_get_active_campaigns_count;

    -- Fonction pour obtenir le taux de complétion moyen des objectifs de campagne (en pourcentage).
    FUNCTION rpt_get_avg_campaign_completion_rate (
        p_user_id       IN NUMBER
    ) RETURN NUMBER
    IS
        v_avg_rate NUMBER := 0;
        v_role     VARCHAR2(30) := get_user_role(p_user_id);
        v_org_id   NUMBER := get_org_id_for_user(p_user_id);
    BEGIN
        SELECT NVL(AVG(
            CASE
                WHEN montant_objectif_action > 0 THEN (montant_recu_action / montant_objectif_action) * 100
                ELSE 0
            END
        ), 0)
        INTO v_avg_rate
        FROM Action_social a
        WHERE a.statut_action IN ('ACTIVE', 'CLOSED', 'COMPLETED')
          AND (
                v_role = 'ADMIN'
             OR (v_role = 'ORGANISATION' AND a.id_org = v_org_id)
             OR (v_role = 'DONOR' AND 1=1) -- Taux moyen global ou visible par tous
              );

        RETURN ROUND(v_avg_rate, 2);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END rpt_get_avg_campaign_completion_rate;

    -- ==========================================================================
    -- 2. Implémentation des Procédures de Reporting (SYS_REFCURSOR)
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
    )
    IS
        v_role        VARCHAR2(30) := get_user_role(p_user_id);
        v_org_id      NUMBER := get_org_id_for_user(p_user_id);
    BEGIN
        OPEN p_result_cursor FOR
            SELECT
                d.id_don,
                d.montant_don,
                d.date_don,
                d.statut_don,
                u.nom_user AS nom_donateur,
                o.nom_org AS nom_organisation,
                a.titre_action AS nom_campagne,
                b.nom_besoin
            FROM Don d
            JOIN Utilisateur u ON d.id_donateur = u.id_user
            JOIN Besoin b ON d.id_besoin = b.id_besoin
            JOIN Action_social a ON b.id_action = a.id_action
            JOIN Organisation o ON a.id_org = o.id_org
            WHERE d.date_don BETWEEN NVL(p_start_date, d.date_don) AND NVL(p_end_date, d.date_don)
              AND (p_statut_don IS NULL OR d.statut_don = p_statut_don)
              AND (p_action_id IS NULL OR a.id_action = p_action_id)
              AND (p_organisation_id IS NULL OR o.id_org = p_organisation_id)
              AND (
                    v_role = 'ADMIN'
                 OR (v_role = 'ORGANISATION' AND o.id_org = v_org_id)
                 OR (v_role = 'DONOR' AND d.id_donateur = p_user_id)
                  )
            ORDER BY d.date_don DESC;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Retourne un curseur vide au lieu de lever une erreur
            OPEN p_result_cursor FOR
                SELECT
                    CAST(NULL AS NUMBER) AS id_don,
                    CAST(NULL AS NUMBER) AS montant_don,
                    CAST(NULL AS DATE) AS date_don,
                    CAST(NULL AS VARCHAR2(20)) AS statut_don,
                    CAST(NULL AS VARCHAR2(100)) AS nom_donateur,
                    CAST(NULL AS VARCHAR2(100)) AS nom_organisation,
                    CAST(NULL AS VARCHAR2(100)) AS nom_campagne,
                    CAST(NULL AS VARCHAR2(100)) AS nom_besoin
                FROM DUAL WHERE 1=0; -- Retourne une structure vide
        WHEN OTHERS THEN
            -- Gérer les autres erreurs et retourner un curseur vide
            OPEN p_result_cursor FOR
                SELECT
                    CAST(NULL AS NUMBER) AS id_don,
                    CAST(NULL AS NUMBER) AS montant_don,
                    CAST(NULL AS DATE) AS date_don,
                    CAST(NULL AS VARCHAR2(20)) AS statut_don,
                    CAST(NULL AS VARCHAR2(100)) AS nom_donateur,
                    CAST(NULL AS VARCHAR2(100)) AS nom_organisation,
                    CAST(NULL AS VARCHAR2(100)) AS nom_campagne,
                    CAST(NULL AS VARCHAR2(100)) AS nom_besoin
                FROM DUAL WHERE 1=0;
    END rpt_get_donation_history;

    -- Procédure pour obtenir le résumé mensuel des dons (montant et nombre).
    PROCEDURE rpt_get_monthly_donations_summary (
        p_user_id       IN NUMBER,
        p_year          IN NUMBER DEFAULT NULL,
        p_result_cursor OUT t_ref_cursor
    )
    IS
        v_role        VARCHAR2(30) := get_user_role(p_user_id);
        v_org_id      NUMBER := get_org_id_for_user(p_user_id);
        v_year        NUMBER := NVL(p_year, TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY')));
    BEGIN
        OPEN p_result_cursor FOR
            SELECT
                TO_CHAR(d.date_don, 'YYYY-MM') AS annee_mois,
                TO_CHAR(d.date_don, 'Month', 'NLS_DATE_LANGUAGE=FRENCH') AS mois_libelle,
                COUNT(d.id_don) AS nombre_dons,
                SUM(d.montant_don) AS montant_total
            FROM Don d
            JOIN Besoin b ON d.id_besoin = b.id_besoin
            JOIN Action_social a ON b.id_action = a.id_action
            WHERE d.statut_don = 'VALIDÉ'
              AND TO_NUMBER(TO_CHAR(d.date_don, 'YYYY')) = v_year
              AND (
                    v_role = 'ADMIN'
                 OR (v_role = 'ORGANISATION' AND a.id_org = v_org_id)
                 OR (v_role = 'DONOR' AND d.id_donateur = p_user_id)
                  )
            GROUP BY TO_CHAR(d.date_don, 'YYYY-MM'), TO_CHAR(d.date_don, 'Month', 'NLS_DATE_LANGUAGE=FRENCH')
            ORDER BY annee_mois;

    EXCEPTION
        WHEN OTHERS THEN
            OPEN p_result_cursor FOR
                SELECT
                    CAST(NULL AS VARCHAR2(7)) AS annee_mois,
                    CAST(NULL AS VARCHAR2(20)) AS mois_libelle,
                    CAST(NULL AS NUMBER) AS nombre_dons,
                    CAST(NULL AS NUMBER) AS montant_total
                FROM DUAL WHERE 1=0;
    END rpt_get_monthly_donations_summary;

    -- Procédure pour obtenir le classement des organisations par montant de dons reçus.
    PROCEDURE rpt_get_org_ranking_by_donations (
        p_user_id       IN NUMBER,
        p_start_date    IN DATE DEFAULT NULL,
        p_end_date      IN DATE DEFAULT NULL,
        p_result_cursor OUT t_ref_cursor
    )
    IS
        v_role        VARCHAR2(30) := get_user_role(p_user_id);
        v_org_id      NUMBER := get_org_id_for_user(p_user_id);
    BEGIN
        -- Cette vue est principalement pour ADMIN et ORGANISATION (pour voir son propre classement)
        IF v_role = 'DONOR' THEN
            -- Les donateurs n'ont pas besoin de ce rapport, on retourne un curseur vide
            OPEN p_result_cursor FOR
                SELECT
                    CAST(NULL AS NUMBER) AS id_org,
                    CAST(NULL AS VARCHAR2(100)) AS nom_org,
                    CAST(NULL AS NUMBER) AS montant_total_don,
                    CAST(NULL AS NUMBER) AS rang
                FROM DUAL WHERE 1=0;
            RETURN;
        END IF;

        OPEN p_result_cursor FOR
            WITH OrgDonations AS (
                SELECT
                    o.id_org,
                    o.nom_org,
                    NVL(SUM(d.montant_don), 0) AS montant_total_don
                FROM Organisation o
                LEFT JOIN Action_social a ON o.id_org = a.id_org
                LEFT JOIN Besoin b ON a.id_action = b.id_action
                LEFT JOIN Don d ON b.id_besoin = d.id_besoin AND d.statut_don = 'VALIDÉ'
                                AND d.date_don BETWEEN NVL(p_start_date, d.date_don) AND NVL(p_end_date, d.date_don)
                WHERE (v_role = 'ADMIN' OR (v_role = 'ORGANISATION' AND o.id_org = v_org_id))
                GROUP BY o.id_org, o.nom_org
            )
            SELECT
                od.id_org,
                od.nom_org,
                od.montant_total_don,
                RANK() OVER (ORDER BY od.montant_total_don DESC) AS rang
            FROM OrgDonations od
            ORDER BY rang;

    EXCEPTION
        WHEN OTHERS THEN
            OPEN p_result_cursor FOR
                SELECT
                    CAST(NULL AS NUMBER) AS id_org,
                    CAST(NULL AS VARCHAR2(100)) AS nom_org,
                    CAST(NULL AS NUMBER) AS montant_total_don,
                    CAST(NULL AS NUMBER) AS rang
                FROM DUAL WHERE 1=0;
    END rpt_get_org_ranking_by_donations;

    -- Procédure pour obtenir les détails de l'activité d'une campagne spécifique.
    PROCEDURE rpt_get_campaign_activity (
        p_user_id       IN NUMBER,
        p_action_id     IN NUMBER,
        p_result_cursor OUT t_ref_cursor
    )
    IS
        v_role        VARCHAR2(30) := get_user_role(p_user_id);
        v_org_id      NUMBER := get_org_id_for_user(p_user_id);
    BEGIN
        OPEN p_result_cursor FOR
            SELECT
                a.titre_action,
                a.date_debut_action,
                a.date_fin_action,
                a.montant_objectif_action,
                a.montant_recu_action,
                a.statut_action,
                o.nom_org,
                b.nom_besoin,
                b.unite_demande,
                b.unite_recue,
                b.pourcentage_rempli
            FROM Action_social a
            JOIN Organisation o ON a.id_org = o.id_org
            LEFT JOIN Besoin b ON a.id_action = b.id_action
            WHERE a.id_action = p_action_id
              AND (
                    v_role = 'ADMIN'
                 OR (v_role = 'ORGANISATION' AND a.id_org = v_org_id)
                 OR (v_role = 'DONOR' AND 1=1) -- Les donateurs peuvent voir les détails d'une campagne
                  );

    EXCEPTION
        WHEN OTHERS THEN
            OPEN p_result_cursor FOR
                SELECT
                    CAST(NULL AS VARCHAR2(100)) AS titre_action,
                    CAST(NULL AS DATE) AS date_debut_action,
                    CAST(NULL AS DATE) AS date_fin_action,
                    CAST(NULL AS NUMBER) AS montant_objectif_action,
                    CAST(NULL AS NUMBER) AS montant_recu_action,
                    CAST(NULL AS VARCHAR2(20)) AS statut_action,
                    CAST(NULL AS VARCHAR2(100)) AS nom_org,
                    CAST(NULL AS VARCHAR2(100)) AS nom_besoin,
                    CAST(NULL AS NUMBER) AS unite_demande,
                    CAST(NULL AS NUMBER) AS unite_recue,
                    CAST(NULL AS NUMBER) AS pourcentage_rempli
                FROM DUAL WHERE 1=0;
    END rpt_get_campaign_activity;

    -- Procédure pour obtenir l'historique des dons d'un donateur spécifique (pour l'interface DONOR).
    PROCEDURE rpt_get_donor_personal_history (
        p_user_id       IN NUMBER, -- Doit être l'ID du donateur
        p_start_date    IN DATE DEFAULT NULL,
        p_end_date      IN DATE DEFAULT NULL,
        p_result_cursor OUT t_ref_cursor
    )
    IS
        v_role        VARCHAR2(30) := get_user_role(p_user_id);
    BEGIN
        -- Sécurité renforcée: Seul le donateur lui-même (ou un ADMIN) peut voir cet historique
        IF v_role NOT IN ('ADMIN', 'DONOR') THEN
            OPEN p_result_cursor FOR
                SELECT
                    CAST(NULL AS NUMBER) AS id_don,
                    CAST(NULL AS NUMBER) AS montant_don,
                    CAST(NULL AS DATE) AS date_don,
                    CAST(NULL AS VARCHAR2(20)) AS statut_don,
                    CAST(NULL AS VARCHAR2(100)) AS nom_organisation,
                    CAST(NULL AS VARCHAR2(100)) AS nom_campagne
                FROM DUAL WHERE 1=0;
            RETURN;
        END IF;

        OPEN p_result_cursor FOR
            SELECT
                d.id_don,
                d.montant_don,
                d.date_don,
                d.statut_don,
                o.nom_org AS nom_organisation,
                a.titre_action AS nom_campagne
            FROM Don d
            JOIN Besoin b ON d.id_besoin = b.id_besoin
            JOIN Action_social a ON b.id_action = a.id_action
            JOIN Organisation o ON a.id_org = o.id_org
            WHERE d.id_donateur = p_user_id -- Filtrage essentiel pour le donateur
              AND d.date_don BETWEEN NVL(p_start_date, d.date_don) AND NVL(p_end_date, d.date_don)
            ORDER BY d.date_don DESC;

    EXCEPTION
        WHEN OTHERS THEN
            OPEN p_result_cursor FOR
                SELECT
                    CAST(NULL AS NUMBER) AS id_don,
                    CAST(NULL AS NUMBER) AS montant_don,
                    CAST(NULL AS DATE) AS date_don,
                    CAST(NULL AS VARCHAR2(20)) AS statut_don,
                    CAST(NULL AS VARCHAR2(100)) AS nom_organisation,
                    CAST(NULL AS VARCHAR2(100)) AS nom_campagne
                FROM DUAL WHERE 1=0;
    END rpt_get_donor_personal_history;

END REPORTING_PKG;
/
