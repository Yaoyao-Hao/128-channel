#include "shared_data.h"

#include <QSharedMemory>
#include <QBuffer>
#include <QDataStream>
#include <QtEndian>

#include <QDateTime>


QSharedMemory sharedMem("BLE_DATA_SHM");
QSharedMemory BLEStatusDataMem("BLE_Status_DATA");


constexpr char COMMAND[] = "bc";
constexpr int COMMAND_INDEX = 10;
constexpr int CHANNEL_INDEX = 7;
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

shared_data::shared_data()
{
    index = 0;
    losspacketindex = 0;
    preindex = currentindex = 0;
    losspacketNum = 2000;
}

QVector<uint8_t> shared_data::parseSpikeData(const QByteArray& data) {

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


void shared_data::WienerConvert(const QByteArray& data,double &X,double &Y) {

    QByteArray byteArray = data;
    QMap<double,double> result = {};
    if (byteArray.size() < 8) {
        qWarning() << "Data less than 8 bytes";
        return;
    }

    QDataStream stream(byteArray);
    stream.setByteOrder(QDataStream::LittleEndian);

    qint32 value1, value2;
    stream >> value1 >> value2;
    X = static_cast<double>(value1);
    Y = static_cast<double>(value2);

}

void shared_data::convertRawData(const QByteArray &raw, SharedBLEData& data)
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

    QByteArray ChannelbyteArray = raw.sliced(CHANNEL_INDEX, 2);
    // qDebug()<<"ChannelbyteArray::::"<<ChannelbyteArray.toHex();
    quint32 Channelresult = (ChannelbyteArray[1] << 8) | static_cast<quint8>(ChannelbyteArray[0]);

    data.channel = static_cast<int>(Channelresult);

    // qDebug()<<"data.channel:::"<<data.channel;


    data.wienerData.wienerFlag = static_cast<quint8>(raw[COMMAND_INDEX]);
    data.wienerData.wienerResult = raw.sliced(COMMAND_INDEX + 1, DATA_LENGTH);

    // qDebug()<<"data.wienerData.wienerResult"<<data.wienerData.wienerResult;

    WienerConvert(data.wienerData.wienerResult,data.wienerData.wienerX,data.wienerData.wienerY);

    if (PACKET_NUMBER_POS + PACKET_NUMBER_LENGTH <= raw.size()) {
        QByteArray byteArray = raw.sliced(PACKET_NUMBER_POS, PACKET_NUMBER_LENGTH);
        std::reverse(byteArray.begin(), byteArray.end());
        quint32 result = 0;
        for (int i = 0; i < PACKET_NUMBER_LENGTH; ++i) {
            result = (result << 8) | static_cast<quint8>(byteArray[i]);
        }
        m_currentindex = result / VALUES_CONVERSION_FACTOR;
        data.index = m_currentindex;
    } else {
        qWarning() << "Warning: Unable to extract packet sequence number, insufficient data length.";
    }

    updatePacketLossStats(data.index);

    // 5. Packet loss detection and padding
    if (m_lastPacketIndex != UINT32_MAX && m_currentindex > m_lastPacketIndex + 1) {
        quint32 lostPackets = m_currentindex - m_lastPacketIndex;
        qWarning() << "Packet loss detected: Loss" << lostPackets << "packet,from"
                   << m_lastPacketIndex + 1 << "to" << m_currentindex - 1;

        // Fill with all-zero data packets
        for (quint32 i = m_lastPacketIndex + 1; i < m_currentindex; ++i) {
            SharedBLEData zeroData = createZeroData(i);
            updateBuffers(zeroData);
        }
    }

    // Update the sequence number of the last received packet
    if (m_currentindex > m_lastPacketIndex) {
        m_lastPacketIndex = m_currentindex;
    }


    // 5. Process different types of data according to data length
    const int rawSize = raw.size();

    if (rawSize >= MIN_SIZE_WITH_SPIKE) {

        processRawData(raw, data, DATA_START_POS, RAW_DATA_LENGTH);
        data.Bytespike = raw.sliced(SPIKE_DATA_POS, SPIKE_DATA_LENGTH);
        // qDebug()<<"data.Bytespike"<<data.Bytespike.toHex();
        data.spike = parseSpikeData(data.Bytespike);
    } else if (rawSize > MIN_SIZE_WITHOUT_SPIKE) {
        // qDebug()<<"rawSize2"<<rawSize;
        processRawData(raw, data, DATA_START_POS, RAW_DATA_LENGTH);
    } else if (rawSize > DATA_START_POS) {
        // qDebug()<<"rawSize3"<<rawSize;
        data.Bytespike = raw.sliced(DATA_START_POS, rawSize - DATA_START_POS);
        data.spike = parseSpikeData(data.Bytespike);
    }

    updateBuffers(data);
}

SharedBLEData shared_data::createZeroData(quint32 packetIndex)
{
    SharedBLEData zeroData;
    zeroData.index = packetIndex;
    zeroData.wienerData.wienerFlag = 0;
    zeroData.wienerData.wienerResult = QByteArray(DATA_LENGTH, 0);
    zeroData.wienerData.wienerX = 0;
    zeroData.wienerData.wienerY = 0;
    zeroData.ByteRaws = QByteArray(RAW_DATA_LENGTH, 0);
    zeroData.Bytespike = QByteArray(SPIKE_DATA_LENGTH, 0);


    zeroData.values.resize(RAW_DATA_LENGTH / 2);
    for (int i = 0; i < zeroData.values.size(); ++i) {
        zeroData.values[i] = 0.0;
    }

    zeroData.spike = parseSpikeData(zeroData.Bytespike);

    return zeroData;
}


void shared_data::processRawData(const QByteArray& raw, SharedBLEData& data, int startPos, int length)
{
    data.ByteRaws = raw.sliced(startPos, length);

    // qDebug()<<"data.ByteRaws"<< data.ByteRaws.toHex();
    data.values.clear();
    data.values.reserve(length);

    for (int i = startPos; i < startPos + length - 1; i += 2) {
        quint8 lowByte = static_cast<quint8>(raw[i]);
        quint8 highByte = static_cast<quint8>(raw[i + 1]);
        quint16 combined = (static_cast<quint16>(highByte) << 8) | lowByte;
        double value = (static_cast<double>(combined) - 32767.0) * 0.195;
        data.values.push_back(value);
    }
}

void shared_data::updateBuffers(const SharedBLEData& data)
{
    try {
        if (m_buffer.size() < packet) {
            m_buffer.append(data.values);
            m_Rawbuffer.append(data.ByteRaws);
            m_spikebuffer.append(data.spike);
            m_spbuffer.append(data.Bytespike);
        } else {
            int replaceIndex = index % packet;
            m_buffer.replace(replaceIndex, data.values);
            m_Rawbuffer.replace(replaceIndex, data.ByteRaws);
            m_spikebuffer.replace(replaceIndex, data.spike);
            m_spbuffer.replace(replaceIndex, data.Bytespike);
        }
        index = (index + 1) % packet;

        if (m_wienerbuffer.size() < wienerpacket) {
            m_wienerbuffer.append(data.wienerData);

        } else {
            int replaceIndex = wienerindex % wienerpacket;
            m_wienerbuffer.replace(replaceIndex, data.wienerData);
        }
        wienerindex = (wienerindex + 1) % wienerpacket;

        m_currentChannel = data.channel;

    } catch (const std::exception& e) {
        qWarning() << "Write failed:" << e.what();
    }
}

void shared_data::updatePacketLossStats(quint32 currentPacketIndex)
{
    if (losspacketindex == 0) {
        preindex = currentPacketIndex;
    } else if (losspacketindex == losspacketNum - 1) {
        int diff  = 0;
        if (currentindex >= preindex) {
            diff = currentindex - preindex;
        } else {
            // Sequence number wrap-around processing
            diff = (0xFFFFFFFF - preindex) + currentindex;
        }
        if(diff>0)
        {
            int expectedDiff = losspacketNum;
            packetloss = std::abs(diff - expectedDiff) / static_cast<double>(expectedDiff);

            qDebug() << "Packet loss rate:" << packetloss << "%"
                     << "Expected:" << expectedDiff << "packets,"
                     << "Sequence span:" << diff
                     << QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzz");
        }
        else{
            packetloss = 100;
            qWarning() << "The current packet sequence number is less than the previous packet sequence number."<< QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzz");
        }

    }
    currentindex = currentPacketIndex;
    losspacketindex = (losspacketindex + 1) % losspacketNum;


}



float hexStringToFloat(const QString &hexString) {

    float result;
    bool ok;
    uint32_t value = hexString.toUInt(&ok, 16);
    if (!ok) {
        qWarning() << "Invalid hexadecimal string";
        return 0;
    }

    int sign = (value >> 31) & 0x1;

    int exponent = (value >> 23) & 0xFF;


    uint32_t mantissa = value & 0x7FFFFF;

    float mantissaValue = 0.0f;
    for (int i = 0; i < 23; ++i) {
        if (mantissa & (1 << (22 - i))) {
            mantissaValue += 1.0f / (1 << (i + 1));
        }
    }

    result = (sign == 0 ? 1 : -1) * (1 + mantissaValue) * pow(2, exponent - 127);

    return result;

}


void convertstatusData(const QByteArray& statusData,struct BLEStatusData &data) {

    int length = statusData.size();

    if(length!=15)
    {
        return;
    }
    int index =  0;
    while(index < length){

        uint8_t opcode = static_cast<uint8_t>(statusData[index++]);
        try {
            switch (opcode) {
            case 0x00: { // Battery level (u16)
                if (index + 2 > length) {
                    throw std::runtime_error("Insufficient data for battery level");
                }
                short battery;
                QByteArray byteArray = statusData.mid(index,sizeof(battery));
                // memcpy(&battery, statusData.constData() + index, sizeof(battery));
                bool ok;
                int value = byteArray.toHex().toInt(&ok, 16);
                if (ok) {
                    battery = static_cast<short>(value);

                } else {
                    qWarning() << "invalid";
                }
                data.BatteryLevel = battery;
                index += 2;

                qDebug()<<"battery::"<<data.BatteryLevel ;
                break;
            }
            case 0x01: { // Charge Indicator (u8)
                if (index >= length) {
                    throw std::runtime_error("Insufficient data for charge indicator");
                }
                data.ChargeIndicator = static_cast<uint8_t>(statusData.at(index));
                qDebug()<<"ChargeIndicator::"<<data.ChargeIndicator;
                index += 1;
                break;
            }

            case 0x02: { // temperature (float)
                if (index + 4 > length) {
                    throw std::runtime_error("Insufficient data for temperature");
                }
                float temp;
                QByteArray byteArray = statusData.mid(index,sizeof(temp));
                temp = hexStringToFloat(byteArray.toHex());

                // qDebug()<<"temp"<<byteArray.toHex().toFloat();
                data.temprature = temp;
                qDebug()<<"temprature::"<<data.temprature;
                index += 4;
                break;
            }
            case 0x03: { // humidity (float)
                if (index + 4 > length) {
                    throw std::runtime_error("Insufficient data for humidity");
                }
                float hum;
                QByteArray byteArray = statusData.mid(index,sizeof(hum));
                hum = hexStringToFloat(byteArray.toHex());
                data.humidity = hum;
                qDebug()<<"humidity::"<<data.humidity;
                index += 4;
                break;
            }
            default:
                throw std::runtime_error("Unknown opcode: 0x" +
                                       QString::number(opcode, 16).toStdString());
           }

        } catch (const std::exception& e) {
                qWarning() << "Error parsing opcode 0x" << Qt::hex << opcode
                                      << ":" << e.what();
            }

        }
}

void shared_data::writeBLEDataToSharedMemory(const QByteArray &value)
{
    SharedBLEData data;
    convertRawData(value,data);
    data.isUpdated = true;

    QBuffer buffer;
    buffer.open(QBuffer::ReadWrite);
    QDataStream stream(&buffer);
    stream << data.values << data.spike<<data.isUpdated;


    if (!sharedMem.isAttached()) {
        if (!sharedMem.create(buffer.size())) {
            qDebug() << "Failed to create shared memory:" << sharedMem.errorString();
            return;
        }
    }

    sharedMem.lock();
    memcpy(sharedMem.data(), buffer.data().data(), buffer.size());
    sharedMem.unlock();

}

SharedBLEData shared_data::readBLEDataFromSharedMemory()
{
    QSharedMemory sharedMem("BLE_DATA_SHM");
    SharedBLEData data;

    if (!sharedMem.attach()) {
        qDebug() << "Failed to attach shared memory:" << sharedMem.errorString();
        return data;
    }

    sharedMem.lock();
    QByteArray shmData(static_cast<const char*>(sharedMem.constData()), sharedMem.size());
    sharedMem.unlock();

    QBuffer buffer(&shmData);
    buffer.open(QBuffer::ReadOnly);
    QDataStream stream(&buffer);
    stream >> data.values >> data.spike >>data.isUpdated;

    return data;

}

void shared_data::writeBLEStatusDataSharedMemory(const QByteArray &value)
{
    BLEStatusData data;
    convertstatusData(value,data);

    QBuffer buffer;
    buffer.open(QBuffer::ReadWrite);
    QDataStream stream(&buffer);
    stream << data.BatteryLevel << data.ChargeIndicator<<data.temprature<<data.humidity;  // 序列化数据


    if (!BLEStatusDataMem.isAttached()) {
        if (!BLEStatusDataMem.create(buffer.size())) {
            qDebug() << "Failed to create shared memory:" << BLEStatusDataMem.errorString();
            return;
        }
    }
    BLEStatusDataMem.lock();
    memcpy(BLEStatusDataMem.data(), buffer.data().data(), buffer.size());
    BLEStatusDataMem.unlock();

}

BLEStatusData shared_data::readBLEStatusDataSharedMemory()
{

    QSharedMemory BLEStatusDataMem("BLE_Status_DATA");
    BLEStatusData data;

    if (!BLEStatusDataMem.attach()) {
        qDebug() << "Failed to attach shared memory:" << BLEStatusDataMem.errorString();
        return data;
    }

    BLEStatusDataMem.lock();
    QByteArray shmData(static_cast<const char*>(BLEStatusDataMem.constData()), BLEStatusDataMem.size());
    BLEStatusDataMem.unlock();

    QBuffer buffer(&shmData);
    buffer.open(QBuffer::ReadOnly);
    QDataStream stream(&buffer);
    stream >> data.BatteryLevel >> data.ChargeIndicator>>data.temprature>>data.humidity;  // 反序列化数据
    return data;
}

double shared_data::Calculateimpedance(const QVector<double>& data)
{
    if (data.isEmpty()) {
        return 0.0;
    }
    double maxVal = data[0];
    double minVal = data[0];
    double D = 0;
    double impedanceValue;

    for (double value : data) {
        if (value > maxVal) {
            maxVal = value;
        }
        if (value < minVal) {
            minVal = value;
        }
    }
    D = maxVal - minVal;
    impedanceValue = ((D * 10 / pow(2, 15))/ 38)*pow(10, 6);

    return impedanceValue;

}


