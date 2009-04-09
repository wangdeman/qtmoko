/****************************************************************************
 **
 ** Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies).
** Contact: Qt Software Information (qt-info@nokia.com)
 **
 ** This file is part of the QtGui module of the Qt Toolkit.
 **
 ** $QT_BEGIN_LICENSE:LGPL$
** Commercial Usage
** Licensees holding valid Qt Commercial licenses may use this file in
** accordance with the Qt Commercial License Agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and Nokia.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 2.1 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU Lesser General Public License version 2.1 requirements
** will be met: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
**
** In addition, as a special exception, Nokia gives you certain
** additional rights. These rights are described in the Nokia Qt LGPL
** Exception version 1.0, included in the file LGPL_EXCEPTION.txt in this
** package.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3.0 as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU General Public License version 3.0 requirements will be
** met: http://www.gnu.org/copyleft/gpl.html.
**
** If you are unsure which license is appropriate for your use, please
** contact the sales department at qt-sales@nokia.com.
** $QT_END_LICENSE$
 **
 ** This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
 ** WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 **
 ****************************************************************************/

#include "qmacdefines_mac.h"
#ifdef QT_MAC_USE_COCOA
#import <private/qcocoawindow_mac_p.h>
#import <private/qcocoawindowdelegate_mac_p.h>
#import <private/qcocoaview_mac_p.h>
#import <private/qt_cocoa_helpers_mac_p.h>

#include <QtGui/QWidget>

QT_FORWARD_DECLARE_CLASS(QWidget);
QT_USE_NAMESPACE

extern Qt::MouseButton cocoaButton2QtButton(NSInteger buttonNum); // qcocoaview.mm

@implementation NSWindow (QT_MANGLE_NAMESPACE(QWidgetIntegration))

- (id)QT_MANGLE_NAMESPACE(qt_initWithQWidget):(QWidget*)widget contentRect:(NSRect)rect styleMask:(NSUInteger)mask;
{
    self = [self initWithContentRect:rect styleMask:mask backing:NSBackingStoreBuffered defer:YES];
    if (self) {
        [[QT_MANGLE_NAMESPACE(QCocoaWindowDelegate) sharedDelegate] becomeDelegteForWindow:self widget:widget];
        [self setReleasedWhenClosed:NO];
    }
    return self;
}

- (QWidget *)QT_MANGLE_NAMESPACE(qt_qwidget)
{
    QWidget *widget = 0;
    if ([self delegate] == [QT_MANGLE_NAMESPACE(QCocoaWindowDelegate) sharedDelegate])
        widget = [[QT_MANGLE_NAMESPACE(QCocoaWindowDelegate) sharedDelegate] qt_qwidgetForWindow:self];
    return widget;
}

@end

@implementation QT_MANGLE_NAMESPACE(QCocoaWindow)

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

/*
    The methods keyDown, keyUp, and flagsChanged... These really shouldn't ever
    get hit. We automatically say we can be first responder if we are a window.
    So, the handling should get handled by the view. This is here more as a
    last resort (i.e., this is code that can potentially be removed).
 */

- (void)keyDown:(NSEvent *)theEvent
{
    bool keyOK = qt_dispatchKeyEvent(theEvent, [self QT_MANGLE_NAMESPACE(qt_qwidget)]);
    if (!keyOK)
        [super keyDown:theEvent];
}

- (void)keyUp:(NSEvent *)theEvent
{
    bool keyOK = qt_dispatchKeyEvent(theEvent, [self QT_MANGLE_NAMESPACE(qt_qwidget)]);
    if (!keyOK)
        [super keyUp:theEvent];
}

- (void)flagsChanged:(NSEvent *)theEvent
{
    qt_dispatchModifiersChanged(theEvent, [self QT_MANGLE_NAMESPACE(qt_qwidget)]);
    [super flagsChanged:theEvent];
}


- (void)tabletProximity:(NSEvent *)tabletEvent
{
    qt_dispatchTabletProximityEvent(tabletEvent);
}

- (void)sendEvent:(NSEvent *)event
{
    [self retain];

    QWidget *widget = [[QT_MANGLE_NAMESPACE(QCocoaWindowDelegate) sharedDelegate] qt_qwidgetForWindow:self];
    QCocoaView *view = static_cast<QCocoaView *>(qt_mac_nativeview_for(widget));
    Qt::MouseButton mouseButton = cocoaButton2QtButton([event buttonNumber]);

    // sometimes need to redirect mouse events to the popup.
    QWidget *popup = qAppInstance()->activePopupWidget();
    if (popup && popup != widget) {
        switch([event type])
        {
        case NSLeftMouseDown:
            qt_mac_handleMouseEvent(view, event, QEvent::MouseButtonPress, mouseButton);
            // Don't call super here. This prevents us from getting the mouseUp event,
            // which we need to send even if the mouseDown event was not accepted. 
            // (this is standard Qt behavior.)
            break;
        case NSRightMouseDown:
        case NSOtherMouseDown:
            if (!qt_mac_handleMouseEvent(view, event, QEvent::MouseButtonPress, mouseButton))
                [super sendEvent:event];
            break;
        case NSLeftMouseUp:
        case NSRightMouseUp:
        case NSOtherMouseUp:
            if (!qt_mac_handleMouseEvent(view, event, QEvent::MouseButtonRelease, mouseButton))
                [super sendEvent:event];
            break;
        case NSMouseMoved:
            qt_mac_handleMouseEvent(view, event, QEvent::MouseMove, Qt::NoButton);
            break;
        case NSLeftMouseDragged:
        case NSRightMouseDragged:
        case NSOtherMouseDragged:
            [QT_MANGLE_NAMESPACE(QCocoaView) currentMouseEvent]->view = view;
            [QT_MANGLE_NAMESPACE(QCocoaView) currentMouseEvent]->theEvent = event;
            if (!qt_mac_handleMouseEvent(view, event, QEvent::MouseMove, mouseButton))
                [super sendEvent:event];
            break;
        default:
            [super sendEvent:event];
            break;
        }
    } else {
        [super sendEvent:event];
    }
    qt_mac_dispatchNCMouseMessage(self, event, [self QT_MANGLE_NAMESPACE(qt_qwidget)], leftButtonIsRightButton);


    [self release];
}

@end

#endif