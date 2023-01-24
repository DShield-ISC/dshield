CONTAINER_NAME := $(or $(CONTAINER_NAME), 'sans-isc-agent')
IMAGE_NAME := $(or $(IMAGE_NAME), 'isc-agent-sans-isc-agent')
PWD := $(or $(PWD), `pwd`)
#Example for Windows: make project PWD=%cd%
#Example for Mac: not necessary to pass in PWD since it defaults correctly

.DEFAULT:
	echo Uh oh! The target does not exist.

.SILENT:

.PHONY: docker-build db
docker-build db:
	docker compose build sans-isc-agent

.PHONY: docker-down dd
docker-down dd:
	docker compose down --remove-orphans

.PHONY: docker-up du
docker-up du:
	docker compose up

.PHONY: docker-up-and-build dub
docker-up-and-build dub:
	docker-compose up --build

.PHONY: docker-up-detached dud
docker-up-detached dud:
	docker compose up -d

.PHONY: install-dev-package idp
install-dev-package idp:
	docker run -v $(PWD):/opt/sans-isc-agent --rm $(IMAGE_NAME) sh -c "pipenv install --dev $$PACKAGE"
	$(MAKE) docker-down
	$(MAKE) docker-up-and-build

.PHONY: install-prod-package ipp
install-prod-package ipp:
	docker run -v $(PWD):/opt/sans-isc-agent --rm $(IMAGE_NAME) sh -c "pipenv install $$PACKAGE"
	$(MAKE) docker-down
	$(MAKE) docker-up-and-build

.PHONY: lint l
lint l:
	docker run -v $(PWD):/opt/sans-isc-agent --rm $(IMAGE_NAME) sh -c "pylint main.py ./plugins"

.PHONY: security sec
security sec:
	docker run -v $(PWD):/opt/sans-isc-agent --rm $(IMAGE_NAME) sh -c "bandit -r ."

.PHONY: shell s
shell s:
	docker compose exec -it $(CONTAINER_NAME) sh

.PHONY: test t
test t:
	docker run -v $(PWD):/opt/sans-isc-agent --rm $(IMAGE_NAME) sh -c "coverage run --rcfile=./.coveragerc && cd .generated/coverage && coverage html"

.PHONY: test-path tp
test-path tp:
	docker run -v $(PWD):/opt/sans-isc-agent --rm $(IMAGE_NAME) sh -c "pytest --disable-warnings -v $$TP"

.PHONY: test-run-failed trf
test-run-failed trf:
	docker run -v $(PWD):/opt/sans-isc-agent --rm $(IMAGE_NAME) sh -c "pytest --disable-warnings -v --last-failed"

############# DevSecOps Targets #############
.PHONY: ops-scan
ops-scan:
	$(MAKE) docker-build
	$(MAKE) lint
	$(MAKE) security
	$(MAKE) test
	echo "ALL GOOD!"
