SET client_min_messages TO WARNING;

-- workaround to use :region in the function definition
SELECT format('CREATE OR REPLACE FUNCTION %1$s.oa_add_region()
  RETURNS TRIGGER AS $$
  BEGIN NEW.region := ''%2$s'';
  RETURN NEW;
  END; $$ LANGUAGE plpgsql STABLE;', :'schema', :'region') AS function
\gset

:function

DROP TRIGGER IF EXISTS oa_set_region ON :schema.address;

CREATE TRIGGER oa_set_region
  BEFORE INSERT OR UPDATE ON :schema.address
  FOR EACH ROW
  WHEN (NEW.region IS NULL OR NEW.region = '')
  EXECUTE PROCEDURE :schema.oa_add_region();
