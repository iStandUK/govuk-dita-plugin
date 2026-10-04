# Map of bookmaps fixture

For #178. `library.ditamap` references two bookmaps, *The alpha book* and
*The beta book*. The build makes one site; `print.html` holds the whole set,
and `print-alpha.html` and `print-beta.html` each hold one book, under its
own title, author and edition. The alpha book's link to the beta book goes
to the website in `print-alpha.html`, and within the document in
`print.html`.
