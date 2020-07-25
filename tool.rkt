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


;BUG:
; code sync does nothing after first click
; other editor still recieves code after room ID is reset
; this suggests the the problem is not the second editor "losing connection"
; therefore it isnt a recv problem, its a send problem
; how do we make sure the send is always correct? reconnect on every send?
; yet we know that on send, c is a connection otherwise we would display an error!
; need to log the server to see how far the request really makes it
; if it doesnt make it to the server, its a send problem and we should try to reconnect
; if it does, that means its a recv error somehow
; most likely its a server problem, messages arent being sent or are being cut off somehow.
;
(define RANDOM (make-pseudo-random-generator))
(define CODE-LEN 6)
(define MAX-CODE-LEN 12)
(define TIMEOUT 5)

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

(define thd (thread (λ () (sync never-evt))))

;use alarm event

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

        (define/augment (on-close)
          (when (ws-conn? c)(ws-close! c)))
 
        (local [(define id-text
                  (new message%
                       (label "Room ID: Disconnected")
                       (parent (get-button-panel))))


                ; make this take in a conncection conn
                ;then use alarm evt or sync timeout or sleep or something
                (define (queue-thread)
                  (if (and (ws-conn? c) (not (ws-conn-closed? c)))
                    
                      ;might be a bug: c could be valid on the if check, but die sometime after the
                      ;thread is called. sync will never run, so we never get the next definition
                      ;(displayln "ok i removed it")
                      (set! thd (thread (λ () 
                                          (displayln "starting thread")
                                          (clear-and-replace (sync (ws-recv-evt c #:payload-type 'text)))
                                          (queue-thread))))
                      
                      ; consider killing the thread here and replacing it with a never evt thread
                      (send id-text set-label (string-append "Room ID: Disconnected"))))

                (define (clear-and-replace text)
                  
                  (when 
                             ;because of sync/timeout, text may be #f on timeout
                             ;in which case we want to skip this and do nothing
                             
                            (equal? 'yes (message-box "Incoming Code Sync"  
                                                       "Would you like to recieve the incoming code from a member of your connected room?\n WARNING: All current code in your editor will be overwritten!"
                                                       #f '(yes-no)))
                    
                            (and (not (eof-object? text))
                                 (displayln "received valid text!")
                                 (send (get-definitions-text) select-all)
                                 (send (get-definitions-text) clear)
                                 (send (get-definitions-text) insert text))))

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
                                     (and id
                                          ;(displayln "close if theres a connection")

                                          ;(when (ws-conn? c) (thread (λ () (ws-close! c))))
                                          ;(displayln "done")
                                          (set! c (connect id))
                                          (send id-text set-label (string-append "Room ID: " id))
                                          ;kill the current thread
                                          ;restart it
                                          (kill-thread thd)
                                          ;thd is set within queue-thread
                                          (queue-thread)))))

                       (parent (get-button-panel))
                       (bitmap id-bitmap)))
              
                (define btn2
                  (new switchable-button%
                       (label "Sync Code")
                       (callback (λ (button)
                                   (if (and (ws-conn? c) (not (ws-conn-closed? c)))
                                       (and
                                        (displayln (send (get-definitions-text) get-text))
                                        (ws-send! c (send (get-definitions-text) get-text)))
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
                  (cons id-text (remq id-text l)))))))

    
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


