; modulemisc.arc

(unless (bound&eval 'modulemisc-has-been-loaded*)


(= modulemisc-has-been-loaded* t)


; This will evaluate its body, one line at a time, in the top-level
; context. This lets the code modify global bindings even if a lexical
; scope would shadow them. Furthermore, the lexical scope will be
; totally inaccessible.
(mac tldo body
  `(do ,@(map [do `(eval ',_)] body)))


(eval '(tldo


(mac mc (parms . body)
  `(annotate 'mac (fn ,parms ,@body)))

(mac =mc (name parms . body)
  `(= ,name (mc ,parms ,@body)))

(mac =fn (name parms . body)
  `(= ,name (fn ,parms ,@body)))

; Expand both ssyntax and macros until neither is left.
(def expand (expr)
  (let nextexpr macex.expr
    (if ssyntax.nextexpr
      (expand:ssexpand nextexpr)
      nextexpr)))

; A (call a b c) form should act the same way as a plain (a b c) form,
; *except* when a is a symbol globally bound to a macro at the time
; the expression is compiled, in which case (call a b c) will
; effectively suppress that macro expansion.
(def call (f . args)
  (apply f args))

(def anormalsym (x)
  (and x (isa x 'sym) (~ssyntax x)))

; This will transform a list of parameters from
; ((var1 val1 var2 val2) body1 body2) format--as seen in Arc's
; 'with--into a Scheme- or CL-style
; (((var1 val1) (var2 val2)) body1 body2) format. If the pairerr
; argument is provided, that error will be raised if the binding list
; has an odd length.
;
; Furthermore, if the first parameter is *not* a list, this will
; magically find as many bindings from the beginning of the parameter
; list as it can. The only bindings that can be found this way are
; those whose names are non-ssyntax symbols, including the non-ssyntax
; symbol 'nil. If there's an odd number of parameters, the last
; parameter will not be put into a binding, since there's no
; expression to bind it with; instead, it will be part of the body.
;
; The restriction on "magic" binding names means that destructuring
; (which Arc's 'let supports) and setforms (which Arc's '= supports)
; are left out. However, a macro which uses destructuring or setforms
; can still take advantage of parse-magic-withlike, since whenever the
; user of the macro needs those features, he or she can just use
; with-style parentheses.
;
(def parse-magic-withlike (arglist (o pairerr))
  (if no.arglist
    '(())
    (let (first . rest) arglist
      (if alist.first
        (if (and pairerr (odd:len first))
          err.pairerr
          (cons pair.first arglist))
        (let withlist (accum a
                        (while (and cdr.arglist
                                    ((orf no anormalsym) car.arglist))
                          (withs (name pop.arglist val pop.arglist)
                            (call a (list name val)))))
          (cons withlist arglist))))))

(def global (name)
  (unless (and name (isa name 'sym) (~ssyntax name))
    (err "A nil, ssyntax, or non-symbol name was given to 'global."))
  (bound&eval name))

(w/uniq g-temp
  (eval `(defset global (name)
           (w/uniq (g-name g-val)
             `(((,g-name ,g-val) (let _ ,name (list _ global._)))
               ,g-val
               [do (= ,',g-temp _)
                   (eval `(= ,,g-name ,',',g-temp))
                   (= ,',g-temp nil)])))))

; Set a global variable temporarily. This is neither thread-safe nor
; continuation-safe, although it will restore the original value of
; the variable upon abnormal exits (as well as normal ones).
(mac w/global (name val . body)
  (zap expand name)
  (w/uniq g-old-val
    `(let ,g-old-val (global ',name)
       (after
         (do (= (global ',name) ,val)
             ,@body)
         (= (global ',name) ,g-old-val)))))


; Change 'load so that it returns the result of the final expression.
(=fn load (file)
  (withs (stream infile.file eof (uniq))
    (let result nil
      (whiler expr (read stream eof) eof
        (= result eval.expr))
      result)))

; Change 'setforms so that when a place becomes macro-expanded into an
; unbound (lexically and globally) symbol, there isn't an error.
; Instead, a global variable is created, as is the usual behavior of =
; for unbound symbols.
;
; The simple way to assure this is to have the setforms be:
;
;  `(()                      ; atwith bindings
;    ,expansion              ; getter expression
;    [assign ,expansion _])  ; setter function expression
;
; However, that breaks functions that swap or rotate places, since one
; place has its setter executed before its getter. For this reason (I
; presume), the current arc.arc behavior of setforms is equivalent to:
;
;  (w/uniq g-place
;    `((,g-place ,expansion)
;      ,expansion
;      [assign ,expansion _]))
;
; As mentioned, this causes there to be an error when the variable is
; being set for the first time. The solution actually used here is to
; wrap ,expansion in (errsafe ...), thereby suppressing the error.
;
; This has the side effect that swapping or rotating places, one of
; which macro-expands to an unbound variable name, will have behavior
; as though the unbound variable had actually been bound to nil (which
; is the exceptional result of errsafe).
;
(let old-setforms setforms
  (=fn setforms (expr)
    (let expansion macex.expr
      (if (and (isa expansion 'sym) (~ssyntax expansion))
        (w/uniq g-place
          `((,g-place (errsafe ,expansion))
            ,g-place
            [assign ,expansion _]))
        old-setforms.expansion))))


))  ; end (eval '(tldo ...))


)  ; end (unless (bound&eval 'modulemisc-has-been-loaded*) ...)

; In Rainbow, comments must end with newlines, not EOF, so keep a
; newline here.
