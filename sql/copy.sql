SET client_min_messages TO WARNING;

/**
 * This should run with the variables
 * :region (e.g. ny, ca)
 * :schema (e.g. oa)
 * :file (e.g. openaddr-collected-us_west.zip)
 * :zip (e.g. us/ca/city_of_lancaster.csv)
 */
SELECT 'addresses_' || md5(now()::text) as table
\gset

CREATE TABLE :"table" (LIKE :schema.address EXCLUDING CONSTRAINTS EXCLUDING INDEXES);
ALTER TABLE :"table" ALTER COLUMN hash DROP NOT NULL;

SELECT format(
  '\copy %s (lon, lat, number, street, unit, city, district, region, postcode, id, hash) FROM PROGRAM ''unzip -p %s %s'' CSV HEADER',
  :'table', :'zip', :'file'
  ) as command
\gset

:command

INSERT INTO :schema.address
  (lon, lat, number, street, unit, city, district, postcode, id, hash, geom, region)
  SELECT lon, lat, number, street, unit, city, district, postcode, id
    , coalesce(hash, substring(md5(concat(number, street, unit, city, district, postcode)), 1, 16)) as hash
    , ST_setsrid(ST_makepoint(lon, lat), 4326) as geom
    , coalesce(region, upper(:'region')) as region
  FROM :"table"
  ON CONFLICT (hash) DO NOTHING;

DROP TABLE :"table";
