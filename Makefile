NAME		:= inception
COMPOSE_FILE	:= srcs/docker-compose.yml
DATA_DIR	:= /home/kinamura/data

.PHONY: all build up down clean fclean re logs status help

all: build up

build:
	@echo "Building $(NAME) images..."
	@mkdir -p $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb
	@docker compose -f $(COMPOSE_FILE) build

up:
	@echo "Starting $(NAME) services..."
	@docker compose -f $(COMPOSE_FILE) up -d
	@docker compose -f $(COMPOSE_FILE) ps

down:
	@echo "Stopping $(NAME) services..."
	@docker compose -f $(COMPOSE_FILE) down

clean: down
	@echo "Removing volumes..."
	@docker compose -f $(COMPOSE_FILE) down -v

fclean: clean
	@echo "Removing all images and pruning system..."
	@docker compose -f $(COMPOSE_FILE) down --rmi all -v 2>/dev/null || true
	@docker system prune -af
	@sudo rm -rf $(DATA_DIR)/wordpress/* $(DATA_DIR)/mariadb/* 2>/dev/null || true

re: fclean all

logs:
	@docker compose -f $(COMPOSE_FILE) logs -f

status:
	@docker compose -f $(COMPOSE_FILE) ps

help:
	@echo "Inception Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  all     - Build and start all services (default)"
	@echo "  build   - Build Docker images"
	@echo "  up      - Start services"
	@echo "  down    - Stop services"
	@echo "  clean   - Stop services and remove volumes"
	@echo "  fclean  - Full clean (volumes + images + data dir)"
	@echo "  re      - Rebuild from scratch"
	@echo "  logs    - Follow logs"
	@echo "  status  - Show service status"
