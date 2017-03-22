### make CSVs (DANGER removes the existent)
### USAGE: python tse-makeCSV.py &

import os
import csv
import glob

## configs:
tmp_folder = '/tmp/tse_transfer/' # must be at /tmp
out1 = tmp_folder+'tse-fontes.csv'
out2 = tmp_folder+'tse-FIM.csv'

## prepare output files:
os.remove(out1)
os.remove(out2)

fd1 = open(out1, 'a')  # for relative use eg. open(r'tse-fontes.csv', 'a')
writer_fontes = csv.writer(fd1, quotechar='"')  # quoting=csv.QUOTE_ALL

fd2 = open(out2, 'a')
writer = csv.writer(fd2, quotechar='"')  # quoting=csv.QUOTE_ALL

## scan input files:
id1 = 0;
for filename in sorted(glob.glob('consulta_cand_*.txt')):

       id1 = id1 + 1
       fonte = [id1,'http://agencia.tse.jus.br/estatistica/sead/odsele/consulta_cand/',filename]
       writer_fontes.writerow(fonte)

       print "\t",filename
       included_cols = [2,5,10,26,27]
       with open(filename, 'rb') as csvfile:
           allCsv = csv.reader(csvfile, delimiter=';', quotechar='"')
           for row in allCsv:
             content = list(row[i] for i in included_cols)
             content.append(id1)
             writer.writerow(content)

