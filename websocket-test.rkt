#lang racket
(require web-server/http)
(require net/rfc6455)
(require net/url)

(define WS_URL (string->url "ws://localhost:8080/"))

(define (connect id)
  (ws-connect WS_URL #:headers `(,(header #"namespace" (string->bytes/utf-8 id)))))


(define c (connect "banana"))
(thread (λ () (displayln (sync (ws-recv-evt c)))))
(ws-send! c "Hello world!")