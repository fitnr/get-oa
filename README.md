get-oa
------

Load [OpenAddresses](openaddresses.io) data into a Postgresql + PostGIS database.

Assuming that you've downloaded one or more OpenAddresses zipped datasets:
```
export PGUSER=myuser PGHOST=myhost PGDATABASE=mydb
make init load FILES="path/to/a.zip path/to/another.zip"
```
