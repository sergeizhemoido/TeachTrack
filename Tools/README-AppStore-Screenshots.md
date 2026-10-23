# App Store screenshots

`AppStoreScreenshotsUITests.testCaptureSevenScreens` launches TeachTrack with
`-AppStoreDemoData`. In Debug builds, this creates a fresh **in-memory** SwiftData
store containing fictional organizations, students, schedules, lessons,
attendance, charges, payments, deposits, and unpaid balances. It does not
modify the normal local database or the CloudKit archive.

Run the screenshot test separately on an iPhone 11 Pro Max for the 6.5-inch
1242 × 2688 set, an iPhone 17 Pro Max for the 6.9-inch 1320 × 2868 set,
and an iPad Pro 13-inch (M5) simulator. Before each run, set the simulator
status bar to 9:41.
Each successful `.xcresult` contains seven named screenshot attachments:
organizations, students, calendar, finance, unpaid balances, lesson history,
and payment history.

Export and validate a result bundle with:

```sh
python3 Tools/export_app_store_screenshots.py /path/to/iPhone.xcresult iphone /path/to/iPhone-output
python3 Tools/export_app_store_screenshots.py /path/to/iPhone-6.5.xcresult iphone-6.5 /path/to/iPhone-6.5-output
python3 Tools/export_app_store_screenshots.py /path/to/iPad.xcresult ipad /path/to/iPad-output
```

The exporter requires exactly seven screenshots, verifies that the PNGs match
the selected device dimensions, and rejects PNG alpha channels.
The simulator's date controls the relative lesson dates in the demo data.

The generated screenshots are ready to upload as app screenshots. App Store
Connect listing text, privacy answers, pricing, availability, and submission
remain separate release tasks.
