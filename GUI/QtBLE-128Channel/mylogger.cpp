#include "mylogger.h"
#include <QDateTime>

#include <QApplication>


bool ensureLogDirExists(const QString &logPath) {
    QFileInfo fileInfo(logPath);
    QDir logDir(fileInfo.absolutePath());

    if (!logDir.exists()) {
        qDebug() << "Log directory not exist, creating:" << logDir.absolutePath();
        return logDir.mkpath(".");
    }
    return true;
}
MyLogger::MyLogger()
{
    using namespace QsLogging;
    Logger& logger = Logger::instance();


    logger.setLoggingLevel(QsLogging::InfoLevel);   // :ml-citation{ref="1,2" data="citationList"}

    const QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd-hhmmss");
    const QString logName = QString("Logs/Ble_%1.log").arg(timestamp);


    const QString logPath = QDir(QCoreApplication::applicationDirPath())
            .filePath(logName);   // :ml-citation{ref="3" data="citationList"}

    if (!ensureLogDirExists(logPath)) {
            qCritical() << "Failed to create log directory!";
            return;
        }


    DestinationPtr fileDestination(DestinationFactory::MakeFileDestination(
                                       logPath,
                                       EnableLogRotation,
                                       MaxSizeBytes(5 * 1024 * 1024),
                                       MaxOldLogCount(100)
                                       ));   // :ml-citation{ref="1,3" data="citationList"}

    logger.addDestination(fileDestination);


    DestinationPtr debugDestination(DestinationFactory::MakeDebugOutputDestination());
    logger.addDestination(debugDestination);   // :ml-citation{ref="3,6" data="citationList"}

    QLOG_INFO() << "app start.";

}
