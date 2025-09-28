# Makefile for etc_data_processor

.PHONY: help test test-unit test-integration test-e2e coverage proto gen clean build run

help:
	@echo "Available commands:"
	@echo "  make test              - Run all tests"
	@echo "  make test-unit         - Run unit tests only"
	@echo "  make test-integration  - Run integration tests only"
	@echo "  make test-e2e          - Run e2e tests only"
	@echo "  make coverage          - Run tests with coverage report"
	@echo "  make coverage-html     - Generate HTML coverage report"
	@echo "  make proto             - Generate protobuf files"
	@echo "  make gen               - Generate all code (proto, mocks, etc)"
	@echo "  make build             - Build the server"
	@echo "  make run               - Run the server"
	@echo "  make clean             - Clean generated files and binaries"
	@echo "  make lint              - Run linter"
	@echo "  make fmt               - Format code"

# Test commands
test:
	@echo "Running all tests..."
	@go test -v ./tests/...

test-unit:
	@echo "Running unit tests..."
	@go test -v ./tests/unit/...

test-integration:
	@echo "Running integration tests..."
	@go test -v ./tests/integration/...

test-e2e:
	@echo "Running e2e tests..."
	@go test -v ./tests/e2e/...

# Coverage commands - excluding auto-generated files
coverage:
	@echo "Running tests with coverage..."
	@go test -coverprofile=coverage.out -coverpkg=./src/... ./tests/...
	@echo "\n=== Coverage Summary (excluding auto-generated files) ==="
	@go tool cover -func=coverage.out | grep -v ".pb.go" | grep -v "mock_" | grep -v "generated"
	@echo "\n=== Total Coverage ==="
	@go tool cover -func=coverage.out | tail -1

coverage-html:
	@echo "Generating HTML coverage report..."
	@go test -coverprofile=coverage.out -coverpkg=./src/... ./tests/...
	@go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

# Check coverage meets 100% for non-auto-generated files
coverage-check:
	@echo "Checking coverage requirements..."
	@go test -coverprofile=coverage.out -coverpkg=./src/... ./tests/... > /dev/null 2>&1
	@coverage=$$(go tool cover -func=coverage.out | grep -v ".pb.go" | grep -v "mock_" | grep -v "generated" | tail -1 | awk '{print $$3}' | sed 's/%//'); \
	if [ "$${coverage%.*}" -lt 100 ]; then \
		echo "ERROR: Coverage is $$coverage%, but 100% is required for non-auto-generated files"; \
		go tool cover -func=coverage.out | grep -v ".pb.go" | grep -v "mock_" | grep -v "generated"; \
		exit 1; \
	else \
		echo "Coverage check passed: $$coverage% ✓"; \
	fi

# Proto generation
proto:
	@echo "Generating protobuf files..."
	@protoc --go_out=. --go_opt=paths=source_relative \
		--go-grpc_out=. --go-grpc_opt=paths=source_relative \
		--grpc-gateway_out=. --grpc-gateway_opt=paths=source_relative \
		--openapiv2_out=./src/api \
		src/proto/*.proto

# Generate all code
gen: proto
	@echo "Generating mocks..."
	@go generate ./...

# Build
build:
	@echo "Building server..."
	@go build -o bin/server ./src/cmd/server

# Run
run:
	@echo "Running server..."
	@go run ./src/cmd/server

# Clean
clean:
	@echo "Cleaning..."
	@rm -rf bin/
	@rm -f coverage.out coverage.html
	@find . -name "*.pb.go" -delete
	@find . -name "*.pb.gw.go" -delete
	@find . -name "mock_*.go" -delete

# Lint
lint:
	@echo "Running linter..."
	@golangci-lint run ./src/... ./tests/...

# Format
fmt:
	@echo "Formatting code..."
	@go fmt ./src/... ./tests/...

# Install dependencies
deps:
	@echo "Installing dependencies..."
	@go mod download
	@go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	@go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
	@go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@latest
	@go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@latest
	@go install github.com/golang/mock/mockgen@latest
	@go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Development workflow shortcuts
dev-test: fmt lint test coverage-check
	@echo "All checks passed ✓"

# CI/CD commands
ci: deps gen build test coverage-check lint
	@echo "CI checks passed ✓"