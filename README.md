How to run the test suites
==========================


Chibi (R7RS)
------------

- Clone the Larceny source repository:
  https://github.com/larcenists/larceny

- Clone the R7RS SRFI implementations repository:
  https://github.com/TaylanUB/scheme-srfis

- `chibi -A $LARCENY_REPO/tools/R6RS -A $R7RS_SRFIS_REPO -A . test-suite.r7rs.scm`
  (where `$LARCENY_REPO` and `$R7RS_SRFIS_REPO` are substituted with
  the correct directory names)

14 test failures are expected, as mentioned in the note printed at the
end of the test suite program.


Guile
-----

- `guile -L . test-suite.r6rs.sps`


Guile (R6RS)
------------

- Remove or move away the existing file `srfi/srfi-126.scm`.

- Copy `srfi/:126.sls` to `srfi/srfi-126.scm`; open it and change the
  library name to `(srfi srfi-126)`.

- `guile -L . test-suite.r6rs.sps`

16 test failures are expected; 14 because Guile exposes the hash
functions of `eq?` and `eqv?` hashtables, and 2 because Guile's
`hashtable-set!` doesn't raise an error on immutable hashtables.


Larceny (R7RS)
--------------

- Clone the Larceny source repository:
  https://github.com/larcenists/larceny

- Clone the R7RS SRFI implementations repository:
  https://github.com/TaylanUB/scheme-srfis

- `export LARCENY_LIBPATH="$LARCENY_REPO/tools/R6RS:$R7RS_SRFIS_REPO:$THIS_REPO"`
  (where `$LARCENY_REPO`, `$R7RS_SRFIS_REPO`, and `$THIS_REPO` are
  substituted with the correct directory names)

- `larceny -r7rs -program test-suite.r7rs.scm`


Larceny (R6RS)
--------------

- Clone the Larceny source repository:
  https://github.com/larcenists/larceny

- Clone the R7RS SRFI implementations repository:
  https://github.com/TaylanUB/scheme-srfis

- Copy `srfi/:126.sls` to `srfi/srfi-126.sls`; open it and change the
  library name to `(srfi srfi-126)`.

- Open `test-suite.r6rs.sps`.  Change the import `(srfi :64)` to
  `(srfi 64)`, and `(srfi :126)` to `(srfi srfi-126)`.

- `export LARCENY_LIBPATH="$LARCENY_REPO/tools/R6RS:$R7RS_SRFIS_REPO:$THIS_REPO"`
  (where `$LARCENY_REPO`, `$R7RS_SRFIS_REPO`, and `$THIS_REPO` are
  substituted with the correct directory names)

- `larceny -r6rs -program test-suite.r6rs.sps`
