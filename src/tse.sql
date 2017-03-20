CREATE EXTENSION file_fdw;
CREATE SERVER files FOREIGN DATA WRAPPER file_fdw;

CREATE FOREIGN TABLE temp1 (id int, urlref text, filename text)
   SERVER files OPTIONS (
     filename '/tmp/tse-fontes.csv',
       format 'csv',
       header 'true'
   );


CREATE FOREIGN TABLE temp2 (year int, state text, name text, bdate text, cpf text,fonte_id int)
   SERVER files OPTIONS (
     filename '/tmp/tse-FIM.csv',
       format 'csv',
       header 'true'
   );

-- -- -- -- -- -- --

CREATE TABLE pubperson.source (
 id bigserial NOT NULL PRIMARY KEY,
 label text,
 country char(2) NOT NULL DEFAULT 'br',
 info JSONb,
 UNIQUE(label)
);

CREATE TABLE pubperson.br_tse_person (
 id bigserial NOT NULL PRIMARY KEY,
 source_id bigint REFERENCES pubperson.source(id),
 fullname text,
 vatid bigint,
 info JSONb
);
CREATE INDEX idx_tse_fullname ON pubperson.br_tse_person (fullname);

UPDATE pubperson.br_tse_person
SET source_id = src.id
FROM pubperson.source src
WHERE src.info->'id' = br_tse_person.info->'fonte_id'
; -- wait ...



CREATE TABLE pubperson.person (
 id bigserial NOT NULL PRIMARY KEY,
 source_id bigint REFERENCES pubperson.source(id),
 fullname text,
 vatid bigint,
 info JSONb
);
CREATE INDEX idx_fullname ON pubperson.person (fullname);




CREATE MATERIALIZED VIEW pubperson.kx_firstname AS
 SELECT regexp_replace(fullname,'\s.+$', '') AS word, 
        count(*) AS freq
 FROM pubperson.br_tse_person
 GROUP BY 1
 ORDER BY 1
;
CREATE INDEX idx_firstname ON pubperson.kx_firstname (word);


INSERT INTO pubperson.source (label,info) 
   SELECT 'br:tse:'||regexp_replace(filename, '\.\w\w\w\w?$', ''), 
          jsonb_build_object('id',id, 'urlref',urlref, 'file',filename)
   FROM temp1;

INSERT INTO pubperson.person (fullname,info) 
   SELECT name, 
          jsonb_build_object( 'bdate',bdate, 'fonte_id',fonte_id,  'year',year, 'state',state, 'cpf',cpf,  'cpfcheck',verify_cpf(cpf) )
   FROM temp2;
-- need some minutes
