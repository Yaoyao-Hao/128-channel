#ifndef HOMEGUI_H
#define HOMEGUI_H

#include <QWidget>
#include "qcustomplot.h"
#include"mylogger.h"
#include "QtBluetooth/shared_data.h"
#include<QTimer>
#include "config.h"
#include <QQueue>

#include <QThread>
#include <QtConcurrent/QtConcurrent>

#include "WaitingDialog.h"

#include "signalfilter.h"

#include <SimpleBLE/SimpleBLE.h>

#include "fileprocessor.h"

#include "beepgenerator.h"

#include "APDetector.h"

namespace Ui {
class HomeGui;
}

class HomeGui : public QWidget
{
    Q_OBJECT

public:
    explicit HomeGui(QWidget *parent = nullptr);
    ~HomeGui();


protected:
    bool eventFilter(QObject *obj, QEvent *event) override;


private slots:
    void on_pbtn_start_clicked();

    void on_pbtn_stop_clicked();

    void stop_clicked();

    void on_pbtn_impedance_clicked();

    void on_cbox_channel_activated(int index);

    void on_pbtn_readthreshold_clicked();

    void on_pbtn_ConfThreshold_clicked();

    void on_pBtn_CalculateThreshold_clicked();


    void on_pBtn_stopImpedance_clicked();

    void on_pbtn_shutdown_clicked();

    void on_pbtn_FPGA_clicked();

    void on_comboBox_mode_activated(int index);

    void on_pbtn_timeadd_clicked();

    void on_pbtn_timeReduce_clicked();

    void on_ledit_imtime_textChanged(const QString &arg1);

    void on_pbtn_viener_clicked();

    void on_radioButton_clicked(bool checked);

    void on_rbtn_savefile_clicked(bool checked);

    void on_tBtn_FilterConfig_clicked();

    void on_cbox_singleChannel_checkStateChanged(const Qt::CheckState &arg1);


    void on_pBtn_SavethresholdData_clicked();
    void on_pbtn_soft_clicked();

    void on_tbtn_IncreaseTime_clicked();

    void on_tbtn_DecreaseTime_clicked();

    void on_tabWidget_currentChanged(int index);

    void on_pBtn_Decodingstart_clicked();


    void on_pbtn_Decodingstop_clicked();

    void on_pbtn_channelreduce_clicked();

    void on_pbtn_channeladd_clicked();



    void on_pbtn_loadDataFile_clicked();

    void on_pBtn_cancel_clicked();

    void on_checkBox_LPF_checkStateChanged(const Qt::CheckState &arg1);

    void on_checkBox_HPF_checkStateChanged(const Qt::CheckState &arg1);

    void on_checkBox_NF_checkStateChanged(const Qt::CheckState &arg1);

    void on_comboBox_LPF_soft_currentTextChanged(const QString &arg1);

    void on_comboBox_HPF_soft_currentTextChanged(const QString &arg1);

    void on_horizontalSlider_valueChanged(int value);

    void on_pushButton_clicked();

    void on_lineEdit_threshold_factor_textChanged(const QString &arg1);



private:
    bool isSavingData = false;
    QFile dataFile;

    bool isSpikeDetection = true;

private:
    Ui::HomeGui *ui;



    QCPItemStraightLine *crosshairH;
    QCPItemStraightLine *crosshairV;
    QCPItemText *coordText;

    QCPItemStraightLine *spikecrosshairH;
    QCPItemStraightLine *spikecrosshairV;
    QCPItemText *spikecoordText;

    QCPItemStraightLine *ISIcrosshairH;
    QCPItemStraightLine *ISIcrosshairV;
    QCPItemText *ISIcoordText;

    QCPItemStraightLine *RastercrosshairH;
    QCPItemStraightLine *RastercrosshairV;
    QCPItemText *RastercoordText;

    QCPItemStraightLine *impedancecrosshairH;
    QCPItemStraightLine *impedancecrosshairV;
    QCPItemText *impedancecoordText;


    QCPItemStraightLine *crosshairHfile;
    QCPItemStraightLine *crosshairVfile;
    QCPItemText *coordTextfile;


    void setupCustomPlot();
    void setupCustomPlot_spike();
    void setupCustomPlot_ISI();
    void setupCustomPlot_Raster();
    void setupCustomPlot_impedance();
    void setupCustomPlot_Decoding();
    void setupInteractions();


    void setupCustomPlot_loaddata();
    void setupCustomPlot_spike_loaddata();
    void setupCustomPlot_ISI_loaddata();
    void setupCustomPlot_Raster_loaddata();

    void addMark(double time, QColor color);
    void addMarkB(double time, QColor color);


    void setFilter(QString ch,QString reg);


    void showContextMenu(const QPoint &pos);

    void showContextMenu_spike(const QPoint &pos);

    void showContextMenu_impedance(const QPoint &pos);

    void extractThresholdData(const QVector<double>& data, double samplingRate, double threshold);

    QMap<int, int> extractISIData(const QQueue<double>& queue_ISI, double samplingRate);

    void cleanupThread();

    void closeAutospikeDetection();

    void setChannelIndex(int index);
signals:
    void thresholdChanged(double newThreshold);

    void writeMemory(const QByteArray &value);

//     void setThresholdValue(double value);

public slots:

    void delayedReplot();

    void syncXAxisRanges(QCPRange newRange);


    void addSpikeLines(QVector<double>& xData,QVector<double>& yData,QVector<uint8_t> spikevalues,double yLow,double yHigh);

    void updatePlot();

    void updatespikePlot();
    void updateISIPlot();

    void updateRaster();
    void updateRasterPlot();


    void updatePlot_file();

    void updatespikePlot_file();

    void updateISIPlot_file();

    void updateRaster_file();
    void updateRasterPlot_file();

    void updateDecodingPlot();

    void updatespike();


    void updateimpedance();

    void upStatus();


    void sendNextChunk();

    void sendOTANextChunk();
    void finishUpload(bool success);

    void finishotaUpload(bool success);

    void sendVienerFilter(QVector<QString> data);

    void upThreshold( QByteArray byteArray);

    void onwriteMemory(const QByteArray &value);


    void onRastermouseWheel(QWheelEvent *event);

    void onRasterfilemouseWheel(QWheelEvent *event);

    void onMousePress(QMouseEvent *event);
    void onMouseMove(QMouseEvent *event);
    void onMouseRelease(QMouseEvent *event);
    void onmouseWheel(QWheelEvent *event);
    void onselectionChanged();


    void onMousePressfile(QMouseEvent *event);
    void onMouseMovefile(QMouseEvent *event);

    void onthresholdChanged(double newThreshold);

    void readCharacteristic( SimpleBLE::Service m_service,SimpleBLE::Characteristic m_Ch);
    void writeCharacteristic(SimpleBLE::Service m_service, SimpleBLE::Characteristic m_Ch,SimpleBLE::ByteArray data);

    void openNotify( SimpleBLE::Service m_service,SimpleBLE::Characteristic m_Ch);

    void onScanTimeout();

    void onConnectError();

    quint8 channelToBitmask(int ch);

    quint8 channelToBitmask2(int ch);

    void onsetSingleChannelFlag(int channel,bool flag);

    void refreshServices();

    bool sendDataToFPGA(QByteArray byte);
    bool sendsoftToMCU(QByteArray byte);
    bool sendUpdataFPGA();
    bool sendStopFPGA();

    bool ResetFPGA();

    bool readFPGAData();

    bool RHDFPGAPowerDown();

    bool startFPGA();


    QVector<double> generateSequentialData(int maxValue = 24,double sample=15000);


//     void onLabelDoubleClick(QMouseEvent *event);

    void on_pbtn_statusUpdata_clicked();

    void on_pbtn_scanStart_clicked();

    void on_pbtn_sacnStop_clicked();

    void on_pbtn_connect_clicked();

    void on_pbtn_disconnect_clicked();
    void onMaxGraphCountChanged(int value);


    void handleProcessingFinished();

protected:
    void closeEvent(QCloseEvent *event) override;

     void keyPressEvent(QKeyEvent *event) override;

private:

    QTimer *plotUpdateTimer;

    QTimer *plotspikeUpdateTimer;

    QTimer *plotISIUpdateTimer;

    QTimer *plotRasterUpdateTimer;

    QTimer *plotimpedanceTimer;

    QTimer *plotDecodingUpdateTimer;


    QTimer *plotUpdateTimer_file;

    QTimer *spikeUpdateTimer;

    QCustomPlot *customPlot;

    QCustomPlot *customPlot_spike;

    QCustomPlot *customPlot_ISI;
    QCustomPlot *customPlot_Raster;

    QCustomPlot *customPlot_loaddata;

    QCustomPlot *customPlot_spike_loaddata;

    QCustomPlot *customPlot_ISI_loaddata;
    QCustomPlot *customPlot_Raster_loaddata;

    QCustomPlot *customPlot_impedance;

    QCustomPlot *customPlot_Decoding;



    QCPItemStraightLine *m_thresholdLine;
    QCPItemText *m_thresholdLabel;

    QCPItemStraightLine *m_thresholdLinefile;
    QCPItemText *m_thresholdLabelfile;

    QCPItemLine *Rawline =nullptr;
    QCPItemText *Rawlabel =nullptr;
    QCPItemLine *line_raster=nullptr;


    QCPItemLine *RawlineB=nullptr;
    QCPItemText *RawlabelB=nullptr;
    QCPItemLine *line_rasterB=nullptr;

    bool m_draggingThreshold =  false;

    bool m_draggingThresholdfile =  false;

    bool m_draggingMarkA = false;
    bool m_draggingMarkB =  false;

    double m_dragStartY;

    double m_MarkA = 0;
    double m_MarkB = 0;

    double threshold;
    double thresholdfile;

    double samplingRate = 15000;

    SignalFilter filter;
    bool lowPassFilterFlag = false;

    double lowPassFilter = 5000;

    bool highPassFilterFlag = false;

    double highPassFilter = 500;

    bool notchFilterFlag = false;
    double notchFilterCenterFreq = 50;
    double notchFilterBW = 5;

    QQueue<QVector<double>> queue_spike;

    QQueue<double> queue_ISI;

    shared_data Memerydata;
    Config *ConfigWidget;


    QCPBars *fossil;

    QCPBars *fossil_file;



    QTimer* scanTimer;
    QTimer* connectTimer;
    SimpleBLE::Adapter adapter;
    std::vector<SimpleBLE::Peripheral> peripherals;
    std::optional<SimpleBLE::Peripheral> connectedPeripheral;
    std::vector<SimpleBLE::Service> services;
    SimpleBLE::Service service;
    std::vector<SimpleBLE::Characteristic> characteristics;
    SimpleBLE::Characteristic characteristic;


    int channelMax = 128;

    int impedancepacket = 25;
    int currentChannel = 0;

    int filecurrentChannel = 0;

    int CurrentMode = 1;

    bool statusflag = true;

    bool nextflag = false;
    bool thflag = false;

    QTimer *nextTimer;


    QByteArray byteArrayBuffer;

    int index = 0;
    QVector<QVector<double>> m_buffer;
    double impedancevalue = 0;

    QVector<double> values;

    QVector<wiener> wienervalues;

    QVector<QVector<uint8_t>> m_spikebuffer;

    QProgressBar *progressBar;
    QProgressBar *progressBar_ota;

     QFile *m_fpgaFile;
     QFile *m_otaFile;

    qint64 m_totalSent;
    qint64 m_fileSize;

    qint64 m_otatotalSent;
    qint64 m_otafileSize;
    QTimer *m_sendFpgaFileTimer;

    QTimer *m_sendotaFileTimer;

    QFuture<void> connectionFuture;

    QFuture<void> impedanceFuture;

    QFuture<void> CalculateThresholdFuture;

    QFuture<void> spike_ISI_Future;

    QHash<int, QVector<double>> xAxisCache;

    QSpinBox *maxGraphSpinBox;

    QSpinBox *maxGraphSpinBoxfile;

    const double m_step = 1000.0 / samplingRate;

    int maxGraphCount = 100;

    int maxGraphCountfile = 100;


    QVector<QVector<uint8_t>> m_spikeAllChannel;
    QMutex m_spikeMutex;

    int currentTableIndex = 0;


    FileProcessor *m_fileProcessor;
    QThread *m_workerThread;
    QSharedPointer<QCPGraphDataContainer> m_dataContainer;


    QThread *DataThread;

    QThread *m_beeperThread;
    BeepGenerator *beeper;

    APDetector  *spikeDetector;

    double threshold_factor = 6.4;

};

#endif // HOMEGUI_H
