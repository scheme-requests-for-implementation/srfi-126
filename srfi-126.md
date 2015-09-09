Author
------

Taylan Ulrich Bayırlı/Kammer, taylanbayirli at Google Mail


Status
------

This SRFI is currently in <em>draft</em> status.  Here is
[an explanation](http://srfi.schemers.org/srfi-process.html) of each
status that a SRFI can hold.  To provide input on this SRFI, please
send email to <code><a href="mailto:srfi minus 126 at srfi dot
schemers dot org">srfi-126@<span
class="antispam">nospam</span>srfi.schemers.org</a></code>.  To
subscribe to the list, follow
[these instructions](http://srfi.schemers.org/srfi-list-subscribe.html).
You can access previous messages via the mailing list
[archive](http://srfi-email.schemers.org/srfi-126).

  - Received: 2015/9/8
  - Draft #1 published: 2015/9/8


Abstract
--------

We provide a hashtable API that takes the R6RS hashtables API as a
basis and makes backwards compatible additions such as support for
weak hashtables.  The API is backwards compatible insofar the R6RS's
prohibition of extending the domains of its procedures is not taken
seriously.


Rationale
---------

This specification provides a more conservative alternative to
SRFI-125.  Instead of inventing a third incompatible hashtable API
(SRFI-125 is mostly, but not entirely, backwards compatible with
SRFI-69), it builds upon the R6RS hashtables API, with only a few,
fully backwards compatible additions, most notably for weak and
ephemeral hashtable support.

There is "full" backwards compatibility in the sense that all R6RS
hashtable operations within a piece of code that execute without
raising exceptions will continue to execute without raising exceptions
when the hashtable library in use is changed to an implementation of
this specification.  On the other hand, R6RS's stark requirement of
raising an exception when a procedure's use does not exactly
correspond to the description in R6RS (which effectively prohibits
extensions to its procedures' semantics) is ignored.

The R6RS hashtables API is favored over SRFI-69 because the latter
contains serious flaws.  In particular, exposing the hashing functions
for the `eq?` and `eqv?` procedures is a hindrance for Scheme
implementations with a moving garbage collector.  SRFI-125 works
around this by removing the `hash-table-equivalence-function` and
`hash-table-hash-function` procedures from its API entirely, and
allowing the hashing function passed to `make-hash-table` to be
ignored by the implementation.  R6RS is arguably cleaner, providing
dedicated constructors for `eq?` and `eqv?` based hashtables, and
returning `#f` when their hashing function is queried.

This specification also does not depend on SRFI-114 (Comparators),
does not specify a spurious amount of utility functions, nor does it
describe a bimap API.  There is no attempt at supporting thread safety
because typical multi-threaded use-cases will most likely involve
locking more than just accesses and mutations of hashtables.

The additions made by this specification to the R6RS hashtables API
may be summarized as follows:

- Support for weak and ephemeral hashtables.
- A triplet of `alist->hashtable` constructors.
- The procedures `hashtable-lookup` and `hashtable-intern!`.
- Addition of the missing `hashtable-values` procedure.
- The procedures `hashtable-for-each`, `hashtable-fold` and
  `hashtable-map->list`.
- The procedures `hashtable-key-list`, `hashtable-value-list`, and
  `hashtable->alist`.


Specification
-------------

The `(scheme hashtables)` library provides a set of operations on
hashtables.  A hashtable is of a disjoint type that associates keys
with values.  Any object can be used as a key, provided a hash
function and a suitable equivalence function is available.  A hash
function is a procedure that maps keys to exact integer objects.  It
is the programmer's responsibility to ensure that the hash function is
compatible with the equivalence function, which is a procedure that
accepts two keys and returns true if they are equivalent and `#f`
otherwise.  Standard hashtables for arbitrary objects based on the
`eq?` and `eqv?` predicates (see report section on “Equivalence
predicates”) are provided.  Also, hash functions for arbitrary
objects, strings, and symbols are provided.

Hashtables can store their key, value, or key and value weakly, or
ephemerally.  Storing an object weakly or ephemerally means that the
storage location of the object does not count towards the total
storage locations in the program which refer to the object, meaning
the object can be reclaimed as soon as no non-weak non-ephemeral
storage locations referring to the object remain.  When this happens,
all entries of the hashtable which have the reclaimed object as their
key or value are deleted.  Storing either or both of a key and value
pair ephemerally means additionally that no references from the value
or key towards the key or value respectively count towards the total
references of the key or value within the program.  For instance, an
ephemerally keyed hashtable with an entry mapping an element of a
vector to the vector itself may delete said entry when no references
remain to the vector nor the element of the vector from outside the
vector.  If the hashtable were weakly keyed, then the reference to the
key from within the vector would protect the key from reclamation,
preventing the deletion of the entry even when no references to the
key (element) nor value (vector) remained from outside the hashtable.

An implementation may implement weak hashtables as ephemeral
hashtables.

*Rationale:* While the semantics of weak hashtables is usually
undesired, their implementation might be more efficient than ephemeral
hashtables.

Booleans, characters, numbers, and symbols are never stored weakly or
ephemerally.

This section uses the hashtable parameter name for arguments that must
be hashtables, and the key parameter name for arguments that must be
hashtable keys.


### Constructors

- `(make-eq-hashtable)` (procedure)
- `(make-eq-hashtable k)`
- `(make-eq-hashtable k weakness)`

Returns a newly allocated mutable hashtable that accepts arbitrary
objects as keys, and compares those keys with `eq?`.  If the `k`
argument is provided and not `#f`, the initial capacity of the
hashtable is set to approximately `k` elements.  The `weakness`
argument, if provided, must be one of: `#f`, `weak-key`, `weak-value`,
`weak-key-and-value`, `ephemeral-key`, `ephemeral-value`, and
`ephemeral-key-and-value`, and determines the weakness or ephemeral
status for the keys and values in the hashtable.

- `(make-eqv-hashtable)` (procedure)
- `(make-eqv-hashtable k)`
- `(make-eqv-hashtable k weakness)`

Returns a newly allocated mutable hashtable that accepts arbitrary
objects as keys, and compares those keys with `eqv?`.  The semantics
of the optional arguments are as in `make-eq-hashtable`.

- `(make-hashtable hash-function equiv)` (procedure)
- `(make-hashtable hash-function equiv k)`
- `(make-hashtable hash-function equiv k weakness)`

`Hash-function` and `equiv` must be procedures.  `Hash-function`
should accept a key as an argument and should return a non-negative
exact integer object.  `Equiv` should accept two keys as arguments and
return a single value.  Neither procedure should mutate the hashtable
returned by `make-hashtable`.  The `make-hashtable` procedure returns
a newly allocated mutable hashtable using `hash-function` as the hash
function and `equiv` as the equivalence function used to compare
keys.  The semantics of the remaining arguments are as in
`make-eq-hashtable` and `make-eqv-hashtable`.

Both `hash-function` and `equiv` should behave like pure functions on
the domain of keys.  For example, the `string-hash` and `string=?`
procedures are permissible only if all keys are strings and the
contents of those strings are never changed so long as any of them
continues to serve as a key in the hashtable.  Furthermore, any pair
of keys for which `equiv` returns true should be hashed to the same
exact integer objects by `hash-function`.

*Note:* Hashtables are allowed to cache the results of calling the
hash function and equivalence function, so programs cannot rely on the
hash function being called for every lookup or update.  Furthermore
any hashtable operation may call the hash function more than once.

- `(alist->eq-hashtable alist)` (procedure)
- `(alist->eq-hashtable k alist)`
- `(alist->eq-hashtable k weakness alist)`

The semantics of this procedure is equivalent to:

    (let ((ht (make-eq-hashtable k weakness)))
      (for-each (lambda (entry)
                  (hashtable-set! ht (car entry) (cdr entry)))
                alist)
      ht)

- `(alist->eqv-hashtable alist)` (procedure)
- `(alist->eqv-hashtable k alist)`
- `(alist->eqv-hashtable k weakness alist)`

This procedure is equivalent to `alist->eq-hashtable` except that
`make-eqv-hashtable` is used to construct the hashtable.

- `(alist->hashtable hash-function equiv alist)` (procedure)
- `(alist->hashtable hash-function equiv k alist)`
- `(alist->hashtable hash-function equiv k weakness alist)`

This procedure is equivalent to `alist->eq-hashtable` except that
`make-hashtable` is used to construct the hashtable.

- `(weakness <weakness symbol>)` (syntax)

The `<weakness symbol>` must correspond to one of the non-`#f` values
accepted for the `weakness` argument of the constructor procedures.
Given such a symbol, it is returned as a datum.  Passing any other
argument is an error.

*Rationale:* This allows for expand-time verification that a valid
weakness attribute is specified.


### Procedures

- `(hashtable? hashtable)` (procedure)

Returns `#t` if `hashtable` is a hashtable, `#f` otherwise.

- `(hashtable-size hashtable)` (procedure)

Returns the number of keys contained in `hashtable` as an exact
integer object.

- `(hashtable-ref hashtable key default)` (procedure)

Returns the value in `hashtable` associated with `key`.  If
`hashtable` does not contain an association for `key`, `default` is
returned.

- `(hashtable-set! hashtable key obj)` (procedure)

Changes `hashtable` to associate `key` with `obj`, adding a new
association or replacing any existing association for `key`, and
returns unspecified values.

- `(hashtable-delete! hashtable key)` (procedure)

Removes any association for `key` within `hashtable` and returns
unspecified values.

- `(hashtable-contains? hashtable key)` (procedure)

Returns `#t` if `hashtable` contains an association for `key`, `#f`
otherwise.

- `(hashtable-lookup hashtable key)` (procedure)

Returns two values: the value in `hashtable` associated with `key` or
an unspecified value if there is none, and a Boolean indicating
whether an association was found.

- `(hashtable-update! hashtable key proc default)` (procedure)

`Proc` should accept one argument, should return a single value, and
should not mutate `hashtable`.  The `hashtable-update!` procedure
applies `proc` to the value in `hashtable` associated with `key`, or
to `default` if `hashtable` does not contain an association for `key`.
The hashtable is then changed to associate `key` with the value
returned by `proc`.

- `(hashtable-intern! hashtable key default-proc)` (procedure)

`Default-proc` should accept zero arguments, should return a single
value, and should not mutate `hashtable`.  The `hashtable-intern!`
procedure returns the association for `key` in `hashtable` if there is
one, otherwise it calls `default-proc`, associates its return value
with `key` in `hashtable`, and returns that value.

- `(hashtable-copy hashtable)` (procedure)
- `(hashtable-copy hashtable mutable)`
- `(hashtable-copy hashtable mutable weakness)`

Returns a copy of `hashtable`.  If the `mutable` argument is provided
and is true, the returned hashtable is mutable; otherwise it is
immutable.  If the optional `weakness` argument is provided, it
determines the weakness of the copy, otherwise the weakness attribute
of `hashtable` is used.

- `(hashtable-clear! hashtable)` (procedure)
- `(hashtable-clear! hashtable k)`

Removes all associations from `hashtable` and returns unspecified
values.

If `k` is provided and not `#f`, the current capacity of the hashtable
is reset to approximately `k` elements.

- `(hashtable-keys hashtable)` (procedure)

Returns a vector of all keys in `hashtable`.  The order of the vector
is unspecified.

- `(hashtable-values hashtable)` (procedure)

Returns a vector of all values in `hashtable`.  The order of the
vector is unspecified, and is not guaranteed to match the order of
keys in the result of `hashtable-keys`.

- `(hashtable-entries hashtable)` (procedure)

Returns two values, a vector of the keys in `hashtable`, and a vector
of the corresponding values.

*Rationale:* Returning the keys and values as vectors allows for
greater locality and less allocation than if they were returned as
lists.

- `(hashtable-for-each proc hashtable)` (procedure)

`Proc` should accept two arguments, and should not mutate `hashtable`.
The `hashtable-for-each` procedure applies `proc` once for every entry
in `hashtable`, passing it the key and value of the entry as
arguments.  The order in which `proc` is applied to the entries is
unspecified.

- `(hashtable-fold proc init hashtable)` (procedure)

`Proc` should accept three arguments, should return a single value,
and should not mutate `hashtable`.  The `hashtable-fold` procedure
accumulates a result by applying `proc` once for every entry in
`hashtable`, passing it as arguments the key and value of the entry
and the result of the previous application, or `init` at the first
application.  The order in which `proc` is applied to the entries is
unspecified.

- `(hashtable-map->list proc hashtable)` (procedure)

`Proc` should accept two arguments, should return a single value, and
should not mutate `hashtable`.  The `hashtable-map->list` procedure
applies `proc` to every key and value in `hashtable` and returns the
returned values as a list.  The order in which `proc` is applied to
the entries is unspecified.

- `(hashtable-key-list hashtable)` (procedure)

Returns a list of all keys in `hashtable`.  The order of the list is
unspecified.

- `(hashtable-value-list hashtable)` (procedure)

Returns a list of all values in `hashtable`.  The order of the list is
unspecified, and is not guaranteed to match the order of keys in the
result of `hashtable-key-list`.

- `(hashtable->alist hashtable)` (procedure)

Returns an alist mapping the keys in `hashtable` to their
corresponding values.

*Rationale:* Returning the keys and values as lists or an alist allows
for using typical list processing idioms such as filtering and
partitioning on the results.  Additionally, these operations may be
implemented more efficiently than their straightforward imitations
using their vector-returning counterparts and `vector->list`.


### Inspection

- `(hashtable-equivalence-function hashtable)` (procedure)

Returns the equivalence function used by `hashtable` to compare keys.
For hashtables created with `make-eq-hashtable` and
`make-eqv-hashtable`, returns `eq?` and `eqv?` respectively.

- `(hashtable-hash-function hashtable)` (procedure)

Returns the hash function used by `hashtable`.  For hashtables created
by `make-eq-hashtable` or `make-eqv-hashtable`, `#f` is returned.

- `(hashtable-weakness hashtable)` (procedure)

Returns the weakness attribute of `hashtable`.  The same values that
are accepted as the `weakness` argument in the constructor procedures
are returned.

- `(hashtable-mutable? hashtable)` (procedure)

Returns `#t` if `hashtable` is mutable, otherwise `#f`.


### Hash functions

The `equal-hash`, `string-hash`, and `string-ci-hash` procedures of
this section are acceptable as the hash functions of a hashtable only
if the keys on which they are called are not mutated while they remain
in use as keys in the hashtable.

- `(equal-hash obj)` (procedure)

Returns an integer hash value for `obj`, based on its structure and
current contents.  This hash function is suitable for use with
`equal?` as an equivalence function.

*Note:* Like `equal?`, the `equal-hash` procedure must always
terminate, even if its arguments contain cycles.

- `(string-hash string)` (procedure)

Returns an integer hash value for `string`, based on its current
contents.  This hash function is suitable for use with `string=?` as
an equivalence function.

- `(string-ci-hash string)` (procedure)

Returns an integer hash value for `string` based on its current
contents, ignoring case.  This hash function is suitable for use with
`string-ci=?` as an equivalence function.

- `(symbol-hash symbol)` (procedure)

Returns an integer hash value for `symbol`.


Implementation
--------------

The source tree of Larceny Scheme contains a portable implementation
of the R6RS hashtables API as an R7RS library.

The alist constructors can be implemented trivially as seen in the
piece of code describing their semantics.  Here is a complete
definition of `alist->eq-hashtable`:

    (define alist->eq-hashtable
      (case-lambda
        ((alist) (alist->eq-hashtable #f #f alist))
        ((k alist) (alist->eq-hashtable k #f alist))
        ((k weakness alist)
         (let ((ht (make-eq-hashtable k weakness)))
           (for-each (lambda (entry)
                       (hashtable-set! ht (car entry) (cdr entry)))
                     alist)
           ht))))

The `hashtable-lookup` and `hashtable-intern!` procedures are trivial
to implement, although it's desirable that they be implemented more
efficiently at the platform level:

    (define (hashtable-lookup ht key)
      (if (hashtable-contains? key)
          (values (hashtable-ref ht key #f) #t)
          (values #f #f)))

    (define (hashtable-intern! ht key default-proc)
      (if (hashtable-contains? key)
          (hashtable-ref ht key)
          (let ((value (default-proc)))
            (hashtable-set! ht key value)
            value)))

The `hashtable-values` and `hashtable-for-each` procedures are trivial
to implement in terms of `hashtable-entries`, but it is desirable that
they be implemented more efficiently at the platform level.

The `hashtable-fold` procedure could be implemented in terms of
`hashtable-entries`, `vector->list`, and `fold`, but it is definitely
desirable to implement it more efficiently.  Given an efficient
`hashtable-fold`, the following definitions can be used:

    (define (hashtable-map->list proc ht)
      (hashtable-fold '()
                      (lambda (key value acc)
                        (cons (proc key value) acc))
                      ht))

    (define (hashtable-key-list ht)
      (hashtable-map->list (lambda (key value) key) ht))

    (define (hashtable-value-list ht)
      (hashtable-map->list (lambda (key value) value) ht))

    (define (hashtable->alist ht)
      (hashtable-map->list cons ht))

Weak and ephemeral hashtables cannot be implemented by portable
library code.  They need to be implemented either directly at the
platform level, or by using functionality which in turn needs to be
implemented at the platform level, such as weak and ephemeral pairs.

For these reasons, a full sample implementation is not provided.


Acknowledgments
---------------

Thanks to Taylor Campbell and MIT/GNU Scheme for inspiring the idea of
weak and ephemeral hashtables, some miscellaneous procedures, and
overall input in the design of this SRFI.


Copyright and license
---------------------

Copyright (C) Taylan Ulrich Bayırlı/Kammer (2015). All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
