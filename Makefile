all: srfi-126.html \
     srfi/\:126.sls \
     srfi/126.sld \
     test-suite.r6rs.sps \
     test-suite.r7rs.scm

srfi-126.html: srfi-126.md
	pandoc \
	  --from=markdown_github-hard_line_breaks+pandoc_title_block \
	  --standalone \
	  --to=html \
	  --include-in-header=header.html \
	  --css=http://srfi.schemers.org/srfi.css \
	  srfi-126.md \
	  >srfi-126.html

srfi/%126.sls: srfi/\:126.sls.in srfi/126.body.scm
	sed "/;; INCLUDE 126.body.scm/ r srfi/126.body.scm" \
	  < srfi/:126.sls.in > srfi/:126.sls

srfi/126.sld: srfi/126.sld.in srfi/126.body.scm
	sed "/;; INCLUDE 126.body.scm/ r srfi/126.body.scm" \
	  < srfi/126.sld.in > srfi/126.sld

test-suite.r6rs.sps: test-suite.r6rs.sps.in test-suite.body.scm
	sed "/;; INCLUDE test-suite.body.scm/ r test-suite.body.scm" \
	  < test-suite.r6rs.sps.in > test-suite.r6rs.sps

test-suite.r7rs.scm: test-suite.r7rs.scm.in test-suite.body.scm
	sed "/;; INCLUDE test-suite.body.scm/ r test-suite.body.scm" \
	  < test-suite.r7rs.scm.in > test-suite.r7rs.scm
