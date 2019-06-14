include envs

REBAR = ./rebar3
AFLAGS = "-kernel shell_history enabled -kernel logger_sasl_compatible true"

.PHONY: rel stagedevrel package version all tree shell

all: version compile


version:
	@echo "$(shell git symbolic-ref HEAD 2> /dev/null | cut -b 12-)-$(shell git log --pretty=format:'%h, %ad' -1)" > $(APP).version


version_header: version
	@echo "-define(VERSION, <<\"$(shell cat $(APP).version)\">>)." > include/$(APP)_version.hrl


clean:
	$(REBAR) clean


rel:
	$(REBAR) release


compile:
	$(REBAR) compile


tests:
	$(REBAR) eunit


dialyzer:
	$(REBAR) dialyzer


xref:
	$(REBAR) xref


upgrade:
	$(REBAR) upgrade
	make tree


update:
	$(REBAR) update


tree:
	$(REBAR) tree | grep -v '=' | sed 's/ (.*//' > tree


tree-diff: tree
	git diff test -- tree


docs:
	$(REBAR) edoc


shell:
	ERL_AFLAGS=$(AFLAGS) $(REBAR) shell --config config/shell.config --name $(APP)$(VSN)@$(FQDN) --setcookie nk --apps $(APP)

network:
	@docker network create -d bridge $(APP)

db-start:
	@docker stop cockroach; docker rm cockroach; docker run -d --name=cockroach --hostname=cockroach --net=$(APP) -p 26257:26257 -p 8080:8080 -v "${PWD}/cockroach-data:/cockroach/cockroach-data" cockroachdb/cockroach:v2.1.0 start --insecure

db-connect:
	@docker exec -it cockroach ./cockroach sql --insecure
