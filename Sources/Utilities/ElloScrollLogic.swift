////
///  ElloScrollLogic.swift
//

class ElloScrollLogic: NSObject, UIScrollViewDelegate {
    var isRunningSpecs = false

    var prevOffset: CGPoint?
    var shouldIgnoreScroll: Bool = false
    var navBarHeight: CGFloat = 44
    var tabBarHeight: CGFloat = 49
    var barHeights: CGFloat { return navBarHeight + tabBarHeight }
    var lastStateChange = CACurrentMediaTime() - 1

    // showingState starts as "indeterminate".  That means that the first time
    // 'show' or 'hide' is called, it will call the appropriate handler no
    // matter what.
    private var showingState: Bool?
    var isShowing: Bool {
        get { return self.showingState ?? true }
        set {
            if showingState != newValue {
                lastStateChange = CACurrentMediaTime()
            }
            showingState = newValue
        }
    }

    private var onShow: Block
    private var onHide: Block

    init(onShow: @escaping Block, onHide: @escaping Block) {
        self.onShow = onShow
        self.onHide = onHide
        super.init()
    }

    func onShow(_ handler: @escaping Block) {
        self.onShow = handler
    }

    func onHide(_ handler: @escaping Block) {
        self.onHide = handler
    }

    private func changedRecently() -> Bool {
        if isRunningSpecs {
            return false
        }

        let now = CACurrentMediaTime()
        return now - lastStateChange < 0.5
    }

    private func show() {
        let wasShowing = self.showingState ?? false

        if !changedRecently() {
            if !wasShowing {
                let prevIgnore = self.shouldIgnoreScroll
                self.shouldIgnoreScroll = true
                self.onShow()
                self.shouldIgnoreScroll = prevIgnore
                lastStateChange = CACurrentMediaTime()
            }
            showingState = true
        }
    }

    private func hide() {
        let wasShowing = self.showingState ?? true

        if !changedRecently() {
            if wasShowing {
                let prevIgnore = self.shouldIgnoreScroll
                self.shouldIgnoreScroll = true
                self.onHide()
                self.shouldIgnoreScroll = prevIgnore
                lastStateChange = CACurrentMediaTime()
            }
            showingState = false
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !scrollView.isDragging && !isRunningSpecs {
            return
        }

        let nextOffset = scrollView.contentOffset
        let shouldAcceptScroll = self.shouldAcceptScroll(scrollView)

        if shouldAcceptScroll {
            if let prevOffset = prevOffset {
                let didScrollDown = self.didScrollDown(scrollView.contentOffset, prevOffset)

                if didScrollDown {
                    let isAtTop = self.isAtTop(scrollView)
                    if !isAtTop {
                        hide()
                    }
                }
                else {
                    let isAtTop = self.isAtTop(scrollView)
                    let movedALittle = self.movedALittle(scrollView.contentOffset, prevOffset)
                    let movedALot = self.movedALot(scrollView.contentOffset, prevOffset)

                    if isAtTop || !movedALittle && !movedALot {
                        show()
                    }
                }
            }
        }

        prevOffset = nextOffset
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        shouldIgnoreScroll = false
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {
        if self.isAtTop(scrollView) {
            show()
        }
        shouldIgnoreScroll = true
    }

    private func shouldAcceptScroll(_ scrollView: UIScrollView) -> Bool {
        let nearBottom = self.nearBottom(scrollView)
        if shouldIgnoreScroll || nearBottom {
            return false
        }

        let contentSizeHeight = scrollView.contentSize.height
        let scrollViewHeight = scrollView.frame.size.height
        let buffer = CGFloat(10)
        return scrollViewHeight + barHeights + buffer < contentSizeHeight
    }

    private func nearBottom(_ scrollView: UIScrollView) -> Bool {
        let contentOffsetBottom = scrollView.contentOffset.y + scrollView.frame.size.height
        let contentSizeHeight = scrollView.contentSize.height
        return contentSizeHeight - contentOffsetBottom < 50
    }

    private func didScrollDown(_ contentOffset: CGPoint, _ prevOffset: CGPoint) -> Bool {
        let contentOffsetY = contentOffset.y
        let prevOffsetY = prevOffset.y
        return contentOffsetY > prevOffsetY
    }

    private func isAtTop(_ scrollView: UIScrollView) -> Bool {
        let contentOffsetTop = scrollView.contentOffset.y
        return contentOffsetTop < 0
    }

    private func isAtBottom(_ scrollView: UIScrollView) -> Bool {
        let contentOffsetBottom = scrollView.contentOffset.y + scrollView.frame.size.height
        let contentSizeHeight = scrollView.contentSize.height
        return contentOffsetBottom > contentSizeHeight
    }

    private func movedALittle(_ contentOffset: CGPoint, _ prevOffset: CGPoint) -> Bool {
        return prevOffset.y - contentOffset.y < 5
    }

    private func movedALot(_ contentOffset: CGPoint, _ prevOffset: CGPoint) -> Bool {
        return prevOffset.y - contentOffset.y > 10
    }

}
