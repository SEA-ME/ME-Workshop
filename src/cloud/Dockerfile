FROM golang:1.19-alpine

WORKDIR /app

COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY *.go ./

RUN go build -o /carsharing-app

EXPOSE 9005

CMD [ "/carsharing-app" ]