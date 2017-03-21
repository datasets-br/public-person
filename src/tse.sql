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

CREATE FUNCTION lib.csv_scan_sources(
   filepath text  -- something as '/tmp/test/*.txt'
) RETURNS setof text  AS $f$
  import glob
  return sorted(glob.glob(filepath))
$f$ immutable language PLpythonU;

CREATE or replace FUNCTION lib.set_serial_tomax(
  tname text, id_name text
) RETURNS void AS $f$
BEGIN
      EXECUTE format(
        'SELECT setval(pg_get_serial_sequence(%L, %L), coalesce(max(%s),0) + 1, false) FROM %s;',
        tname, id_name, id_name, tname
      );
END
$f$ language PLpgSQL;

CREATE FUNCTION lib.array_select_idx(
   text[],   -- input array
   idxs int[]  -- the indexes to be selected
) RETURNS text[]  AS $f$
   SELECT array_agg(x)
   FROM (
     SELECT $1[x] AS x FROM unnest($2) t(x)
   ) t2;
$f$ immutable language SQL;


-- -- -- -- -- -- --

CREATE VIEW pubperson.vw_tmp_sources AS
  SELECT row_number() OVER () as id, regexp_matches(item, '(\d\d\d\d)_(..).txt$') as ano_uf, *
  FROM lib.csv_scan_sources('/tmp/TSE/consulta_cand*.*') t(item)
  ORDER BY item;

CREATE TABLE pubperson.source (
 id bigserial NOT NULL PRIMARY KEY,
 label text,
 country char(2) NOT NULL DEFAULT 'br',
 info JSONb,
 UNIQUE(label)
);

INSERT INTO pubperson.source(id,label,info)
  SELECT id, 
         'br;'|| lower(ano_uf[2]) ||':tse:candidatos:'||ano_uf[1] AS label, 
         jsonb_build_object(
             'year',ano_uf[1],          'country','BR', 
             'state',ano_uf[2],         'file',item,
             'isBasedOnUrl','http://www.tse.jus.br/eleicoes/estatisticas/repositorio-de-dados-eleitorais'
         )
   FROM pubperson.vw_tmp_sources
;
SELECT lib.set_serial_tomax('pubperson.source','id');


CREATE TABLE pubperson.person (
 id bigserial NOT NULL PRIMARY KEY,
 source_id bigint REFERENCES pubperson.source(id),
 fullname text,
 vatid bigint,
 info JSONb
);
CREATE INDEX idx_fullname ON pubperson.person (fullname);

-- select id,label, (info->>'year')::int as year, s.info->>'file' as filename 
-- from pubperson.source;

-- nao funciona info->>'year' < to_jsonb(2004)

-- process "Killed"! reduzir por blocos range de id.

-- good:
--SELECT lib.array_select_idx(c,array[2,5,10,26,27])  
--FROM lib.get_csvfile('/tmp/TSE/consulta_cand_1994_RS.txt', ';') t(c), pubperson.source s;

-- working: to insert into pubperson.person
--SELECT  lib.array_select_idx(c,array[2,5,10,26,27])
--FROM pubperson.source s, LATERAL lib.get_csvfile(s.info->>'file') g(c)
--WHERE s.id>100 AND s.id<110;

SELECT  s.label, lib.array_select_idx(c,array[2,5,10,26,27])
FROM pubperson.source s, LATERAL lib.get_csvfile(s.info->>'file',';') g(c)
WHERE s.id>0 AND s.id<10;




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
