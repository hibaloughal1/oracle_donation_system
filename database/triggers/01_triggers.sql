-- ============================================================
-- TRIGGER: TRG_AUDIT_UTILISATEUR
-- Audits INSERT/UPDATE/DELETE on Utilisateur
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_AUDIT_UTILISATEUR
AFTER INSERT OR UPDATE OR DELETE ON Utilisateur
FOR EACH ROW
DECLARE
    v_operation   VARCHAR2(20);
    v_old_values  VARCHAR2(2000);
    v_new_values  VARCHAR2(2000);
    v_user_id     NUMBER;
BEGIN
    IF INSERTING THEN
        v_operation  := 'INSERT';
        v_old_values := NULL;
        v_new_values :=
              'nom=' || :NEW.nom_user
           || ', email=' || :NEW.email_user
           || ', tel=' || :NEW.tel_user
           || ', statut=' || :NEW.statut_user;

        v_user_id := :NEW.id_user;

    ELSIF UPDATING THEN
        v_operation  := 'UPDATE';
        v_old_values :=
              'nom=' || :OLD.nom_user
           || ', email=' || :OLD.email_user
           || ', tel=' || :OLD.tel_user
           || ', statut=' || :OLD.statut_user;

        v_new_values :=
              'nom=' || :NEW.nom_user
           || ', email=' || :NEW.email_user
           || ', tel=' || :NEW.tel_user
           || ', statut=' || :NEW.statut_user;

        v_user_id := :OLD.id_user;

    ELSIF DELETING THEN
        v_operation  := 'DELETE';
        v_old_values :=
              'nom=' || :OLD.nom_user
           || ', email=' || :OLD.email_user
           || ', tel=' || :OLD.tel_user
           || ', statut=' || :OLD.statut_user;

        v_new_values := NULL;
        v_user_id := :OLD.id_user;
    END IF;

    INSERT INTO Audit_Log_Utilisateur (
        id_user,
        operation,
        old_values,
        new_values,
        changed_by,
        change_date
    ) VALUES (
        v_user_id,
        v_operation,
        v_old_values,
        v_new_values,
        NVL(SYS_CONTEXT('APP_CTX','USER_EMAIL'), USER),
        SYSDATE
    );
END;
/
SHOW ERRORS;


-- ============================================================
-- TRIGGER: TRG_BESOIN_PROTECT_DELETE
-- Prevent delete of Besoin when Don rows exist
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_BESOIN_PROTECT_DELETE
BEFORE DELETE ON Besoin
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM Don
    WHERE id_besoin = :OLD.id_besoin;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Impossible de supprimer ce besoin: des dons y sont déjà associés.'
        );
    END IF;
END;
/
SHOW ERRORS;

-- ============================================================
-- TRIGGER: TRG_DON_UPDATE_NEED
-- After a donation, update Besoin.unite_recue
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_DON_UPDATE_NEED
AFTER INSERT ON Don
FOR EACH ROW
DECLARE
    v_status   VARCHAR2(50);
    v_message  VARCHAR2(200);
    v_delta    NUMBER;
BEGIN
    -- Example logic: 1 unité pour 100 de montant
    v_delta := FLOOR(:NEW.montant_don / 100);

    IF v_delta IS NULL OR v_delta <= 0 THEN
        RETURN; -- no impact on quantity
    END IF;

    SECURITY_PKG.SP_UPDATE_NEED_QTY(
        p_besoin_id => :NEW.id_besoin,
        p_delta     => v_delta,
        p_status    => v_status,
        p_message   => v_message
    );

    IF v_status <> 'OK' THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'Echec de mise à jour du besoin: ' || v_message
        );
    END IF;
END;
/
SHOW ERRORS;


-- ============================================================
-- TRIGGER: TRG_ACTION_COMPLETE
-- When all besoins of an action are full, mark the action COMPLETED
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_ACTION_COMPLETE
AFTER INSERT OR UPDATE ON Besoin
FOR EACH ROW
DECLARE
    v_action_id      Action_social.id_action%TYPE;
    v_not_full_count NUMBER;
BEGIN
    v_action_id := :NEW.id_action;

    -- Count besoins that are NOT at 100% for this action
    SELECT COUNT(*)
    INTO v_not_full_count
    FROM Besoin
    WHERE id_action = v_action_id
      AND (pourcentage_rempli < 100 OR pourcentage_rempli IS NULL);

    IF v_not_full_count = 0 THEN
        UPDATE Action_social
        SET statut_action = 'COMPLETED'
        WHERE id_action = v_action_id
          AND statut_action <> 'COMPLETED';
    END IF;
END;
/
SHOW ERRORS;

-- ============================================================
-- TRIGGER: TRG_USERS_PASSWORD_HASH
-- ============================================================

CREATE OR REPLACE TRIGGER trg_users_password_hash
BEFORE INSERT OR UPDATE OF password_hash
ON Utilisateur
FOR EACH ROW
DECLARE
  v_len PLS_INTEGER;
BEGIN
  IF :NEW.password_hash IS NOT NULL THEN
    v_len := LENGTH(:NEW.password_hash);

    -- Very simple “already hashed” heuristic: 64 hex chars (SHA-256 style) [web:1][web:20]
    IF NOT REGEXP_LIKE(:NEW.password_hash, '^[0-9A-Fa-f]{64}$') THEN
      SELECT STANDARD_HASH(:NEW.password_hash, 'SHA256')
      INTO   :NEW.password_hash
      FROM   dual;
    END IF;
  END IF;
END;
/
SHOW ERRORS;


-- ============================================================
-- TRIGGER: TRG_USERS_EMAIL_LOWERCASE
-- ============================================================

CREATE OR REPLACE TRIGGER trg_users_email_lowercase
BEFORE INSERT OR UPDATE OF email_user
ON Utilisateur
FOR EACH ROW
BEGIN
      IF :NEW.email_user IS NOT NULL THEN
            :NEW.email_user := LOWER(:NEW.email_user);
      END IF;
END;
/
SHOW ERRORS;

-- ============================================================
-- TRIGGER: TRG_ORGANISATION_AUDIT
-- ============================================================
CREATE OR REPLACE TRIGGER trg_organisation_audit
AFTER INSERT OR UPDATE OR DELETE
ON Organisation
FOR EACH ROW
DECLARE
  v_old_values  VARCHAR2(2000);
  v_new_values  VARCHAR2(2000);
  v_operation   VARCHAR2(10);
BEGIN
  IF INSERTING THEN
    v_operation := 'INSERT';
    v_new_values :=
         'id_org='        || :NEW.id_org
      || ';nom_org='      || :NEW.nom_org
      || ';statut_org='   || :NEW.statut_org
      || ';id_user_owner='|| :NEW.id_user_owner;

  ELSIF UPDATING THEN
    v_operation := 'UPDATE';
    v_old_values :=
         'id_org='        || :OLD.id_org
      || ';nom_org='      || :OLD.nom_org
      || ';statut_org='   || :OLD.statut_org
      || ';id_user_owner='|| :OLD.id_user_owner;

    v_new_values :=
         'id_org='        || :NEW.id_org
      || ';nom_org='      || :NEW.nom_org
      || ';statut_org='   || :NEW.statut_org
      || ';id_user_owner='|| :NEW.id_user_owner;

  ELSIF DELETING THEN
    v_operation := 'DELETE';
    v_old_values :=
         'id_org='        || :OLD.id_org
      || ';nom_org='      || :OLD.nom_org
      || ';statut_org='   || :OLD.statut_org
      || ';id_user_owner='|| :OLD.id_user_owner;
  END IF;

  INSERT INTO Business_Log_Audit (
    table_name,
    record_pk,
    operation,
    old_values,
    new_values,
    changed_by,
    change_date
  ) VALUES (
    ORA_DICT_OBJ_NAME,
    NVL(:NEW.id_org, :OLD.id_org),
    v_operation,
    v_old_values,
    v_new_values,
    NVL(SYS_CONTEXT('APP_CTX','USER_EMAIL'), USER),
    SYSDATE
  );
END;
/
SHOW ERRORS;


-- ============================================================
-- TRIGGER: TRG_ORGANISATION_STATUS_VALIDATION
-- ============================================================

CREATE OR REPLACE TRIGGER trg_organisation_status_validation
BEFORE UPDATE OF statut_org
ON Organisation
FOR EACH ROW
DECLARE
      e_invalid_status EXCEPTION;
      PRAGMA EXCEPTION_INIT(e_invalid_status, -20001);
BEGIN
      IF :OLD.statut_org = :NEW.statut_org THEN
        RETURN;
      END IF;

      -- Allowed transitions:
      -- PENDING -> ACTIVE
      -- PENDING -> SUSPENDED
      -- ACTIVE  -> SUSPENDED
      -- SUSPENDED -> ACTIVE
      IF NOT (
            (:OLD.statut_org = 'PENDING'   AND :NEW.statut_org IN ('ACTIVE','SUSPENDED'))
         OR (:OLD.statut_org = 'ACTIVE'    AND :NEW.statut_org = 'SUSPENDED')
         OR (:OLD.statut_org = 'SUSPENDED' AND :NEW.statut_org = 'ACTIVE')
      ) THEN
        RAISE_APPLICATION_ERROR(
          -20001,
          'Invalid organisation status transition: '
          || :OLD.statut_org || ' -> ' || :NEW.statut_org
        );
      END IF;
END;
/
SHOW ERRORS;

-- ============================================================
-- TRIGGER: TRG_ACTION_AUDIT
-- ============================================================

CREATE OR REPLACE TRIGGER trg_action_audit
AFTER INSERT OR UPDATE OR DELETE
ON Action_social
FOR EACH ROW
DECLARE
  v_old_values  VARCHAR2(2000);
  v_new_values  VARCHAR2(2000);
BEGIN
  IF INSERTING THEN
    v_new_values :=
         'id_action='        || :NEW.id_action
      || ';id_org='          || :NEW.id_org
      || ';titre_action='    || :NEW.titre_action
      || ';statut_action='   || :NEW.statut_action
      || ';date_debut='      || TO_CHAR(:NEW.date_debut_action,'YYYY-MM-DD')
      || ';date_fin='        || TO_CHAR(:NEW.date_fin_action,'YYYY-MM-DD');

  ELSIF UPDATING THEN
    v_old_values :=
         'id_action='        || :OLD.id_action
      || ';id_org='          || :OLD.id_org
      || ';titre_action='    || :OLD.titre_action
      || ';statut_action='   || :OLD.statut_action
      || ';date_debut='      || TO_CHAR(:OLD.date_debut_action,'YYYY-MM-DD')
      || ';date_fin='        || TO_CHAR(:OLD.date_fin_action,'YYYY-MM-DD');

    v_new_values :=
         'id_action='        || :NEW.id_action
      || ';id_org='          || :NEW.id_org
      || ';titre_action='    || :NEW.titre_action
      || ';statut_action='   || :NEW.statut_action
      || ';date_debut='      || TO_CHAR(:NEW.date_debut_action,'YYYY-MM-DD')
      || ';date_fin='        || TO_CHAR(:NEW.date_fin_action,'YYYY-MM-DD');

  ELSIF DELETING THEN
    v_old_values :=
         'id_action='        || :OLD.id_action
      || ';id_org='          || :OLD.id_org
      || ';titre_action='    || :OLD.titre_action
      || ';statut_action='   || :OLD.statut_action
      || ';date_debut='      || TO_CHAR(:OLD.date_debut_action,'YYYY-MM-DD')
      || ';date_fin='        || TO_CHAR(:OLD.date_fin_action,'YYYY-MM-DD');
  END IF;

  INSERT INTO Business_Log_Audit (
    table_name,
    record_pk,
    operation,
    old_values,
    new_values,
    changed_by,
    change_date
  ) VALUES (
    ORA_DICT_OBJ_NAME,
    NVL(:NEW.id_org, :OLD.id_org),
    v_operation,
    v_old_values,
    v_new_values,
    NVL(SYS_CONTEXT('APP_CTX','USER_EMAIL'), USER),
    SYSDATE
  );
END;
/
SHOW ERRORS;

-- ============================================================
-- TRIGGER: TRG_ACTION_STATUS_VALIDATION
-- ============================================================

CREATE OR REPLACE TRIGGER trg_action_status_validation
BEFORE UPDATE OF statut_action
ON Action_social
FOR EACH ROW
BEGIN
  IF :OLD.statut_action = :NEW.statut_action THEN
    RETURN;
  END IF;

  -- DRAFT -> ACTIVE
  -- ACTIVE -> CLOSED or COMPLETED
  -- CLOSED -> COMPLETED (optional)
  IF NOT (
        (:OLD.statut_action = 'DRAFT' AND :NEW.statut_action = 'ACTIVE')
     OR (:OLD.statut_action = 'ACTIVE' AND :NEW.statut_action IN ('CLOSED','COMPLETED'))
     OR (:OLD.statut_action = 'CLOSED' AND :NEW.statut_action = 'COMPLETED')
  ) THEN
    RAISE_APPLICATION_ERROR(
      -20002,
      'Invalid action status transition: '
      || :OLD.statut_action || ' -> ' || :NEW.statut_action
    );
  END IF;
END;
/
SHOW ERRORS;

-- ============================================================
-- TRIGGER: TRG_ACTION_AUTO_CLOSE
-- ============================================================

CREATE OR REPLACE TRIGGER trg_action_auto_close
BEFORE INSERT OR UPDATE ON Action_social
FOR EACH ROW
BEGIN
  IF :NEW.statut_action = 'ACTIVE'
     AND :NEW.date_fin_action < SYSDATE THEN
    :NEW.statut_action := 'CLOSED';
  END IF;
END;
/
SHOW ERRORS;

-- ============================================================
-- TRIGGER: TRG_BESOIN_AUDIT
-- ============================================================

create or replace TRIGGER trg_besoin_audit
AFTER INSERT OR UPDATE OR DELETE
ON Besoin
FOR EACH ROW
DECLARE
  v_old_values  VARCHAR2(2000);
  v_new_values  VARCHAR2(2000);
  v_operation VARCHAR2(10);
BEGIN
  IF INSERTING THEN
    v_operation := 'INSERT';
    v_new_values :=
         'id_besoin='        || :NEW.id_besoin
      || ';id_action='       || :NEW.id_action
      || ';nom_besoin='      || :NEW.nom_besoin
      || ';unite_demande='   || :NEW.unite_demande
      || ';unite_recue='     || :NEW.unite_recue;

  ELSIF UPDATING THEN
    v_operation := 'UPDATE';
    v_old_values :=
         'id_besoin='        || :OLD.id_besoin
      || ';id_action='       || :OLD.id_action
      || ';nom_besoin='      || :OLD.nom_besoin
      || ';unite_demande='   || :OLD.unite_demande
      || ';unite_recue='     || :OLD.unite_recue;

    v_new_values :=
         'id_besoin='        || :NEW.id_besoin
      || ';id_action='       || :NEW.id_action
      || ';nom_besoin='      || :NEW.nom_besoin
      || ';unite_demande='   || :NEW.unite_demande
      || ';unite_recue='     || :NEW.unite_recue;

  ELSIF DELETING THEN
    v_operation := 'DELETE';
    v_old_values :=
         'id_besoin='        || :OLD.id_besoin
      || ';id_action='       || :OLD.id_action
      || ';nom_besoin='      || :OLD.nom_besoin
      || ';unite_demande='   || :OLD.unite_demande
      || ';unite_recue='     || :OLD.unite_recue;
  END IF;

  INSERT INTO Business_Log_Audit(
      table_name,
      record_pk,
      operation,
      old_values,
      new_values,
      changed_by,
      change_date
    ) VALUES (
      'Besoin',
      NVL(:NEW.id_besoin, :OLD.id_besoin),
      v_operation,
      v_old_values,
      v_new_values,
      NVL(
        SYS_CONTEXT('APP_CTX','USER_EMAIL'),
        SYS_CONTEXT('USERENV','SESSION_USER')
      ),
      SYSDATE
    );

END;
/
SHOW ERRORS;

-- ============================================================
-- TRIGGER: trg_don_prevent_closed_campaign
-- ============================================================

CREATE OR REPLACE TRIGGER trg_don_prevent_closed_campaign
BEFORE INSERT
ON Don
FOR EACH ROW
DECLARE
  v_statut_action Action_social.statut_action%TYPE;
BEGIN
  SELECT a.statut_action
  INTO   v_statut_action
  FROM   Besoin b
  JOIN   Action_social a
    ON   a.id_action = b.id_action
  WHERE  b.id_besoin = :NEW.id_besoin;

  IF v_statut_action IN ('CLOSED','COMPLETED') THEN
    RAISE_APPLICATION_ERROR(
      -20003,
      'Cannot donate to a closed or completed campaign.'
    );
  END IF;
END;
/
SHOW ERRORS;

-- ============================================================
-- TRIGGER: trg_don_audit
-- ============================================================

CREATE OR REPLACE TRIGGER trg_don_audit
AFTER INSERT OR UPDATE OR DELETE
ON Don
FOR EACH ROW
DECLARE
  v_old_values  VARCHAR2(2000);
  v_new_values  VARCHAR2(2000);
  v_operation VARCHAR2(10);
BEGIN
  IF INSERTING THEN
    v_operation := 'INSERT';
    v_new_values :=
         'id_don='       || :NEW.id_don
      || ';id_donateur=' || :NEW.id_donateur
      || ';id_besoin='   || :NEW.id_besoin
      || ';montant_don=' || :NEW.montant_don
      || ';statut_don='  || :NEW.statut_don;

  ELSIF UPDATING THEN
    v_operation := 'UPDATE';
    v_old_values :=
         'id_don='       || :OLD.id_don
      || ';id_donateur=' || :OLD.id_donateur
      || ';id_besoin='   || :OLD.id_besoin
      || ';montant_don=' || :OLD.montant_don
      || ';statut_don='  || :OLD.statut_don;

    v_new_values :=
         'id_don='       || :NEW.id_don
      || ';id_donateur=' || :NEW.id_donateur
      || ';id_besoin='   || :NEW.id_besoin
      || ';montant_don=' || :NEW.montant_don
      || ';statut_don='  || :NEW.statut_don;

  ELSIF DELETING THEN
    v_operation := 'DELETE';
    v_old_values :=
         'id_don='       || :OLD.id_don
      || ';id_donateur=' || :OLD.id_donateur
      || ';id_besoin='   || :OLD.id_besoin
      || ';montant_don=' || :OLD.montant_don
      || ';statut_don='  || :OLD.statut_don;
  END IF;

  INSERT INTO Business_Log_Audit(
    table_name,
    record_pk,
    operation,
    old_values,
    new_values,
    changed_by,
    change_date
  ) VALUES (
    'Don',
    NVL(:NEW.id_don, :OLD.id_don),
    v_operation,
    v_old_values,
    v_new_values,
    NVL(
        SYS_CONTEXT('APP_CTX','USER_EMAIL'),
        SYS_CONTEXT('USERENV','SESSION_USER')
      ),
    SYSDATE
  );
END;
/
SHOW ERRORS;

-- ============================================================
-- TRIGGER: trg_payment_proofs_audit
-- ============================================================

CREATE OR REPLACE TRIGGER trg_payment_proofs_audit
AFTER INSERT OR UPDATE OR DELETE
ON Payment_Proofs
FOR EACH ROW
DECLARE
  v_old_values  VARCHAR2(2000);
  v_new_values  VARCHAR2(2000);
  v_operation VARCHAR2(10);
BEGIN
  IF INSERTING THEN
    v_operation := 'INSERT';
    v_new_values :=
         'id_proof='    || :NEW.id_proof
      || ';id_don='     || :NEW.id_don
      || ';file_name='  || :NEW.file_name
      || ';file_type='  || :NEW.file_type;

  ELSIF UPDATING THEN
    v_operation := 'UPDATE';
    v_old_values :=
         'id_proof='    || :OLD.id_proof
      || ';id_don='     || :OLD.id_don
      || ';file_name='  || :OLD.file_name
      || ';file_type='  || :OLD.file_type;

    v_new_values :=
         'id_proof='    || :NEW.id_proof
      || ';id_don='     || :NEW.id_don
      || ';file_name='  || :NEW.file_name
      || ';file_type='  || :NEW.file_type;

  ELSIF DELETING THEN
    v_operation := 'DELETE';
    v_old_values :=
         'id_proof='    || :OLD.id_proof
      || ';id_don='     || :OLD.id_don
      || ';file_name='  || :OLD.file_name
      || ';file_type='  || :OLD.file_type;
  END IF;

  INSERT INTO Business_Log_Audit(
    table_name,
    record_pk,
    operation,
    old_values,
    new_values,
    changed_by,
    change_date
  ) VALUES (
    'Payment_Proofs',
    NVL(:NEW.id_proof, :OLD.id_proof),
    v_operation,
    v_old_values,
    v_new_values,
    NVL(
        SYS_CONTEXT('APP_CTX','USER_EMAIL'),
        SYS_CONTEXT('USERENV','SESSION_USER')
      ),
    SYSDATE
  );
END;
/
SHOW ERRORS;


-- ============================================================
-- TRIGGER: trg_global_error_log
-- ============================================================

/*
ALTER SESSION SET CONTAINER = XEPDB1;
GRANT ADMINISTER DATABASE TRIGGER TO donation_app;
*/


CREATE OR REPLACE TRIGGER trg_global_error_log
AFTER SERVERERROR
ON DATABASE
DECLARE
  PRAGMA AUTONOMOUS_TRANSACTION;

  v_err_code    VARCHAR2(20);
  v_err_stack   VARCHAR2(2000);
  v_backtrace   VARCHAR2(2000);
  v_user        VARCHAR2(100);
BEGIN
  v_err_code  := TO_CHAR(SQLCODE);
  v_err_stack := DBMS_UTILITY.format_error_stack;
  v_backtrace := DBMS_UTILITY.format_error_backtrace;

  v_user := NVL(
              SYS_CONTEXT('APP_CTX','USER_EMAIL'),
              SYS_CONTEXT('USERENV','SESSION_USER')
            );

  -- Avoid recursive logging
  IF ORA_DICT_OBJ_NAME = 'ERROR_LOG' THEN
    RETURN;
  END IF;

  INSERT INTO Error_Log (
    error_code,
    error_message,
    source_procedure,
    error_date,
    details
  ) VALUES (
    v_err_code,
    SUBSTR(v_err_stack, 1, 500),
    SYS_CONTEXT('USERENV','MODULE'),
    SYSDATE,
    SUBSTR(v_backtrace, 1, 1000)
  );

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    -- NEVER let an error propagate from a SERVERERROR trigger
    NULL;
END;
/
SHOW ERRORS;

