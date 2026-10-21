# subfolder-root

Where the root map sits relative to its topics (#239).

`maps/book.ditamap` is a root map in a subfolder, with its topic and images in folders beside
it. Built as the root, DITA-OT reports `DOTJ036W` and the plugin reports `GOVK016W` (the root
map is below the top of its tree) and `GOVK005W` (the diagram is outside the input directory,
so it is not inlined). `--args.input.dir` set to this folder widens the plugin's own inline
scope, so the diagram is inlined and `GOVK005W` goes; `DOTJ036W` and `GOVK016W` stay, because
the toolkit's test and the site's layout do not follow it.

`top.ditamap` is the layout the manual asks for: the root map at the top of the tree, with
`maps/book.ditamap` included by `<mapref href>`. It builds without any of the three.
