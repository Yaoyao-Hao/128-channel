#ifndef SIGNALFILTER_H
#define SIGNALFILTER_H

#include <QObject>
#include <QVector>
#include <QDebug>

class SignalFilter : public QObject
{
    Q_OBJECT
public:
    explicit SignalFilter(QObject *parent = nullptr);
    

    void setSampleRate(double sampleRate);
    

    QVector<double> lowPassFilter(const QVector<double>& signal, double cutoffFreq);
    

    QVector<double> highPassFilter(const QVector<double>& signal, double cutoffFreq);
    

    QVector<double> notchFilter(const QVector<double>& signal, double centerFreq, double bandwidth);

private:
    double m_sampleRate;
    

    QVector<double> firstOrderLowPass(const QVector<double>& signal, double cutoffFreq);
    

    QVector<double> firstOrderHighPass(const QVector<double>& signal, double cutoffFreq);
    

    QVector<double> secondOrderNotch(const QVector<double>& signal, double centerFreq, double bandwidth);
};

#endif // SIGNALFILTER_H
