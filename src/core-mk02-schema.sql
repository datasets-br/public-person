/**
 * Prepare of the PubPerson database and its specialized library.
 * Starter script (danger purge all!).
 * @version 1.0.0
 * @see https://github.com/datasets-br/public-person
 */

DROP schema IF EXISTS pubperson CASCADE;
CREATE schema pubperson;


/**
 * Catalogue of source's metadata.
 */
CREATE TABLE pubperson.source (
 id bigserial NOT NULL PRIMARY KEY,
 label text,    -- URN starting with country code.
 info JSONb,    -- all other info
 UNIQUE(label)
);

/**
 * Main table, person's data.
 */
CREATE TABLE pubperson.person (
 id bigserial NOT NULL      PRIMARY KEY,
 source_id bigint NOT NULL  REFERENCES pubperson.source(id),
 name text NOT NULL,        -- https://schema.org/name
 vatid_cpf bigint,          -- https://schema.org/vatID
 birthDate date NOT NULL,   -- https://schema.org/birthDate
 info JSONb,                -- all other info
 UNIQUE(birthDate,name),
 UNIQUE(vatid_cpf)
);
CREATE INDEX idx_fullname ON pubperson.person (name);

-- -- -- --
-- -- -- --
-- -- -- --

/**
 * Auxiliar cache, for person's first-name frequency analysis.
 */
CREATE MATERIALIZED VIEW pubperson.kx_firstname AS
 SELECT regexp_replace(name,'\s.+$', '') AS word,
        count(*) AS freq
 FROM pubperson.person
 GROUP BY 1
 ORDER BY 1
;
CREATE INDEX idx_firstname ON pubperson.kx_firstname (word);


CREATE VIEW pubperson.vw_csv_source AS
  SELECT
    id as source_id,
    label as urn,
    info->>'data_item' as data_item,
    info->>'isBasedOnUrl' as "isBasedOnUrl"
  FROM pubperson.source
  ORDER BY 1
;

CREATE MATERIALIZED VIEW pubperson.vw_source_freq AS
 SELECT  unnest(lib.jsonb_array2ints(info->'source_ids')) as source_id,
         count(id) as n
 FROM pubperson.person group by 1 order by 2 DESC
; -- select v.*, s.label FROM pubperson.vw_source_freq v INNER JOIN pubperson.source s ON s.id=v.src order by n;

-- -- -- --
-- -- -- --
-- -- -- --

/**
 * Updates serial ID of a table.
 * @return table of file names.
 */
CREATE OR REPLACE FUNCTION pubperson.mk_csv(
  _cmd text,   -- command
  _path text DEFAULT NULL -- target path or file
) RETURNS void AS $f$
DECLARE
  cp text;
  ipath text;
  src record;
BEGIN
  IF  _cmd='source' THEN -- -- -- --
      IF _path IS NULL THEN _path := '/tmp/sources.csv'; END IF;
      EXECUTE format(E'
        COPY (SELECT * FROM pubperson.vw_csv_source) TO %L WITH CSV HEADER
      ', _path);
      RAISE NOTICE 'COPY source TO %', _path;
  ELSIF _cmd='person' THEN -- -- -- --
      IF _path IS NULL THEN _path := '/tmp'; END IF;
      FOR src IN
        SELECT * FROM pubperson.source WHERE info->'data_item' IS NOT NULL
      LOOP
        ipath := _path || '/persons-src' || src.id || '.csv';
        EXECUTE format('
          COPY (
            SELECT name, birthDate, vatID_cpf as "vatID_cpf"
            FROM pubperson.person
            WHERE source_id=%s
            ORDER BY 1,2
          ) TO %L WITH CSV HEADER
        ', src.id, ipath);
        RAISE NOTICE 'COPY person TO %', ipath;
      END LOOP;
  ELSE
      RAISE EXCEPTION 'COMADO DESCONHECIDO';
  END IF;
END
$f$ language PLpgSQL;
