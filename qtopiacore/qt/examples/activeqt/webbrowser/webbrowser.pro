TEMPLATE = app

CONFIG += qaxcontainer

QTDIR_build:REQUIRES = shared

HEADERS  = webaxwidget.h
SOURCES	 = main.cpp
FORMS	 = mainwindow.ui
wince*: FORMS = wincemainwindow.ui


# install
target.path = $$[QT_INSTALL_EXAMPLES]/activeqt/webbrowser
sources.files = $$SOURCES $$HEADERS $$RESOURCES $$FORMS webbrowser.pro
sources.path = $$[QT_INSTALL_EXAMPLES]/activeqt/webbrowser
INSTALLS += target sources