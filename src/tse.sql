CREATE EXTENSION IF NOT EXISTS PLpythonU;

-- -- -- --
CREATE schema IF NOT EXISTS lib;

CREATE FUNCTION lib.get_csvfile(
  file text,
  delim_char char(1) = ',',
  quote_char char(1) = '"'
) RETURNS setof text[]  AS $f$
  import csv
  return csv.reader(
     open(file, 'rb'), 
     quotechar=quote_char, 
     delimiter=delim_char, 
     skipinitialspace=True, 
     escapechar='\\'
  )
$f$ immutable language PLpythonU;
-- for lib.get_csvline() see http://stackoverflow.com/a/42929480/287948

CREATE or replace FUNCTION lib.csv_scan_sources(
   filepath text  -- something as '/tmp/test/*.txt'
) RETURNS text[]  AS $f$
  import glob
  # import numpy as np
  #np.asarray( sorted(glob.glob(filepath)) )
  dataset_list = ';'.join(sorted(glob.glob(filepath)))
  dataset_array = []
  for item in dataset_list.split(';'): # comma, or other
     dataset_array.append(item)
  dataset_array
$f$ immutable language PLpythonU;


-- -- -- -- -- -- --

select x from unnest( lib.csv_scan_sources('/tmp/TSE2/*.txt') ) t(x);


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
