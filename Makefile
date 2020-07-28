VPATH = .:assets
vpath %.html .:_includes:_layouts:_site
vpath %.scss assets/css
vpath %.xml _site
vpath %.yaml spec
vpath default.% lib

DOCS      = $(wildcard docs/*.md)
REVEALJS  = $(wildcard _slides/*.md)
SLIDES   := $(patsubst _slides/%.md,_site/_slides/%.html,$(REVEALJS))
PAGES     = $(filter-out README.md,$(wildcard *.md))
HTML     := $(patsubst %.md,_site/%.html,$(PAGES))

deploy : jekyll slides

tau0006-%.pdf : %.tex
	docker run -i -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		-v "`pwd`/assets/fonts:/usr/share/fonts" blang/latex:ctanfull \
		latexmk -pdflatex="xelatex" -cd -f -interaction=batchmode -pdf $<
	mv $*.pdf $@

plano.tex : pdf.yaml plano.md plano-metodo.md plano-programa.md \
	plano-apoio-avalia.md biblio-leitura.md plano-biblio.md | styles
	docker run -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		pandoc/core:2.10 -o $@ -d $^

%.tex : pdf.yaml %.md | default.latex
	docker run -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		pandoc/core:2.10 -o $@ -d $^

pandoc : $(HTML)

_site/%.html : html.yaml %.md | styles
	docker run -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		pandoc/core:2.10 -o $@ -d $^

slides : $(SLIDES)

_site/_slides/%.html : revealjs.yaml %.md | styles
	docker run -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		pandoc/core:2.10 -o $@ -d $^

jekyll : clean $(PAGES) README.md
	docker run --rm -v "`pwd`:/srv/jekyll" \
		jekyll/jekyll:4.1.0 /bin/bash -c "chmod 777 /srv/jekyll && jekyll build"

serve :
	docker run --rm -p 4000:4000 -h 127.0.0.1 \
		-v "`pwd`:/srv/jekyll" -it jekyll/jekyll:4.1.0 \
		jekyll serve --skip-initial-build --no-watch

styles :
	git clone https://github.com/citation-style-language/styles.git

clean :
	rm -rf styles *.aux *.bbl *.bcf *.blg *.fdb_latexmk *.fls *.log *.run.xml
