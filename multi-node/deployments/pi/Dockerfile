# Builder
FROM golang:1.19

WORKDIR /go/src/app
COPY . .

RUN go build -o /go/bin/pi
 
EXPOSE 8080
CMD ["/go/bin/pi"]
