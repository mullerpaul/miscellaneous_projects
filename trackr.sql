CREATE USER trackr
IDENTIFIED BY trackr
DEFAULT TABLESPACE USERS
QUOTA 10m ON USERS;

GRANT CREATE TABLE, CREATE SESSION TO trackr;

--- cleanup - ignore table does not exist errors here.
DROP TABLE trackr_events PURGE;
DROP TABLE trackr_measurements PURGE;
DROP TABLE trackr_measurements_type PURGE;

--
CREATE TABLE trackr_measurements_type
 (measurement_type VARCHAR2(48));

ALTER TABLE trackr_measurements_type
ADD CONSTRAINT trackr_measurements_type_pk 
PRIMARY KEY (measurement_type);

INSERT INTO trackr_measurements_type (measurement_type) VALUES ('timestamp');
INSERT INTO trackr_measurements_type (measurement_type) VALUES ('timestamp and amount');
INSERT INTO trackr_measurements_type (measurement_type) VALUES ('duration');

--
CREATE TABLE trackr_measurements
 (measurement_id    NUMBER       NOT NULL, 
  measurement_type  varchar2(48) NOT NULL,
  measurement_label VARCHAR2(64) NOT NULL);

ALTER TABLE trackr_measurements
ADD CONSTRAINT trackr_measurements_pk
PRIMARY KEY (measurement_id);

ALTER TABLE trackr_measurements
ADD CONSTRAINT trackr_measurement_type_fk
FOREIGN KEY (measurement_type) REFERENCES trackr_measurements_type;

--
CREATE TABLE trackr_events
 (measurement_id             NUMBER NOT NULL,
  measurement_timestamp      DATE   NOT NULL,
  measurement_amount         NUMBER,
  measurement_end_timestamp  DATE);

ALTER TABLE trackr_events
ADD CONSTRAINT trackr_events_pk
PRIMARY KEY (measurement_id, measurement_timestamp);

ALTER TABLE trackr_events
ADD CONSTRAINT trackr_measurement_fk
FOREIGN KEY (measurement_id) REFERENCES trackr_measurements;
  
---  enter some sample data
INSERT INTO trackr_measurements
 (measurement_id, measurement_type, measurement_label)  
VALUES
 (1, 'timestamp', 'What time did I get to work?');
 
INSERT INTO trackr_measurements
 (measurement_id, measurement_type, measurement_label)  
VALUES
 (2, 'timestamp and amount', 'How much do I weigh?');
 
INSERT INTO trackr_measurements
 (measurement_id, measurement_type, measurement_label)  
VALUES
 (3, 'duration', 'How long did I excersize?');
 
COMMIT;

BEGIN
  FOR i IN 1 .. 30 LOOP
    BEGIN
      INSERT INTO trackr_events
        (measurement_id, measurement_timestamp, measurement_amount)
      VALUES 
        (1, TRUNC(SYSDATE-i) + 8/24 + (50 - dbms_random.value(low => 0, HIGH => 10))/(24*60), NULL);  

      INSERT INTO trackr_events
        (measurement_id, measurement_timestamp, measurement_amount)
      VALUES 
        (2, TRUNC(SYSDATE-i) + 7/24 + i/(24*60), round(195 + dbms_random.value(low => 0, HIGH => 10),0));
      
      INSERT INTO trackr_events
        (measurement_id, measurement_timestamp, measurement_end_timestamp)
      VALUES 
        (3, TRUNC(SYSDATE-i) + 17/24 - (dbms_random.value(low => 0, HIGH => 10)/(24*60)), TRUNC(SYSDATE-i) + 18/24 + (dbms_random.value(low => 0, HIGH => 10)/(24*60)));
    END;
  END LOOP;

  COMMIT;
END;
/

-- test data
SELECT m.measurement_label, e.measurement_timestamp, e.measurement_amount, e.measurement_end_timestamp,
       round(24 * 60 * (e.measurement_end_timestamp - e.measurement_timestamp ), 1) AS duration_minutes
  FROM trackr_measurements m,
       trackr_events e
 WHERE m.measurement_id = e.measurement_id
 ORDER BY e.measurement_id, e.measurement_timestamp;      

TRUNCATE TABLE trackr_events;
TRUNCATE TABLE trackr_measurements;

---- what features do we need?
--
-- data entry screens 
--    choose measurement category from list screen
--    populate data entry for timestamp (current time) and amount (recent avg?) 
--    big button for record data
-- admin screen to add/remove/edit measurement categories
-- graph screen to graph selected measurement(s) over time
-- export screen to export selected measurement(s)

