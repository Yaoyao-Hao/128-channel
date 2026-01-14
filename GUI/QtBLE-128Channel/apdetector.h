#ifndef APDETECTOR_H
#define APDETECTOR_H

#include <QVector>
#include <QObject>
#include <algorithm>
#include <cmath>

class APDetector : public QObject
{
    Q_OBJECT

public:
    explicit APDetector(QObject *parent = nullptr);


    QVector<double> tkeo(const QVector<double> &x);


    struct DetectionResult {
        QVector<int> peaks;
        QVector<double> tkSignal;
        double threshold;
    };

    DetectionResult detect_ap_neo(const QVector<double> &signal, double fs,
                                  double threshold_factor = 6.4, double ref_period = 0.002);

private:

    double calculateMedian(QVector<double> data);

    double calculateStdDev(const QVector<double> &data, double mean);

    QVector<int> findPeaks(const QVector<double> &signal, double height, int distance);
};

#endif // APDETECTOR_H
