(lang dune 3.2)
(using dune_site 0.1)

(name brr)
(version v0.0.7+dune)

(generate_opam_files true)

(license ISC BSD-3-Clause)

(authors "The brr programmers")

(maintainers "Daniel Bünzli <daniel.buenzli@erratique.ch>")

(source (uri git+https://erratique.ch/repos/brr.git))

(homepage "https://erratique.ch/software/brr")
(bug_reports "https://github.com/dbuenzli/brr/issues")
(documentation "https://erratique.ch/software/brr/doc/")

(package
 (name brr)
 (synopsis "Browser programming toolkit for OCaml")
 (description
  "Brr is a toolkit for programming browsers in OCaml with the
[`js_of_ocaml`][jsoo] compiler. It provides:

* Interfaces to a selection of browser APIs.
* An OCaml console developer tool for live interaction
  with programs running in web pages.
* A JavaScript FFI for idiomatic OCaml programming.

Brr is distributed under the ISC license. It depends on the
`js_of_ocaml` compiler and runtime – but not on its libraries or
syntax extension.

[jsoo]: https://ocsigen.org/js_of_ocaml

Homepage: <https://erratique.ch/software/brr>")
 (tags (reactive declarative frp front-end browser org:erratique))
 (sites (share console))
 (depends
  (ocaml               (>= 4.08.0))
  (dune                :build)
  (ocamlfind           :build)
  (js_of_ocaml-compiler (>= 5.5.0))
  (js_of_ocaml-toplevel (>= 5.5.0))))
