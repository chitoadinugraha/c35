enum ComposerActionKind { mic, send, abort, recStop }

ComposerActionKind composerActionKind({required bool streaming, required bool recording, required bool hasText}) =>
    recording
        ? ComposerActionKind.recStop
        : streaming
            ? (hasText ? ComposerActionKind.send : ComposerActionKind.abort)
            : hasText
                ? ComposerActionKind.send
                : ComposerActionKind.mic;
