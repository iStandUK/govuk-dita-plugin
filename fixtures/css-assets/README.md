# css-assets fixture

`assets/` stands for the folder of files a publisher's stylesheet refers to with `url()`
(#197). CI builds with `-Dgovuk.css.assets` naming it and asserts that its contents arrive,
subfolders included, beside the stylesheet in `args.csspath`.
