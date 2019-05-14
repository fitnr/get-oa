CREATE SCHEMA IF NOT EXISTS :schema;

CREATE TABLE IF NOT EXISTS :schema.address (
    lon numeric,
    lat numeric,
    number text,
    street text,
    unit text,
    city text,
    district text,
    region text,
    postcode text,
    id text,
    hash text primary key,
    geom Geometry(Point,4326)
);

CREATE INDEX IF NOT EXISTS address_geom_idx ON :schema.address USING GIST (geom);

CREATE OR REPLACE FUNCTION :schema.oa_add_geom()
  RETURNS TRIGGER AS $$
  BEGIN 
  NEW.geom := ST_setsrid(ST_makepoint(NEW.lon, NEW.lat),4326);
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS oa_add_geom ON :schema.address;

CREATE TRIGGER oa_add_geom
  BEFORE INSERT OR UPDATE ON :schema.address
  FOR EACH ROW
  WHEN (NEW.GEOM IS NULL)
  EXECUTE PROCEDURE :schema.oa_add_geom();
