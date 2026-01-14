#include "signalfilter.h"
#include <cmath>

SignalFilter::SignalFilter(QObject *parent) : QObject(parent), m_sampleRate(15000.0)
{
}

void SignalFilter::setSampleRate(double sampleRate)
{
    if (sampleRate > 0) {
        m_sampleRate = sampleRate;
    } else {
        qWarning() << "Invalid sample rate, using default value 1000 Hz";
    }
}

QVector<double> SignalFilter::lowPassFilter(const QVector<double>& signal, double cutoffFreq)
{
    if (cutoffFreq <= 0 || cutoffFreq >= m_sampleRate / 2) {
        qWarning() << "Invalid cutoff frequency for low pass filter";
        return signal;
    }
    

    return firstOrderLowPass(signal, cutoffFreq);
}

QVector<double> SignalFilter::highPassFilter(const QVector<double>& signal, double cutoffFreq)
{
    if (cutoffFreq <= 0 || cutoffFreq >= m_sampleRate / 2) {
        qWarning() << "Invalid cutoff frequency for high pass filter";
        return signal;
    }
    
    return firstOrderHighPass(signal, cutoffFreq);
}

QVector<double> SignalFilter::notchFilter(const QVector<double>& signal, double centerFreq, double bandwidth)
{
    if (centerFreq <= 0 || centerFreq >= m_sampleRate / 2 || bandwidth <= 0) {
        qWarning() << "Invalid parameters for notch filter";
        return signal;
    }

    return secondOrderNotch(signal, centerFreq, bandwidth);
}

QVector<double> SignalFilter::firstOrderLowPass(const QVector<double>& signal, double cutoffFreq)
{
    QVector<double> filtered(signal.size());
    if (signal.isEmpty()) return filtered;
    
    const double dt = 1.0 / m_sampleRate;
    const double RC = 1.0 / (2 * M_PI * cutoffFreq);
    const double alpha = dt / (RC + dt);
    
    filtered[0] = signal[0];
    
    for (int i = 1; i < signal.size(); ++i) {
        filtered[i] = filtered[i-1] + alpha * (signal[i] - filtered[i-1]);
    }
    
    return filtered;
}

QVector<double> SignalFilter::firstOrderHighPass(const QVector<double>& signal, double cutoffFreq)
{
    QVector<double> filtered(signal.size());
    if (signal.isEmpty()) return filtered;
    
    const double dt = 1.0 / m_sampleRate;
    const double RC = 1.0 / (2 * M_PI * cutoffFreq);
    const double alpha = RC / (RC + dt);

    filtered[0] = signal[0];
    
    for (int i = 1; i < signal.size(); ++i) {
        filtered[i] = alpha * (filtered[i-1] + signal[i] - signal[i-1]);
    }
    
    return filtered;
}

QVector<double> SignalFilter::secondOrderNotch(const QVector<double>& signal, double centerFreq, double bandwidth)
{
    QVector<double> filtered(signal.size());
    if (signal.size() < 3) return signal;
    
    const double dt = 1.0 / m_sampleRate;
    const double omega0 = 2 * M_PI * centerFreq / m_sampleRate;
    const double alpha = sin(omega0) * sinh(M_LN2 / 2 * bandwidth * omega0 / sin(omega0));
    
    const double b0 = 1;
    const double b1 = -2 * cos(omega0);
    const double b2 = 1;
    const double a0 = 1 + alpha;
    const double a1 = -2 * cos(omega0);
    const double a2 = 1 - alpha;
    
    filtered[0] = signal[0];
    filtered[1] = signal[1];
    
    for (int i = 2; i < signal.size(); ++i) {
        filtered[i] = (b0*signal[i] + b1*signal[i-1] + b2*signal[i-2] 
                      - a1*filtered[i-1] - a2*filtered[i-2]) / a0;
    }
    
    return filtered;
}
