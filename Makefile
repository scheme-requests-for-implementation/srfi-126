srfi-126.html: srfi-126.md
	pandoc \
	  --css=http://srfi.schemers.org/srfi.css \
	  --from=markdown_github-hard_line_breaks \
	  --include-in-header=header.html \
	  --standalone \
	  --to=html \
	  --metadata=title:"R6RS-based hashtables" \
	  srfi-126.md \
	  >srfi-126.html
