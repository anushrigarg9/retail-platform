# Build Stage
FROM public.ecr.aws/amazonlinux/amazonlinux:2023 AS build-env

RUN dnf --setopt=install_weak_deps=False install -q -y \
    git \
    golang \
    && \
    dnf clean all

RUN mkdir -p "${GOPATH}/src" "${GOPATH}/bin" /appsrc

WORKDIR /appsrc

ENV GOPROXY=https://goproxy.io,direct

# Copy dependency files first to leverage layer caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source and build
COPY . .
RUN go build -o main main.go

# Package Stage
FROM public.ecr.aws/amazonlinux/amazonlinux:2023

RUN dnf --setopt=install_weak_deps=False install -q -y \
    shadow-utils \
    ca-certificates \
    && \
    dnf clean all

ENV APPUSER=appuser
ENV APPUID=1000
ENV APPGID=1000

RUN useradd \
    --home "/app" \
    --create-home \
    --user-group \
    --uid "$APPUID" \
    "$APPUSER"

WORKDIR /app
USER appuser

COPY --chown=appuser:appuser --from=build-env /appsrc/main /app/


COPY ./ATTRIBUTION.md ./LICENSES.md

ENV GIN_MODE=release

ENTRYPOINT ["/app/main"]
