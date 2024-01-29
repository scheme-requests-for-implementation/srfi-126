;;; SPDX-FileCopyrightText: 2015 - 2016 Taylan Kammer <taylan.kammer@gmail.com>
;;;
;;; SPDX-License-Identifier: MIT

(define-library (srfi 126)
  (export
   make-eq-hashtable make-eqv-hashtable make-hashtable
   alist->eq-hashtable alist->eqv-hashtable alist->hashtable
   weakness
   hashtable?
   hashtable-size
   hashtable-ref hashtable-set! hashtable-delete!
   hashtable-contains?
   hashtable-lookup hashtable-update! hashtable-intern!
   hashtable-copy hashtable-clear! hashtable-empty-copy
   hashtable-keys hashtable-values hashtable-entries
   hashtable-key-list hashtable-value-list hashtable-entry-lists
   hashtable-walk hashtable-update-all! hashtable-prune! hashtable-merge!
   hashtable-sum hashtable-map->lset hashtable-find
   hashtable-empty? hashtable-pop! hashtable-inc! hashtable-dec!
   hashtable-equivalence-function hashtable-hash-function hashtable-weakness
   hashtable-mutable?
   hash-salt equal-hash string-hash string-ci-hash symbol-hash)
  (import
   (scheme base)
   (scheme case-lambda)
   (scheme process-context)
   (srfi 1)
   (srfi 27))
  (cond-expand
   (guile
    ;; Guile doesn't have (r6rs ...) prefixed R6RS library modules,
    ;; and it can use its own R6RS hashtables implementation instead
    ;; of the bundled r6rs/hashtables.sld library.
    (import (rnrs enums (6)))
    (import (prefix (rnrs hashtables (6)) rnrs-)))
   (else
    (import (r6rs enums))
    (import (prefix (r6rs hashtables) rnrs-))))
  (begin
    ;; Smallest allowed in R6RS.
    (define (greatest-fixnum) (expt 23 2)))
  (include "126.body.scm"))
