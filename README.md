# PDF Sign & Watermark — Flutter hiring task

Graphics Cycle Flutter Developer take-home (short version). Flutter 3.x, null-safety, **MVC**.

## What it does

1. Pick a real PDF from the device.
2. Open **Signature** or **Watermark**.
3. Configure the overlay.
4. Tap **Done** / **Apply** → a new merged PDF is written to app documents and can be opened or shared.

Flow: `Pick PDF → Signature or Watermark screen → configure → Done/Apply → saved PDF`.

## Task coverage

### Signature (Type tab)

- App bar back + title **Draw Signature**
- Name field with clear (X); red border on focus
- Live preview (font / size / weight / color)
- 5 font thumbnails (red border = selected)
- Size slider **20–80 pt** with live readout
- Two weight boxes (`Aa` light / bold)
- 8 color swatches (red ring = selected)
- **Placement:** tap/drag on a page-1 canvas. **Default is bottom-center of page 1** (`Offset(0.5, 0.82)`).
- Full-width red **Done** stamps the typed name into the picked PDF and saves a new file
- **Draw** tab captures a handwritten signature from a touch/stylus canvas and exports it as PNG
- **Import** tab selects a real PNG/JPG signature image and previews it
- Drawn/imported signatures are embedded into page 1 of the saved PDF

### Watermark (Text tab)

- Text / Image tabs (Text default, red); Image supports picking, preview, replacement and removal
- Text Format card: placeholder `Watermark`, font family dropdown, size (default 14), style Regular / Italic / Bold / Bold Italic, color swatch + hex, color picker
- Position card: 3x3 anchor grid, over/under content layer selector, live dimension badge
- Adjustments: opacity **0–100%**, rotation **-180° to +180°**, tap/drag placement (default page center)
- Page range: validated **From Page / To Page** fields using the actual PDF page count
- Full-width red **Apply Watermark** action
- Image tab: selects a real PNG/JPG (or another supported image), previews it, and embeds it into the output PDF

## MVC

| Layer | Path | Role |
| --- | --- | --- |
| Model | `lib/models/` | `PickedPdf`, `SignatureModel`, `WatermarkModel`, `PdfRepository` (stamp + save) |
| View | `lib/views/` | UI only; listens to controllers |
| Controller | `lib/controllers/` | User actions, validation, calls repository, `notifyListeners()` |

Views do not import Syncfusion. PDF bytes are stamped in the model repository.

## Placement choice (README as required)

Interactive tap/drag is implemented. If the user never moves the signature, it lands at **bottom-center of page 1**. Watermark defaults to **center**, rotated **-45°**.

## Run

```bash
flutter pub get
flutter run
```

Use a physical Android/iOS device or emulator. Pick any small PDF, configure a tab, and tap Done.

## Notes

- TrueType signature fonts are in `assets/fonts/`.
- Watermark uses PDF standard fonts (Helvetica / Times / Courier) so bold/italic map cleanly.
- Output files: `{app documents}/signed_*` or `watermarked_*`.
- Watermarks are written to a named Syncfusion PDF layer on every selected page. The
	selected layer name is persisted in the generated PDF for PDF viewers that support
	optional content layers, and the selected page range remains strictly enforced.
	Syncfusion's public loaded-page API does not expose insertion before existing page
	content, so the Under Content choice is represented as an optional-content layer
	rather than a guaranteed z-order change in every PDF viewer.

## Deliverables

- Flutter 3.x null-safe implementation with MVC structure
- Real PDF signature and watermark processing using Syncfusion PDF
- Output saved to the app documents directory and exposed in the saved-file dialog
- Estimated implementation time: approximately 6 hours, including UI, PDF processing,
  validation, device checks, and final polish
