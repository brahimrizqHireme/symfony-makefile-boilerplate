DOCKER_COMPOSE      = docker-compose
CONTAINER_PHP       = sf4_php
CONTAINER_PHP_USER  = dev
CONTAINER_PHP_PATH  = /home/wwwroot/sf4

EXEC_PHP            = docker exec -it -u $(CONTAINER_PHP_USER) $(CONTAINER_PHP) sh -c "cd $(CONTAINER_PHP_PATH) &&
EXEC_PHP_AS_ROOT    = docker exec -it -u 0 $(CONTAINER_PHP) sh -c "cd $(CONTAINER_PHP_PATH) &&

SYMFONY             = $(EXEC_PHP) bin/console
COMPOSER            = $(EXEC_PHP) composer
NPM                 = $(EXEC_PHP) npm
FIXER               = $(EXEC_PHP) vendor/bin/php-cs-fixer


##
## --------------
PROJET: ## PROJET
------: ## ------

install: ## Install and start the complete project (for the first time)
install: .env build start assets dbinit fixture dbsetup cache permission

run: ## Install and start the project
run: .env start db cache permission watch

kill: ## Down the project
	$(DOCKER_COMPOSE) kill
	$(DOCKER_COMPOSE) down --volumes --remove-orphans

clean: ## Stop the project and remove generated files
clean: kill
	rm -rf .env vendor node_modules

reset: ## Stop and remove generated files and start a fresh install of the project
reset: clean install

.PHONY: install run kill clean reset


##
## ------------
DOCKER: ## DOCKER
-----: ## -----

build: ## Build your Docker
	$(DOCKER_COMPOSE) build 

start: ## Start the project
	$(DOCKER_COMPOSE) up -d --remove-orphans --no-recreate

stop: ## Stop the project
	$(DOCKER_COMPOSE) stop

.PHONY: build start stop


##
## ------------
TOOLS: ## TOOLS
-----: ## -----

dbinit: ## Remove and install the Database
dbinit: vendor .env
	$(SYMFONY) doctrine:schema:drop --force"
	$(SYMFONY) doctrine:schema:create"
	$(SYMFONY) doctrine:schema:update --force"

dbsetup: ## Remove and install the Database
dbsetup: dbinit
	$(SYMFONY) app:setup"

db: ## Update the Database
db: vendor .env
	$(SYMFONY) doctrine:schema:update --force"

fixer: ## Launch the PHP-CS-Fixer
	$(FIXER) fix"

fixture: ## Import fixtures in the project
	$(SYMFONY) doctrine:fixtures:load"

cache: ## Reset the server cache
	$(SYMFONY) cache:war --no-debug"

permission: ## Reset the server cache
	$(EXEC_PHP_AS_ROOT) chown -Rf www-data:www-data var"
	$(EXEC_PHP_AS_ROOT) chmod -Rf 777 var"

migration: ## Generate a new doctrine migration
migration: vendor
	$(SYMFONY) doctrine:migrations:diff"

assets: ## Run Webpack Encore to compile assets
assets: node_modules
	$(NPM) run dev"

watch: ## Run Webpack Encore in watch mode
watch: node_modules
	$(NPM) run watch"

.PHONY: db fixer fixture cache migration assets watch


# rules based on files
vendor: composer.json
	$(COMPOSER) install"

node_modules: package.json
	$(NPM) install"

.env: .env.dist
	@if [ -f .env ]; \
	then\
		echo '\033[1;41m/!\ The .env.dist file has changed. Please check your .env file (this message will not be displayed again).\033[0m';\
		touch .env;\
		exit 1;\
	else\
		echo cp .env.dist .env;\
		cp .env.dist .env;\
	fi

.DEFAULT_GOAL := help
help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'
.PHONY: help
