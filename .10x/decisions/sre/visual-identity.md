# SRE: visual-identity (task 2.2a) and the site

- **Availability:** since `b2e3e19` the site depends on one host only, GitHub Pages. CanvasKit, the fonts and the clips all come from it. Before that, a blocked `www.gstatic.com` stopped the app from starting at all.
- **First visit:** 18 requests and 3,268,230 bytes on the wire (2026-10-29). GitHub Pages lets the browser keep files for 10 minutes, and each deploy gives every file a new date, so a visitor downloads CanvasKit again after a deploy.
- **Budget:** the GitHub Pages soft limit of 100 GB a month is about 30,000 first visits.
- **Monitoring:** none, on purpose: there is no server and no telemetry. After each deploy the signals are CI's run and a check of the live site in headless Chrome with a fresh profile (`cdp.dart` in the merge session's notes folder).
- **Alarm reliability:** 2.2a does not schedule or ring. The record and the countdown only show `nextRing`.
