OPAM_INIT      = ~/.opam/opam-init/init.sh
BIN_DIR        = ./bin/
OCAM_BLD_OPTS  = -use-ocamlfind
PARSER_GENR   := ocamlyacc
TEST_OPTS     := -v
TEST_SUITE     = e2e-tests

all : clean eqeq


# Real targets:

eqeq :
	bash -c 'source $(OPAM_INIT) && ocamlbuild $(OCAM_BLD_OPTS) ./$@.native'

scanner scanner.ml : scanner.mll
	ocamllex scanner.mll

# usage: `make PARSER_GENR=menhir {parser,eqeq,...}`
parser parser.ml parser.mli : parser.mly
	$(PARSER_GENR) parser.mly

%.cmo : %.ml
	ocamlc -c $<

%.cmi : %.mli
	ocamlc -c $<

debugtokens : debugtokens.ml
	bash -c 'source $(OPAM_INIT) && ocamlbuild $(OCAM_BLD_OPTS) ./$@.native'


.PHONY : clean test eqeq all e2e warnEqeq

e2e : test lint

# colorize warnings from ocaml compiler
warnEqeq:
	$(MAKE) eqeq | grep --color=auto -E '^|^Warning'

test : clean warnEqeq $(BIN_DIR)/$(TEST_SUITE).sh
	$(BIN_DIR)/$(TEST_SUITE).sh $(TEST_OPTS)

lint:
	@$(BIN_DIR)/lint.sh

clean :
	ocamlbuild -clean
	$(BIN_DIR)/$(TEST_SUITE).sh -c
	$(RM) ./$(TEST_SUITE).log
	$(RM) *.diff *.native scanner.ml
	$(RM) parser.ml parser.mli parser.output parser.conflicts
	$(RM) *.cmx *.cmi *.cmo *.cmx *.o


# Generated 20160321@18:20, with:
#   make clean &&
#      make scanner &&
#      make parser &&
#      ocamldep *.ml *.mli
ast.cmo :
ast.cmx :
codegen.cmo : sast.cmo ast.cmo
codegen.cmx : sast.cmx ast.cmx
debugtokens.cmo : scanner.cmo parser.cmi ast.cmo
debugtokens.cmx : scanner.cmx parser.cmx ast.cmx
eqeq.cmo : semant.cmo scanner.cmo sast.cmo parser.cmi codegen.cmo ast.cmo
eqeq.cmx : semant.cmx scanner.cmx sast.cmx parser.cmx codegen.cmx ast.cmx
parser.cmo : ast.cmo parser.cmi
parser.cmx : ast.cmx parser.cmi
relation.cmo : sast.cmo ast.cmo
relation.cmx : sast.cmx ast.cmx
sast.cmo : ast.cmo
sast.cmx : ast.cmx
scanner.cmo : parser.cmi
scanner.cmx : parser.cmx
semant.cmo : sast.cmo relation.cmo ast.cmo
semant.cmx : sast.cmx relation.cmx ast.cmx
parser.cmi : ast.cmo
