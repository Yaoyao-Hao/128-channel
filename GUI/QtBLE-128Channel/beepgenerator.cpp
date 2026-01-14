#include "beepgenerator.h"
#include <QMediaDevices>

// beepgenerator.cpp
#include "beepgenerator.h"

BeepGenerator::BeepGenerator(QObject *parent)
    : QObject(parent)
    , m_audioSink(nullptr)
    , m_audioIO(nullptr)
    , m_buffer(nullptr)
    , m_frequency(440.0)
    , m_volume(0.5)
    , m_durationMs(100)
{

    this->moveToThread(&m_audioThread);
    m_audioThread.start();


    connect(this, &BeepGenerator::playRequested,
            this, &BeepGenerator::handlePlayRequest,
            Qt::QueuedConnection);


    QTimer::singleShot(0, this, &BeepGenerator::initializeAudio);
}

BeepGenerator::~BeepGenerator()
{
    m_audioThread.quit();
    m_audioThread.wait();

    if (m_audioSink) {
        m_audioSink->stop();
        delete m_audioSink;
    }
    if (m_buffer) {
        delete m_buffer;
    }
}

void BeepGenerator::initializeAudio()
{

    Q_ASSERT(QThread::currentThread() == &m_audioThread);


    m_format.setSampleRate(44100);
    m_format.setChannelCount(1);
    m_format.setSampleFormat(QAudioFormat::Int16);


    QAudioDevice device = QMediaDevices::defaultAudioOutput();
    if (device.isNull()) {
        qWarning() << "No audio output device available";
        return;
    }


    if (!device.isFormatSupported(m_format)) {
        qWarning() << "Default format not supported, trying to use the nearest.";
        // m_format = device.nearestFormat(m_format);
    }


    m_audioSink = new QAudioSink(device, m_format, this);
    m_audioSink->setVolume(m_volume);


    m_buffer = new QBuffer(this);
    m_buffer->open(QIODevice::ReadWrite);

    generateBeep();
}

void BeepGenerator::setFrequency(double frequency)
{
    if (frequency > 0 && frequency <= 20000) {
        m_frequency = frequency;
        QMetaObject::invokeMethod(this, "generateBeep", Qt::QueuedConnection);
    }
}

void BeepGenerator::setVolume(double volume)
{
    m_volume = qBound(0.0, volume, 1.0);
    if (m_audioSink) {
        QMetaObject::invokeMethod(this, [this, volume]() {
            m_audioSink->setVolume(volume);
        }, Qt::QueuedConnection);
    }
}

void BeepGenerator::setDuration(int durationMs)
{
    if (durationMs > 0 && durationMs <= 5000) {
        m_durationMs = durationMs;
        QMetaObject::invokeMethod(this, "generateBeep", Qt::QueuedConnection);
    }
}

void BeepGenerator::playAsync()
{

    emit playRequested();
}

void BeepGenerator::handlePlayRequest()
{

    play();
}

void BeepGenerator::generateBeep()
{


    Q_ASSERT(QThread::currentThread() == &m_audioThread);

    if (!m_audioSink) return;


    int sampleCount = m_format.sampleRate() * m_durationMs / 1000;
    m_data.clear();
    m_data.reserve(sampleCount * m_format.bytesPerFrame());


    const double twoPi = 2.0 * M_PI;
    const double phaseIncrement = twoPi * m_frequency / m_format.sampleRate();
    const double maxAmplitude = 32767 * m_volume;

    for (int i = 0; i < sampleCount; ++i) {
        double sample = std::sin(i * phaseIncrement);
        qint16 value = static_cast<qint16>(sample * maxAmplitude);


        m_data.append(static_cast<char>(value & 0xFF));
        m_data.append(static_cast<char>((value >> 8) & 0xFF));
    }


    m_buffer->close();
    m_buffer->setData(m_data);
    m_buffer->open(QIODevice::ReadOnly);
    m_buffer->seek(0);

}

void BeepGenerator::play()
{

    Q_ASSERT(QThread::currentThread() == &m_audioThread);

    if (!m_audioSink || !m_buffer) return;
    m_audioSink->stop();
    m_buffer->seek(0);
    m_audioIO = m_audioSink->start();
    if (m_audioIO) {
        m_audioIO->write(m_buffer->data());
    }
}
