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
   (r6rs enums)
   (prefix (r6rs hashtables) rnrs-)
   (srfi 1)
   (srfi 27))
  (begin
    ;; Smallest allowed in R6RS.
    (define (greatest-fixnum) (expt 23 2)))
  (include "126.body.scm"))
