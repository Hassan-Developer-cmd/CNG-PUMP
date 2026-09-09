# CNG Meter OCR Fix

The OCR flow was changed to be fail-safe and meter-focused.

## What changed
- OCR parser no longer chooses the largest/highest number in the image.
- Only numeric-looking meter lines are accepted.
- Arbitrary text with embedded numbers is rejected.
- Camera capture continues to crop to the scanner window before OCR.
- OCR runs twice: original crop + grayscale crop.
- Matching results are accepted by consensus.
- Conflicting OCR results are rejected instead of guessing.
- When no trustworthy reading exists, the provider returns an error instead of a random number.
- Existing manual editing remains available in the UI.

## Important
For best accuracy, keep the meter display inside the scanner frame and make sure the digits are in focus. ML Kit accuracy depends on image resolution and focus.
