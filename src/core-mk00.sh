## see core-README.md

echo 'Will refresh SQL lib. Supply password.'
psql -h localhost -U postgres datasets_br < core-mk01-lib.sql

echo 'Will DROP old PubPerson schema! Supply password.'
psql -h localhost -U postgres datasets_br < core-mk02-schema.sql

