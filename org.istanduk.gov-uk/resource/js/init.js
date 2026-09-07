/* Initialise govuk-frontend components. The version is filled in at build time
   from resource/govuk-frontend/VERSION.txt; keeping this in a file rather than
   an inline module script lets pages carry a strict Content-Security-Policy. */
import { initAll } from './govuk-frontend-@GOVUK_FRONTEND_VERSION@.min.js';
initAll();
