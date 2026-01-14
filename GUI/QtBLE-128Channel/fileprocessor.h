#ifndef FILEPROCESSOR_H
#define FILEPROCESSOR_H

#include <QObject>
#include <QFile>
#include <QVector>
#include <QThread>
#include <QtConcurrent/QtConcurrent>
#include <QMutex>

struct FileBLEData {
    QByteArray ByteRaws;
    QVector<double> values;

    QByteArray Bytespike;
    QVector<uint8_t> spike;
    bool isUpdated = false;
    quint32 index;
};

class FileProcessor : public QObject
{
    Q_OBJECT

public:
    explicit FileProcessor(QObject *parent = nullptr);
    ~FileProcessor();
    QVector<QVector<double>> readRawBufferfile();
    QVector<QVector<uint8_t>> readSpikeBufferfile();


public slots:
    void processFile(const QString &filePath);
    void cancelProcessing();

    void convertRawData(const QByteArray& raw,FileBLEData& data);
    void processRawData(const QByteArray& raw, FileBLEData& data, int startPos, int length);
    void updateBuffers(const FileBLEData& data);
    QVector<uint8_t> parseSpikeData(const QByteArray& data);

signals:
    void progressUpdated(int value);
    void dataChunkProcessed(const QVector<double> &xData, const QVector<double> &yData);
    void processingFinished();
    void errorOccurred(const QString &error);

private:
    QFile m_file;
    bool m_cancelRequested;
    QMutex m_mutex;
    QVector<QVector<double>> m_rawbufferfile;
    QVector<QVector<uint8_t>> m_spikebufferfile;
};

#endif // FILEPROCESSOR_H
