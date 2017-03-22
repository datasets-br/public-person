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

/**
 * Auxiliar cache, for person's first-name frequency analysis. 
 */
CREATE MATERIALIZED VIEW pubperson.kx_firstname AS
 SELECT regexp_replace(fullname,'\s.+$', '') AS word, 
        count(*) AS freq
 FROM pubperson.br_tse_person
 GROUP BY 1
 ORDER BY 1
;
CREATE INDEX idx_firstname ON pubperson.kx_firstname (word);


