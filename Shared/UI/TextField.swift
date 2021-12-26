// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

#if os(macOS)
import Foundation
import AppKit
import mbientSwiftUI
import Combine

struct ResigningTextField: View {

    var placeholderText: String
    var initialText: String

    var config: TextFieldConfig
    var onCommit: (String) -> Void

    @State private var text = ""

    var body: some View {
#if os(macOS)
        macTextField
#elseif os(iOS)
        iOSTextField
            .onAppear { text = placeholderText }
#endif
    }
#if os(macOS)
    private var macTextField: some View {
        SingleLineTextField(initialText: initialText,
                            placeholderText: placeholderText,
                            config: config,
                            onCommit: onCommit,
                            onCancel: { }
        )
            .alignmentGuide(.firstTextBaseline) { $0[.firstTextBaseline] + 1 }
            .frame(height: config.size * 1.25, alignment: .leading)
    }
#endif

    private var iOSTextField: some View {
        TextField(placeholderText, text: $text) { _ in } onCommit: { onCommit(text) }
        .font(.title2)
    }
}

struct TextFieldConfig {
    var textColor: Color = .primary
    var font: Font
    let size: CGFloat
    var weight: NSFont.Weight = .medium
    var design: NSFontDescriptor.SystemDesign = .rounded
    var lineBreakMode: NSLineBreakMode = .byTruncatingMiddle
    var alignment: NSTextAlignment = .left

    static func largeDeviceStyle() -> Self {
        self.init(font: .system(.title), size: 18)
    }
}

// MARK: - Components

struct SingleLineTextField: NSViewControllerRepresentable {

    var initialText: String
    var placeholderText: String
    var config: TextFieldConfig

    let onCommit: ((String) -> Void)
    let onCancel: (() -> Void)

    func makeNSViewController(context: Context) -> SingleLineTextFieldVC {
        let vc = SingleLineTextFieldVC(
            initialText: initialText,
            placeholder: placeholderText,
            font: .systemFont(ofSize: config.size, weight: config.weight),
            size: config.size,
            alignment: config.alignment
        )
        vc.field.textColor = NSColor(config.textColor)
        vc.field.textContainer?.lineBreakMode = config.lineBreakMode
        vc.onCommit = onCommit
        vc.onCancel = onCancel
        return vc
    }

    func updateNSViewController(_ vc: SingleLineTextFieldVC,
                                context: Context) {
        vc.field.string = initialText
        vc.field.textColor = NSColor(config.textColor)
        vc.field.font = .systemFont(ofSize: config.size, weight: config.weight)
        switch config.alignment {
            case .left:
                vc.field.alignLeft(nil)

            case .right:
                vc.field.alignRight(nil)

            default:
                vc.field.alignCenter(nil)
        }
    }
}

final class SingleLineTextFieldVC: NSViewController {

    var initialText: String
    var onCommit: ((String) -> Void)? = nil
    var onCancel: (() -> Void)? = nil

    var font: NSFont
    private var applyTextAlignment: NSTextAlignment
    private var subs: Set<AnyCancellable> = []

    let field = CustomCaretTextView(frame: .zero)

    init(initialText: String,
         placeholder: String,
         font: NSFont,
         size: CGFloat,
         alignment: NSTextAlignment) {
        self.initialText = initialText
        self.font = font
        self.applyTextAlignment = alignment
        super.init(nibName: nil, bundle: nil)
        field.setPlaceholder(placeholder, self.font, alignment)
    }

    override func resignFirstResponder() -> Bool {
        onCommit?(field.string)
        return super.resignFirstResponder()
    }

    override func removeFromParent() {
        onCommit?(field.string)
        field.trackingAreas.forEach { [weak self] in self?.field.removeTrackingArea($0) }
        super.removeFromParent()
    }

    override func loadView() {
        view = field
        field.frame = view.frame
        configureTextField()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        resignFirstResponderOnClickMonitor()
    }

    private func configureTextField() {
        field.delegate = self
        field.allowsUndo = false
        field.string = initialText
        field.font = font
        field.alignment = applyTextAlignment
        field.isContinuousSpellCheckingEnabled = false
        field.textContainer?.maximumNumberOfLines = 1
        field.textContainer?.widthTracksTextView = true
        field.backgroundColor = .clear
        field.importsGraphics = false
    }

    private func resignFirstResponderOnClickMonitor() {
        NSApp.publisher(for: \.currentEvent)
            .filter { event in event?.type == NSEvent.EventType.leftMouseDown }
            .sink { [weak self] event in
                guard let self = self,
                      self.view.window?.firstResponder === self.field,
                      let location = event?.locationInWindow else { return }
                let localPoint = self.view.convert(location, from: nil)

                if !self.view.bounds.contains(localPoint) {
                    self.onCommit?(self.field.string)
                    self.view.window?.makeFirstResponder(self.view.window?.nextResponder)
                }
            }
            .store(in: &subs)


        NSApp.publisher(for: \.accessibilityFocusedUIElement)
            .sink { [weak self] element in
                guard let self = self,
                      self.view.window?.firstResponder === self.field
                else { return }

                if (element as? SingleLineTextFieldVC) === self { return }
                else {
                    self.onCommit?(self.field.string)
                    self.view.window?.makeFirstResponder(self.view.window?.nextResponder)
                }
            }
            .store(in: &subs)

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SingleLineTextFieldVC: NSTextViewDelegate {

    override func cancelOperation(_ sender: Any?) {
        onCommit?(field.string)
        onCancel?()
        view.window?.makeFirstResponder(nil)
    }

    func textView(_ view: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            onCommit?(view.string)
            view.window?.makeFirstResponder(nil)
            _ = self.resignFirstResponder()
            return true
        }
        return false
    }
}

class CustomCaretTextView: NSTextView {

    // MARK: - Caret Width

    var caretWidth: CGFloat = 3

    private lazy var radius = caretWidth / 2
    private lazy var displayAdjustment = caretWidth - 1

    open override func drawInsertionPoint(in rect: NSRect, color: NSColor, turnedOn flag: Bool) {

        var rect = rect
        rect.size.width = caretWidth

        let path = NSBezierPath(roundedRect: rect,
                                xRadius: radius,
                                yRadius: radius)
        path.setClip()

        super.drawInsertionPoint(in: rect,
                                 color: NSColor(.myHighlight),
                                 turnedOn: flag)
    }

    open override func setNeedsDisplay(_ rect: NSRect, avoidAdditionalLayout flag: Bool) {
        var rect = rect
        rect.size.width += displayAdjustment
        super.setNeedsDisplay(rect, avoidAdditionalLayout: flag)
    }

    // MARK: - Placeholder String

    func setPlaceholder(_ string: String, _ font: NSFont, _ alignment: NSTextAlignment) {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        placeholder = NSAttributedString(
            string: string, attributes: [
                NSAttributedString.Key.foregroundColor : NSColor.placeholderTextColor,
                NSAttributedString.Key.font : font,
                NSAttributedString.Key.paragraphStyle : style
            ]
        )
    }

    private var placeholder: NSAttributedString? = NSAttributedString(
        string: "", attributes: [NSAttributedString.Key.foregroundColor: NSColor.placeholderTextColor]
    )

    var placeholderInsets: NSEdgeInsets = NSEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)

    override func becomeFirstResponder() -> Bool {
        self.needsDisplay = true
        return super.becomeFirstResponder()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard string.isEmpty else { return }
        placeholder?.draw(in: dirtyRect.insetBy(placeholderInsets))
    }
}


extension NSRect {
    func insetBy(_ insets: NSEdgeInsets) -> NSRect {
        return insetBy(dx: insets.left + insets.right, dy: insets.top + insets.bottom)
            .applying(CGAffineTransform(translationX: insets.left - insets.right, y: insets.top - insets.bottom))
    }
}
#endif
