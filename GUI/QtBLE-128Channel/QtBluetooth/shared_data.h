#ifndef SHARED_DATA_H
#define SHARED_DATA_H

#include <QVector>
#include <QQueue>
#include<qdebug.h>
#include <QFile>
#include <QDataStream>


struct wiener {
    QByteArray  wienerResult;
    double wienerX;
    double wienerY;
    bool wienerFlag;

};

struct SharedBLEData {
    QByteArray ByteRaws;
    QVector<double> values;

    QByteArray Bytespike;
    QVector<uint8_t> spike;
    bool isUpdated = false;
    quint32 index;
    int channel;
    wiener wienerData;
};

struct BLEStatusData {
    short BatteryLevel;
    uint8_t ChargeIndicator;
    float temprature;
    float humidity;
};
class shared_data
{
public:
    shared_data();

    const int TIME_MS = 8;
    const int CHANNELS = 128;
    const int BYTES_PER_MS = 16;

    int packet = 250;

    int wienerpacket = 1250;

    int index = 0;

    int wienerindex = 0;

    int losspacketindex = 0;

    quint32 preindex;
    quint32 currentindex;

    quint32 m_currentindex;

    int m_currentChannel = 0;

    QQueue<quint32> packetHistory;
    int losspacketNum = 2000;
    double packetloss = 0;

    quint32 m_lastPacketIndex = 0;
    QVector<QVector<double>> m_buffer;
    QVector<QVector<uint8_t>> m_spikebuffer;
    QVector<QByteArray> m_Rawbuffer;
    QVector<QByteArray> m_spbuffer;

    QVector<wiener> m_wienerbuffer;

    void convertRawData(const QByteArray& raw,SharedBLEData& data);
    void writeBLEDataToSharedMemory(const QByteArray &value);

    SharedBLEData readBLEDataFromSharedMemory();

    void writeBLEStatusDataSharedMemory(const QByteArray &value);

    BLEStatusData readBLEStatusDataSharedMemory();

    SharedBLEData createZeroData(quint32 packetIndex);

    double Calculateimpedance(const QVector<double>& data);



    void processRawData(const QByteArray& raw, SharedBLEData& data, int startPos, int length);
    void updateBuffers(const SharedBLEData& data);
    void updatePacketLossStats(quint32 currentPacketIndex);
    QVector<uint8_t> parseSpikeData(const QByteArray& data);
    void  WienerConvert(const QByteArray& data,double &X,double &Y);

};

#endif // SHARED_DATA_H
