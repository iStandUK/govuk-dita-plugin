# PDF/UA negative fixture

A publication that must **fail** PDF/UA-1 (#164). Its one figure is an image with
no alternative text. CI builds it with DesignSystemPDF and expects:

- DesignSystemPDF to warn `DSPDF009W` and still write the PDF;
- veraPDF to report the PDF as not compliant.

If either stops happening, the accessibility check has been weakened. Do not
"fix" this fixture by adding alternative text.
