MAKEFILE_VERSION := 1.0
BANNER  = \n \033[38;5;51m██\033[38;5;240m╗\033[38;5;51m███\033[38;5;240m╗   \033[38;5;51m██\033[38;5;240m╗ \033[38;5;51m██████\033[38;5;240m╗\033[38;5;51m███████\033[38;5;240m╗\033[38;5;51m██████\033[38;5;240m╗ \033[38;5;51m████████\033[38;5;240m╗\033[38;5;51m██\033[38;5;240m╗ \033[38;5;51m██████\033[38;5;240m╗ \033[38;5;51m███\033[38;5;240m╗   \033[38;5;51m██\033[38;5;240m╗\n \033[38;5;45m██\033[38;5;239m║\033[38;5;45m████\033[38;5;239m╗  \033[38;5;45m██\033[38;5;239m║\033[38;5;45m██\033[38;5;239m╔════╝\033[38;5;45m██\033[38;5;239m╔════╝\033[38;5;45m██\033[38;5;239m╔══\033[38;5;45m██\033[38;5;239m╗╚══\033[38;5;45m██\033[38;5;239m╔══╝\033[38;5;45m██\033[38;5;239m║\033[38;5;45m██\033[38;5;239m╔═══\033[38;5;45m██\033[38;5;239m╗\033[38;5;45m████\033[38;5;239m╗  \033[38;5;45m██\033[38;5;239m║\n \033[38;5;39m██\033[38;5;238m║\033[38;5;39m██\033[38;5;238m╔\033[38;5;39m██\033[38;5;238m╗ \033[38;5;39m██\033[38;5;238m║\033[38;5;39m██\033[38;5;238m║     \033[38;5;39m█████\033[38;5;238m╗  \033[38;5;39m██████\033[38;5;238m╔╝   \033[38;5;39m██\033[38;5;238m║   \033[38;5;39m██\033[38;5;238m║\033[38;5;39m██\033[38;5;238m║   \033[38;5;39m██\033[38;5;238m║\033[38;5;39m██\033[38;5;238m╔\033[38;5;39m██\033[38;5;238m╗ \033[38;5;39m██\033[38;5;238m║\n \033[38;5;33m██\033[38;5;237m║\033[38;5;33m██\033[38;5;237m║╚\033[38;5;33m██\033[38;5;237m╗\033[38;5;33m██\033[38;5;237m║\033[38;5;33m██\033[38;5;237m║     \033[38;5;33m██\033[38;5;237m╔══╝  \033[38;5;33m██\033[38;5;237m╔═══╝    \033[38;5;33m██\033[38;5;237m║   \033[38;5;33m██\033[38;5;237m║\033[38;5;33m██\033[38;5;237m║   \033[38;5;33m██\033[38;5;237m║\033[38;5;33m██\033[38;5;237m║╚\033[38;5;33m██\033[38;5;237m╗\033[38;5;33m██\033[38;5;237m║\n \033[38;5;27m██\033[38;5;236m║\033[38;5;27m██\033[38;5;236m║ ╚\033[38;5;27m████\033[38;5;236m║╚\033[38;5;27m██████\033[38;5;236m╗\033[38;5;27m███████\033[38;5;236m╗\033[38;5;27m██\033[38;5;236m║        \033[38;5;27m██\033[38;5;236m║   \033[38;5;27m██\033[38;5;236m║╚\033[38;5;27m██████\033[38;5;236m╔╝\033[38;5;27m██\033[38;5;236m║ ╚\033[38;5;27m████\033[38;5;236m║\n \033[38;5;235m╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ \033[1;3;38;5;240mMakefile v$(MAKEFILE_VERSION)\033[0m\n

override TIMESTAMP := $(shell date +%s 2>/dev/null || echo "0")

ifneq ($(QUIET),true)
	override QUIET := false
endif

#? Docker
NAME		:= inception
DOCKER		:= docker
COMPOSE		:= docker compose
RM		:= rm -rf

#? Compose Configuration
COMPOSE_FILE	:= srcs/docker-compose.yml
ENV_FILE	:= srcs/.env
COMPOSE_FLAGS	:= -f $(COMPOSE_FILE)
SERVICES	:= nginx wordpress mariadb

#? Git and Docker info
GIT_COMMIT	:= $(shell git rev-parse --short HEAD 2>/dev/null || echo "")
DOCKER_VERSION	:= $(shell $(DOCKER) --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo "unknown")
COMPOSE_VERSION	:= $(shell $(COMPOSE) version --short 2>/dev/null || echo "unknown")

#? Detect PLATFORM and ARCH
ARCH		?= $(shell uname -m || echo unknown)

ifeq ($(shell uname -s),Darwin)
	PLATFORM	:= macOS
	THREADS		:= $(shell sysctl -n hw.ncpu || echo 1)
	DATA_DIR	:= $(HOME)/tmp/data
else
	PLATFORM	:= $(shell uname -s || echo unknown)
	THREADS		:= $(shell getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)
	DATA_DIR	:= /home/kinamura/data
endif

export DATA_DIR

#? Setup
SERVICE_COUNT	:= $(words $(SERVICES))
P		:= %%
MAKEFLAGS	+= --no-print-directory

ifeq ($(VERBOSE),true)
	override SUPPRESS :=
else
	override VERBOSE := false
	override SUPPRESS := > /dev/null 2> /dev/null
endif

#? Default Make
.ONESHELL:
all: | info build up
	@ELAPSED=$$(expr $$(date +%s 2>/dev/null || echo "0") - $(TIMESTAMP)); \
	printf "\n\033[1;92mAll services up in \033[92m(\033[97m%dm:%02ds\033[92m)\033[0m\n" \
	$$((ELAPSED / 60)) $$((ELAPSED % 60))

ifneq ($(QUIET),true)
info:
	@printf " $(BANNER)\n"
	@printf "\033[1;92mPLATFORM     \033[1;93m?| \033[0m$(PLATFORM)\n"
	@printf "\033[1;96mARCH         \033[1;93m?| \033[0m$(ARCH)\n"
	@printf "\033[1;93mDOCKER       \033[1;93m?| \033[0m$(DOCKER) \033[1;93m(\033[97m$(DOCKER_VERSION)\033[93m)\n"
	@printf "\033[1;94mCOMPOSE      \033[1;94m:| \033[0m$(COMPOSE) \033[1;94m(\033[97m$(COMPOSE_VERSION)\033[94m)\n"
	@printf "\033[1;91mCOMPOSE_FILE \033[1;91m!| \033[0m$(COMPOSE_FILE)\n"
	@printf "\033[1;95mSERVICES     \033[1;94m:| \033[0m$(SERVICES)\n"
	@printf "\033[1;96mTHREADS      \033[1;94m:| \033[0m$(THREADS)\n"
	@printf "\n\033[1;92mBuilding $(NAME) \033[91m(\033[97m$(GIT_COMMIT)\033[91m) \033[93m$(PLATFORM) \033[96m$(ARCH)\033[0m\n\n"
else
info:
	@true
endif

help:
	@printf " $(BANNER)\n"
	@printf "\033[1;97minception makefile\033[0m\n"
	@printf "usage: make [target]\n\n"
	@printf "\033[1;4mTargets:\033[0m\n"
	@printf "  \033[1mall\033[0m          Build and start all services (default)\n"
	@printf "  \033[1mdown\033[0m         Stop all services\n"
	@printf "  \033[1mclean\033[0m        Stop services and remove volumes\n"
	@printf "  \033[1mfclean\033[0m       Full clean (volumes, images, prune)\n"
	@printf "  \033[1mre\033[0m           Rebuild from scratch\n"
	@printf "  \033[1mlogs\033[0m         Follow service logs\n"
	@printf "  \033[1mstatus\033[0m       Show service status\n"
	@printf "  \033[1minfo\033[0m         Display build information\n"
	@printf "  \033[1mhelp\033[0m         Show this help message\n"

#? Create host directories for volumes
setup:
	@mkdir -p $(DATA_DIR)/wordpress
	@mkdir -p $(DATA_DIR)/mariadb

#? Build services
.ONESHELL:
build: setup
	@$(QUIET) || printf "\033[1;92mBuilding images\033[37m...\033[0m\n"
	@$(VERBOSE) || printf "$(COMPOSE) $(COMPOSE_FLAGS) build\n"
	@$(COMPOSE) $(COMPOSE_FLAGS) build || exit 1
	@printf "\033[1;92mImages built.\033[0m\n"

#? Start services
.ONESHELL:
up:
	@$(QUIET) || printf "\033[1;92mStarting services\033[37m...\033[0m\n"
	@$(VERBOSE) || printf "$(COMPOSE) $(COMPOSE_FLAGS) up -d\n"
	@$(COMPOSE) $(COMPOSE_FLAGS) up -d $(SUPPRESS) || exit 1
	@$(COMPOSE) $(COMPOSE_FLAGS) ps $(SUPPRESS) || true
	@printf "\033[1;92m$(NAME) ready \033[1;93m(\033[1;97m$(SERVICE_COUNT) services\033[1;93m)\033[0m\n"

#? Stop services
down:
	@printf "\033[1;91mStopping: \033[1;97mservices...\033[0m\n"
	@$(COMPOSE) $(COMPOSE_FLAGS) down $(SUPPRESS) || true
	@printf "\033[1;92mServices stopped.\033[0m\n"

#? Stop and remove volumes
clean:
	@printf "\033[1;91mRemoving: \033[1;97mservices and volumes...\033[0m\n"
	@$(COMPOSE) $(COMPOSE_FLAGS) down -v $(SUPPRESS) || true
	@printf "\033[1;92mClean complete.\033[0m\n"

#? Full clean (volumes + images + prune)
fclean: clean
	@printf "\033[1;91mRemoving: \033[1;97mimages...\033[0m\n"
	@$(COMPOSE) $(COMPOSE_FLAGS) down --rmi all $(SUPPRESS) || true
	@sudo rm -rf $(DATA_DIR)
	@printf "\033[1;91mPruning: \033[1;97munused Docker resources...\033[0m\n"
	@$(DOCKER) system prune -af $(SUPPRESS) || true
	@printf "\033[1;92mFull clean complete.\033[0m\n"

#? Rebuild
re: fclean
	@$(MAKE) all

#? Follow logs
logs:
	@$(COMPOSE) $(COMPOSE_FLAGS) logs -f

#? Show status
status:
	@printf " $(BANNER)\n"
	@$(COMPOSE) $(COMPOSE_FLAGS) ps

#? Non-File Targets
.PHONY: all info help setup build up down clean fclean re logs status
