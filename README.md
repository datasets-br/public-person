**public-person dataset**:  identifying unically Brazilian public persons.

&nbsp;&nbsp;&nbsp;&nbsp; ![](docs/assets/datasets-public-person-logo-v1-180px.png)

Semantic as [schema.org](http://schema.org/docs/schemas.html) (`sc`) complemented by [Wikidata](https://www.wikidata.org) (`wd`):

* **name** as [sc:Person](https://schema.org/Person)/[sc:name](https://schema.org/name) (full name).

* **vatID-cpf** as [sc:Person](https://schema.org/Person)/[sc:vatID](https://schema.org/vatID) specialized as [wd:cadastroPessoasFísicas](https://www.wikidata.org/wiki/Q5016244).


The main source for "valid public names" (and license to use here) are the Brazilians [Official Gazettes](https://en.wikipedia.org/wiki/Government_gazette).

## Data sources and preparation

Data comes from multiple sources as follows:

* TSE - Tribunal Superior Eleitoral. [Preparation here](src/tse-README.md). Produces `data/tse-*.csv` files and/or SQL.
* ...

For CSV files description, see [datapackage.json](datapackage.json).

## License

This material is licensed by its maintainers under the Public Domain Dedication
and License.

Nevertheless, it should be noted that this material is ultimately sourced from TSE, ....
