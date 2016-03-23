OPAM_INIT      = ~/.opam/opam-init/init.sh
OCAM_BLD_OPTS  = -use-ocamlfind
PARSER_GENR   := ocamlyacc
# Copy/pasted *.cmo make-targets (from generated list at bottom of file)
OBJS = ast.cmo codegen.cmo eqeq.cmo parser.cmo scanner.cmo semant.cmo


all : clean eqeq

eqeq :
	bash -c 'source $(OPAM_INIT) && ocamlbuild $(OCAM_BLD_OPTS) ./$@.native'

scanner scanner.ml : scanner.mll
	ocamllex scanner.mll

parser parser.ml parser.mli : parser.mly
	$(PARSER_GENR) parser.mly
# eg: `make PARSER_GENR=menhir parser/whatever`

%.cmo : %.ml
	ocamlc -c $<

%.cmi : %.mli
	ocamlc -c $<

debugtokens: debugtokens.ml
	bash -c 'source $(OPAM_INIT) && ocamlbuild $(OCAM_BLD_OPTS) ./$@.native'

.PHONY : clean test eqeq all

test: clean eqeq.native testall.sh
	./testall.sh -v tests/*.eq

lint:
	@./lint.sh

clean :
	ocamlbuild -clean
	$(RM) *.diff *.native scanner.ml
	$(RM) parser.ml parser.mli parser.output parser.conflicts
	$(RM) *.cmx *.cmi *.cmo *.cmx *.o
	$(RM) testall.log


# Generated 20160321@18:20, with:
#   make clean &&
#      make scanner &&
#      make parser &&
#      ocamldep *.ml *.mli
ast.cmo :
ast.cmx :
codegen.cmo : ast.cmo
codegen.cmx : ast.cmx
eqeq.cmo : semant.cmo scanner.cmo parser.cmi codegen.cmo ast.cmo
eqeq.cmx : semant.cmx scanner.cmx parser.cmx codegen.cmx ast.cmx
parser.cmo : ast.cmo parser.cmi
parser.cmx : ast.cmx parser.cmi
scanner.cmo : parser.cmi
scanner.cmx : parser.cmx
semant.cmo : ast.cmo
semant.cmx : ast.cmx
parser.cmi : ast.cmo
