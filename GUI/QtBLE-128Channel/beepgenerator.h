// beepgenerator.h
#ifndef BEEPGENERATOR_H
#define BEEPGENERATOR_H

#include <QObject>
#include <QAudioFormat>
#include <QAudioSink>
#include <QBuffer>
#include <QIODevice>
#include <QtMath>
#include <QDebug>
#include <QMediaDevices>
#include <QThread>
#include <QTimer>

class BeepGenerator : public QObject
{
    Q_OBJECT

public:
    explicit BeepGenerator(QObject *parent = nullptr);
    ~BeepGenerator();

    void setFrequency(double frequency);
    void setVolume(double volume);
    void setDuration(int durationMs);
    void playAsync();

signals:
    void playRequested();

private slots:
    void handlePlayRequest();

private:
    void generateBeep();
    void initializeAudio();
    void play();

    QAudioFormat m_format;
    QAudioSink *m_audioSink;
    QIODevice *m_audioIO;
    QBuffer *m_buffer;
    QByteArray m_data;

    double m_frequency;
    double m_volume;
    int m_durationMs;

    QThread m_audioThread;
};

#endif // BEEPGENERATOR_H
