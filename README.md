# PhotoLibraryPickerTest

A test project to pick an image or video on iOS using PHPicker and loadFileRepresentation

Tap the `Pick Video` button. You will need to grant `Always Allow` authorization to the Photo Library on first run.

The picker is filtered to videos. Select a video, the URL will be shown. 

The video will tried to be copied to a temp directory, as suggested on various threads and docs.

The copy fails.

References:
- [Documentaton: loadFileRepresentation](https://developer.apple.com/documentation/foundation/nsitemprovider/2888338-loadfilerepresentation)
- [Developer Forums: Could not load some videos](https://developer.apple.com/forums/thread/652695)
- [Developer Forums: How to correctly load video selected with PHPickerViewController?](https://developer.apple.com/forums/thread/661834)
