## see tse-README.md

python tse-mk01-getZips.py # or run only, in background "&"

recode ISO-8859-1..UTF-8 *.txt # or &

echo 'run after PubPerson schema initicalization, and supply password. Wait 1h'
psql -h localhost -U postgres datasets_br < tse-mk02-inserts.sql

