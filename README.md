**public-person dataset**:  identifying unically Brazilian public persons.

Semantic as [schema.org](http://schema.org/docs/schemas.html) (`sc`) complemented by [Wikidata](https://www.wikidata.org) (`wd`):

* **name** as [sc:Person](https://schema.org/Person)/[sc:name](https://schema.org/name) (full name).

* **vatID-cpf** as [sc:Person](https://schema.org/Person)/[sc:vatID](https://schema.org/vatID) specialized as [wd:cadastroPessoasFísicas](https://www.wikidata.org/wiki/Q5016244).


The main source for "valid public names" (and license to use here) are the Brazilians [Official Gazettes](https://en.wikipedia.org/wiki/Government_gazette).

## Data sources

Data comes from multiple sources as follows:

... TSE ... See [datapackage.json](datapackage.json)...

## Preparation

This package includes SQL scripts to fetch information and filter it.

...

### data/tse-*.csv

... Run script ... see also [rafonseca/tse-data/collect_and_make_csv.ipynb](https://github.com/rafonseca/tse-data/blob/master/collect_and_make_csv.ipynb) data analysis.

### data/xxx*.csv
...

## License

This material is licensed by its maintainers under the Public Domain Dedication
and License.

Nevertheless, it should be noted that this material is ultimately sourced from TSE, ....
