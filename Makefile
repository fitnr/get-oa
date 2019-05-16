SHELL = bash
psql = psql
schema = oa
FILES =
space = $() $()

.PHONY: default load load-% init clean

default: load

region = $(word 2,$(subst /,$(space),$(1)))
city   = $(basename $(notdir $(1)))

.SECONDEXPANSION:

# Load a file inside the zip without unzipping the whole thing
# command has the format load-COUNTRY/REGION/file.csv
define load_recipe
$(addprefix load-,$(1)): load-%.csv: $(2) | region-$$$$(call region,$$$$*)
	$(psql) -f sql/copy.sql \
	-v schema=$(schema) \
	-v file=$$*.csv \
	-v region=$$(subst region-,,$$|) \
	-v city=$$(call city,$$*) \
	-v zip=$$<
endef

# get the CSV files in a single zip
get_csv = $(shell unzip -qq -l $(1) *.csv | grep -ve'-summary.csv' | awk '{ print $$4 }')

# define a csv_FILE variable for each of the input files
$(foreach f,$(FILES),$(eval csv_$f := $(call get_csv,$f)))

# define the load task for each file, dependent on the input zip
$(foreach f,$(FILES),$(eval $(call load_recipe,$(csv_$f),$f)))

region-%:
	$(psql) -c "create table if not exists $(schema).$*_address partition of $(schema).address for values in ('$*')"
	$(psql) -c "create index if not exists $*_address_geom_idx ON $(schema).$*_address using gist (geom)"
	-$(psql) -c "alter table $(schema).$*_address add primary key (hash);"

# define the top-level load task
load: $(foreach f,$(FILES),$(addprefix load-,$(csv_$f)))

init:
	$(psql) -c "create extension if not exists citext"
	$(psql) -c "create schema if not exists $(schema)"
	$(psql) -c "create table if not exists $(schema).address ( \
      lon numeric, \
      lat numeric, \
      number text, \
      street citext, \
      unit text, \
      city citext, \
      district text, \
      region citext, \
      postcode text, \
      id text, \
      hash text, \
      geom geometry(point,4326) \
    ) partition by list (region)"

clean: ; $(psql) -c "drop table if exists $(schema).address;"
