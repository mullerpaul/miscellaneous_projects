DROP TABLE dice_log
/

CREATE TABLE dice_log
 (call_time             TIMESTAMP  DEFAULT SYSTIMESTAMP NOT NULL,
  roll_result           NUMBER                          NOT NULL)
PCTFREE 0  --insert only table
/

CREATE OR REPLACE PACKAGE dice IS
  -- Author  : PMULLER
  -- Created : 1/17/2017 9:53:06 AM

  -- Public function and procedure declarations
  PROCEDURE enable_dice_logging;

  PROCEDURE disable_dice_logging;

  FUNCTION get_dice_logging_status RETURN VARCHAR;

  FUNCTION roll_1d6 RETURN NUMBER;

  FUNCTION roll_2d6 RETURN NUMBER;

END dice;
/

CREATE OR REPLACE PACKAGE BODY dice IS

  -- Private variable declarations
  gv_dice_logging BOOLEAN;

  -- Function and procedure implementations
  ---------------------------------------------------------
  PROCEDURE enable_dice_logging IS
  BEGIN
    gv_dice_logging := TRUE;
  END enable_dice_logging;

  PROCEDURE disable_dice_logging IS
  BEGIN
    gv_dice_logging := FALSE;
  END disable_dice_logging;

  ---------------------------------------------------------
  FUNCTION get_dice_logging_status RETURN VARCHAR IS
    lv_result VARCHAR2(10);
  BEGIN
    IF gv_dice_logging
    THEN
      lv_result := 'enabled';
    ELSE
      lv_result := 'disabled';
    END IF;
    RETURN lv_result;
  END get_dice_logging_status;

  ---------------------------------------------------------
  PROCEDURE log_roll(lv_result_to_log IN NUMBER) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO dice_log (roll_result) VALUES (lv_result_to_log);
    COMMIT;
  END log_roll;

  ---------------------------------------------------------
  FUNCTION roll_1d6 RETURN NUMBER IS
    lv_result NUMBER;
  BEGIN
    lv_result := trunc(dbms_random.value(low => 1, high => 7));
  
    IF gv_dice_logging
    THEN
      log_roll(lv_result_to_log => lv_result);
    END IF;
  
    RETURN lv_result;
  END roll_1d6;

  ---------------------------------------------------------
  FUNCTION roll_2d6 RETURN NUMBER IS
  BEGIN
    RETURN roll_1d6 + roll_1d6;
  END roll_2d6;

BEGIN
  -- Package initialization
  gv_dice_logging := TRUE;

END dice;
/

SELECT * FROM user_errors ORDER BY TYPE, SEQUENCE;

SELECT dice.get_dice_logging_status FROM dual;

SELECT dice.roll_1d6 FROM dual;
SELECT dice.roll_2d6 FROM dual;

SELECT * FROM dice_log ORDER BY call_time;
SELECT roll_result, COUNT(*) FROM dice_log GROUP BY roll_result ORDER BY 1;


