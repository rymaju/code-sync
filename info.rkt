#lang info
(define collection "code-sync")
(define deps '("base" "gui-lib" "data-lib" "drracket-plugin-lib" "rfc6455" "net" "web-server-lib"))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib"))
(define scribblings '(("scribblings/code-sync.scrbl" ())))
(define pkg-desc "Fast Code Sharing for DrRacket")
(define version "0.0")
(define pkg-authors '(jung.ry@northeastern.edu))
