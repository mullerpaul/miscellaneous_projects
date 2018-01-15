-------- cleanup --------
DROP TABLE risk_simulation_battles PURGE;
DROP TABLE risk_simulation_runs PURGE;
DROP SEQUENCE risk_simulation_runs_seq;

-------- tables and constraints --------
CREATE TABLE risk_simulation_runs
 (simulation_run_ID      NUMBER       NOT NULL,
  simulation_time        DATE         NOT NULL,
  software_version       NUMBER       NOT NULL,
  attack_armies          NUMBER(2,0)  NOT NULL,
  defend_armies          NUMBER(2,0)  NOT NULL,
  attacker_dice_strategy VARCHAR2(48) NOT NULL,
  defender_dice_strategy VARCHAR2(48) NOT NULL,
  simulation_run_count   NUMBER,
  attack_success_count   NUMBER);

ALTER TABLE risk_simulation_runs
ADD CONSTRAINT risk_simulation_runs_pk
PRIMARY key (simulation_run_id);

CREATE SEQUENCE risk_simulation_runs_seq;

CREATE TABLE risk_simulation_battles
(simulation_run_id         NUMBER      NOT NULL, 
 battle_id                 NUMBER      NOT NULL,
 elapsed_rounds            NUMBER      NOT NULL,
 was_attack_successful     VARCHAR2(1) NOT NULL,
 final_attack_armies_count NUMBER      NOT NULL,
 final_defend_armies_count NUMBER      NOT NULL)
PCTFREE 0;   --insert only dakara

ALTER TABLE risk_simulation_battles
ADD CONSTRAINT risk_simulation_battles_pk
PRIMARY KEY (simulation_run_id, battle_id);
 
ALTER TABLE risk_simulation_battles
ADD CONSTRAINT risk_simulation_battles_fk01 
FOREIGN KEY (simulation_run_id) REFERENCES risk_simulation_runs;
 
ALTER TABLE risk_simulation_battles
ADD CONSTRAINT risk_simulation_battles_ck01 
CHECK (was_attack_successful IN ('Y','N'));

-------- view for Tableau access --------
CREATE OR REPLACE VIEW risk_statistics_vw
AS
SELECT r.simulation_run_id,  
       r.attack_armies, r.defend_armies, r.simulation_run_count, --r.attack_success_count, 
       r.attacker_dice_strategy, r.defender_dice_strategy,
       b.battle_id, b.was_attack_successful, b.elapsed_rounds, b.final_attack_armies_count, b.final_defend_armies_count
  FROM risk_simulation_runs r,
       risk_simulation_battles b
 WHERE r.simulation_run_id = b.simulation_run_id;

CREATE OR REPLACE VIEW risk_statistics_rollup_vw
AS
SELECT simulation_run_id, simulation_run_count, attack_Armies, defend_Armies, 
       was_attack_successful, final_attack_Armies_count, final_Defend_armies_count,
       occurances, occurances/simulation_run_count AS occurance_probability,
       row_number () OVER (PARTITION BY simulation_run_id
                           ORDER BY CASE 
                                      WHEN was_attack_successful = 'N' THEN -1 * final_defend_armies_count      
                                      ELSE final_attack_armies_count
                                    END) AS result_bin_id
  FROM (SELECT r.simulation_run_id, r.simulation_run_count, r.attack_Armies, r.defend_Armies, 
               b.was_attack_successful, b.final_attack_Armies_count, b.final_Defend_armies_count,
               COUNT(*) AS occurances
          FROM risk_simulation_runs r,
               risk_simulation_battles b
         WHERE r.simulation_run_id = b.simulation_run_id
         GROUP BY r.simulation_run_id, r.simulation_run_count, r.attack_Armies, r.defend_Armies, 
                  b.was_attack_successful, b.final_attack_Armies_count, b.final_Defend_armies_count);

-------- package spec --------
CREATE OR REPLACE PACKAGE risk_simulation IS

  -- Author  : PMULLER
  -- Created : 1/17/2017 10:59:11 AM
  PROCEDURE simulate_battle(pi_attack_armies          IN NUMBER,
                            pi_defend_armies          IN NUMBER,
                            pi_attacker_dice_strategy IN VARCHAR2 DEFAULT 'always roll maximum number of dice',
                            pi_defender_dice_strategy IN VARCHAR2 DEFAULT 'always roll maximum number of dice');

  PROCEDURE testing;

END risk_simulation;
/

-------- package body --------
CREATE OR REPLACE PACKAGE BODY risk_simulation IS

  TYPE la_dice_varray IS VARRAY(3) OF NUMBER(1, 0); -- Varray 

  ---------------------------------------------------------
  PROCEDURE print_dice_array(pi_array IN la_dice_varray) IS
  BEGIN
    FOR i IN pi_array.first .. pi_array.last LOOP
      dbms_output.put(to_char(pi_array(i)) || ' ');
    END LOOP;
  
  END print_dice_array;

  ---------------------------------------------------------
  FUNCTION load_dice_array(pi_dice_count IN NUMBER) RETURN la_dice_varray IS
    la_result la_dice_varray := la_dice_varray();
  BEGIN
    FOR j IN 1 .. pi_dice_count LOOP
      la_result.extend;
      la_result(j) := dice.roll_1d6;
    END LOOP;
    
    RETURN la_result;
    
  END load_dice_array;

  ---------------------------------------------------------
  PROCEDURE get_top_two(pi_array                IN la_dice_varray,
                        po_highest_value        OUT NUMBER,
                        po_second_highest_value OUT NUMBER) IS
  
    lv_greatest        NUMBER;
    lv_second_greatest NUMBER;
  
  BEGIN
    CASE pi_array.count
      WHEN 1 THEN
        lv_greatest := pi_array(1);
      
      WHEN 2 THEN
        BEGIN
          lv_greatest        := greatest(pi_array(1), pi_array(2));
          lv_second_greatest := least(pi_array(1), pi_array(2));
        END;
      
      WHEN 3 THEN
        BEGIN
          lv_greatest        := pi_array(1);
          lv_second_greatest := 0;
          FOR i IN 2 .. 3 LOOP
            CASE
              WHEN pi_array(i) >= lv_greatest THEN
                lv_second_greatest := lv_greatest;
                lv_greatest        := pi_array(i);
              WHEN pi_array(i) >= lv_second_greatest THEN
                lv_second_greatest := pi_array(i);
              ELSE
                NULL;
            END CASE;
          END LOOP;
        END;
    END CASE;
  
    po_highest_value        := lv_greatest;
    po_second_highest_value := lv_second_greatest;
  
  END get_top_two;

  ---------------------------------------------------------
  FUNCTION get_attack_dice_used(pi_attack_armies IN NUMBER,
                                pi_defend_armies IN NUMBER,
                                pi_strategy      IN VARCHAR) RETURN NUMBER IS
    lv_result NUMBER;
  
  BEGIN
    CASE pi_strategy
      WHEN 'always roll maximum number of dice' THEN
        /*  one less than # of armies up to a max of three. */
        IF pi_attack_armies IN (2, 3)
        THEN
          lv_result := pi_attack_armies - 1;
        ELSE
          lv_result := 3;
        END IF;
      ELSE
        raise_application_error(-20004, 'no other strategies implemented yet!');
    END CASE;
  
    RETURN lv_result;
  
  END get_attack_dice_used;

  ---------------------------------------------------------
  FUNCTION get_defend_dice_used(pi_defend_armies IN NUMBER,
                                pi_attack_armies IN NUMBER,
                                pi_strategy      IN VARCHAR) RETURN NUMBER IS
    lv_result NUMBER;
  
  BEGIN
    CASE pi_strategy
      WHEN 'always roll maximum number of dice' THEN
        /*  one less than # of armies up to a max of two. */
        IF pi_defend_armies = 1
        THEN
          lv_result := 1;
        ELSE
          lv_result := 2;
        END IF;
      ELSE
        raise_application_error(-20004, 'That strategy not implemented yet!');
    END CASE;
  
    RETURN lv_result;
  
  END get_defend_dice_used;

  ---------------------------------------------------------
  PROCEDURE simulate_battle(pi_attack_armies          IN NUMBER,
                            pi_defend_armies          IN NUMBER,
                            pi_attacker_dice_strategy IN VARCHAR2 DEFAULT 'always roll maximum number of dice',
                            pi_defender_dice_strategy IN VARCHAR2 DEFAULT 'always roll maximum number of dice') IS
  
    lc_simulation_runs CONSTANT NUMBER := 2000;
    lc_version         CONSTANT risk_simulation_runs.software_version%TYPE := 1;
  
    lv_attack_army_cnt NUMBER;
    lv_attack_dice_cnt NUMBER;
    lv_defend_army_cnt NUMBER;
    lv_defend_dice_cnt NUMBER;
  
    lv_attack_dice_table la_dice_varray;
    lv_defend_dice_table la_dice_varray;
  
    lv_attack_high        NUMBER;
    lv_attack_second_high NUMBER;
    lv_defend_high        NUMBER;
    lv_defend_second_high NUMBER;
    lv_round_counter      NUMBER;
  
    lv_attack_success_flag risk_simulation_battles.was_attack_successful%TYPE;
  
  BEGIN
    /*  verify inputs are Not null and are positive integers and attack armies is at least 2 (by rule) */
    IF (pi_attack_armies < 2 OR pi_attack_armies IS NULL OR pi_attack_armies <> trunc(pi_attack_armies) OR
       pi_defend_armies < 1 OR pi_defend_armies IS NULL OR pi_defend_armies <> trunc(pi_defend_armies))
    THEN
      raise_application_error(-20001, 'Invalid input');
    END IF;
  
    /*  log dice rolls */
    dice.enable_dice_logging;
  
    /*  Insert row into parent table */
    INSERT INTO risk_simulation_runs
      (simulation_run_id,
       simulation_time,
       software_version,
       attack_armies,
       defend_armies,
       attacker_dice_strategy,
       defender_dice_strategy)
    VALUES
      (risk_simulation_runs_seq.nextval,
       SYSDATE,
       lc_version,
       pi_attack_armies,
       pi_defend_armies,
       pi_attacker_dice_strategy,
       pi_defender_dice_strategy);
  
    /* loop for battle simulations */
    FOR i IN 1 .. lc_simulation_runs LOOP
      BEGIN
--        dbms_output.put_line('STARTING RUN #' || to_char(i));
        /* Init army count and round counter variables.  
        These will be modified inside the battle round loop. */
        lv_attack_army_cnt := pi_attack_armies;
        lv_defend_army_cnt := pi_defend_armies;
        lv_round_counter   := 1;
      
        /* Each battle has one or more rounds.  Loop over rounds until complete. */
        LOOP
          /* Init dice arrays */
          lv_attack_dice_table := la_dice_varray();
          lv_defend_dice_table := la_dice_varray();
        
          /*  set dice count for this round. */
          lv_attack_dice_cnt := get_attack_dice_used(pi_attack_armies => lv_attack_army_cnt,
                                                     pi_defend_armies => lv_defend_army_cnt,
                                                     pi_strategy      => pi_attacker_dice_strategy);
          lv_defend_dice_cnt := get_defend_dice_used(pi_defend_armies => lv_defend_army_cnt,
                                                     pi_attack_armies => lv_attack_army_cnt,
                                                     pi_strategy      => pi_defender_dice_strategy);
        
          /*  logging to screen.  Remove later */
/*          dbms_output.put_line('Start round #' || to_char(lv_round_counter));
          dbms_output.put_line('attacker has ' || lv_attack_army_cnt || ' armies and will use ' ||
                               lv_attack_dice_cnt || ' dice');
          dbms_output.put_line('defender has ' || lv_defend_army_cnt || ' armies and will use ' ||
                               lv_defend_dice_cnt || ' dice');
*/        
          /* Load the dice arrays - Roll the bones! */
          lv_attack_dice_table := load_dice_array(pi_dice_count => lv_attack_dice_cnt);
          lv_defend_dice_table := load_dice_array(pi_dice_count => lv_defend_dice_cnt);

/*          dbms_output.put('Attacker dice: ');
          print_dice_array(lv_attack_dice_table);
        
          dbms_output.put('  Defender dice: ');
          print_dice_array(lv_defend_dice_table);
          dbms_output.put_line('');
*/        
          /* find out who won and decrement armies count */
          get_top_two(pi_array                => lv_attack_dice_table,
                      po_highest_value        => lv_attack_high,
                      po_second_highest_value => lv_attack_second_high);
          get_top_two(pi_array                => lv_defend_dice_table,
                      po_highest_value        => lv_defend_high,
                      po_second_highest_value => lv_defend_second_high);
        
          /* there will always be a "highest" for both attack and defend */
          IF lv_defend_high >= lv_attack_high
          THEN
            lv_attack_army_cnt := lv_attack_army_cnt - 1;
          ELSE
            lv_defend_army_cnt := lv_defend_army_cnt - 1;
          END IF;
        
          /* there may be a second highest result as well */
          IF (lv_attack_dice_table.count > 1 AND lv_defend_dice_table.count > 1)
          THEN
            IF lv_defend_second_high >= lv_attack_second_high
            THEN
              lv_attack_army_cnt := lv_attack_army_cnt - 1;
            ELSE
              lv_defend_army_cnt := lv_defend_army_cnt - 1;
            END IF;
          END IF;
        
          /*  Exit loop if battle is complete */
          IF lv_attack_army_cnt = 1 OR lv_defend_army_cnt = 0
          THEN
            EXIT; -- terminate loop
          END IF;
        
          /* If not, increment round counter and start next round!  */
          lv_round_counter := lv_round_counter + 1;
        
        END LOOP;
      
        /* Battle over - insert row into risk_simulation_battles table.
        We'll get here if one OR other conditions below is true.  If BOTH are true
        something is very wrong.  Catch that just in case. */
        IF (lv_attack_army_cnt = 1 AND lv_defend_army_cnt = 0)
        THEN
          raise_application_error(-20003, 'no winner - both loose - impossible condition!');
        END IF;
      
        /* Determine who won.  This will be inserted into the results table. */
        IF lv_defend_army_cnt = 0
        THEN
          lv_attack_success_flag := 'Y';
        ELSE
          lv_attack_success_flag := 'N';
        END IF;
      
--        dbms_output.put_line('attack success flag: ' || lv_attack_success_flag);
      
        INSERT INTO risk_simulation_battles
          (simulation_run_id,
           battle_id,
           elapsed_rounds,
           was_attack_successful,
           final_attack_armies_count,
           final_defend_armies_count)
        VALUES
          (risk_simulation_runs_seq.currval,
           i, --the index variable on the outer FOR loop.
           lv_round_counter,
           lv_attack_success_flag,
           lv_attack_army_cnt,
           lv_defend_army_cnt);
      
      END;
    END LOOP;
  
    /* Now we can compute the results columns in the parent table */
    UPDATE (SELECT a.simulation_run_id, a.simulation_run_count, a.attack_success_count, 
                   b.simulations_ran, b.successful_attacks
              FROM risk_simulation_runs a,
                   (SELECT simulation_run_id,  
                           COUNT(*) AS simulations_ran, 
                           COUNT(CASE WHEN was_attack_successful = 'Y' THEN 'x' END) AS successful_attacks
                      FROM risk_simulation_battles
                     GROUP BY simulation_run_id) b 
             WHERE a.simulation_run_id = b.simulation_run_id
               AND a.simulation_run_count IS NULL)
       SET simulation_run_count = simulations_ran,
           attack_success_count = successful_attacks;        

    /* One commit for the parent row, all the child rows, and the bulk update. 
    Optionally remove this and do it in the calling block. */
    COMMIT;
  
  END simulate_battle;

  ---------------------------------------------------------
  PROCEDURE testing IS
  
    lv_x la_dice_varray;
  
  BEGIN
    dbms_output.put_line('x');
    lv_x := load_dice_array(pi_dice_count => 1);
    print_dice_array(lv_x);
    dbms_output.put_line('x');

  END testing;

END risk_simulation;
/
  
SELECT * FROM user_errors ORDER BY 1,2,3;

BEGIN
  risk_simulation.testing;
END;
/

BEGIN
--  risk_simulation.simulate_battle(pi_attack_armies => 2, pi_defend_armies => 1);  --should be 5/12 (41%)
--  risk_simulation.simulate_battle(pi_attack_armies => 3, pi_defend_armies => 2);
  risk_simulation.simulate_battle(pi_attack_armies => 6, pi_defend_armies => 5);
END;
/

BEGIN   -- N=1000 80s  -  N=2000 144s 
  FOR a IN 2 .. 10 LOOP
    FOR d IN 1 .. 10 LOOP
      risk_simulation.simulate_battle(pi_attack_armies => a, pi_defend_armies => d);
    END LOOP;
  END LOOP;
END;
/
  
SELECT * FROM risk_simulation_runs;
SELECT * FROM risk_simulation_battles;
SELECT simulation_run_id, COUNT(*), COUNT(CASE WHEN was_attack_successful = 'Y' THEN 'x' END)
  FROM risk_simulation_battles
 GROUP BY simulation_run_id
 ORDER BY 1;

SELECT attack_armies, defend_armies, simulation_run_count, attack_success_count
  FROM risk_simulation_runs;

SELECT * FROM risk_simulation_battles;
  


--  update the stats columns in parent table
UPDATE (SELECT a.simulation_run_id, a.simulation_run_count, a.attack_success_count, 
               b.simulations_ran, b.successful_attacks
          FROM risk_simulation_runs a,
               (SELECT simulation_run_id,  
                       COUNT(*) AS simulations_ran, 
                       COUNT(CASE WHEN was_attack_successful = 'Y' THEN 'x' END) AS successful_attacks
                  FROM risk_simulation_battles
                 GROUP BY simulation_run_id) b 
         WHERE a.simulation_run_id = b.simulation_run_id)
   SET simulation_run_count = simulations_ran,
       attack_success_count = successful_attacks;        

--
-- detail level - but with some parent level info pulled down as well (repeated for each child row)
SELECT * FROM risk_statistics_vw ;
 
-- intermediate level - details rolled up to possible outcome level
SELECT * FROM risk_statistics_rollup_vw
 WHERE attack_Armies = 5 
   AND defend_Armies = 5
 ORDER BY simulation_run_id, result_bin_id;

-- high level
SELECT simulation_run_id, attack_Armies, defend_armies, simulation_run_count, attack_success_count,
       attack_success_count / simulation_run_count AS attack_success_probability
  FROM risk_simulation_runs
 ORDER BY 1;



  
--- 
SELECT COUNT(*) FROM dice_log;

SELECT a.*, round(100/6, 3) AS normal_pct, round(100*ratio_to_report(occurances) over (), 3) AS pct_of_total
  FROM (SELECT roll_result, COUNT(*) occurances FROM dice_log GROUP BY roll_result) a
 ORDER BY roll_Result;




