# {{{1 Configurações gerais
#      ====================

VPATH = .:assets
vpath %.csl _csl
vpath %.html .:_includes:_layouts:_site
vpath %.scss assets/css
vpath %.xml _site
vpath %.yaml .:_spec
vpath default.% _lib

PANDOC/CROSSREF := docker run -v "`pwd`:/data" --user "`id -u`:`id -g`" pandoc/crossref:2.10

ROOT    = $(filter-out README.md,$(wildcard *.md))
PAGES  := $(patsubst %.md,_site/%.html,$(ROOT))
DOCS    = $(wildcard _docs/*.md)
SLIDES := $(patsubst _docs/%.md,_site/aula/%/index.html,$(DOCS))
NOTAS  := $(patsubst _docs/%.md,_site/aula/%/notas.html,$(DOCS))

deploy : _site/index.html $(PAGES) $(SLIDES) $(NOTAS) _site/package-lock.json

# {{{1 Produtos PDF
#      ============

%.pdf : %.tex
	docker run -i -v "`pwd`:/data" --user "`id -u`:`id -g`" \
		-v "`pwd`/assets/fonts:/usr/share/fonts" blang/latex:ctanfull \
		latexmk -pdflatex="xelatex" -cd -f -interaction=batchmode -pdf $<

tau0006-plano.tex : pdf.yaml plano.md plano-metodo.md plano-programa.md \
	plano-apoio-avalia.md biblio-leitura.md plano-biblio.md | _csl
	$(PANDOC/CROSSREF) -o $@ -d $^

tau0006-cronograma.tex : pdf.yaml cronograma.md cronograma-pdf.md
	$(PANDOC/CROSSREF) -o $@ -d $^

%.tex : pdf.yaml %.md | default.latex
	$(PANDOC/CROSSREF) -o $@ -d $^

# {{{1 Slides, notas de aula e outros HTML
#      ===================================

.pages : $(PAGES)
	touch .pages

.notas : $(NOTAS)
	touch .notas

.slides : $(SLIDES)
	touch .slides

_site/index.html : README.md _config.yaml _sass assets reveal.js
	docker run -v "`pwd`:/srv/jekyll" jekyll/jekyll:4.1.0 \
		/bin/bash -c "chmod 777 /srv/jekyll && jekyll build --future"

_site/%.html : html.yaml %.md | _csl _site/index.html
	$(PANDOC/CROSSREF) -o $@ -d $^

_site/aula/%/index.html : revealjs.yaml _docs/%.md | _csl _site/index.html
	@mkdir -p _site/aula/$*
	$(PANDOC/CROSSREF) -o $@ \
		-V multiplexSecret=$(multiplexSecret) \
		-V multiplexSocketId=$(multiplexSocketId) \
		-V multiplexUrl=$(multiplexUrl) \
	  -d $^

_site/aula/%/notas.html : html.yaml _docs/%.md | _csl _site/index.html
	@mkdir -p _site/aula/$*
	$(PANDOC/CROSSREF) -o $@ -d $^

_site/package-lock.json : package.json | _site
	cp package.json _site/
	cd _site && npm install

# {{{1 PHONY
#      =====

_csl :
	git clone https://github.com/citation-style-language/styles.git _csl

serve :
	docker run -v "`pwd`:/srv/jekyll" jekyll/jekyll:4.1.0 \
		jekyll serve --skip-initial-build

clean :
	rm -rf _csl *.aux *.bbl *.bcf *.blg *.fdb_latexmk *.fls *.log *.run.xml

# vim: set foldmethod=marker shiftwidth=2 tabstop=2 :
