
#include <QLoggingCategory>
#include <QApplication>
#include "homegui.h"

int main(int argc, char *argv[])
{


    QApplication a(argc, argv);
    qputenv("QT_BLUETOOTH_BACKEND", "win32");

    QLoggingCategory::setFilterRules(QStringLiteral("qt.bluetooth* = true"));

    HomeGui h;
    h.show();

    return a.exec();
}
