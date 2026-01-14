#include "fileprocessor.h"

#include <QDebug>

constexpr char COMMAND[] = "bc";
constexpr int COMMAND_INDEX = 10;
constexpr int FLAG_LENGTH = 1;
constexpr int DATA_LENGTH = 8;
constexpr int MIN_SIZE_WITH_SPIKE = 360;
constexpr int MIN_SIZE_WITHOUT_SPIKE = 148;
constexpr int PACKET_NUMBER_POS = 3;
constexpr int PACKET_NUMBER_LENGTH = 4;
constexpr int DATA_START_POS = 19;
constexpr int RAW_DATA_LENGTH = 240;
constexpr int SPIKE_DATA_POS = 259;
constexpr int SPIKE_DATA_LENGTH = 128;
constexpr int VALUES_CONVERSION_FACTOR = 120;
constexpr double VALUE_SCALE_FACTOR = 0.195;
constexpr int VALUE_OFFSET = 32767;

FileProcessor::FileProcessor(QObject *parent)
    : QObject(parent)
    , m_cancelRequested(false)
{
    // qRegisterMetaType<DataBlock>("DataBlock");
}

FileProcessor::~FileProcessor()
{
    if (m_file.isOpen()) {
        m_file.close();
    }
}

QVector<QVector<double>> FileProcessor::readRawBufferfile()
{
    QMutexLocker locker(&m_mutex);
    QVector<QVector<double>> data = m_rawbufferfile;
    return data;

}

QVector<QVector<uint8_t> > FileProcessor::readSpikeBufferfile()
{
    QMutexLocker locker(&m_mutex);
    QVector<QVector<uint8_t>> data = m_spikebufferfile;
    return data;
}

void FileProcessor::processFile(const QString &filePath)
{

    m_file.setFileName(filePath);
    if (!m_file.open(QIODevice::ReadOnly)) {
        emit errorOccurred(tr("Unable to open file: %1").arg(filePath));
        return;
    }
    qint64 fileSize = m_file.size();

    const int CHUNK_SIZE = 387;


    int chunkCount = 0;
    qint64 totalBytesRead = 0;

    while (!m_file.atEnd()) {

        QByteArray chunk = m_file.read(CHUNK_SIZE);
        totalBytesRead = chunk.size();

        qDebug() << "Chunk in hex: " << chunk.toHex();
        if(totalBytesRead>380)
        {
            FileBLEData data;
            convertRawData(chunk,data);
        }
        chunkCount++;
    }

    QThread::msleep(10);
    m_file.close();
    // emit processingFinished();

}

void FileProcessor::cancelProcessing()
{
    m_cancelRequested = true;
}

void FileProcessor::convertRawData(const QByteArray &raw, FileBLEData &data)
{

    if (COMMAND_INDEX >= raw.size()) {
        qCritical() << "Error: Insufficient data length to locate instruction.";
        return;
    }

    if (COMMAND_INDEX + DATA_LENGTH > raw.size()) {
        qCritical() << "Error: Insufficient data length"
                    << "\nlength required:" << DATA_LENGTH
                    << "\nactual length:" << raw.size();
        return;
    }


    if (PACKET_NUMBER_POS + PACKET_NUMBER_LENGTH <= raw.size()) {
        QByteArray byteArray = raw.sliced(PACKET_NUMBER_POS, PACKET_NUMBER_LENGTH);
        std::reverse(byteArray.begin(), byteArray.end());
        quint32 result = 0;
        for (int i = 0; i < PACKET_NUMBER_LENGTH; ++i) {
            result = (result << 8) | static_cast<quint8>(byteArray[i]);
        }
        data.index = result / VALUES_CONVERSION_FACTOR;
    } else {
        qWarning() << "Warning: Unable to extract packet sequence number, insufficient data length.";
    }


    const int rawSize = raw.size();

    if (rawSize >= MIN_SIZE_WITH_SPIKE) {

        processRawData(raw, data, DATA_START_POS, RAW_DATA_LENGTH);
        data.Bytespike = raw.sliced(SPIKE_DATA_POS, SPIKE_DATA_LENGTH);
        qDebug() << "data.Bytespike: " << data.Bytespike.toHex();
        data.spike = parseSpikeData(data.Bytespike);
    } else if (rawSize > MIN_SIZE_WITHOUT_SPIKE) {
        processRawData(raw, data, DATA_START_POS, RAW_DATA_LENGTH);
    } else if (rawSize > DATA_START_POS) {
        data.Bytespike = raw.sliced(DATA_START_POS, rawSize - DATA_START_POS);
        data.spike = parseSpikeData(data.Bytespike);
    }


    updateBuffers(data);

}

void FileProcessor::processRawData(const QByteArray &raw, FileBLEData &data, int startPos, int length)
{
    data.ByteRaws = raw.sliced(startPos, length);
    data.values.clear();
    data.values.reserve(length / 2);

    for (int i = startPos; i < startPos + length - 1; i += 2) {
        quint8 lowByte = static_cast<quint8>(raw[i]);
        quint8 highByte = static_cast<quint8>(raw[i + 1]);
        quint16 combined = (static_cast<quint16>(highByte) << 8) | lowByte;
        double value = (static_cast<double>(combined) - 32767.0) * 0.195;
        data.values.push_back(value);
    }

}

void FileProcessor::updateBuffers(const FileBLEData &data)
{
    try {

        QMutexLocker locker(&m_mutex);
        m_rawbufferfile.append(data.values);
        m_spikebufferfile.append(data.spike);

    } catch (const std::exception& e) {
        qWarning() << "Write failed:" << e.what();
    }

}

QVector<uint8_t> FileProcessor::parseSpikeData(const QByteArray &data)
{

    constexpr int kTotalBytes = 128;
    constexpr int kChannels = 128;
    constexpr int kTimePoints = 8;
    constexpr int kBytesPerMs = 8;

    if (data.size() < kTotalBytes) {
        return {};
    }

    QVector<uint8_t> result(kChannels * kTimePoints, 0);

    const uint8_t* rawData = reinterpret_cast<const uint8_t*>(data.constData());
    uint8_t* resultData = result.data();


    for (int ch = 0; ch < 64; ++ch) {
        const int group = ch / 8;
        const int bitPos = ch % 8;
        const int resultBase = ch * kTimePoints;

        for (int t = 0; t < kTimePoints; ++t) {
            const int byteIndex = t * kBytesPerMs + group;
            const uint8_t byte = rawData[byteIndex];


            resultData[resultBase + t] = (byte >> bitPos) & 1;
        }
    }


    for (int ch = 64; ch < kChannels; ++ch) {
        const int relativeCh = ch - 64;
        const int group = relativeCh / 8;
        const int bitPos = relativeCh % 8;
        const int resultBase = ch * kTimePoints;

        for (int t = 0; t < kTimePoints; ++t) {
            const int byteIndex = 64 + t * kBytesPerMs + group;
            const uint8_t byte = rawData[byteIndex];

            resultData[resultBase + t] = (byte >> bitPos) & 1;
        }
    }

    return result;

}
