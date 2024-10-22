/**
 * Library of selected util functions for pubperson schema.
 * @version 1.0.0
 * @see https://github.com/datasets-br/public-person
 */

CREATE EXTENSION IF NOT EXISTS PLpythonU;

-- -- -- --
CREATE schema IF NOT EXISTS lib;

/**
 * Get all CSV file.
 * @return table of text-array.
 */
CREATE OR REPLACE FUNCTION lib.get_csvfile(
  file text,                 -- the complete path with file name (eg. '/tmp/my.csv')
  delim_char char(1) = ',',  -- filed separator
  quote_char char(1) = '"'   -- quotation
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

/**
 * Check CPF (last two digits of check).
 * @return string NULL or CPF.
 */
CREATE OR REPLACE FUNCTION lib.cpf_whengood(
  cpf text -- a 11-digits only string
) RETURNS text AS $f$
    if (not cpf) or (len(cpf) < 11):
        return None
    inteiros = map(int, cpf)
    novo = inteiros[:9]
    while len(novo) < 11:
        r = sum([(len(novo)+1-i)*v for i,v in enumerate(novo)]) % 11
        if r > 1:
            f = 11 - r
        else:
            f = 0
        novo.append(f)
    if novo == inteiros:
        return cpf
    return None
$f$ immutable language PLpythonU;

/**
 * List a filesystem's folder content.
 * @return table of file names.
 */
CREATE OR REPLACE FUNCTION lib.csv_scan_sources(
   filepath text  -- something as '/tmp/test/*.txt'
) RETURNS setof text  AS $f$
  import glob
  return sorted(glob.glob(filepath))
$f$ immutable language PLpythonU;

/**
 * Updates serial ID of a table.
 * @return table of file names.
 */
CREATE OR REPLACE FUNCTION lib.set_serial_tomax(
  tname text,   -- table name
  id_name text  -- field name of ID
) RETURNS void AS $f$
BEGIN
      EXECUTE format(
        'SELECT setval(pg_get_serial_sequence(%L, %L), coalesce(max(%s),0) + 1, false) FROM %s;',
        tname, id_name, id_name, tname
      );
END
$f$ language PLpgSQL;

/**
 * Reduce an array to the selected indexes.
 * @return array.
 */
CREATE OR REPLACE FUNCTION lib.array_select_idx(
   anyarray,     -- input array
   idxs int[]  -- the indexes to be selected
) RETURNS anyarray  AS $f$
   SELECT array_agg(x)
   FROM (
     SELECT $1[x] AS x FROM unnest($2) t(x)
   ) t2;
$f$ immutable language SQL;

--- ---- -----

/**
 * Extracts Brazilian's birth day from a "old standard" string.
 * @return integer array of day-month-year.
 */
CREATE OR REPLACE FUNCTION lib.parse_birth_br(
  text   -- input string
) RETURNS int[] AS $f$
	SELECT CASE WHEN dia>0 AND dia<31 AND mes>0 AND mes<13 AND ano < EXTRACT(YEAR FROM now()) THEN array[dia,mes,ano] ELSE array[]::int[] END as d
	FROM (
	  SELECT
	    d[1]::int as dia,
	    COALESCE(  d[2],  ('{"JAN":1,"FEV":2,"MAR":3,"ABR":4,"MAI":5,"JUN":6,"JUL":7,"AGO":8,"SET":9,"OUT":10,"NOV":11,"DEZ":12}'::JSON)->>upper(substr(d[3],1,3))  )::int as mes,
	    COALESCE(  d[4]::int, 1900+d[5]::int ) as ano
	  FROM regexp_matches($1,'^\s*(\d\d)[\-/]?(?:(\d\d)|([A-Za-z]+))[\-/]?(?:(\d\d\d\d)|(\d\d))\s*$') t(d)
	) t2
	;
$f$ immutable language SQL;

/**
 * Extracts Brazilian's birth day from a "old standard" string.
 * Uses lib.parse_birth_br().
 * @return date internal format.
 */
CREATE OR REPLACE FUNCTION lib.parse_birth_br2iso(text) RETURNS date AS $f$
DECLARE
  aux text;
BEGIN
	SELECT CASE WHEN
		array_length(d,1) IS NULL THEN NULL::text
		ELSE format('%s-%s-%s',d[3],d[2],d[1])
	       END INTO aux
	FROM lib.parse_birth_br($1) t(d);
	RETURN aux::date;
	EXCEPTION WHEN others THEN   -- avoids out of range as 1963-2-29
		RETURN NULL::date;
END;
$f$ immutable language PLpgSQL;

/**
 * Reduce to distincts and sort an array.
 */
CREATE OR REPLACE FUNCTION lib.array_distinct(
      anyarray,             -- input array
      boolean DEFAULT false -- flag to ignore nulls
) RETURNS anyarray AS $f$
      SELECT array_agg(DISTINCT x ORDER BY x)  -- sorts also with no orderBy
      FROM unnest($1) t(x)
      WHERE CASE WHEN $2 THEN x IS NOT NULL ELSE true END;
$f$ LANGUAGE SQL IMMUTABLE;

------

CREATE or replace function lib.jsonb_array2ints(jsonb)
    returns int[]
    language sql
as $f$
	SELECT array_agg(x::int)
	FROM jsonb_array_elements_text($1) t(x)
$f$;

CREATE or replace function lib.jsonb_array2texts(jsonb)
    returns text[]
    language sql
as $f$
	SELECT array_agg(x::text)
	FROM jsonb_array_elements_text($1) t(x)
$f$;
