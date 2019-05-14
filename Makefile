SHELL = bash

psql = psql

schema = oa

FILES =

space = $() $()

.PHONY: default load load-% init clean

default: load

# Load a file inside the zip without unzipping the whole thing
# command has the format load-COUNTRY/REGION/file.csv
define load_recipe
$(addprefix load-,$(1)): load-%.csv: $(2)
	$$(eval region := $$(word 2,$$(subst /,$(space),$$(*D))))
	$(psql) -q -v schema=$(schema) -v region=$$(region) -f sql/trigger-region.sql
	$(psql) -c "\copy oa.address (lon, lat, number, street, unit, city, district, region, postcode, id, hash) \
	FROM PROGRAM 'unzip -p $$< $$*.csv' CSV HEADER"
	$(psql) -q -c "DROP TRIGGER IF EXISTS oa_set_region ON $(schema).address;"
endef

# get the CSV files in a single zip
get_csv = $(shell unzip -qq -l $(1) *.csv | grep -ve'-summary.csv' | awk '{ print $$4 }')

# define a csv_FILE variable for each of the input files
$(foreach f,$(FILES),$(eval csv_$f := $(call get_csv,$f)))

# define the load task for each file, dependent on the input zip
$(foreach f,$(FILES),$(eval $(call load_recipe,$(csv_$f),$f)))

# define the top-level load task
load: $(foreach f,$(FILES),$(addprefix load-,$(csv_$f)))

init: ; $(psql) -v schema=$(schema) -f sql/init.sql

clean: ; $(psql) -c "drop table if exists $(schema).address;"