QT       += core gui widgets multimedia
QT       += bluetooth
QT += printsupport
QT += opengl


greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

CONFIG += c++17

QMAKE_CXXFLAGS += -std:c++17 -Zc:__cplusplus -permissive- option

DEFINES += QCUSTOMPLOT_USE_OPENGL

LIBS += -lopengl32 -lglu32

LIBS += "D:/Coding-soft/QT6/6.9.1/msvc2022_64/lib/freeglut.lib"

# SimpleBLE
INCLUDEPATH += C:/SimpleBLE/include
# SimpleBLE
LIBS += -LC:/SimpleBLE/lib -lsimpleble

SOURCES += \
    QtBluetooth/shared_data.cpp \
    apdetector.cpp \
    beepgenerator.cpp \
    config.cpp \
    fileprocessor.cpp \
    homegui.cpp \
    main.cpp \
    mylogger.cpp \
    qcustomplot.cpp \
    signalfilter.cpp \
    spikedetector.cpp \
    waitingdialog.cpp

HEADERS += \
    QtBluetooth/shared_data.h \
    apdetector.h \
    beepgenerator.h \
    config.h \
    fileprocessor.h \
    homegui.h \
    mylogger.h \
    qcustomplot.h \
    signalfilter.h \
    spikedetector.h \
    waitingdialog.h

FORMS += \
    config.ui \
    homegui.ui

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

DISTFILES +=

INCLUDEPATH += $$PWD/QsLog
include($$PWD/QsLog/QsLog.pri)
