# Make sure ocamlbuild can find opam-managed packages: first run
#
# eval `opam config env`

# Easiest way to build: using ocamlbuild, which in turn uses ocamlfind

OPAM_INIT      = ~/.opam/opam-init/init.sh
OCAM_BLD_OPTS  = -use-ocamlfind -pkgs llvm,llvm.analysis -cflags -w,+a-4
PARSER_GENR   := ocamlyacc

# Copy/pasted make-targets from generated list at bottom of file:
OBJS = ast.cmo ast.cmx codegen.cmo codegen.cmx microc.cmo microc.cmx parser.cmo parser.cmx scanner.cmo scanner.cmx semant.cmo semant.cmx parser.cmi

eqeq.native:
	bash -c 'source $(OPAM_INIT) && ocamlbuild $(OCAM_BLD_OPTS) eqeq.native'

test: clean eqeq.native testall.sh
	./testall.sh -v tests/*.eq

clean :
	ocamlbuild -clean
	$(RM) testall.log *.diff eqeq scanner.ml
	$(RM) parser.ml parser.mli parser.output parser.conflicts
	$(RM) *.cmx *.cmi *.cmo *.cmx *.o
	$(RM) test-*.out test-*.ll

eqeq : $(OBJS)
	ocamlc $@ microc.ml
	ocamlc *.cmx -o $@

scanner scanner.ml : scanner.mll
	ocamllex scanner.mll

parser parser.ml parser.mli : parser.mly
	$(PARSER_GENR) parser.mly

%.cmo : %.ml
	ocamlc -c $<

%.cmi : %.mli
	ocamlc -c $<

# %.cmx : %.ml
# 	ocamlfind ocamlopt -c -package llvm $<

.PHONY : clean test eqeq.native


# Generated 20160321@18:20, with:
#   make clean &&
#      make scanner &&
#      make parser &&
#      ocamldep *.ml *.mli
ast.cmo :
ast.cmx :
codegen.cmo : ast.cmo
codegen.cmx : ast.cmx
microc.cmo : semant.cmo scanner.cmo parser.cmi codegen.cmo ast.cmo
microc.cmx : semant.cmx scanner.cmx parser.cmx codegen.cmx ast.cmx
parser.cmo : ast.cmo parser.cmi
parser.cmx : ast.cmx parser.cmi
scanner.cmo : parser.cmi
scanner.cmx : parser.cmx
semant.cmo : ast.cmo
semant.cmx : ast.cmx
parser.cmi : ast.cmo
