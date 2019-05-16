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

\set partition :region _address

CREATE TABLE :schema.:table (LIKE :schema.:partition EXCLUDING CONSTRAINTS EXCLUDING INDEXES);
ALTER TABLE :schema.:table ALTER COLUMN hash DROP NOT NULL;

SELECT format(
  '\copy %s.%s (lon, lat, number, street, unit, city, district, region, postcode, id, hash) FROM PROGRAM ''unzip -p %s %s'' CSV HEADER',
  :'schema', :'table', :'zip', :'file'
  ) as command
\gset

:command

INSERT INTO :schema.:partition
  (lon, lat, number, street, unit, city, district, postcode, id, hash, geom, region)
  SELECT lon
    , lat
    , number
    -- remove multiple spaces in streets
    , regexp_replace(street, ' +', ' ') street
    , unit
    -- city file name if no city is given
    , coalesce(city, upper(replace(replace(:'city', '_', ' '), 'city of ', ' '))) as city
    , district
    , postcode
    , id
    -- generate a hash if none is given
    , coalesce(hash, substring(md5(concat(number, street, unit, city, district, postcode)), 1, 16)) as hash
    -- generate a geometry
    , ST_setsrid(ST_makepoint(lon, lat), 4326) as geom
    -- use region from file path. The region in each line can differ, which breaks the partitioning.
    , :'region' as region
  FROM :schema.:table
  ON CONFLICT (hash) DO NOTHING;

DROP TABLE :schema.:table;
