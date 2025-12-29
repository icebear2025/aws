FROM alpine:latest AS builder
WORKDIR /build
RUN apk add --no-cache curl
COPY product .
RUN chmod +x product

FROM scratch
WORKDIR /app
COPY --from=builder /build/product .
CMD ["./product"]