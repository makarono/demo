# Stage 1: Build the Go binary
FROM golang:1.20-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy the Go modules files
COPY go.mod go.sum ./

# Download the Go module dependencies
RUN go mod download

# Copy the Go source code
COPY *.go ./

# Build the Go binary
RUN CGO_ENABLED=0 go build -tags netgo -ldflags '-s -w' -o consumer -buildvcs=false

# Stage 2: Create a minimal Docker image
FROM scratch

# Copy the Go binary from the builder stage
COPY --from=builder /app/consumer /

# Set the entrypoint for the Docker image
ENTRYPOINT ["./consumer"]
