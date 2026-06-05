FROM golang:1.26-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . .

ARG VERSION=dev
ARG COMMIT=none
ARG BUILD_DATE=unknown

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w -X 'main.Version=${VERSION}' -X 'main.Commit=${COMMIT}' -X 'main.BuildDate=${BUILD_DATE}'" -o ./CLIProxyAPI ./cmd/server/

FROM alpine:3.23

RUN apk add --no-cache tzdata ca-certificates && \
    rm -rf /var/cache/apk/*

RUN mkdir -p /CLIProxyAPI /root/.cli-proxy-api /CLIProxyAPI/logs

COPY --from=builder /app/CLIProxyAPI /CLIProxyAPI/CLIProxyAPI

COPY config.example.yaml /CLIProxyAPI/config.example.yaml
COPY config.yaml /CLIProxyAPI/config.yaml

WORKDIR /CLIProxyAPI

EXPOSE 8317

ENV TZ=Asia/Shanghai

RUN cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo "${TZ}" > /etc/timezone && \
    rm -rf /usr/share/zoneinfo

CMD ["./CLIProxyAPI"]
