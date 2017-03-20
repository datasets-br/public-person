### adapted from https://github.com/rafonseca/tse-data/blob/master/collect_and_make_csv.ipynb
### USAGE: python tse-getZips.py &


import urllib
import zipfile
import os
import errno


## Config:
tse_baseUrl = 'http://agencia.tse.jus.br/estatistica/sead/odsele/consulta_cand/'
tmp_folder = '/tmp/tse_transfer/' # must be at /tmp


## make TEMP folder:
try:
    os.makedirs(tmp_folder)
except OSError as exc:
    if exc.errno == errno.EEXIST and os.path.isdir(tmp_folder):
        print "\n Plese remove folder with command: rm -r ",tmp_folder
        os._exit(1)


## Download files:
for year in range(1994,2017,2):
    filename='consulta_cand_'+str(year)+'.zip'
    print filename
    urllib.urlretrieve(tse_baseUrl+filename,filename=tmp_folder+filename)

## Unzip downloaded files:
for year in range(1994,2017,2): # or 2004
    filename='consulta_cand_'+str(year)+'.zip'
    zip_ref = zipfile.ZipFile(tmp_folder+filename, 'r')
    zip_ref.extractall(tmp_folder)
    zip_ref.close()
