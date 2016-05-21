% R6RS-based hashtables

Author
------

Taylan Ulrich Bayırlı/Kammer, taylanbayirli at Google Mail


Status
------

This SRFI is currently in <em>final</em> status.  Here is
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
  - Draft #2 published: 2015/9/9
  - Draft #3 published: 2015/9/11
  - Draft #4 published: 2015/9/12
  - Draft #5 published: 2015/9/13
  - Draft #6 published: 2015/9/26
  - Draft #7 published: 2015/10/6
  - Draft #8 published: 2015/10/10
  - Draft #9 published: 2015/11/12
  - Draft #10 published: 2015/12/7
  - Draft #11 published: 2016/1/23
  - Draft #12 published: 2016/1/24
  - Finalized: 2016/2/1
  - Revised to fix errata: 2016/5/12
  - Revised to fix errata: 2016/5/21

Abstract
--------

We provide a hashtable API that takes the R6RS hashtables API as a
basis and makes backwards compatible additions such as support for
weak hashtables, external representation, API support for double
hashing implementations, and utility procedures.


Rationale
---------

This specification provides an alternative to SRFI-125.  It builds on
the R6RS hashtables API instead of SRFI-69, with only fully backwards
compatible additions such as weak and ephemeral hashtables, an
external representation, and API support for hashing strategies that
require a pair of hash functions.  Some of these additions are
optional to support, so as to aid in adoption of the SRFI by smaller
Scheme implementations which would otherwise disregard the SRFI
entirely.  Other additions are limited to utility procedures.  It does
not depend on SRFI-114 (Comparators), and does not attempt to specify
thread-safety because typical multi-threaded use-cases will most
likely involve locking more than just accesses and mutations of
hashtables.

The inclusion criteria for utility procedures is that they be

- used frequently in typical user code, or
- nontrivial to define or imitate when needed, or
- essential for the efficient implementation of further operations.

There is "full" backwards compatibility in the sense that all R6RS
hashtable operations within a piece of code that execute without
raising exceptions will continue to execute without raising exceptions
when the hashtable library in use is changed to an implementation of
this specification.  On the other hand, R6RS's stark requirement of
raising an exception when a procedure's use does not exactly
correspond to the description in R6RS (which effectively prohibits
extensions to its procedures' semantics) is ignored.

The R6RS hashtables API is favored over SRFI-69 because the latter
contains a crucial flaw: exposing the hash functions for the `eq?` and
`eqv?` procedures is a hindrance for Scheme implementations with a
moving garbage collector.  SRFI-125 works around this by allowing the
user-provided hash function passed to `make-hash-table` to be ignored
by the implementation, and allowing the `hash-table-hash-function`
procedure to return `#f` instead of the hash function passed to
`make-hash-table`.  R6RS avoids the issue by providing dedicated
constructors for `eq?` and `eqv?` based hashtables, and returning `#f`
when their hash function is queried.

While the SRFI is based on the R6RS hashtables API instead of SRFI-69,
the provided utility procedures nevertheless make it relatively
straightforward to change code written for SRFI-69 to use the API
specified herein.

The utility procedures provided by this SRFI in addition to the R6RS
API may be categorized as follows:

- Constructors: `alist->eq-hashtable`, `alist->eqv-hashtable`,
  `alist->hashtable`

- Access and mutation: `hashtable-lookup`, `hashtable-intern!`

- Copying: `hashtable-empty-copy`

- Key/value collections: `hashtable-values`, `hashtable-key-list`,
  `hashtable-value-list`, `hashtable-entry-lists`

- Iteration: `hashtable-walk`, `hashtable-update-all!`,
  `hashtable-prune!`, `hashtable-merge!`, `hashtable-sum`,
  `hashtable-map->lset`, `hashtable-find`

- Miscellaneous: `hashtable-empty?`, `hashtable-pop!`,
  `hashtable-inc!`, `hashtable-dec!`

Additionally, this specification adheres to the R7RS rule of
specifying a single return value for procedures which don't have
meaningful return values.


Specification
-------------

The `(srfi 126)` library provides a set of operations on hashtables.
A hashtable is of a disjoint type that associates keys with values.
Any object can be used as a key, provided a hash function or a pair of
hash functions, and a suitable equivalence function, are available.  A
hash function is a procedure that maps keys to non-negative exact
integer objects.  It is the programmer's responsibility to ensure that
the hash functions are compatible with the equivalence function, which
is a procedure that accepts two keys and returns true if they are
equivalent and `#f` otherwise.  Standard hashtables for arbitrary
objects based on the `eq?` and `eqv?` predicates (see R7RS section on
“Equivalence predicates”) are provided.  Also, hash functions for
arbitrary objects, strings, and symbols are provided.

Hashtables can store their key, value, or key and value weakly.
Storing an object weakly means that the storage location of the object
does not count towards the total storage locations in the program
which refer to the object, meaning the object can be reclaimed as soon
as no non-weak storage locations referring to the object remain.
Weakly stored objects referring to each other in a cycle will be
reclaimed as well if none of them are referred to from outside the
cycle.  When a weakly stored object is reclaimed, associations in the
hashtable which have the object as their key or value are deleted.

Hashtables can also store their key and value in ephemeral storage
pairs.  The objects in an ephemeral storage pair are stored weakly,
but both protected from reclamation as long as there remain non-weak
references to the first object from outside the ephemeral storage
pair.  In particular, an ephemeral-key hashtable (where the keys are
the first objects in the ephemeral storage pairs), with an association
mapping an element of a vector to the vector itself, may delete said
association when no non-weak references remain to the vector nor its
element in the rest of the program.  If it were a weak-key hashtable,
the reference to the key from within the vector would cyclically
protect the key and value from reclamation, even when no non-weak
references to the key and value remained from outside the hashtable.
At the absence of such references between the key and value,
ephemeral-key and ephemeral-value hashtables behave effectively
equivalent to weak-key and weak-value hashtables.

An implementation may implement weak-key and weak-value hashtables as
ephemeral-key and ephemeral-value hashtables.

*Rationale:* While the semantics of weak-key and weak-value hashtables
is undesired, their implementation might be more efficient than
ephemeral-key and ephemeral-value hashtables.

Ephemeral-key-and-value hashtables use a pair of ephemeral storage
pairs for each association: one where the key is the first object and
one where the value is.  This means that the key and value are
protected from reclamation until no references remain to neither the
key nor value from outside the hashtable.  In contrast, a
weak-key-and-value hashtable will delete an association as soon as
either the key or value is reclaimed.

Support for all types of weak and ephemeral hashtables is optional.

Booleans, characters, numbers, symbols, and the empty list are
recommended, but not required, to never be stored weakly or
ephemerally.

*Rationale:* Objects of these types can be recreated arbitrarily, such
that a new instance is equivalent (as per `eqv?`) to a previous
instance, even if the previous instance was deallocated and the new
instance allocated freshly.  Therefore objects of these types must be
considered alive at all times even if no references remain to them in
a program.

*Warning:* In portable code, one may neither rely on weak hashtables
keeping associations for objects of these types at absence of other
references to the object, nor may one rely on the hashtable
automatically clearing associations for objects of these types.
Furthermore, the exact types of objects to which this caveat applies
differs between implementations.  For instance, some implementations
may automatically clear associations only for big exact integers and
exact rationals, whereas other implementations may also do so for all
inexact numbers.

This document uses the `hashtable` parameter name for arguments that
must be hashtables, and the `key` parameter name for arguments that
must be hashtable keys.


### Constructors

- `(make-eq-hashtable)` *procedure*
- `(make-eq-hashtable capacity)`
- `(make-eq-hashtable capacity weakness)`

Returns a newly allocated mutable hashtable that accepts arbitrary
objects as keys, and compares those keys with `eq?`.  If the
`capacity` argument is provided and not `#f`, it must be an exact
non-negative integer and the initial capacity of the hashtable is set
to approximately `capacity` elements.  The `weakness` argument, if
provided, must be one of: `#f`, `weak-key`, `weak-value`,
`weak-key-and-value`, `ephemeral-key`, `ephemeral-value`, and
`ephemeral-key-and-value`, and determines the weakness or ephemeral
status for the keys and values in the hashtable.  All values other
than `#f` are optional to support; the implementation should signal
the user in an implementation-defined manner when an unsupported value
is used.

- `(make-eqv-hashtable)` *procedure*
- `(make-eqv-hashtable capacity)`
- `(make-eqv-hashtable capacity weakness)`

Returns a newly allocated mutable hashtable that accepts arbitrary
objects as keys, and compares those keys with `eqv?`.  The semantics
of the optional arguments are as in `make-eq-hashtable`.

- `(make-hashtable hash equiv)` *procedure*
- `(make-hashtable hash equiv capacity)`
- `(make-hashtable hash equiv capacity weakness)`

If `hash` is `#f` and `equiv` is the `eq?` procedure, the semantics of
`make-eq-hashtable` apply to the rest of the arguments.  If `hash` is
`#f` and `equiv` is the `eqv?` procedure, the semantics of
`make-eqv-hashtable` apply to the rest of the arguments.

Otherwise, `hash` must be a pair of hash functions or a hash function,
and and `equiv` must be a procedure.  `Equiv` should accept two keys
as arguments and return a single value.  None of the procedures should
mutate the hashtable returned by `make-hashtable`.  The
`make-hashtable` procedure returns a newly allocated mutable hashtable
using the function(s) specified by `hash` as its hash function(s), and
`equiv` as the equivalence function used to compare keys.  The
semantics of the remaining arguments are as in `make-eq-hashtable` and
`make-eqv-hashtable`.

Implementations using a hashing strategy that involves a single hash
function should ignore one of the functions in the pair when given a
pair of hash functions.  Implementations preferring a hashing strategy
involving a pair of hash functions may automatically derive a pair of
hash functions from a given single hash function.

The hash functions and `equiv` should behave like pure functions on
the domain of keys.  For example, the `string-hash` and `string=?`
procedures are permissible only if all keys are strings and the
contents of those strings are never changed so long as any of them
continues to serve as a key in the hashtable.  Furthermore, any pair
of keys for which `equiv` returns true should be hashed to the same
exact integer objects by the given hash function(s).

*Note:* Hashtables are allowed to cache the results of calling a hash
function and equivalence function, so programs cannot rely on a hash
function being called for every lookup or update.  Furthermore any
hashtable operation may call a hash function more than once.

- `(alist->eq-hashtable alist)` *procedure*
- `(alist->eq-hashtable capacity alist)`
- `(alist->eq-hashtable capacity weakness alist)`

The semantics of this procedure can be described as:

    (let ((ht (make-eq-hashtable capacity weakness)))
      (for-each (lambda (entry)
                  (hashtable-set! ht (car entry) (cdr entry)))
                (reverse alist))
      ht)

where omission of the `capacity` and/or `weakness` arguments
corresponds to their omission in the call to `make-eq-hashtable`.

- `(alist->eqv-hashtable alist)` *procedure*
- `(alist->eqv-hashtable capacity alist)`
- `(alist->eqv-hashtable capacity weakness alist)`

This procedure is equivalent to `alist->eq-hashtable` except that
`make-eqv-hashtable` is used to construct the hashtable.

- `(alist->hashtable hash equiv alist)` *procedure*
- `(alist->hashtable hash equiv capacity alist)`
- `(alist->hashtable hash equiv capacity weakness alist)`

This procedure is equivalent to `alist->eq-hashtable` except that
`make-hashtable` is used to construct the hashtable, with the given
`hash` and `equiv` arguments.

- `(weakness <weakness symbol>)` *syntax*

The `<weakness symbol>` must correspond to one of the non-`#f` values
accepted for the `weakness` argument of the constructor procedures.
Given such a symbol, it is returned as a datum.  Passing any other
argument is an error.

*Rationale:* This allows for expand-time verification that a valid
weakness attribute is specified.


### External representation

An implementation may optionally support external representations for
the most common types of hashtables so that they can be read and
written by and appear as constants in programs.

`Eq?` and `eqv?` based hashtables are written using the notation
`#hasheq(entry ...)` and `#hasheqv(entry ...)` respectively, where
each `entry` must have the form `(key . value)`.

Hashtables using `equal-hash` as the hash function and `equal?` as the
equivalence function may be written using the notation `#hash(entry
...)`.  Other types of hashtables may be written using the notation
`#hash(type entry ...)` where `type` must be one of: `string`,
`string-ci`, and `symbol`.  When `type` is `string`, the hashtable
uses `string-hash` and `string=?` as the hash and equivalence function
respectively.  When `string-ci`, it uses `string-ci-hash` and
`string-ci=?`.  When `symbol`, it uses `symbol-hash` and `eq?`.

It is an error if any two keys in the list of entries are equivalent
as per the equivalence function of the hashtable.

Hashtable constants are self-evaluating, meaning they do not need to
be quoted in programs.  The resulting hashtable must be immutable, and
its weakness `#f`.  The keys and values in the hashtable may be
immutable.


### Quasiquote

An implementation supporting external representation for hashtables
may optionally extend `quasiquote` for hashtable constants.

When a hashtable constant appears within a quasiquote expression and
is not already unquoted, the behavior of the quasiquote algorithm on
the hashtable can be explained as follows:

    (let ((copy (hashtable-empty-copy hashtable #t)))
      (hashtable-walk hashtable
        (lambda (key value)
          (let ((key (apply-quasiquote key))
                (value (apply-quasiquote value)))
            (hashtable-set! copy key value))))
      ;; Make it immutable again.
      (hashtable-copy copy))

where the procedure `apply-quasiquote` recursively applies the
quasiquote algorithm to the key and value.


### Procedures

- `(hashtable? obj)` *procedure*

Returns `#t` if `obj` is a hashtable, `#f` otherwise.

- `(hashtable-size hashtable)` *procedure*

Returns the number of keys contained in `hashtable` as an exact
integer object.

- `(hashtable-ref hashtable key)` *procedure*
- `(hashtable-ref hashtable key default)`

Returns the value in `hashtable` associated with `key`.  If
`hashtable` does not contain an association for `key`, `default` is
returned.  If `hashtable` does not contain an association for `key`
and the `default` argument is not provided, an error should be
signaled.

- `(hashtable-set! hashtable key obj)` *procedure*

Changes `hashtable` to associate `key` with `obj`, adding a new
association or replacing any existing association for `key`, and
returns an unspecified value.

- `(hashtable-delete! hashtable key)` *procedure*

Removes any association for `key` within `hashtable` and returns
an unspecified value.

- `(hashtable-contains? hashtable key)` *procedure*

Returns `#t` if `hashtable` contains an association for `key`, `#f`
otherwise.

- `(hashtable-lookup hashtable key)` *procedure*

Returns two values: the value in `hashtable` associated with `key` or
an unspecified value if there is none, and a Boolean indicating
whether an association was found.

- `(hashtable-update! hashtable key proc)` *procedure*
- `(hashtable-update! hashtable key proc default)`

`Proc` should accept one argument, should return a single value, and
should not mutate `hashtable`.  The `hashtable-update!` procedure
applies `proc` to the value in `hashtable` associated with `key`, or
to `default` if `hashtable` does not contain an association for `key`.
The hashtable is then changed to associate `key` with the value
returned by `proc`.  If `hashtable` does not contain an association
for `key` and the `default` argument is not provided, an error should
be signaled.  `Hashtable-update!` returns the value of the new
association for `key` in `hashtable`.

- `(hashtable-intern! hashtable key default-proc)` *procedure*

`Default-proc` should accept zero arguments, should return a single
value, and should not mutate `hashtable`.  The `hashtable-intern!`
procedure returns the association for `key` in `hashtable` if there is
one, otherwise it calls `default-proc` with zero arguments, associates
its return value with `key` in `hashtable`, and returns that value.

- `(hashtable-copy hashtable)` *procedure*
- `(hashtable-copy hashtable mutable)`
- `(hashtable-copy hashtable mutable weakness)`

Returns a copy of `hashtable`.  If the `mutable` argument is provided
and is true, the returned hashtable is mutable; otherwise it is
immutable.  If the optional `weakness` argument is provided, it
determines the weakness of the copy, otherwise the weakness attribute
of `hashtable` is used.

- `(hashtable-clear! hashtable)` *procedure*
- `(hashtable-clear! hashtable capacity)`

Removes all associations from `hashtable` and returns an unspecified
value.  If `capacity` is provided and not `#f`, it must be an exact
non-negative integer and the current capacity of the hashtable is
reset to approximately `capacity` elements.

- `(hashtable-empty-copy hashtable)` *procedure*
- `(hashtable-empty-copy hashtable capacity)`

Returns a newly allocated mutable hashtable that has the same hash and
equivalence functions and weakness attribute as `hashtable`.  The
`capacity` argument may be `#t` to set the initial capacity of the
copy to approximately `(hashtable-size hashtable)` elements; otherwise
the semantics of `make-eq-hashtable` apply to the `capacity` argument.

- `(hashtable-keys hashtable)` *procedure*

Returns a vector of all keys in `hashtable`.  The order of the vector
is unspecified.

- `(hashtable-values hashtable)` *procedure*

Returns a vector of all values in `hashtable`.  The order of the
vector is unspecified, and is not guaranteed to match the order of
keys in the result of `hashtable-keys`.

- `(hashtable-entries hashtable)` *procedure*

Returns two values, a vector of the keys in `hashtable`, and a vector
of the corresponding values.

*Rationale:* Returning the keys and values as vectors allows for
greater locality and less allocation than if they were returned as
lists.

- `(hashtable-key-list hashtable)` *procedure*

Returns a list of all keys in `hashtable`.  The order of the list is
unspecified.

- `(hashtable-value-list hashtable)` *procedure*

Returns a list of all values in `hashtable`.  The order of the list is
unspecified, and is not guaranteed to match the order of keys in the
result of `hashtable-key-list`.

- `(hashtable-entry-lists hashtable)` *procedure*

Returns two values, a list of the keys in `hashtable`, and a list of
the corresponding values.

*Rationale:* Returning the keys and values as lists allows for using
typical list processing idioms such as filtering and partitioning on
the results.  Additionally, these operations may be implemented more
efficiently than their straightforward imitations using their
vector-returning counterparts and `vector->list`.

- `(hashtable-walk hashtable proc)` *procedure*

`Proc` should accept two arguments, and should not mutate `hashtable`.
The `hashtable-walk` procedure applies `proc` once for every
association in `hashtable`, passing it the key and value as arguments.
The order in which `proc` is applied to the associations is
unspecified.  Return values of `proc` are ignored.
`Hashtable-walk` returns an unspecified value.

- `(hashtable-update-all! hashtable proc)` *procedure*

`Proc` should accept two arguments, should return a single value, and
should not mutate `hashtable`.  The `hashtable-update-all!` procedure
applies `proc` once for every association in `hashtable`, passing it
the key and value as arguments, and changes the value of the
association to the return value of `proc`.  The order in which `proc`
is applied to the associations is unspecified.
`Hashtable-update-all!` returns an unspecified value.

- `(hashtable-prune! hashtable proc)` *procedure*

`Proc` should accept two arguments, should return a single value, and
should not mutate `hashtable`.  The `hashtable-prune!` procedure
applies `proc` once for every association in `hashtable`, passing it
the key and value as arguments, and deletes the association if `proc`
returns a true value.  The order in which `proc` is applied to the
associations is unspecified.  `Hashtable-prune!` returns an
unspecified value.

*Rationale:* This procedure is provided in place of a typical "filter"
and "remove" pair because the name "remove" may easily be confused
with "delete," and because the semantics of a mutative filtering
operation, which is to select elements to keep and remove the rest,
counters the human intuition of selecting elements to remove.

- `(hashtable-merge! hashtable-dest hashtable-source)` *procedure*

Effectively equivalent to:

    (begin
      (hashtable-walk hashtable-source
        (lambda (key value)
          (hashtable-set! hashtable-dest key value)))
      hashtable-dest)

*Rationale:* The return value is specified to be `hashtable-dest` only
for compatibility with the analogous SRFI-69 procedure.  This return
value should not be relied on in new code.  On the other hand, it can
be relied upon that `hashtable-dest` is mutated.

- `(hashtable-sum hashtable init proc)` *procedure*

`Proc` should accept three arguments, should return a single value,
and should not mutate `hashtable`.  The `hashtable-sum` procedure
accumulates a result by applying `proc` once for every association in
`hashtable`, passing it as arguments: the key, the value, and the
result of the previous application or `init` at the first application.
The order in which `proc` is applied to the associations is
unspecified.

- `(hashtable-map->lset hashtable proc)` *procedure*

`Proc` should accept two arguments, should return a single value, and
should not mutate `hashtable`.  The `hashtable-map->lset` procedure
applies `proc` once for every association in `hashtable`, passing it
the key and value as arguments, and accumulates the returned values
into a list.  The order in which `proc` is applied to the
associations, and the order of the results in the returned list, are
unspecified.

*Note:* This procedure can trivially imitate `hashtable->alist`:
`(hashtable-map->lset hashtable cons)`.

*Warning:* Since the order of the results is unspecified, the returned
list should be treated as a set or multiset.  Relying on the order of
results will produce unpredictable programs.

- `(hashtable-find hashtable proc)` *procedure*

`Proc` should accept two arguments, should return a single value, and
should not mutate `hashtable`.  The `hashtable-find` procedure applies
`proc` to associations in `hashtable` in an unspecified order until
one of the applications returns a true value or the associations are
exhausted.  Three values are returned: the key and value of the
matching association or two unspecified values if none matched, and a
Boolean indicating whether any association matched.

- `(hashtable-empty? hashtable)` *procedure*

Effectively equivalent to:

    (zero? (hashtable-size hashtable))

- `(hashtable-pop! hashtable)` *procedure*

Effectively equivalent to:

    (let-values (((key value found?)
                  (hashtable-find hashtable (lambda (k v) #t))))
      (when (not found?)
        (error))
      (hashtable-delete! hashtable key)
      (values key value))

- `(hashtable-inc! hashtable key)` *procedure*
- `(hashtable-inc! hashtable key number)`

Effectively equivalent to:

    (hashtable-update! hashtable key (lambda (v) (+ v number)) 0)

where `number` is 1 when not provided.

- `(hashtable-dec! hashtable key)` *procedure*
- `(hashtable-dec! hashtable key number)`

Effectively equivalent to:

    (hashtable-update! hashtable key (lambda (v) (- v number)) 0)

where `number` is 1 when not provided.


### Inspection

- `(hashtable-equivalence-function hashtable)` *procedure*

Returns the equivalence function used by `hashtable` to compare keys.
For hashtables created with `make-eq-hashtable` and
`make-eqv-hashtable`, returns `eq?` and `eqv?` respectively.

- `(hashtable-hash-function hashtable)` *procedure*

Returns the hash function(s) used by `hashtable`, that is, either a
procedure, or a pair of procedures.  For hashtables created by
`make-eq-hashtable` or `make-eqv-hashtable`, `#f` is returned.

*Note:* Implementations using a hashing strategy that involves a
single hash function may return a single procedure even when a pair of
procedures was passed to `make-hashtable`.  Implementations preferring
a hashing strategy involving a pair of hash functions may return a
pair of procedures even when a single procedure was passed to
`make-hashtable`.  In any case, all values returned by this procedure
are suitable for the `hash` argument of `make-hashtable` and must
result in a hashtable with equivalent hashing behavior.

- `(hashtable-weakness hashtable)` *procedure*

Returns the weakness attribute of `hashtable`.  The same values that
are accepted as the `weakness` argument in the constructor procedures
are returned.  This procedure may expose the fact that weak-key and
weak-value hashtables are implemented as ephemeral-key and
ephemeral-value hashtables, returning symbols indicating the latter
even when the former were used to construct the hashtable.

- `(hashtable-mutable? hashtable)` *procedure*

Returns `#t` if `hashtable` is mutable, otherwise `#f`.


### Hash functions

The `equal-hash`, `string-hash`, and `string-ci-hash` procedures of
this section are acceptable as the hash functions of a hashtable only
if the keys on which they are called are not mutated while they remain
in use as keys in the hashtable.

An implementation may initialize its hash functions with a random salt
value at program startup, meaning they are not guaranteed to return
the same values for the same inputs across multiple runs of a program.
If however the environment variable `SRFI_126_HASH_SEED` is set to a
non-empty string before program startup, then the salt value is
derived from that string in a deterministic manner.

- `(hash-salt)` *syntax*

Expands to a form evaluating to an exact non-negative integer that
lies within the fixnum range of the implementation.  The value the
expanded form evaluates to remains constant throughout the execution
of the program.  It is random for every run of the program, except
when the environment variable `SRFI_126_HASH_SEED` is set to a
non-empty string before program startup, in which case it is derived
from the value of that environment variable in a deterministic manner.

- `(equal-hash obj)` *procedure*

Returns an integer hash value for `obj`, based on its structure and
current contents.  This hash function is suitable for use with
`equal?` as an equivalence function.

*Note:* Like `equal?`, the `equal-hash` procedure must always
terminate, even if its arguments contain cycles.

- `(string-hash string)` *procedure*

Returns an integer hash value for `string`, based on its current
contents.  This hash function is suitable for use with `string=?` as
an equivalence function.

- `(string-ci-hash string)` *procedure*

Returns an integer hash value for `string` based on its current
contents, ignoring case.  This hash function is suitable for use with
`string-ci=?` as an equivalence function.

- `(symbol-hash symbol)` *procedure*

Returns an integer hash value for `symbol`.


Implementation
--------------

Larceny Scheme contains a portable implementation of the R6RS
hashtables API as an R7RS library.  It is included in the version
control repository of this SRFI under `r6rs/hashtables.sld`.

A straightforward implementation of this SRFI as an R6RS library is
included in the version control repository under `srfi/:126.sls`, and
an R7RS variant under `srfi/126.sld`.  (The R6RS and R7RS libraries
use the same body of code, with different library boilerplate.)  The
implementation lacks weak and ephemeral hashtables and external
representation, and some procedures are implemented inefficiently
since there is no access to the underlying mechanics of the
hashtables.

Weak and ephemeral hashtables cannot be implemented by portable
library code.  They need to be implemented either directly at the
platform level, or by using functionality which in turn needs to be
implemented at the platform level, such as weak and ephemeral pairs.
See MIT/GNU Scheme for an example.

External representation cannot be implemented by portable library
code.

A sample implementation for GNU Guile is included in the version
control repository under `srfi/srfi-126.scm`.  It installs external
representation support into the Guile runtime when the library is
loaded (without `quasiquote` integration), and supports all types of
weakness which Guile has native support for.  This is achieved in
approximately 350 lines of library code.


Acknowledgments
---------------

Thanks to Taylor Campbell and MIT/GNU Scheme for inspiring the idea of
weak and ephemeral hashtables, some miscellaneous procedures, and
overall input in the design of this SRFI.

Thanks to Mark Weaver for his review of and comments on the SRFI,
which had substantial effect on the result.

Thanks to Jorgen Schäfer for numerous comments on the SRFI which
helped in the decision making.

Thanks also to everyone on the discussion mailing list for their
extensive input that helped shape this SRFI.


Copyright and license
---------------------

Copyright (C) Taylan Ulrich Bayırlı/Kammer (2015, 2016). All Rights Reserved.

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
