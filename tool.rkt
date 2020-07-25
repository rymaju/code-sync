#lang racket/base
(require drracket/tool
         racket/class
         racket/local
         racket/gui/base
         racket/unit
         mrlib/switchable-button
         net/rfc6455
         net/url
         web-server/http)

(provide tool@)

; This URL goes to a very simple websocket server hosted on Google Cloud Services
; Theres a link to the repo in the README
(define WS-URL (string->url "wss://drracket-code-sync.ue.r.appspot.com/"))


(define RANDOM (make-pseudo-random-generator))
(define CODE-LEN 6)
(define MAX-CODE-LEN 12)

(define (generate-random-code)
  (apply string-append (build-list CODE-LEN (lambda (x) (random-helper (random 1 36 RANDOM))))))

(define (random-helper n)
  (cond 
    [(< n 10) (number->string n)]
    [else (string (integer->char (+ 55 n)))]))

(define (connect id)
  (ws-connect WS-URL #:headers `(,(header #"namespace" (string->bytes/utf-8 id)))))

(define (anonymously-connect)
  (ws-connect WS-URL))

(define c "Disconnected")


(define tool@
  (unit
    (import drracket:tool^)
    (export drracket:tool-exports^)
 
    ; note to self, mixins are ugly: maybe i can rewrite this as a class?
    (define set-room-id-mixin
      (mixin (drracket:unit:frame<%>) ()
        (super-new)
        (inherit get-button-panel
                 get-definitions-text)
        (inherit register-toolbar-buttons)
 
        (local [

                (define id-text
                    (new message%
                        (label "Room ID: Disconnected")
                        (parent (get-button-panel))))

                (define (queue-thread)
                  (when (ws-conn? c)
                    (thread (λ () (clear-and-replace (sync (ws-recv-evt c)))))))

                (define (clear-and-replace text)
                  (when (equal? 'yes (message-box "Incoming Code Sync"  
                                                   "Would you like to recieve the incoming code from a member of your connected room?\n WARNING: All current code in your editor will be overwritten!"
                                                   #f '(yes-no)))

                      (send (get-definitions-text) delete 0 (send (get-definitions-text) last-position))
                      (send (get-definitions-text) insert text 0 0))
                  (queue-thread))

                (define btn
                  (new switchable-button% 
                       (label "Set Room ID")
                       (callback (λ (button)
                                   (letrec [(code (generate-random-code))
                                            (id (get-text-from-user "Set Room ID"
                                                                  "If you are creating a room, use the pre-generated Room ID.\nOtherwise, if you're joining another user, input their Room ID below."
                                                                  #f	 
                                                                  code
                                                                  '(disallow-invalid)
                                                                  #:validate (λ (id) (and (>= (string-length id) CODE-LEN)
                                                                                          (<= (string-length id) MAX-CODE-LEN)))))]
                                     (and id (set! c (connect id))
                                          (send id-text set-label (string-append "Room ID: " id))
                                          (queue-thread)))))

                       (parent (get-button-panel))
                       (bitmap id-bitmap)))
              
                (define btn2
                  (new switchable-button%
                       (label "Sync Code")
                       (callback (λ (button)
                                   (if (ws-conn? c)
                                     (ws-send! c (send (get-definitions-text) get-text))
                                     (message-box "No Connection"  
                                                   "You are not currently connected to a Room. \nClick 'Set Room ID' to join/create a room first!"
                                                   #f '(caution ok)))))
                       (parent (get-button-panel))
                       (bitmap sync-bitmap)))]

          

          (register-toolbar-buttons (list btn btn2) #:numbers (list 11 12))


          (send (get-button-panel) change-children
                (λ (l)
                  (cons btn2 (remq btn2 l))))
          (send (get-button-panel) change-children
                (λ (l)
                  (cons btn (remq btn l))))
          (send (get-button-panel) change-children
                (λ (l)
                  (cons id-text (remq id-text l))))

        (queue-thread))))

    
    (define id-bitmap
      (let* ((bmp (make-bitmap 16 16))
             (bdc (make-object bitmap-dc% bmp)))
        (send bdc erase)
        (send bdc set-smoothing 'smoothed)
        (send bdc set-pen "black" 1 'transparent)
        (send bdc set-brush "blue" 'solid)
        (send bdc draw-ellipse 2 2 8 8)
        (send bdc set-brush "red" 'solid)
        (send bdc draw-ellipse 6 6 8 8)
        (send bdc set-bitmap #f)
        bmp))

    (define sync-bitmap
      (let* ((bmp (make-bitmap 16 16))
             (bdc (make-object bitmap-dc% bmp)))
        (send bdc erase)
        (send bdc set-smoothing 'smoothed)
        (send bdc set-pen "black" 1 'transparent)
        (send bdc set-brush "purple" 'solid)
        (send bdc draw-ellipse 2 2 8 8)
        (send bdc set-brush "yellow" 'solid)
        (send bdc draw-ellipse 6 6 8 8)
        (send bdc set-bitmap #f)
        bmp))

    (define (phase1) (void))
    (define (phase2) (void))

    (drracket:get/extend:extend-unit-frame set-room-id-mixin)))


          