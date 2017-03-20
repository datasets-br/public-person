
## TSE data preparation

Source data at http://agencia.tse.jus.br/estatistica/sead/odsele/consulta_cand/


```sh
python tse-getZips.py # or run in background "&"

recode ISO-8859-1..UTF-8 *.txt # or &

python tse-makeCSV.py

psql -h localhost -U postgres restest < tse.sql # wait 1h
```

There are 3520846 full-names, but 1492419 distinct. There are some little of names with problems, as  "0DÁRICO", "0SEAS", and "ABRRAÃO".

