#lang racket
(require web-server/http)
(require net/rfc6455)
(require net/url)

(define WS_URL (string->url "wss://drracket-code-sync.ue.r.appspot.com/"))

(define (connect id)
  (ws-connect WS_URL #:headers `(,(header #"namespace" (string->bytes/utf-8 id)))))


(define c (connect "banana"))
(define (queue)
  (thread (λ () (let [(res (sync (ws-recv-evt c)))]
                  (when res (displayln res)
                  (queue))))))


;(queue)
(ws-send! c "This should just work, at least on the recieving end")

