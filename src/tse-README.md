
## TSE-candidatos data preparation

**TSE** (Tribunal Superior Eleitoral) is a official source of data, at http://agencia.tse.jus.br/estatistica/sead/odsele/consulta_cand/

The scripts will transfer all zip files to `/tmp/tse_transfer` folder and the selected data to the PostgreSQL database. 
Use [core refresh](core-README.md) (the `python core-refresh-csv.py tse` command) to update the PubPerson's data folder with the new TSE database.

If pubpeson core was started, make all TSE preparation with `sh tse-mk00.sh`. To run in background, prefer copy/paste each line of [the shell script](tse-mk00.sh).

Tips:

* for use PostgreSQL's Python extension in UBUNTU, use `apt install postgresql-contrib postgresql-plpython`.
* The data source have problems with header, see LEIAME.pdf and complete **[the control spreadsheet](https://docs.google.com/spreadsheets/d/1FpWvyi3UTda-UOFYxshf0Vg03oYY_cSukHE6ZrGjn2w/edit#gid=1692329256)**
* ... Data of TSE is a bit dirty,
   * there are unrevised names like "0DÁRICO", "0SEAS", and "ABRRAÃO".
   * there are a lot of invalid birth dates and invalid CPF, losting records. 
* ... and the dataset description is a mess: not use CSV header, but each file needs different interpretation.

## TSE-candidatos data analysis

There are 3.5 million (3520846) data items, but many are repeated (each election year). 
The newer data are better, so, when repeat we can select only the last version.

* all (100%) have [name](https://schema.org/name) (full name) valid property.
* 59% (2081277 items) have [birthDate](https://schema.org/birthDate) valid property.
* xx% (xxx items) have [vatID](https://schema.org/vatID) (Brazilian CPF) valid property.
* There are 1492419? distinct names.
* There are 310 source files `consulta_cand*.txt`, and the its fields are not uniform. 
* Supposing uniformity, the relevant fields are at positions 3,6,11,14 and 27 (from 1), and secondary positions 15,28 and 31. Supposing corresponds respectivally to fields (of the LEIAME documentation) `ANO_ELEICAO`,`SIGLA_UF`,`NOME_CANDIDATO`,`CPF_CANDIDATO`,`DATA_NASCIMENTO`,  `NOME_URNA_CANDIDATO`,`NUM_TITULO_ELEITORAL_CANDIDATO`,`SEXO`.

Other results:
* There are some little of names with problems, as  "0DÁRICO", "0SEAS", and "ABRRAÃO", as showed by `pubperson.kx_firstname` table.
* ... Unique name-birthDate entries
* ... unique valid vatIDs

## TSE-filiados data preparation

Under construction. Not seems good data, no `birthDate` and no CPF.
Official source at  http://www.tse.jus.br/partidos/filiacao-partidaria/relacao-de-filiados

