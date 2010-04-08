; order-contribs.arc
;
; === An extensible, standard way to order the parts of a multival ===
;
; This defines order-contribs, a multival whose purpose is to order
; the contributions of multivals, which may be useful for implementing
; things like multimethod precedence.
;
; Out of the box, order-contribs does nothing but produce a singleton
; list that contains the list of contributions passed to it. This
; represents the idea that all the contributions have been given the
; same ranking. In other words, they're all in the same rank bracket,
; and the return value of order-contribs is a list of just that one
; bracket.
;
; To extend order-contribs, contribute to it a table whose 'fn entry
; is a function that acts just like order-contribs (taking a list of
; contributions and returning a list of brackets of contributions). If
; all the functions contributed this way are stable sorts, in the
; sense that the orders of contributions within each resulting bracket
; are the same as the orders those contributions started with in the
; original list, then order-contribs will also be a stable sort. The
; initial list of contributions passed to order-contribs will be in
; the reverse order they were contributed (usually the same as the
; reverse code order), and it's a good idea to preserve this property,
; just so that when programmers decide that rearranging definitions is
; the most appropriate way to fix something, it's easier for them to
; predict and reason about what the new order should be.
;
; A special aspect of order-contribs is the way that its *own*
; contributions are ordered. Essentially, it orders them itself. For a
; better idea of how this works, suppose one of the contributed sort
; methods would sort itself after some other one. Then that can't be
; the first sort method; if it were, then it wouldn't be. An
; exhaustive search is done of all the possible orders, except that
; any search branches that end up being absurd like this are trimmed
; off. Once a non-absurd order is found (which will be an order that's
; finer than or equivalent to the preorder (i.e. brackets) it
; determines), it's used.
;
; If there are multiple orders that could be found this way, then the
; *particular* one found is unspecified. For instance, if five sort
; methods each determine *total* orders (by returning lists of
; singleton brackets), and each puts itself at the beginning, then
; none of those orders is absurd, so any of them could be found. So be
; careful when contributing sort methods that might unduly trample
; over each other like that.
;
; Another thing: Be careful not to contribute a sort method that
; depends on a multival whose reducer uses order-contribs, or else
; you'll probably have some infinite recursion on your hands. Although
; order-contribs can bootstrap itself, it does so based on assumptions
; it makes about its own behavior, assumptions which can't necessarily
; be extended to the other multival.
;
; Speaking of assumptions, since order-contribs is intended for use
; within reducers, it's assumed to have no side effects. If a
; contributed sort method has side effects, no guarantees are made
; about when or how often those side effects will happen.

(packed:using-rels-as mu "multival.arc"
                      ut "../utils.arc"
                      am "../amb.arc"


; In case you want to have more than one order-contribs for different
; purposes, all it takes to make a new one is to define a multival
; that uses self-orderer-reducer.
;
; Keep in mind that contribs-that-order will be an association list
; mapping contribution labels to contributions. Furthermore, the
; contributions to a self-orderer-reducer multival must be tables with
; 'fn entries. Therefore, to get the comparator function out of an
; element of the contribs-that-order list, we use !fn:cadr. The cadr
; part gets the value of the association, and the !fn part gets the
; 'fn entry.
;
(def my.self-orderer-reducer (contribs-that-order)
  (withs (rep2comp !fn:cadr
          ordered-orderers (map rep2comp
                             (apply join (my.circularly-order rep2comp
                                           contribs-that-order))))
    (obj val (fn (contribs-to-order)
               (ut:foldlet rankings  list.contribs-to-order
                           orderer   ordered-orderers
                 (mappend orderer rankings)))
         cares '())))

; On a lower level, if all you want to do is order a bunch of things
; based on themselves the way order-contribs does, you can use
; circularly-order. The comparator-reps argument is a list of
; comparator representations (in order-contribs's case, the
; contributions). The rep2comp argument is a function that produces a
; comparator from its representation (in order-contribs's case, by
; extracting a 'fn entry from a table). Once again, a comparator is a
; function that accepts a list of things, partitions that list into
; multiple lists (brackets), sorts the brackets, and returns the list
; of sorted brackets.
;
; NOTE: This could be optimized greatly. Then again, this should only
; be done once or twice per run of a program when calculating multival
; values (which are cached), so it might not be worth worrying about.
;
(def my.circularly-order (rep2comp comparator-reps)
  (let amb (am.make-amb
             (fn () (err "The comparators are circularly humble.")))
    (ut:xloop order-so-far '() rep-brackets list.comparator-reps
      (unless (my.is-start-of-brackets order-so-far rep-brackets)
        call.amb)
      (let reps (apply join rep-brackets)
        (if (is len.order-so-far len.reps)
          rep-brackets
          (let rep (apply amb car.rep-brackets)
            (do.next (join order-so-far list.rep)
                     do.rep2comp.rep.reps)))))))

(def my.is-start-of-brackets (order-so-far rep-brackets)
  (withs ((first-so-far . others-so-far) order-so-far
          (first-bracket . other-brackets) rep-brackets)
    (if no.order-so-far t
        no.rep-brackets nil
        no.first-bracket
      (my.is-start-of-brackets order-so-far other-brackets)
      (iflet the-pos (pos first-so-far first-bracket)
        (let (before it-and-after) (split first-bracket the-pos)
          (my.is-start-of-brackets
            others-so-far
            (cons (join before cdr.it-and-after) other-brackets)))))))

(mu:defmultifn-stub my.order-contribs my.self-orderer-reducer)


)