/**
 * TSE inserts for PubPerson.
 * run after core.
 * @version 1.0.0
 * @see https://github.com/datasets-br/public-person
 */


/**
 * Scans all CSV filenames and show its properties.
 */
DROP VIEW IF EXISTS pubperson.vw_tmp_sources;
CREATE VIEW pubperson.vw_tmp_sources AS
  SELECT row_number() OVER () as id,
         'br'::text as country,
         'tse'::text as authority,
         'candidatos'::text as data_group,
         regexp_matches(item, '(\d\d\d\d)_(..).txt$') as ano_uf,
         regexp_replace(item,'^.+/','') as item  -- only filename
  FROM lib.csv_scan_sources('/tmp/tse_transfer/consulta_cand*.*') t(item)
  ORDER BY item;

/**
 * Metadata of all TSE official sources.
 */
INSERT INTO pubperson.source(id,label,info)
  SELECT id,
         -- URN jurisdiction:autority:data_group:item
         format('%s:%s:%s:%s', lower(country), authority||';'||lower(ano_uf[2]), data_group, ano_uf[1]) as label,
         jsonb_build_object(
             'year',ano_uf[1],             'country',upper(country),
	     'authority',authority,        'data_group',data_group,
             'state',ano_uf[2],            'data_item',item,
             'isBasedOnUrl','http://www.tse.jus.br/eleicoes/estatisticas/repositorio-de-dados-eleitorais'
         )
   FROM pubperson.vw_tmp_sources
;
SELECT lib.set_serial_tomax('pubperson.source','id');

INSERT INTO pubperson.source(label,info) VALUES
   ('br:tse',jsonb_build_object('country','BR',  'authority','tse', 'name','Tribunal Superior Eleitoral', 'isBasedOnUrl','http://tse.jus.br'))
;


/**
 * Unify in one table all TSE official relevant data.
 */

-- get from all CSV files
DISCARD TEMPORARY;
CREATE TEMPORARY TABLE tmp_fullcheck AS
  SELECT  s.id, lib.array_select_idx(c,array[3,6,11,14,27,  15,28,31]) as c
    -- 'ANO_ELEICAO','SIGLA_UF','NOME_CANDIDATO','CPF_CANDIDATO','DATA_NASCIMENTO'
    -- 'NOME_URNA_CANDIDATO','NUM_TITULO_ELEITORAL_CANDIDATO','SEXO'
  FROM pubperson.source s, LATERAL lib.get_csvfile(s.info->>'data_item',';') g(c)
  WHERE s.id>0 AND s.id<100;  -- (WHEN LOW MEMORY) needs "where"

  -- WHEN LOW MEMORY (Python consumes a lot!) SPLIT INTO id SEGMENTS:
	INSERT INTO tmp_fullcheck(id,c)
	  SELECT  s.id, lib.array_select_idx(c,array[3,6,11,14,27,  15,28,31]) as c
	  FROM pubperson.source s, LATERAL lib.get_csvfile(s.info->>'data_item',';') g(c)
	  WHERE s.id>=100 AND s.id<200;
	INSERT INTO tmp_fullcheck(id,c)
	  SELECT  s.id, lib.array_select_idx(c,array[3,6,11,14,27,  15,28,31]) as c
	  FROM pubperson.source s, LATERAL lib.get_csvfile(s.info->>'data_item',';') g(c)
	  WHERE s.id>=200 AND s.id<280;
	INSERT INTO tmp_fullcheck(id,c)
	  SELECT  s.id, lib.array_select_idx(c,array[3,6,11,14,27,  15,28,31]) as c
	  FROM pubperson.source s, LATERAL lib.get_csvfile(s.info->>'data_item',';') g(c)
	  WHERE s.id>=280 AND s.id<400;
  -- END WHEN.


/**
 * All TSE official data into PubPerson schema.
 */
INSERT INTO pubperson.person(source_id,name,birthDate,info)
  SELECT max(id) as source_id,
         nome,
         bdate,
         jsonb_build_object(
           'source_ids',lib.array_distinct(array_agg(id)),
           'vatid_cpfs',lib.array_distinct(array_agg(cpf))
         )
  FROM (
    SELECT id, trim(c[3]) as nome,
           lib.cpf_whengood(regexp_replace(c[4],'[^\d]+','','g')) as cpf,
           lib.parse_birth_br2iso(c[5]) as bdate
    FROM tmp_fullcheck
  ) t
  WHERE cpf IS NOT NULL AND bdate IS NOT NULL -- discards invalids
  GROUP BY nome,bdate
ON CONFLICT DO NOTHING  -- discards duplications. (DANGER?)
;

-------------- ERROR
--UPDATE pubperson.person
--SET vatid_cpf = ((info->'vatid_cpfs')->>0)::bigint
--WHERE length((info->>'vatid_cpfs')::text)=15
--; -- ERROR:  duplicate key value violates unique constraint "person_vatid_cpf_key"


/**
 * After all.
 */
REFRESH MATERIALIZED VIEW pubperson.kx_firstname;

-- DROP TEMPORARY TABLE tmp_fullcheck;
