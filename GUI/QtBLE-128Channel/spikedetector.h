#ifndef SPIKEDETECTOR_H
#define SPIKEDETECTOR_H

#include <QObject>
#include <QVector>
#include <QQueue>
#include <cmath>
#include <algorithm>

class SpikeDetector : public QObject
{
    Q_OBJECT

public:
    explicit SpikeDetector(QObject *parent = nullptr);
    ~SpikeDetector();


    struct Config {
        double sampleRate = 15000.0;
        double lowCutFreq = 300.0;
        double highCutFreq = 3000.0;
        double thresholdMultiplier = 4.5;
        double refractoryPeriod = 0.002;
        int filterOrder = 4;
        int detectionWindowPre = 30;
        int detectionWindowPost = 60;
        bool useNEO = true;
        double NEOThreshold = 0.1;
    };

    void setConfig(const Config &config);
    void processData(const QVector<double> &rawData);
    void reset();

signals:
    void spikeDetected(int64_t timestamp, const QVector<double> &waveform);
    void processingStats(double currentThreshold, int spikesCount);

private:

    void designBandpassFilter();
    QVector<double> applyFilter(const QVector<double> &data);


    double calculateNEO(double x_prev, double x_curr, double x_next);
    QVector<double> applyNEO(const QVector<double> &data);


    double calculateRobustThreshold(const QVector<double> &data);
    double calculateMAD(const QVector<double> &data);


    void detectSpikes(const QVector<double> &filteredData);

    Config m_config;


    QVector<double> m_bCoeffs;
    QVector<double> m_aCoeffs;


    QVector<double> m_filterState;


    int64_t m_globalSampleCounter;
    int64_t m_lastSpikeSample;
    QVector<double> m_signalBuffer;


    int m_spikesCount;
    double m_currentThreshold;
};

#endif // SPIKEDETECTOR_H
