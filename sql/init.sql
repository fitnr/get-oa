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
