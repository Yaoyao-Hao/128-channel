#include "SpikeDetector.h"
#include <QDebug>
#include <numeric>

SpikeDetector::SpikeDetector(QObject *parent)
    : QObject(parent)
    , m_globalSampleCounter(0)
    , m_lastSpikeSample(0)
    , m_spikesCount(0)
    , m_currentThreshold(0.0)
{
    reset();
    designBandpassFilter();
}

SpikeDetector::~SpikeDetector()
{
}

void SpikeDetector::setConfig(const Config &config)
{
    m_config = config;
    designBandpassFilter();
    reset();
}

void SpikeDetector::reset()
{
    m_globalSampleCounter = 0;
    m_lastSpikeSample = -static_cast<int64_t>(m_config.refractoryPeriod * m_config.sampleRate);
    m_signalBuffer.clear();
    m_spikesCount = 0;
    m_currentThreshold = 0.0;

    int filterSize = std::max(m_aCoeffs.size(), m_bCoeffs.size());
    m_filterState = QVector<double>(filterSize, 0.0);
}

void SpikeDetector::designBandpassFilter()
{

    double nyquist = m_config.sampleRate / 2.0;
    double low = m_config.lowCutFreq / nyquist;
    double high = m_config.highCutFreq / nyquist;

    if (m_config.filterOrder == 2) {

        double centerFreq = sqrt(m_config.lowCutFreq * m_config.highCutFreq);
        double bandwidth = m_config.highCutFreq - m_config.lowCutFreq;
        double Q = centerFreq / bandwidth;

        m_bCoeffs = {0.1, 0.0, -0.1};
        m_aCoeffs = {1.0, -1.9, 0.95};
    }

    m_filterState = QVector<double>(m_aCoeffs.size(), 0.0);
}

QVector<double> SpikeDetector::applyFilter(const QVector<double> &data)
{
    if (m_bCoeffs.isEmpty() || m_aCoeffs.isEmpty()) {
        return data;
    }

    QVector<double> filtered(data.size());
    int n = data.size();
    int nb = m_bCoeffs.size();
    int na = m_aCoeffs.size();

    for (int i = 0; i < n; i++) {

        double output = m_bCoeffs[0] * data[i] + m_filterState[0];
        filtered[i] = output;


        for (int j = 0; j < na - 1; j++) {
            m_filterState[j] = m_bCoeffs[j+1] * data[i] + m_filterState[j+1] - m_aCoeffs[j+1] * output;
        }
        if (na > 1) {
            m_filterState[na-2] = m_bCoeffs[na-1] * data[i] - m_aCoeffs[na-1] * output;
        }
    }

    return filtered;
}

double SpikeDetector::calculateNEO(double x_prev, double x_curr, double x_next)
{
    // NEO: Ψ[x(n)] = [x(n)]² - x(n-1) * x(n+1)
    return (x_curr * x_curr) - (x_prev * x_next);
}

QVector<double> SpikeDetector::applyNEO(const QVector<double> &data)
{
    QVector<double> neoOutput(data.size(), 0.0);

    if (data.size() < 3) {
        return neoOutput;
    }
    for (int i = 1; i < data.size() - 1; i++) {
        neoOutput[i] = calculateNEO(data[i-1], data[i], data[i+1]);
    }

    return neoOutput;
}

double SpikeDetector::calculateMAD(const QVector<double> &data)
{
    if (data.isEmpty()) return 0.0;
    QVector<double> sortedData = data;
    std::sort(sortedData.begin(), sortedData.end());
    double median = sortedData[sortedData.size() / 2];

    QVector<double> absoluteDeviations(data.size());
    for (int i = 0; i < data.size(); i++) {
        absoluteDeviations[i] = std::abs(data[i] - median);
    }

    std::sort(absoluteDeviations.begin(), absoluteDeviations.end());
    double mad = absoluteDeviations[absoluteDeviations.size() / 2];

    return mad;
}

double SpikeDetector::calculateRobustThreshold(const QVector<double> &data)
{
    if (data.isEmpty()) return 0.0;

    double mad = calculateMAD(data);
    double stdEstimate = mad / 0.6745;

    QVector<double> absData(data.size());
    for (int i = 0; i < data.size(); i++) {
        absData[i] = std::abs(data[i]);
    }

    std::sort(absData.begin(), absData.end());
    double percentile95 = absData[static_cast<int>(absData.size() * 0.95)];

    double baseThreshold = std::min(stdEstimate, percentile95 * 0.5);

    return m_config.thresholdMultiplier * baseThreshold;
}

void SpikeDetector::detectSpikes(const QVector<double> &processedData)
{
    int refractorySamples = static_cast<int>(m_config.refractoryPeriod * m_config.sampleRate);

    for (int i = 0; i < processedData.size(); i++) {
        int64_t currentSample = m_globalSampleCounter + i;

        if (currentSample - m_lastSpikeSample <= refractorySamples) {
            continue;
        }
        double signalValue = processedData[i];
        if (m_config.useNEO && std::abs(signalValue) < m_config.NEOThreshold) {
            continue;
        }

        if (std::abs(signalValue) > m_currentThreshold) {

            int startIdx = i - m_config.detectionWindowPre;
            int endIdx = i + m_config.detectionWindowPost;

            if (startIdx >= 0 && endIdx < processedData.size()) {
                QVector<double> waveform;
                for (int j = startIdx; j <= endIdx; j++) {
                    waveform.append(processedData[j]);
                }

                emit spikeDetected(currentSample, waveform);

                m_lastSpikeSample = currentSample;
                m_spikesCount++;
            }
        }
    }
}

void SpikeDetector::processData(const QVector<double> &rawData)
{
    if (rawData.isEmpty()) return;
    QVector<double> filteredData = applyFilter(rawData);

    QVector<double> processedData = filteredData;
    if (m_config.useNEO) {
        processedData = applyNEO(filteredData);
    }
    m_signalBuffer.append(processedData);
    int maxBufferSize = static_cast<int>(m_config.sampleRate);
    if (m_signalBuffer.size() > maxBufferSize) {
        m_signalBuffer = m_signalBuffer.mid(m_signalBuffer.size() - maxBufferSize);
    }

    m_currentThreshold = calculateRobustThreshold(m_signalBuffer);

    detectSpikes(processedData);
    emit processingStats(m_currentThreshold, m_spikesCount);
    m_globalSampleCounter += rawData.size();
}
