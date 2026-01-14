#include "APDetector.h"
#include <QDebug>

APDetector::APDetector(QObject *parent) : QObject(parent)
{
}

QVector<double> APDetector::tkeo(const QVector<double> &x)
{
    int n = x.size();
    QVector<double> tk(n, 0.0);

    if (n < 3) {
        qWarning() << "Signal length must be at least 3 for TKEO calculation";
        return tk;
    }

    // calculate TKEO：x[n]^2 - x[n-1]*x[n+1]
    for (int i = 1; i < n - 1; i++) {
        double x_sq = x[i] * x[i];  // x^2[n]
        double x_prod = x[i-1] * x[i+1];  // x[n-1]*x[n+1]
        tk[i] = x_sq - x_prod;
    }
    tk[0] = x[0];
    tk[n-1] = x[n-1];

    return tk;
}

APDetector::DetectionResult APDetector::detect_ap_neo(const QVector<double> &signal, double fs,
                                                      double threshold_factor, double ref_period)
{
    DetectionResult result;

    if (signal.isEmpty()) {
        qWarning() << "Input signal is empty";
        return result;
    }

    // result.tkSignal = tkeo(signal);

    result.tkSignal = signal;

    // 2.Calculate the threshold: Median + threshold_factor * Standard deviation
    double median = calculateMedian(result.tkSignal);
    double mean = 0.0;
    for (double value : result.tkSignal) {
        mean += value;
    }
    mean /= result.tkSignal.size();

    double std_dev = calculateStdDev(result.tkSignal, mean);
    result.threshold = median + threshold_factor * std_dev;

    // 3. Calculate the minimum peak interval (refractory period).
    int min_peak_interval = static_cast<int>(ref_period * fs);

    result.peaks = findPeaks(result.tkSignal, result.threshold, min_peak_interval);

    return result;
}

double APDetector::calculateMedian(QVector<double> data)
{
    if (data.isEmpty()) return 0.0;


    std::sort(data.begin(), data.end());

    int n = data.size();
    if (n % 2 == 0) {

        return (data[n/2 - 1] + data[n/2]) / 2.0;
    } else {

        return data[n/2];
    }
}

double APDetector::calculateStdDev(const QVector<double> &data, double mean)
{
    if (data.size() <= 1) return 0.0;

    double variance = 0.0;
    for (double value : data) {
        variance += (value - mean) * (value - mean);
    }
    variance /= (data.size() - 1);

    return std::sqrt(variance);
}

QVector<int> APDetector::findPeaks(const QVector<double> &signal, double height, int distance)
{
    QVector<int> peaks;
    int n = signal.size();

    if (n == 0) return peaks;


    for (int i = 1; i < n - 1; i++) {

        if (signal[i] > height &&
            signal[i] > signal[i-1] &&
            signal[i] > signal[i+1]) {


            bool valid = true;
            for (int peak : peaks) {
                if (std::abs(i - peak) < distance) {
                    valid = false;

                    if (signal[i] > signal[peak]) {
                        peaks.removeOne(peak);
                        peaks.append(i);
                    }
                    break;
                }
            }

            if (valid) {
                peaks.append(i);
            }
        }
    }


    std::sort(peaks.begin(), peaks.end());

    return peaks;
}
