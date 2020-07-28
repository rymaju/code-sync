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

; local server
;(define WS-URL (string->url "ws://localhost:8080/"))



; TODO:
; fix set position/mline error, probably has to do with select-all in locked flow state
; added a check, need to see if it works or not
; remove all displaylns just in case that was a problem

; images
; and different modes maybe




(define RANDOM (make-pseudo-random-generator))
(define CODE-LEN 6)
(define MAX-CODE-LEN 12)


; use (string [List-of Char])

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

;(define thd (thread (λ () (sync never-evt))))

(define thd #f)

(define tool@
  (unit
    (import drracket:tool^)
    (export drracket:tool-exports^)
 
    ; note to self, mixins are ugly: maybe i can rewrite this as a class?
    (define set-room-id-mixin
      (mixin (drracket:unit:frame<%>) ()
        (super-new)
        (inherit get-button-panel
                 get-definitions-text
                 get-editor)
        (inherit register-toolbar-buttons)

        (define/augment (on-close)
          (when (ws-conn? c)(ws-close! c)))
 
        (local [(define id-text
                  (new message%
                       (label "Room ID: Disconnected")
                       (parent (get-button-panel))))


               
                (define (queue-thread)
                  (if (and (ws-conn? c) (not (ws-conn-closed? c)))
                      (set! thd (thread (λ () 
                                          (clear-and-replace (sync (ws-recv-evt c #:payload-type 'text)))
                                          (queue-thread))))     
                      ; consider killing the thread here and replacing it with a never evt thread
                      (send id-text set-label (string-append "Room ID: Disconnected"))))

                (define (clear-and-replace text)
                  (cond
                    ; connection was closed/terminated
                    [(ws-conn-closed? c)
                     (message-box "Connection Closed"  
                                  "Uh oh! The connection to your Room has been closed.\n Please reconnect with 'Set Room ID'."
                                  #f '(caution ok))]
                    
                    [(and
                      (string? text)
                      (equal? 'yes (message-box "Incoming Code Sync"  
                                                "Would you like to recieve the incoming code from a member of your connected room?\n WARNING: All current code in your editor will be overwritten!"
                                                #f '(yes-no))))
                     (if (or (send (get-editor) locked-for-flow?)
                             (send (get-editor) locked-for-write?))
                         (begin (send (get-definitions-text) select-all)
                                (send (get-definitions-text) insert text))
                         (message-box "Editor Locked"  
                                      "Oops! Your editor was locked to write/flow during the incoming sync. Please try syncing again."
                                      #f '(caution ok)))]))
                
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
                                          ;(when (ws-conn? c) (thread (λ () (ws-close! c))))
                                          (set! c (connect id))
                                          (send id-text set-label (string-append "Room ID: " id))
                                          ;kill the current thread
                                          ;restart it
                                          (and thd (kill-thread thd))
                                          ;thd is set within queue-thread
                                          (queue-thread)))))

                       (parent (get-button-panel))
                       (bitmap id-bitmap)))
              
                (define btn2
                  (new switchable-button%
                       (label "Send Code")
                       (callback (λ (button)
                                   (if (and (ws-conn? c) (not (ws-conn-closed? c)))
                                       (ws-send! c (send (get-definitions-text) get-text))
                                       ;might wanna add a timer that disables the button for a few seconds
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

    ;let*
    ;better icons
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


