#include "homegui.h"
#include "ui_homegui.h"

HomeGui::HomeGui(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::HomeGui)
{
    ui->setupUi(this);

    setFocusPolicy(Qt::StrongFocus);

    for(int i = 0;i<channelMax;i++)
    {
        QString channel = QString("ch:%1").arg(i);
        ui->cbox_channel->addItem(channel);
    }

    progressBar = ui->progressBar;

    progressBar->setVisible(false);

    progressBar_ota = ui->progressBar_ota;

    progressBar_ota->setVisible(false);


    m_beeperThread = new QThread();
    beeper  =  new BeepGenerator(this);

    DataThread = new QThread();

    // Memerydata.moveToThread(DataThread);
    // beeper->moveToThread(m_beeperThread);
    // m_beeperThread->start();



      auto adapters = SimpleBLE::Adapter::get_adapters();
      if (adapters.size() > 0) {
          adapter = adapters[0];
         qDebug("Bluetooth adapter initialization successful:");
         qDebug()<<QString::fromStdString(adapter.identifier());
      } else {
          qDebug("Error: Bluetooth adapter not found");
          QMessageBox::critical(this, "Error", "Bluetooth adapter not found");
      }

      scanTimer = new QTimer(this);
      connect(scanTimer, &QTimer::timeout, this, &HomeGui::onScanTimeout);

      connectTimer = new QTimer(this);
      connect(connectTimer, &QTimer::timeout, this, &HomeGui::onConnectError);
    setupCustomPlot();

    setupCustomPlot_spike();
    setupCustomPlot_ISI();
    setupCustomPlot_Raster();
    setupCustomPlot_impedance();

    setupCustomPlot_Decoding();

    setupInteractions();

    setupCustomPlot_loaddata();
    setupCustomPlot_spike_loaddata();
    setupCustomPlot_ISI_loaddata();
    setupCustomPlot_Raster_loaddata();


    connect(customPlot_loaddata->xAxis, SIGNAL(rangeChanged(QCPRange)), this, SLOT(syncXAxisRanges(QCPRange)));
    connect(customPlot_Raster_loaddata->xAxis, SIGNAL(rangeChanged(QCPRange)), this, SLOT(syncXAxisRanges(QCPRange)));


   plotUpdateTimer = new QTimer(this);
   connect(plotUpdateTimer, &QTimer::timeout, this, &HomeGui::updatePlot);


   plotUpdateTimer_file = new QTimer(this);
   connect(plotUpdateTimer_file, &QTimer::timeout, this, &HomeGui::updatePlot_file);


   plotspikeUpdateTimer = new QTimer(this);
   connect(plotspikeUpdateTimer, &QTimer::timeout, this, &HomeGui::updatespikePlot);

   plotISIUpdateTimer = new QTimer(this);
   connect(plotISIUpdateTimer, &QTimer::timeout, this, &HomeGui::updateISIPlot);

   plotRasterUpdateTimer = new QTimer(this);
   connect(plotRasterUpdateTimer, &QTimer::timeout, this, &HomeGui::updateRasterPlot);

   plotDecodingUpdateTimer = new QTimer(this);
   connect(plotDecodingUpdateTimer, &QTimer::timeout, this, &HomeGui::updateDecodingPlot);



   spikeUpdateTimer = new QTimer(this);
   connect(spikeUpdateTimer, &QTimer::timeout, this, &HomeGui::updatespike);


   plotimpedanceTimer = new QTimer(this);
   connect(plotimpedanceTimer, &QTimer::timeout, this, &HomeGui::updateimpedance);

    connect(this, &HomeGui::thresholdChanged, this, &HomeGui::onthresholdChanged);

    connect(this, &HomeGui::writeMemory, this, &HomeGui::onwriteMemory);

    m_sendFpgaFileTimer = new QTimer(this);
    m_sendFpgaFileTimer->setSingleShot(true);
    connect(m_sendFpgaFileTimer, &QTimer::timeout, this, &HomeGui::sendNextChunk);


    m_sendotaFileTimer = new QTimer(this);
    m_sendotaFileTimer->setSingleShot(true);
    connect(m_sendotaFileTimer, &QTimer::timeout, this, &HomeGui::sendOTANextChunk);


    ConfigWidget = new Config();


    filter.setSampleRate(samplingRate);

    spikeDetector = new APDetector();

}

HomeGui::~HomeGui()
{
    delete ui;
}
bool HomeGui::eventFilter(QObject *obj, QEvent *event)
{
    if (obj == ui->widget && event->type() == QEvent::Wheel)
    {
        QWheelEvent *wheelEvent = static_cast<QWheelEvent*>(event);
        if (QApplication::keyboardModifiers() & Qt::ControlModifier)
        {
            double factor = wheelEvent->angleDelta().y() > 0 ? 0.85 : 1.15;

            ui->widget->xAxis->scaleRange(factor, ui->widget->xAxis->range().center());
            ui->widget->yAxis->scaleRange(factor, ui->widget->yAxis->range().center());
            ui->widget->replot();
            return true;
        }
    }
    return HomeGui::eventFilter(obj, event);
}

void HomeGui::setupCustomPlot()
{
    customPlot = ui->widget;


#ifdef QCUSTOMPLOT_USE_OPENGL
    customPlot->setOpenGl(true);
    customPlot->setBufferDevicePixelRatio(1);
    customPlot->setPlottingHint(QCP::phImmediateRefresh, false);
#endif
    if (!QOpenGLContext::currentContext()) {
        qDebug() << "OpenGL not supported on this system";
        customPlot->setOpenGl(false);
    }

    qDebug() << "OpenGL acceleration enabled:" << customPlot->openGl();

    qDebug()<<"init customplot";

    // ============ Basic chart settings ============
    customPlot->setBackground(QBrush(QColor(245, 245, 245)));
    customPlot->plotLayout()->insertRow(0);
    QCPTextElement *title = new QCPTextElement(customPlot, "Raw signal", QFont("Arial", 12, QFont::Bold));
    customPlot->plotLayout()->addElement(0, 0, title);

    customPlot->addGraph();
    customPlot->addGraph();
    customPlot->addGraph();
    customPlot->graph(0)->setPen(QPen(Qt::red, 1));
    customPlot->graph(0)->setScatterStyle(QCPScatterStyle(QCPScatterStyle::ssNone, 5));
    customPlot->graph(0)->setName("Raw signal");


    QPen greenPen(QColor(50, 180, 50), 1);
    customPlot->graph(1)->setPen(greenPen);
    customPlot->graph(1)->setScatterStyle(QCPScatterStyle(QCPScatterStyle::ssNone, 5));
    customPlot->graph(1)->setName("Threshold");


    QPen bluePen(QColor(50, 50, 255), 1);
    customPlot->graph(2)->setPen(bluePen);
    customPlot->graph(2)->setScatterStyle(QCPScatterStyle(QCPScatterStyle::ssNone, 1));
    customPlot->graph(2)->setName("spike");
    customPlot->graph(2)->setLineStyle(QCPGraph::lsLine);



    // X
    customPlot->xAxis->setLabel("Time (ms)");
    customPlot->xAxis->setRange(0, 2000); // 2000ms
    customPlot->xAxis->grid()->setSubGridVisible(true);

    // Y
    customPlot->yAxis->setLabel("Amplitude(uV)");
    customPlot->yAxis->setRange(-400, 400);
    customPlot->yAxis->grid()->setSubGridVisible(true);

    customPlot->xAxis->grid()->setPen(QPen(QColor(200, 200, 200), 1, Qt::DotLine));
    customPlot->yAxis->grid()->setPen(QPen(QColor(200, 200, 200), 1, Qt::DotLine));
    customPlot->xAxis->grid()->setSubGridPen(QPen(QColor(220, 220, 220), 1, Qt::DotLine));
    customPlot->yAxis->grid()->setSubGridPen(QPen(QColor(220, 220, 220), 1, Qt::DotLine));
    customPlot->legend->setVisible(true);
    customPlot->legend->setFont(QFont("Arial", 9));
    customPlot->legend->setBrush(QBrush(QColor(255, 255, 255, 200)));
    customPlot->legend->setBorderPen(QPen(QColor(180, 180, 180), 1));
    customPlot->axisRect()->insetLayout()->setInsetAlignment(0, Qt::AlignTop|Qt::AlignRight);

    // ============ Crosshair initialization============
    crosshairH = new QCPItemStraightLine(customPlot);
    crosshairH->setPen(QPen(QColor(150, 150, 150), 1, Qt::DashLine));
    crosshairH->setVisible(false);
    crosshairV = new QCPItemStraightLine(customPlot);
    crosshairV->setPen(QPen(QColor(150, 150, 150), 1, Qt::DashLine));
    crosshairV->setVisible(false);

    coordText = new QCPItemText(customPlot);
    coordText->setPositionAlignment(Qt::AlignLeft|Qt::AlignTop);
    coordText->position->setType(QCPItemPosition::ptAxisRectRatio);
    coordText->position->setCoords(0.02, 0.02);
    coordText->setText("X: -, Y: -");
    coordText->setTextAlignment(Qt::AlignLeft);
    coordText->setFont(QFont(font().family(), 9));
    coordText->setPadding(QMargins(5, 5, 5, 5));
    coordText->setBrush(QBrush(QColor(255, 255, 255, 200)));
    coordText->setPen(QPen(QColor(100, 100, 100)));

    // Create threshold line
    m_thresholdLine = new QCPItemStraightLine(customPlot);
    m_thresholdLine->point1->setCoords(customPlot->xAxis->range().lower, 50);
    m_thresholdLine->point2->setCoords(customPlot->xAxis->range().upper, 50);
    m_thresholdLine->setPen(QPen(QColor(50, 180, 50), 2, Qt::DashLine));

    m_thresholdLabel = new QCPItemText(customPlot);
    m_thresholdLabel->setText(QString::number(50.0, 'f', 2));
    m_thresholdLabel->setPositionAlignment(Qt::AlignRight | Qt::AlignTop);
    m_thresholdLabel->position->setParentAnchor(m_thresholdLine->point1);
    m_thresholdLabel->position->setCoords(50, -5);
    m_thresholdLabel->setPadding(QMargins(2, 2, 2, 2));
    m_thresholdLabel->setBrush(QBrush(Qt::white));
    m_thresholdLabel->setPen(QPen(Qt::black));

    threshold =m_thresholdLabel->text().toDouble();


    m_draggingThreshold = false;

    // customPlot->setInteractions(QCP::iRangeDrag | QCP::iRangeZoom|QCP::iSelectPlottables);
    customPlot->axisRect()->setRangeDrag(Qt::Vertical);
    customPlot->axisRect()->setRangeZoom(Qt::Vertical);
    connect(customPlot, &QCustomPlot::mousePress, this, &HomeGui::onMousePress);
    connect(customPlot, &QCustomPlot::mouseMove, this, &HomeGui::onMouseMove);
    connect(customPlot, &QCustomPlot::mouseRelease, this, &HomeGui::onMouseRelease);
    connect(customPlot, &QCustomPlot::mouseWheel, this, &HomeGui::onmouseWheel);
    connect(customPlot, &QCustomPlot::selectionChangedByUser, this, &HomeGui::onselectionChanged);

    customPlot->setNotAntialiasedElements(QCP::aeAll);
    customPlot->replot();
}

void HomeGui::setupCustomPlot_spike()
{
    customPlot_spike = ui->widget_Spike;
    customPlot_spike->setBackground(QBrush(QColor(245, 245, 245)));

    customPlot_spike->plotLayout()->insertRow(0);
    QCPTextElement *title = new QCPTextElement(customPlot_spike, "spike", QFont("Arial", 12, QFont::Bold));
    customPlot_spike->plotLayout()->addElement(0, 0, title);

    customPlot_spike->xAxis->setLabel("Time(ms)");
    customPlot_spike->xAxis->setRange(0, 1.6);
    customPlot_spike->xAxis->grid()->setSubGridVisible(true);

    customPlot_spike->yAxis->setLabel("Amplitude(uV)");
    customPlot_spike->yAxis->setRange(-400, 400);
    customPlot_spike->yAxis->grid()->setSubGridVisible(true);

    customPlot_spike->xAxis->grid()->setPen(QPen(QColor(200, 200, 200), 1, Qt::DotLine));
    customPlot_spike->yAxis->grid()->setPen(QPen(QColor(200, 200, 200), 1, Qt::DotLine));
    customPlot_spike->xAxis->grid()->setSubGridPen(QPen(QColor(220, 220, 220), 1, Qt::DotLine));
    customPlot_spike->yAxis->grid()->setSubGridPen(QPen(QColor(220, 220, 220), 1, Qt::DotLine));


    customPlot_spike->legend->setVisible(true);
    customPlot_spike->legend->setFont(QFont("Arial", 9));
    customPlot_spike->legend->setBrush(QBrush(QColor(255, 255, 255, 200)));
    customPlot_spike->legend->setBorderPen(QPen(QColor(180, 180, 180), 1));

    maxGraphSpinBox = new QSpinBox(customPlot_spike);
    maxGraphSpinBox->setRange(1, 500);
    maxGraphSpinBox->setValue(100);
    maxGraphSpinBox->setFixedSize(100, 30);
    maxGraphSpinBox->setToolTip("Maximum number of waveforms");
    maxGraphSpinBox->move(customPlot_spike->width()+100, 2);

    connect(maxGraphSpinBox, QOverload<int>::of(&QSpinBox::valueChanged),
            this, &HomeGui::onMaxGraphCountChanged);

    spikecrosshairH = new QCPItemStraightLine(customPlot_spike);
    spikecrosshairH->setPen(QPen(QColor(150, 150, 150), 1, Qt::DashLine));
    spikecrosshairH->setVisible(false);


    spikecrosshairV = new QCPItemStraightLine(customPlot_spike);
    spikecrosshairV->setPen(QPen(QColor(150, 150, 150), 1, Qt::DashLine));
    spikecrosshairV->setVisible(false);


    customPlot_spike->setInteractions(QCP::iRangeDrag | QCP::iRangeZoom | QCP::iSelectPlottables);
    customPlot_spike->axisRect()->setRangeDrag(Qt::Vertical);
    customPlot_spike->axisRect()->setRangeZoom(Qt::Vertical);

    customPlot_spike->legend->setVisible(false);
    customPlot_spike->replot();

}

void HomeGui::setupCustomPlot_ISI()
{

    customPlot_ISI = ui->widget_ISI;


    customPlot_ISI->plotLayout()->insertRow(0);
    QCPTextElement *title = new QCPTextElement(customPlot_ISI, "ISI", QFont("Arial", 12, QFont::Bold));
    customPlot_ISI->plotLayout()->addElement(0, 0, title);

    QCPAxis *keyAxis = customPlot_ISI->xAxis;
    QCPAxis *valueAxis = customPlot_ISI->yAxis;
    fossil = new QCPBars(keyAxis, valueAxis);

    fossil->setAntialiased(false);
    fossil->setName("Inter-Spike-interval");
    fossil->setPen(QPen(QColor(0, 168, 140).lighter(130)));
    fossil->setBrush(QColor(0, 168, 140));
    QVector<double> ticks;
    QVector<QString> labels;

    QVector<double> fossilData;
    for (int i=1;i<=100;i++) {
        ticks.append(i);
        if(i%10==0)
        {
            labels.append(QString("%1ms").arg(i));
        }
        else
        {

            labels.append(QString(""));
        }

    }

    for (int i=1;i<=100;i++) {
        fossilData.append(i);
    }

    QSharedPointer<QCPAxisTickerText> textTicker(new QCPAxisTickerText);
    textTicker->addTicks(ticks, labels);


    keyAxis->setTicker(textTicker);



    keyAxis->setTickLabelRotation(60);
    keyAxis->setSubTicks(false);
    keyAxis->setTickLength(0, 4);
    keyAxis->setRange(0, ticks.size()+1);
    keyAxis->setUpperEnding(QCPLineEnding::esSpikeArrow);

    valueAxis->setRange(0, fossilData.size());
    valueAxis->setPadding(35);
    valueAxis->setLabel("count");
    valueAxis->setUpperEnding(QCPLineEnding::esSpikeArrow);
    // fossil->setData(ticks, fossilData);
    customPlot_ISI->setInteractions(QCP::iRangeDrag | QCP::iRangeZoom | QCP::iSelectPlottables);
    customPlot_ISI->replot();
}

void HomeGui::setupCustomPlot_Raster()
{
    customPlot_Raster = ui->widget_raster;
    customPlot_Raster->setBackground(QBrush(QColor(245, 245, 245)));
    customPlot_Raster->plotLayout()->insertRow(0);
    QCPTextElement *title = new QCPTextElement(customPlot_Raster, "raster", QFont("Arial", 12, QFont::Bold));
    customPlot_Raster->plotLayout()->addElement(0, 0, title);



    const int numChannels = channelMax;
    const double timeRange = 2000;

    for (int channel = 0; channel < numChannels; ++channel)
    {
        QCPGraph* graph = customPlot_Raster->addGraph();

        QPen bluePen(QColor(50, 50, 255), 1);
        graph->setPen(bluePen);
        graph->setScatterStyle(QCPScatterStyle(QCPScatterStyle::ssNone, 5));
        graph->setLineStyle(QCPGraph::lsLine);
    }
    customPlot_Raster->xAxis->setRange(0, timeRange);

    customPlot_Raster->yAxis->setRange(-1, numChannels +0.5);

    QSharedPointer<QCPAxisTickerText> textTicker(new QCPAxisTickerText);
    for (int i = 0; i < numChannels; ++i) {

        if(i%16==0)
        {
          textTicker->addTick(i, QString("channel %1").arg(i));
        }
        else if(i == 127)
        {
            textTicker->addTick(i, QString("channel 127"));
        }
        else
        {
            textTicker->addTick(i, QString(""));
        }

    }
    customPlot_Raster->yAxis->setTicker(textTicker);

    customPlot_Raster->xAxis->grid()->setPen(QPen(QColor(200, 200, 200), 1, Qt::DotLine));
    customPlot_Raster->yAxis->grid()->setPen(QPen(QColor(200, 200, 200), 1, Qt::DotLine));
    customPlot_Raster->xAxis->grid()->setSubGridPen(QPen(QColor(220, 220, 220), 1, Qt::DotLine));
    customPlot_Raster->yAxis->grid()->setSubGridPen(QPen(QColor(220, 220, 220), 1, Qt::DotLine));
    customPlot_Raster->legend->setVisible(true);
    customPlot_Raster->legend->setFont(QFont("Arial", 9));
    customPlot_Raster->legend->setBrush(QBrush(QColor(255, 255, 255, 200)));
    customPlot_Raster->legend->setBorderPen(QPen(QColor(180, 180, 180), 1));


    customPlot_Raster->axisRect()->insetLayout()->setInsetAlignment(0, Qt::AlignTop|Qt::AlignRight);
    RastercrosshairH = new QCPItemStraightLine(customPlot_Raster);
    RastercrosshairH->setPen(QPen(QColor(150, 150, 150), 1, Qt::DashLine));
    RastercrosshairH->setVisible(false);
    RastercrosshairV = new QCPItemStraightLine(customPlot_Raster);
    RastercrosshairV->setPen(QPen(QColor(150, 150, 150), 1, Qt::DashLine));
    RastercrosshairV->setVisible(false);

    customPlot_Raster->setInteractions(QCP::iRangeDrag | QCP::iRangeZoom | QCP::iSelectPlottables);

    customPlot_Raster->legend->setVisible(false);

    customPlot_Raster->axisRect()->setRangeDrag(Qt::Vertical);
    customPlot_Raster->axisRect()->setRangeZoom(Qt::Vertical);

    connect(customPlot_Raster, &QCustomPlot::mouseWheel, this, &HomeGui::onRastermouseWheel);

    customPlot_Raster->setNotAntialiasedElements(QCP::aeAll);
    QFont Rasterfont;
    Rasterfont.setStyleStrategy(QFont::NoAntialias);
    customPlot_Raster->xAxis->setTickLabelFont(Rasterfont);
    customPlot_Raster->yAxis->setTickLabelFont(Rasterfont);

    customPlot_Raster->replot();


}

void HomeGui::setupCustomPlot_impedance()
{
    customPlot_impedance = ui->widget_imped;
    customPlot_impedance->setBackground(QBrush(QColor(245, 245, 245)));


    customPlot_impedance->plotLayout()->insertRow(0);
    QCPTextElement *title = new QCPTextElement(customPlot_impedance, "Impedance", QFont("Arial", 12, QFont::Bold));
    customPlot_impedance->plotLayout()->addElement(0, 0, title);
    customPlot_impedance->addGraph();
    QPen greenPen(QColor(50, 180, 50), 1.5);
    customPlot_impedance->graph(0)->setName("Impedance");
    customPlot_impedance->xAxis->setLabel("Time(s)");
    customPlot_impedance->xAxis->setRange(0, 200);
    customPlot_impedance->xAxis->grid()->setSubGridVisible(true);

    customPlot_impedance->yAxis->setLabel("Amplitude(uV)");
    customPlot_impedance->yAxis->setRange(-6000, 6000);
    customPlot_impedance->yAxis->grid()->setSubGridVisible(true);

    customPlot_impedance->xAxis->grid()->setPen(QPen(QColor(200, 200, 200), 1, Qt::DotLine));
    customPlot_impedance->yAxis->grid()->setPen(QPen(QColor(200, 200, 200), 1, Qt::DotLine));
    customPlot_impedance->xAxis->grid()->setSubGridPen(QPen(QColor(220, 220, 220), 1, Qt::DotLine));
    customPlot_impedance->yAxis->grid()->setSubGridPen(QPen(QColor(220, 220, 220), 1, Qt::DotLine));

    customPlot_impedance->legend->setVisible(true);
    customPlot_impedance->legend->setFont(QFont("Arial", 9));
    customPlot_impedance->legend->setBrush(QBrush(QColor(255, 255, 255, 200)));
    customPlot_impedance->legend->setBorderPen(QPen(QColor(180, 180, 180), 1));

    customPlot_impedance->axisRect()->insetLayout()->setInsetAlignment(0, Qt::AlignTop|Qt::AlignRight);
    impedancecrosshairH = new QCPItemStraightLine(customPlot_impedance);
    impedancecrosshairH->setPen(QPen(QColor(150, 150, 150), 1, Qt::DashLine));
    impedancecrosshairH->setVisible(false);

    impedancecrosshairV = new QCPItemStraightLine(customPlot_impedance);
    impedancecrosshairV->setPen(QPen(QColor(150, 150, 150), 1, Qt::DashLine));
    impedancecrosshairV->setVisible(false);

    impedancecoordText = new QCPItemText(customPlot_impedance);
    impedancecoordText->setPositionAlignment(Qt::AlignLeft|Qt::AlignTop);
    impedancecoordText->position->setType(QCPItemPosition::ptAxisRectRatio);
    impedancecoordText->position->setCoords(0.02, 0.02);
    impedancecoordText->setText("ImpedanceValue:");
    impedancecoordText->setTextAlignment(Qt::AlignLeft);
    impedancecoordText->setFont(QFont(font().family(), 9));
    impedancecoordText->setPadding(QMargins(5, 5, 5, 5));
    impedancecoordText->setBrush(QBrush(QColor(255, 255, 255, 200)));
    impedancecoordText->setPen(QPen(QColor(100, 100, 100)));

    customPlot_impedance->setInteractions(QCP::iRangeDrag | QCP::iRangeZoom | QCP::iSelectPlottables);

    customPlot_impedance->replot();

}

void HomeGui::setupCustomPlot_Decoding()
{

    customPlot_Decoding = ui->widget_Decoding;
    customPlot_Decoding->setBackground(QBrush(QColor(245, 245, 245)));
    customPlot_Decoding->plotLayout()->insertRow(0);
    QCPTextElement *title = new QCPTextElement(customPlot_Decoding, "Decoding Result", QFont("Arial", 12, QFont::Bold));
    customPlot_Decoding->plotLayout()->addElement(0, 0, title);

    customPlot_Decoding->addGraph();
    customPlot_Decoding->addGraph();

    customPlot_Decoding->graph(0)->setPen(QPen(QColor(0, 0, 0), 1.5));
    customPlot_Decoding->graph(0)->setScatterStyle(QCPScatterStyle(QCPScatterStyle::ssNone, 5));
    customPlot_Decoding->graph(0)->setName("X");

    QPen greenPen(QColor(50, 180, 50), 1.5);
    customPlot_Decoding->graph(1)->setPen(greenPen);
    customPlot_Decoding->graph(1)->setScatterStyle(QCPScatterStyle(QCPScatterStyle::ssNone, 5));
    customPlot_Decoding->graph(1)->setName("Y");

    customPlot_Decoding->xAxis->setLabel("Time(s)");
    customPlot_Decoding->xAxis->setRange(0, 10000);
    customPlot_Decoding->xAxis->grid()->setSubGridVisible(true);

    customPlot_Decoding->yAxis->setLabel("Amplitude(uV)");
    customPlot_Decoding->yAxis->setRange(-6000, 6000);
    customPlot_Decoding->yAxis->grid()->setSubGridVisible(true);

    customPlot_Decoding->xAxis->grid()->setPen(QPen(QColor(200, 200, 200), 1, Qt::DotLine));
    customPlot_Decoding->yAxis->grid()->setPen(QPen(QColor(200, 200, 200), 1, Qt::DotLine));
    customPlot_Decoding->xAxis->grid()->setSubGridPen(QPen(QColor(220, 220, 220), 1, Qt::DotLine));
    customPlot_Decoding->yAxis->grid()->setSubGridPen(QPen(QColor(220, 220, 220), 1, Qt::DotLine));

    customPlot_Decoding->legend->setVisible(true);
    customPlot_Decoding->legend->setFont(QFont("Arial", 9));
    customPlot_Decoding->legend->setBrush(QBrush(QColor(255, 255, 255, 200)));
    customPlot_Decoding->legend->setBorderPen(QPen(QColor(180, 180, 180), 1));


    customPlot_Decoding->axisRect()->insetLayout()->setInsetAlignment(0, Qt::AlignTop|Qt::AlignRight);

    customPlot_Decoding->replot();

}

void HomeGui::setupInteractions()
{


    connect(customPlot, &QCustomPlot::mouseMove, this, [=](QMouseEvent *event)
    {
        double x = customPlot->xAxis->pixelToCoord(event->pos().x());
        double y = customPlot->yAxis->pixelToCoord(event->pos().y());


        coordText->setText(QString("X: %1 ms\nY: %2 uV").arg(x, 0, 'f', 2).arg(y, 0, 'f', 2));
        coordText->setVisible(true);

        customPlot->replot();
    });

    connect(customPlot, &QCustomPlot::mouseRelease, this, [=]()
    {
        crosshairV->setVisible(false);
        crosshairH->setVisible(false);
        customPlot->replot();
    });

    customPlot->setInteraction(QCP::iRangeZoom, true);

    connect(customPlot, &QCustomPlot::mouseDoubleClick, this, [=]()
    {
        customPlot->rescaleAxes();
        customPlot->replot();
    });

    customPlot->setContextMenuPolicy(Qt::CustomContextMenu);
    connect(customPlot, &QCustomPlot::customContextMenuRequested, this, &HomeGui::showContextMenu);

    customPlot_spike->setContextMenuPolicy(Qt::CustomContextMenu);
    connect(customPlot_spike, &QCustomPlot::customContextMenuRequested, this, &HomeGui::showContextMenu_spike);


    customPlot_impedance->setContextMenuPolicy(Qt::CustomContextMenu);
    connect(customPlot_impedance, &QCustomPlot::customContextMenuRequested, this, &HomeGui::showContextMenu_impedance);
}

void HomeGui::setupCustomPlot_loaddata()
{
    customPlot_loaddata = ui->widget_loaddata;


#ifdef QCUSTOMPLOT_USE_OPENGL
    customPlot_loaddata->setOpenGl(true);

    // 设置适当的重绘策略
    customPlot_loaddata->setBufferDevicePixelRatio(1);
    customPlot_loaddata->setPlottingHint(QCP::phImmediateRefresh, false);
#endif
    if (!QOpenGLContext::currentContext()) {
        qDebug() << "OpenGL not supported on this system";
        customPlot_loaddata->setOpenGl(false); // 回退到软件渲染
    }

    customPlot_loaddata->setBackground(QBrush(QColor(245, 245, 245)));

    customPlot_loaddata->plotLayout()->insertRow(0);
    QCPTextElement *title = new QCPTextElement(customPlot_loaddata, "Raw signal", QFont("Arial", 12, QFont::Bold));
    customPlot_loaddata->plotLayout()->addElement(0, 0, title);


    customPlot_loaddata->addGraph();
    customPlot_loaddata->addGraph();
    customPlot_loaddata->addGraph();

    customPlot_loaddata->graph(0)->setPen(QPen(Qt::red, 1));
    customPlot_loaddata->graph(0)->setScatterStyle(QCPScatterStyle(QCPScatterStyle::ssNone, 5));
    customPlot_loaddata->graph(0)->setName("Raw signal");

    QPen greenPen(QColor(50, 180, 50), 1);

    customPlot_loaddata->graph(1)->setPen(greenPen);
    customPlot_loaddata->graph(1)->setScatterStyle(QCPScatterStyle(QCPScatterStyle::ssNone, 5));
    customPlot_loaddata->graph(1)->setName("Threshold");

    QPen bluePen(QColor(50, 50, 255), 1);
    customPlot_loaddata->graph(2)->setPen(bluePen);
    customPlot_loaddata->graph(2)->setScatterStyle(QCPScatterStyle(QCPScatterStyle::ssNone, 1));
    customPlot_loaddata->graph(2)->setName("spike");
    customPlot_loaddata->graph(2)->setLineStyle(QCPGraph::lsLine);

    customPlot_loaddata->xAxis->setLabel("Time (ms)");
    customPlot_loaddata->xAxis->setRange(0, 2000);
    customPlot_loaddata->xAxis->grid()->setSubGridVisible(true);

    customPlot_loaddata->yAxis->setLabel("Amplitude(uV)");
    customPlot_loaddata->yAxis->setRange(-400, 400);
    customPlot_loaddata->yAxis->grid()->setSubGridVisible(true);

    customPlot_loaddata->xAxis->grid()->setPen(QPen(QColor(200, 200, 200), 1, Qt::DotLine));
    customPlot_loaddata->yAxis->grid()->setPen(QPen(QColor(200, 200, 200), 1, Qt::DotLine));
    customPlot_loaddata->xAxis->grid()->setSubGridPen(QPen(QColor(220, 220, 220), 1, Qt::DotLine));
    customPlot_loaddata->yAxis->grid()->setSubGridPen(QPen(QColor(220, 220, 220), 1, Qt::DotLine));

    customPlot_loaddata->legend->setVisible(true);
    customPlot_loaddata->legend->setFont(QFont("Arial", 9));
    customPlot_loaddata->legend->setBrush(QBrush(QColor(255, 255, 255, 200)));
    customPlot_loaddata->legend->setBorderPen(QPen(QColor(180, 180, 180), 1));

    customPlot_loaddata->axisRect()->insetLayout()->setInsetAlignment(0, Qt::AlignTop|Qt::AlignRight);

    crosshairHfile = new QCPItemStraightLine(customPlot_loaddata);
    crosshairHfile->setPen(QPen(QColor(150, 150, 150), 1, Qt::DashLine));
    crosshairHfile->setVisible(false);

    crosshairVfile = new QCPItemStraightLine(customPlot_loaddata);
    crosshairVfile->setPen(QPen(QColor(150, 150, 150), 1, Qt::DashLine));
    crosshairVfile->setVisible(false);

    coordTextfile = new QCPItemText(customPlot_loaddata);
    coordTextfile->setPositionAlignment(Qt::AlignLeft|Qt::AlignTop);
    coordTextfile->position->setType(QCPItemPosition::ptAxisRectRatio);
    coordTextfile->position->setCoords(0.02, 0.02);
    coordTextfile->setText("X: -, Y: -");
    coordTextfile->setTextAlignment(Qt::AlignLeft);
    coordTextfile->setFont(QFont(font().family(), 9));
    coordTextfile->setPadding(QMargins(5, 5, 5, 5));
    coordTextfile->setBrush(QBrush(QColor(255, 255, 255, 200)));
    coordTextfile->setPen(QPen(QColor(100, 100, 100)));

    m_thresholdLinefile = new QCPItemStraightLine(customPlot_loaddata);
    m_thresholdLinefile->point1->setCoords(customPlot_loaddata->xAxis->range().lower, 50);
    m_thresholdLinefile->point2->setCoords(customPlot_loaddata->xAxis->range().upper, 50);
    m_thresholdLinefile->setPen(QPen(QColor(50, 180, 50), 2, Qt::DashLine));

    m_thresholdLabelfile = new QCPItemText(customPlot_loaddata);
    m_thresholdLabelfile->setText(QString::number(50.0, 'f', 2));
    m_thresholdLabelfile->setPositionAlignment(Qt::AlignRight | Qt::AlignTop);
    m_thresholdLabelfile->position->setParentAnchor(m_thresholdLinefile->point1);
    m_thresholdLabelfile->position->setCoords(50, -5);
    m_thresholdLabelfile->setPadding(QMargins(2, 2, 2, 2));
    m_thresholdLabelfile->setBrush(QBrush(Qt::white));
    m_thresholdLabelfile->setPen(QPen(Qt::black));

    thresholdfile =m_thresholdLabelfile->text().toDouble();

    QFont font1;
    font1.setStyleStrategy(QFont::NoAntialias);
    customPlot_loaddata->xAxis->setTickLabelFont(font1);
    customPlot_loaddata->yAxis->setTickLabelFont(font1);

    m_draggingThresholdfile = false;

    customPlot_loaddata->setInteractions(QCP::iRangeDrag | QCP::iRangeZoom|QCP::iSelectPlottables);
    connect(customPlot_loaddata, &QCustomPlot::mousePress, this, &HomeGui::onMousePressfile);
    connect(customPlot_loaddata, &QCustomPlot::mouseMove, this, &HomeGui::onMouseMovefile);
    connect(customPlot_loaddata, &QCustomPlot::mouseRelease, this, &HomeGui::onMouseRelease);

    customPlot_loaddata->setNotAntialiasedElements(QCP::aeAll);

    customPlot_loaddata->replot();

}

void HomeGui::setupCustomPlot_spike_loaddata()
{
    customPlot_spike_loaddata = ui->widget_Spike_loaddata;
    customPlot_spike_loaddata->setBackground(QBrush(QColor(245, 245, 245)));

    customPlot_spike_loaddata->plotLayout()->insertRow(0);
    QCPTextElement *title = new QCPTextElement(customPlot_spike_loaddata, "spike", QFont("Arial", 12, QFont::Bold));
    customPlot_spike_loaddata->plotLayout()->addElement(0, 0, title);

    customPlot_spike_loaddata->xAxis->setLabel("Time(ms)");
    customPlot_spike_loaddata->xAxis->setRange(0, 1.6);
    customPlot_spike_loaddata->xAxis->grid()->setSubGridVisible(true);

    customPlot_spike_loaddata->yAxis->setLabel("Amplitude(uV)");
    customPlot_spike_loaddata->yAxis->setRange(-400, 400);
    customPlot_spike_loaddata->yAxis->grid()->setSubGridVisible(true);

    customPlot_spike_loaddata->xAxis->grid()->setPen(QPen(QColor(200, 200, 200), 1, Qt::DotLine));
    customPlot_spike_loaddata->yAxis->grid()->setPen(QPen(QColor(200, 200, 200), 1, Qt::DotLine));
    customPlot_spike_loaddata->xAxis->grid()->setSubGridPen(QPen(QColor(220, 220, 220), 1, Qt::DotLine));
    customPlot_spike_loaddata->yAxis->grid()->setSubGridPen(QPen(QColor(220, 220, 220), 1, Qt::DotLine));

    customPlot_spike_loaddata->legend->setVisible(true);
    customPlot_spike_loaddata->legend->setFont(QFont("Arial", 9));
    customPlot_spike_loaddata->legend->setBrush(QBrush(QColor(255, 255, 255, 200)));
    customPlot_spike_loaddata->legend->setBorderPen(QPen(QColor(180, 180, 180), 1));

    maxGraphSpinBoxfile = new QSpinBox(customPlot_spike_loaddata);
    maxGraphSpinBoxfile->setRange(1, 500);
    maxGraphSpinBoxfile->setValue(100);
    maxGraphSpinBoxfile->setFixedSize(100, 30);
    maxGraphSpinBoxfile->setToolTip("Maximum number of waveforms");
    maxGraphSpinBoxfile->move(customPlot_spike_loaddata->width()+300, 2);

    connect(maxGraphSpinBoxfile, QOverload<int>::of(&QSpinBox::valueChanged),
            this, [this](int value) {
                    maxGraphCountfile = value;
                    updatespikePlot_file();

            });

    spikecrosshairH = new QCPItemStraightLine(customPlot_spike_loaddata);
    spikecrosshairH->setPen(QPen(QColor(150, 150, 150), 1, Qt::DashLine));
    spikecrosshairH->setVisible(false);

    spikecrosshairV = new QCPItemStraightLine(customPlot_spike_loaddata);
    spikecrosshairV->setPen(QPen(QColor(150, 150, 150), 1, Qt::DashLine));
    spikecrosshairV->setVisible(false);

    customPlot_spike_loaddata->setInteractions(QCP::iRangeDrag | QCP::iRangeZoom | QCP::iSelectPlottables);
    customPlot_spike_loaddata->axisRect()->setRangeDrag(Qt::Vertical);
    customPlot_spike_loaddata->axisRect()->setRangeZoom(Qt::Vertical);
    customPlot_spike_loaddata->legend->setVisible(false);
    customPlot_spike_loaddata->replot();
}

void HomeGui::setupCustomPlot_ISI_loaddata()
{
    customPlot_ISI_loaddata = ui->widget_ISI_loaddata;
    customPlot_ISI_loaddata->plotLayout()->insertRow(0);
    QCPTextElement *title = new QCPTextElement(customPlot_ISI_loaddata, "ISI", QFont("Arial", 12, QFont::Bold));
    customPlot_ISI_loaddata->plotLayout()->addElement(0, 0, title);

    QCPAxis *keyAxis = customPlot_ISI_loaddata->xAxis;
    QCPAxis *valueAxis = customPlot_ISI_loaddata->yAxis;
    fossil_file = new QCPBars(keyAxis, valueAxis);

    fossil_file->setAntialiased(false);
    fossil_file->setName("Inter-Spike-interval");
    fossil_file->setPen(QPen(QColor(0, 168, 140).lighter(130)));
    fossil_file->setBrush(QColor(0, 168, 140));

    QVector<double> ticks;
    QVector<QString> labels;

    QVector<double> fossilData;
    for (int i=1;i<=100;i++) {
        ticks.append(i);
        if(i%10==0)
        {
            labels.append(QString("%1ms").arg(i));
        }
        else
        {

            labels.append(QString(""));
        }

    }

    for (int i=1;i<=100;i++) {
        fossilData.append(i);
    }

    QSharedPointer<QCPAxisTickerText> textTicker(new QCPAxisTickerText);
    textTicker->addTicks(ticks, labels);


    keyAxis->setTicker(textTicker);

    keyAxis->setTickLabelRotation(60);
    keyAxis->setSubTicks(false);
    keyAxis->setTickLength(0, 4);
    keyAxis->setRange(0, ticks.size()+1);
    keyAxis->setUpperEnding(QCPLineEnding::esSpikeArrow);

    valueAxis->setRange(0, fossilData.size());
    valueAxis->setPadding(35);
    valueAxis->setLabel("count");
    valueAxis->setUpperEnding(QCPLineEnding::esSpikeArrow);

    customPlot_ISI_loaddata->setInteractions(QCP::iRangeDrag | QCP::iRangeZoom | QCP::iSelectPlottables);
    customPlot_ISI_loaddata->replot();

}

void HomeGui::setupCustomPlot_Raster_loaddata()
{
    customPlot_Raster_loaddata = ui->widget_raster_loaddata;
    customPlot_Raster_loaddata->setBackground(QBrush(QColor(245, 245, 245)));
    customPlot_Raster_loaddata->plotLayout()->insertRow(0);
    QCPTextElement *title = new QCPTextElement(customPlot_Raster_loaddata, "raster", QFont("Arial", 12, QFont::Bold));
    customPlot_Raster_loaddata->plotLayout()->addElement(0, 0, title);
    const int numChannels = channelMax;
    const double timeRange = 2000;

    for (int channel = 0; channel < numChannels; ++channel)
    {
        QCPGraph* graph = customPlot_Raster_loaddata->addGraph();

        QPen bluePen(QColor(50, 50, 255), 1);
        graph->setPen(bluePen);
        graph->setScatterStyle(QCPScatterStyle(QCPScatterStyle::ssNone, 5));
        graph->setLineStyle(QCPGraph::lsLine);
    }
    customPlot_Raster_loaddata->xAxis->setRange(0, timeRange);

    customPlot_Raster_loaddata->yAxis->setRange(-1, numChannels +0.5);

    QSharedPointer<QCPAxisTickerText> textTicker(new QCPAxisTickerText);
    for (int i = 0; i < numChannels; ++i) {
        if(i%16==0)
        {
            textTicker->addTick(i, QString("channel %1").arg(i));
        }
        else if(i == 127)
        {
            textTicker->addTick(i, QString("channel 127"));
        }
        else
        {
            textTicker->addTick(i, QString(""));
        }

    }
    customPlot_Raster_loaddata->yAxis->setTicker(textTicker);
    customPlot_Raster_loaddata->xAxis->grid()->setPen(QPen(QColor(200, 200, 200), 1, Qt::DotLine));
    customPlot_Raster_loaddata->yAxis->grid()->setPen(QPen(QColor(200, 200, 200), 1, Qt::DotLine));
    customPlot_Raster_loaddata->xAxis->grid()->setSubGridPen(QPen(QColor(220, 220, 220), 1, Qt::DotLine));
    customPlot_Raster_loaddata->yAxis->grid()->setSubGridPen(QPen(QColor(220, 220, 220), 1, Qt::DotLine));

    customPlot_Raster_loaddata->legend->setVisible(true);
    customPlot_Raster_loaddata->legend->setFont(QFont("Arial", 9));
    customPlot_Raster_loaddata->legend->setBrush(QBrush(QColor(255, 255, 255, 200)));
    customPlot_Raster_loaddata->legend->setBorderPen(QPen(QColor(180, 180, 180), 1));
    customPlot_Raster_loaddata->axisRect()->insetLayout()->setInsetAlignment(0, Qt::AlignTop|Qt::AlignRight);
    RastercrosshairH = new QCPItemStraightLine(customPlot_Raster_loaddata);
    RastercrosshairH->setPen(QPen(QColor(150, 150, 150), 1, Qt::DashLine));
    RastercrosshairH->setVisible(false);

    RastercrosshairV = new QCPItemStraightLine(customPlot_Raster_loaddata);
    RastercrosshairV->setPen(QPen(QColor(150, 150, 150), 1, Qt::DashLine));
    RastercrosshairV->setVisible(false);

    customPlot_Raster_loaddata->setInteractions(QCP::iRangeDrag | QCP::iRangeZoom | QCP::iSelectPlottables);

    customPlot_Raster_loaddata->legend->setVisible(false);

    connect(customPlot_Raster_loaddata, &QCustomPlot::mouseWheel, this, &HomeGui::onRasterfilemouseWheel);

    customPlot_Raster_loaddata->setNotAntialiasedElements(QCP::aeAll);
    QFont Rasterfont;
    Rasterfont.setStyleStrategy(QFont::NoAntialias);
    customPlot_Raster_loaddata->xAxis->setTickLabelFont(Rasterfont);
    customPlot_Raster_loaddata->yAxis->setTickLabelFont(Rasterfont);
    customPlot_Raster_loaddata->replot();

}

void HomeGui::showContextMenu(const QPoint &pos)
{
    customPlot = ui->widget;

    QMenu *menu = new QMenu(this);
    menu->setAttribute(Qt::WA_DeleteOnClose);

    menu->addAction("Save image", this, [=]()
    {
        QString fileName = QFileDialog::getSaveFileName(this, "Save image", "", "PNG (*.png);;JPG (*.jpg);;PDF (*.pdf)");
        if (!fileName.isEmpty())
        {
            if (fileName.endsWith(".png"))
                customPlot->savePng(fileName);
            else if (fileName.endsWith(".jpg"))
                customPlot->saveJpg(fileName);
            else if (fileName.endsWith(".pdf"))
                customPlot->savePdf(fileName);
        }
    });

    menu->addSeparator();

    menu->addAction("reset view", this, [=]()
    {
        customPlot->rescaleAxes();
        customPlot->replot();
    });

    menu->addAction("Show/Hide Legend", this, [=]()
    {
        customPlot->legend->setVisible(!customPlot->legend->visible());
        customPlot->replot();
    });

    menu->addAction("Delet Mark", this, [=]()
    {
        if(Rawline!=nullptr)
        {
            qDebug()<<"Delet Mark";
            Rawline->setVisible(false);
            Rawlabel->setVisible(false);
            line_raster->setVisible(false);
        }

        if(RawlineB!=nullptr)
        {
            qDebug()<<"Delet Mark1";
            RawlineB->setVisible(false);
            RawlabelB->setVisible(false);
            line_rasterB->setVisible(false);
        }

        customPlot->replot();
        customPlot_Raster->replot();

    });
    menu->popup(customPlot->mapToGlobal(pos));
}

void HomeGui::showContextMenu_spike(const QPoint &pos)
{

    QMenu *menu = new QMenu(this);
    menu->setAttribute(Qt::WA_DeleteOnClose);

    menu->addAction("Save image", this, [=]()
    {
        QString fileName = QFileDialog::getSaveFileName(this, "Save image", "", "PNG (*.png);;JPG (*.jpg);;PDF (*.pdf)");
        if (!fileName.isEmpty())
        {
            if (fileName.endsWith(".png"))
                customPlot_spike->savePng(fileName);
            else if (fileName.endsWith(".jpg"))
                customPlot_spike->saveJpg(fileName);
            else if (fileName.endsWith(".pdf"))
                customPlot_spike->savePdf(fileName);
        }
    });

    menu->addSeparator();

    menu->addAction("Reset View", this, [=]()
    {
        customPlot_spike->rescaleAxes();
        customPlot_spike->replot();
    });


    menu->addAction("Clear Data", this, [=]()
    {
        customPlot_spike->clearGraphs();  // 这会移除所有 graphs 及其数据
        customPlot_spike->replot();  // 刷新显示
        queue_spike.clear();
    });


    menu->popup(customPlot_spike->mapToGlobal(pos));

}

void HomeGui::showContextMenu_impedance(const QPoint &pos)
{

    QMenu *menu = new QMenu(this);
    menu->setAttribute(Qt::WA_DeleteOnClose);

    menu->addAction("Save image", this, [=]()
                    {
                        QString fileName = QFileDialog::getSaveFileName(this, "Save image", "", "PNG (*.png);;JPG (*.jpg);;PDF (*.pdf)");
                        if (!fileName.isEmpty())
                        {
                            if (fileName.endsWith(".png"))
                                customPlot_impedance->savePng(fileName);
                            else if (fileName.endsWith(".jpg"))
                                customPlot_impedance->saveJpg(fileName);
                            else if (fileName.endsWith(".pdf"))
                                customPlot_impedance->savePdf(fileName);
                        }
                    });

    menu->addSeparator();

    menu->addAction("Save impedance Data", this, [=]()
                    {
                        QString fileName = QString("impedance_Data_%1_ch%2.bin")
                                               .arg(QDateTime::currentDateTime().toString("yyyyMMdd_HHmmss"))
                                               .arg(currentChannel);

                        QFile impedancefile(fileName);
                        if (!impedancefile.open(QIODevice::WriteOnly)) {
                            qWarning() << "Unable to open file:" << impedancefile.errorString();
                            return false;
                        }
                        QDataStream out(&impedancefile);

                        for (const auto& row : m_buffer) {
                            out << row;
                        }
                        out << static_cast<quint32>(impedancevalue);
                        impedancefile.close();

                        QMessageBox mes(this);
                        mes.setText(QString("impedance impedance save successful"));
                        mes.exec();

                    });


    menu->popup(customPlot_impedance->mapToGlobal(pos));
}

void HomeGui::extractThresholdData(const QVector<double>& data, double samplingRate, double threshold) {

    if (data.isEmpty() || samplingRate <= 0) {
        qWarning("Invalid input: data size=%d, samplingRate=%.2f", data.size(), samplingRate);
        return;
    }

    const double samplingIntervalMs = 1000.0 / samplingRate;
    const int pointsBefore = qBound(0, static_cast<int>(0.4 / samplingIntervalMs), data.size());
    const int pointsAfter = qBound(0, static_cast<int>(1.2 / samplingIntervalMs), data.size());

    for (int i = 0; i < data.size() - 1; ++i) {

        bool crossFlag = false;

        if(threshold>0)
        {
            crossFlag = (data[i] < threshold) && (data[i+1] >= threshold);
        }
        else
        {
            crossFlag = (data[i] > threshold) && (data[i+1] <= threshold);
        }
        if(!crossFlag) continue;

        const int startIdx = qMax(0, i - pointsBefore);
        const int endIdx = qMin(data.size() - 1, i + pointsAfter);
        QVector<double> segment = data.sliced(startIdx, endIdx - startIdx + 1);
        if (queue_spike.size() >= maxGraphCount) queue_spike.dequeue();
        queue_spike.enqueue(segment);

        queue_ISI.enqueue(i);

        // beeper->playAsync();
    }

    if (queue_ISI.isEmpty()) {
        qDebug("No threshold crossings detected");
    }
}

QMap<int, int> HomeGui::extractISIData(const QQueue<double>& queue_ISI, double samplingRate)
{

    QMap<int, int> frequencyMap;
    if (queue_ISI.size() < 2) return frequencyMap;

    const double samplingIntervalMs = 1000.0 / samplingRate;
    QVector<double> indices = queue_ISI.toVector();
    std::sort(indices.begin(), indices.end());

    for (int i = 1; i < indices.size(); ++i) {
        const double diffMs = (indices[i] - indices[i-1]) * samplingIntervalMs;
        if (diffMs <= 0) continue;
        const int roundedMs = qRound(diffMs);
        frequencyMap[roundedMs]++;
    }
    return frequencyMap;


}

void HomeGui::cleanupThread()
{
    if (m_workerThread) {
        if (m_workerThread->isRunning()) {
            m_workerThread->quit();
            m_workerThread->wait();
        }
        m_workerThread = nullptr;
    }
    m_fileProcessor = nullptr;

}

void HomeGui::closeAutospikeDetection()
{
    if(isSpikeDetection == false)
    {
        isSpikeDetection = true;
        spikeUpdateTimer->stop();
    }


}

void HomeGui::setChannelIndex(int index)
{
    QFuture<void> future = QtConcurrent::run([this, index]() {
        bool status = statusflag;
        if(!statusflag){
            stop_clicked();
        }

        if(!startFPGA()) {
            return;
        }

        for (size_t i = 0; i < services.size(); i++) {
            if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1())) {
                service = services[i];
                characteristics = service.characteristics();
                break;
            }
        }

        for(int i = 0; i < characteristics.size(); i++) {
            if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("1f393840-1711-5955-86e6-c1b77090e7fe").toLatin1())) {
                characteristic = characteristics[i];
                break;
            }
        }

        QString str2 = QString("%1").arg(index, 2, 16, QLatin1Char('0'));
        QString dataToWrite = "C7E547" + str2;
        SimpleBLE::ByteArray data = SimpleBLE::ByteArray::fromHex(dataToWrite.toStdString());

        writeCharacteristic(service, characteristic, data);

        currentChannel = index;

        if(ui->cbox_singleChannel->isChecked()) {
            onsetSingleChannelFlag(currentChannel, true);
            ResetFPGA();
        }



        if(!status) {

            QMetaObject::invokeMethod(this, "on_pbtn_start_clicked", Qt::QueuedConnection);
        }
    });

}

void HomeGui::delayedReplot()
{
    customPlot->replot(QCustomPlot::rpQueuedReplot);
}

void HomeGui::syncXAxisRanges(QCPRange newRange)
{

    customPlot_loaddata->xAxis->blockSignals(true);
    customPlot_Raster_loaddata->xAxis->blockSignals(true);

    customPlot_loaddata->xAxis->setRange(newRange);
    customPlot_Raster_loaddata->xAxis->setRange(newRange);

    customPlot_loaddata->replot();
    customPlot_Raster_loaddata->replot();


    customPlot_loaddata->xAxis->blockSignals(false);
    customPlot_Raster_loaddata->xAxis->blockSignals(false);


}

QVector<double> HomeGui::generateSequentialData(int maxValue ,double sample) {
    QVector<double> data;
    for (int i = 0; i <= maxValue; ++i) {
        double tmp = static_cast<double>(i) / sample * 1000;
        data.append(tmp);
    }
    return data;
}

void HomeGui::addSpikeLines(QVector<double>& xData,QVector<double>& yData,QVector<uint8_t> spikevalues,double yLow,double yHigh)
{
    int spikesize = spikevalues.size();
    for (int i = 0; i < spikesize; ++i) {
        if(spikevalues[i] > 0)
        {
            double time = static_cast<double>(i);

            xData << std::numeric_limits<double>::quiet_NaN();
            yData << std::numeric_limits<double>::quiet_NaN();

            xData << time << time;
            yData << yLow << yHigh;
            xData << std::numeric_limits<double>::quiet_NaN();
            yData << std::numeric_limits<double>::quiet_NaN();
        }
    }
}

bool hasSpike(const QVector<double>& values) {
    if (values.size() < 3) return false;


    QVector<double> diffs;
    for (int i = 1; i < values.size(); ++i) {

        diffs.append(std::abs(values[i] - values[i - 1]));
    }


    QVector<double> sortedDiffs = diffs;
    std::sort(sortedDiffs.begin(), sortedDiffs.end());
    double median = sortedDiffs[sortedDiffs.size() / 2];
    double end = sortedDiffs[sortedDiffs.size()-1];
    QVector<double> deviations;
    for (double diff : diffs) {
        deviations.append(std::abs(diff - median));
    }
    std::sort(deviations.begin(), deviations.end());
    double mad = deviations[deviations.size() / 2] * 1.4826;

    double threshold = 3 * mad;
    for (double diff : diffs) {
        if (diff > threshold) {
            return true;
        }
    }
    return false;
}

void HomeGui::updatePlot()
{

    values.clear();
    if(CurrentMode != 3)
    {
        auto& m_buffer = Memerydata.m_buffer;
        double count = 0;

        values.reserve(values.size() + m_buffer.size());


        for (auto& value : m_buffer) {
            count += value.size();
            values.append(std::move(value));
        }

        if(lowPassFilterFlag)
        {
            values = filter.lowPassFilter(values, lowPassFilter);
        }
        else if(highPassFilterFlag)
        {
            values = filter.highPassFilter(values, highPassFilter);
        }
        else if(notchFilterFlag)
        {
            values = filter.notchFilter(values, notchFilterCenterFreq, notchFilterBW);
        }

        QVector<double> timeAxis(count);
        double *data = timeAxis.data();
        for (int i = 0; i < count; i++) {
            data[i] = i * m_step;

        }

        customPlot->graph(0)->setData(timeAxis, values,true);

        ui->label_packetLoss->setText(QString::number(Memerydata.packetloss, 'f')+"%");

        ui->label_channelIndex->setText(QString("%1").arg(Memerydata.m_currentChannel));

        auto localValues = this->values;
        auto localSamplingRate = samplingRate;
        auto localThreshold = threshold;
        auto localQueue_ISI = queue_ISI;

        extractThresholdData(localValues, localSamplingRate, localThreshold);


        updatespikePlot();

        updateISIPlot();

    }

    if(CurrentMode != 2)
    {
        m_spikebuffer =  Memerydata.m_spikebuffer;
        auto localQueue_ISI = queue_ISI;
        int size = static_cast<int>(values.size());
        QVector<uint8_t> spikevalues(size, 0);

        for (int position : localQueue_ISI) {
            if (position < size) {
                int tmp = qRound(position * m_step);
                spikevalues[tmp] = 1;
            }
        }
        QVector<double> xData, yData;
        const double yLow = customPlot->yAxis->range().lower;
        const double yHigh = double(yLow+abs(yLow/5));
        addSpikeLines(xData,yData,spikevalues,yLow,yHigh);
        customPlot->graph(2)->setData(xData, yData);
        updateRasterPlot();

    }
    customPlot->replot();
    queue_ISI.clear();
    queue_spike.clear();
}

void HomeGui::updateRaster()
{
    QMutexLocker locker(&m_spikeMutex);
    const auto& spikeAllChannel = m_spikeAllChannel;

    locker.unlock();

    int numGraphs = customPlot_Raster->graphCount();

    int numChannels = spikeAllChannel.size();
    int n = qMin(numGraphs, numChannels);

    for (int i = 0; i < n; ++i) {

        QVector<double> xData, yData;
        const double yLow = i;
        const double yHigh = double(2*i+1)/2.0;
        addSpikeLines(xData,yData,spikeAllChannel[i],yLow,yHigh);
        if (!xData.isEmpty()) {
            customPlot_Raster->graph(i)->setData(xData, yData);
            customPlot_Raster->graph(i)->setVisible(true);
            QPen redPen(Qt::blue, 1);
            customPlot_Raster->graph(i)->setPen(redPen);
        } else {
            customPlot_Raster->graph(i)->setVisible(false);
        }
        if(i == currentChannel)
        {
            QPen redPen(Qt::red, 1);
            customPlot_Raster->graph(i)->setPen(redPen);
        }
    }

    for (int i = n; i < numGraphs; ++i) {
        customPlot_Raster->graph(i)->data()->clear();
    }

    customPlot_Raster->replot(QCustomPlot::rpQueuedReplot);
}

void HomeGui::updateRasterPlot()
{

    spike_ISI_Future = QtConcurrent::run([this]()
    {
        QVector<QVector<uint8_t>> localSpikeValues;
        {
            QMutexLocker locker(&m_spikeMutex);
            localSpikeValues = std::move(m_spikebuffer);
            m_spikebuffer.clear();
        }

        if (localSpikeValues.empty()) {
            return;
        }
        const int numSpikes = localSpikeValues.size();

        const int numChannels = channelMax;
        const int totalTimePoints = numSpikes * 8;

        QVector<QVector<uint8_t>> spikeAllChannel(numChannels);
        QVector<double> spiketimeAxis(totalTimePoints);

        for (int ch = 0; ch < numChannels; ++ch) {
            spikeAllChannel[ch].resize(totalTimePoints);
        }
        for (int ch = 0; ch < numChannels; ++ch) {
            uint8_t* dest = spikeAllChannel[ch].data();

            for (int spikeIdx = 0; spikeIdx < numSpikes; ++spikeIdx) {
                const QVector<uint8_t>& spikeData = localSpikeValues[spikeIdx];
                const int srcOffset = ch * 8;

                std::copy(spikeData.constBegin() + srcOffset,
                          spikeData.constBegin() + srcOffset + 8,
                          dest + spikeIdx * 8);
            }
        }

    {
        QMutexLocker locker(&m_spikeMutex);
        m_spikeAllChannel = std::move(spikeAllChannel);
    }

    QMetaObject::invokeMethod(this, [this]() {
        updateRaster();
    }, Qt::QueuedConnection);
});

}

void HomeGui::updatePlot_file()
{
    values.clear();

    queue_ISI.clear();
    queue_spike.clear();

    m_buffer = m_fileProcessor->readRawBufferfile();
    double count = 0;

    values.reserve(values.size() + m_buffer.size());

    for (auto& value : m_buffer) {
        count += value.size();
        values.append(std::move(value));
    }



    if(lowPassFilterFlag)
    {
        values = filter.lowPassFilter(values, lowPassFilter);
    }
    else if(highPassFilterFlag)
    {
        values = filter.highPassFilter(values, highPassFilter);
    }
    else if(notchFilterFlag)
    {
        values = filter.notchFilter(values, notchFilterCenterFreq, notchFilterBW);
    }

    QVector<double> timeAxis(count);
    double *data = timeAxis.data();
    for (int i = 0; i < count; ++i) {
        data[i] = i * m_step;
    }

    customPlot_loaddata->graph(0)->setData(timeAxis, values,true);

    updatespikePlot_file();
    updateISIPlot_file();

    auto localQueue_ISI = queue_ISI;
    int size = static_cast<int>(values.size());
    QVector<uint8_t> spikevalues(size, 0);

    for (int position : localQueue_ISI) {
        if (position < size) {
            int tmp = qRound(position * m_step);
            spikevalues[tmp] = 1;
        }
    }
    QVector<double> xData, yData;
    const double yLow = customPlot_loaddata->yAxis->range().lower;
    const double yHigh = double(yLow+abs(yLow/5));
    addSpikeLines(xData,yData,spikevalues,yLow,yHigh);

    customPlot_loaddata->graph(2)->setData(xData, yData);

    customPlot_loaddata->replot();

    m_spikebuffer =  m_fileProcessor->readSpikeBufferfile();
    updateRasterPlot_file();


}

void HomeGui::updatespikePlot_file()
{

    queue_ISI.clear();
    queue_spike.clear();

    auto localValues = this->values;
    auto localSamplingRate = samplingRate;
    auto localThreshold = thresholdfile;
    auto localQueue_ISI = queue_ISI;

    extractThresholdData(localValues, localSamplingRate, localThreshold);

    static const QList<QColor> colorPalette = {
        QColor(255, 0, 0),
        QColor(0, 150, 0),
        QColor(0, 0, 255),
        QColor(255, 128, 0),
        QColor(128, 0, 128),
        QColor(0, 128, 128)
    };
    const int maxGraphs = maxGraphCountfile;
    int graphsToDraw = qMin(queue_spike.size(), maxGraphs);
    int startIndex = 0;

    const int existingGraphs = customPlot_spike_loaddata->graphCount();

    for (int i = existingGraphs; i < graphsToDraw; ++i) {
        customPlot_spike_loaddata->addGraph();
    }

    for (int i = existingGraphs - 1; i >= graphsToDraw; --i) {
        customPlot_spike_loaddata->removeGraph(i);
    }

    for (int graphIndex = 0; graphIndex < graphsToDraw; ++graphIndex)
    {
        QCPGraph* graph = customPlot_spike_loaddata->graph(graphIndex);

        int dataIndex = startIndex + graphIndex;
        const QVector<double>& spikeData = queue_spike.at(dataIndex);

        const QColor& color = colorPalette.at(graphIndex % colorPalette.size());
        graph->setPen(QPen(color));

        const int dataSize = spikeData.size();
        if (!xAxisCache.contains(dataSize)) {
            xAxisCache[dataSize] = generateSequentialData(dataSize, samplingRate);
        }

        graph->setData(xAxisCache[dataSize], spikeData);
    }

    QCustomPlot::RefreshPriority refreshPriority =
        (graphsToDraw > 50) ? QCustomPlot::rpQueuedReplot : QCustomPlot::rpImmediateRefresh;

    customPlot_spike_loaddata->replot(refreshPriority);

}

void HomeGui::updateISIPlot_file()
{

    QMap<int, int> temI_SIS = extractISIData(queue_ISI,samplingRate);

    QVector<double> ticks;
    QVector<QString> labels;
    QVector<double> fossilData;
    for (auto it = temI_SIS.begin(); it != temI_SIS.end(); ++it) {
        ticks.append(it.key());
        fossilData.append(it.value());
    }
    fossil_file->setData(ticks, fossilData);
    customPlot_ISI_loaddata->yAxis->rescale();
    customPlot_ISI_loaddata->replot();
}

void HomeGui::updateRaster_file()
{
    QMutexLocker locker(&m_spikeMutex);

    const auto& spikeAllChannel = m_spikeAllChannel;

    locker.unlock();

    int numGraphs = customPlot_Raster_loaddata->graphCount();

    int numChannels = spikeAllChannel.size();
    int n = qMin(numGraphs, numChannels);

    for (int i = 0; i < n; ++i) {

        QVector<double> xData, yData;
        const double yLow = i;
        const double yHigh = double(2*i+1)/2.0;
        addSpikeLines(xData,yData,spikeAllChannel[i],yLow,yHigh);
        if (!xData.isEmpty()) {
            customPlot_Raster_loaddata->graph(i)->setData(xData, yData);
            customPlot_Raster_loaddata->graph(i)->setVisible(true);

        } else {
            customPlot_Raster_loaddata->graph(i)->setVisible(false);
        }
        if(i == filecurrentChannel)
        {

            QPen bluePen(Qt::red, 1);
            customPlot_Raster_loaddata->graph(i)->setPen(bluePen);
        }

    }

    for (int i = n; i < numGraphs; ++i) {
        customPlot_Raster_loaddata->graph(i)->data()->clear();
    }

    customPlot_Raster_loaddata->replot(QCustomPlot::rpQueuedReplot);

}

void HomeGui::updateRasterPlot_file()
{

    spike_ISI_Future = QtConcurrent::run([this](){

        QVector<QVector<uint8_t>> localSpikeValues;
        {
            QMutexLocker locker(&m_spikeMutex);
            localSpikeValues = std::move(m_spikebuffer);
            m_spikebuffer.clear();
        }

        if (localSpikeValues.empty()) {
            return;
        }

        const int numSpikes = localSpikeValues.size();

        const int numChannels = channelMax;
        const int totalTimePoints = numSpikes * 8;

        QVector<QVector<uint8_t>> spikeAllChannel(numChannels);
        QVector<double> spiketimeAxis(totalTimePoints);

        for (int ch = 0; ch < numChannels; ++ch) {
            spikeAllChannel[ch].resize(totalTimePoints);
        }

        for (int ch = 0; ch < numChannels; ++ch) {
            uint8_t* dest = spikeAllChannel[ch].data();
            for (int spikeIdx = 0; spikeIdx < numSpikes; ++spikeIdx) {
                const QVector<uint8_t>& spikeData = localSpikeValues[spikeIdx];
                const int srcOffset = ch * 8;

                std::copy(spikeData.constBegin() + srcOffset,
                          spikeData.constBegin() + srcOffset + 8,
                          dest + spikeIdx * 8);
            }
        }
        {
            QMutexLocker locker(&m_spikeMutex);
            m_spikeAllChannel = std::move(spikeAllChannel);
        }

        QMetaObject::invokeMethod(this, [this]() {
            updateRaster_file();
        }, Qt::QueuedConnection);
    });
}

void HomeGui::updatespikePlot()
{
    static const QList<QColor> colorPalette = {
        QColor(255, 0, 0),
        QColor(0, 150, 0),
        QColor(0, 0, 255),
        QColor(255, 128, 0),
        QColor(128, 0, 128),
        QColor(0, 128, 128)
    };
    const int maxGraphs = maxGraphCount;

    int graphsToDraw = queue_spike.size();
    const int existingGraphs = customPlot_spike->graphCount();
    for (int i = existingGraphs; i < graphsToDraw; ++i) {
        customPlot_spike->addGraph();
    }

    for (int i = existingGraphs - 1; i >= graphsToDraw; --i) {
        customPlot_spike->removeGraph(i);
    }

    for (int graphIndex = 0; graphIndex < graphsToDraw; ++graphIndex)
    {
        QCPGraph* graph = customPlot_spike->graph(graphIndex);
        int dataIndex =  graphIndex;
        const QVector<double>& spikeData = queue_spike.at(dataIndex);
        const QColor& color = colorPalette.at(graphIndex % colorPalette.size());
        graph->setPen(QPen(color));
        const int dataSize = spikeData.size();
        if (!xAxisCache.contains(dataSize)) {
            xAxisCache[dataSize] = generateSequentialData(dataSize, samplingRate);
        }

        graph->setData(xAxisCache[dataSize], spikeData);
    }
    QCustomPlot::RefreshPriority refreshPriority =
        (graphsToDraw > 50) ? QCustomPlot::rpQueuedReplot : QCustomPlot::rpImmediateRefresh;

    customPlot_spike->replot(refreshPriority);
}

void HomeGui::updateISIPlot()
{

    QMap<int, int> temI_SIS = extractISIData(queue_ISI,samplingRate);

    QVector<double> ticks;
    QVector<QString> labels;
    QVector<double> fossilData;
    for (auto it = temI_SIS.begin(); it != temI_SIS.end(); ++it) {
        ticks.append(it.key());
        fossilData.append(it.value());
    }
    fossil->setData(ticks, fossilData);
    customPlot_ISI->yAxis->rescale();
    customPlot_ISI->replot();

}

void HomeGui::updateDecodingPlot()
{

    QVector<double> wienerbufferX = {0};
    QVector<double> wienerbufferY = {0};
    wienervalues =  Memerydata.m_wienerbuffer;
    static double count = 0;
    for (wiener value: wienervalues) {
        wienerbufferX.append(value.wienerX);
        wienerbufferY.append(value.wienerY);
        count ++;
    }

    QVector<double> timeAxis(count);
    for (int i = 0; i < count; ++i) {
        timeAxis[i] = static_cast<double>(i)  * 8;
    }
    customPlot_Decoding->graph(0)->setData(timeAxis, wienerbufferX);
    customPlot_Decoding->graph(1)->setData(timeAxis, wienerbufferY);
    customPlot_Decoding->setNotAntialiasedElements(QCP::aeAll);
    QFont font;
    font.setStyleStrategy(QFont::NoAntialias);
    customPlot_Decoding->xAxis->setTickLabelFont(font);
    customPlot_Decoding->yAxis->setTickLabelFont(font);
    customPlot_Decoding->yAxis->rescale(true);
    customPlot_Decoding->replot();

}

void HomeGui::updatespike()
{
    APDetector::DetectionResult spikeResult =  spikeDetector->detect_ap_neo(values,samplingRate,threshold_factor);


    QString Result = QString(" threshold Value %1").arg(spikeResult.threshold);

    if(spikeResult.peaks.size()>0)
    {

        stop_clicked();
        spikeUpdateTimer->stop();
        QMessageBox::information(this, tr("Finish"), Result);
    }
    else
    {
        on_pbtn_channeladd_clicked();
    }
    if(currentChannel == 127)
    {
        stop_clicked();
        spikeUpdateTimer->stop();
        QMessageBox::information(this, tr("Finish"), QString("No spike data detected"));
    }


}

void HomeGui::updateimpedance()
{

    SharedBLEData data = Memerydata.readBLEDataFromSharedMemory();
    if (!data.isUpdated)
    {
        return;
    }

    try {
        if(m_buffer.size()<impedancepacket)
        {
            m_buffer.append(data.values);
        }
        else{
            index = index % impedancepacket;
            m_buffer.replace(index,data.values);
        }
        index = (index + 1);
    } catch (const std::exception& e) {
        qWarning() << "Write failed:" << e.what();
    }

    QVector<double> values;
    static double count = 0;
    for (QVector<double> value: m_buffer) {
        values.append(value);
        count += value.size();
    }
    static double time = 0;
    const double totalTime = count / samplingRate;

    QVector<double> timeAxis(count);
    for (int i = 0; i < count; ++i) {
        timeAxis[i] = static_cast<double>(i) / samplingRate * 1000;
    }

    impedancevalue = Memerydata.Calculateimpedance(values);
    impedancecoordText->setText("impedanceValue:"+QString::number(impedancevalue)+"Ω");
    customPlot_impedance->graph(0)->setData(timeAxis, values);
    customPlot_impedance->setNotAntialiasedElements(QCP::aeAll);
    QFont font1;
    font1.setStyleStrategy(QFont::NoAntialias);
    customPlot_impedance->xAxis->setTickLabelFont(font1);
    customPlot_impedance->yAxis->setTickLabelFont(font1);

    customPlot_impedance->replot();

    if(index == impedancepacket)
    {
        on_pBtn_stopImpedance_clicked();
    }

}

void HomeGui::upStatus()
{
    BLEStatusData data = Memerydata.readBLEStatusDataSharedMemory();
    ui->label_power->setText(QString::number(data.BatteryLevel)+"mV");
    if(data.ChargeIndicator==1)
    {
        ui->label_chargestatus->setText("charge");
    }
    else
    {
        ui->label_chargestatus->setText("uncharge");
    }
    ui->label_temp->setText(QString::number(data.temprature, 'f', 2)+"℃");
    ui->label_RH->setText(QString::number(data.humidity, 'f', 2)+"%RH");
}

void HomeGui::sendNextChunk()
{
    if (!m_fpgaFile || !m_fpgaFile->isOpen()) {
        QMessageBox::critical(this, tr("Error"), tr("File not open"));
        return;
    }

    if (m_totalSent >= m_fileSize) {
        finishUpload(true);
        return;
    }

    QByteArray chunk = m_fpgaFile->read(256);
    if (chunk.isEmpty()) {
        finishUpload(false);
        QMessageBox::critical(this, tr("Error"), tr("Failed to read file"));
        return;
    }

    bool sendSuccess = sendDataToFPGA(chunk);
    if (!sendSuccess) {
        finishUpload(false);
        QMessageBox::critical(this, tr("Error"), tr("Failed to send data"));
        return;
    }

    m_totalSent += chunk.size();
    progressBar->setValue(m_totalSent);
    m_sendFpgaFileTimer->start(0);

}

void HomeGui::sendOTANextChunk()
{

    if (!m_otaFile || !m_otaFile->isOpen()) {
        QMessageBox::critical(this, tr("Error"), tr("File not open"));
        return;
    }
    if (m_otatotalSent >= m_otafileSize) {
        finishotaUpload(true);
        return;
    }
    QByteArray chunk = m_otaFile->read(20);
    if (chunk.isEmpty()) {
        finishotaUpload(false);
        QMessageBox::critical(this, tr("Error"), tr("Failed to read file"));
        return;
    }

    bool sendSuccess = sendsoftToMCU(chunk);
    if (!sendSuccess) {
        finishotaUpload(false);
        QMessageBox::critical(this, tr("Error"), tr("Failed to send data"));
        return;
    }

    m_otatotalSent += chunk.size();
    progressBar_ota->setValue(m_otatotalSent);

    m_sendotaFileTimer->start(0);
}

void HomeGui::finishUpload(bool success)
{
    if (m_fpgaFile) {
        if (m_fpgaFile->isOpen()) {
            m_fpgaFile->close();
        }
        delete m_fpgaFile;
        m_fpgaFile = nullptr;
    }

    if (m_sendFpgaFileTimer->isActive()) {
        m_sendFpgaFileTimer->stop();
    }


    if (success) {
        progressBar->setValue(m_fileSize);
        sendStopFPGA();
        QMessageBox::information(this, tr("Success"), tr("File sending completed"));
    } else {
        QMessageBox::critical(this, tr("Error"), tr("Upload interrupted"));
    }
    progressBar->setVisible(false);

}

void HomeGui::finishotaUpload(bool success)
{

    if (m_otaFile) {
        if (m_otaFile->isOpen()) {
            m_otaFile->close();
        }
        delete m_otaFile;
        m_otaFile = nullptr;
    }

    if (m_sendotaFileTimer->isActive()) {
        m_sendotaFileTimer->stop();
    }

    if (success) {
        progressBar_ota->setValue(m_otafileSize);
        // sendStopFPGA();
        QMessageBox::information(this, tr("Success"), tr("File sending completed"));
    } else {
        QMessageBox::critical(this, tr("Error"), tr("Upload interrupted"));
    }
    progressBar_ota->setVisible(false);
}

void HomeGui::sendVienerFilter(QVector<QString> data)
{
    QString sendDatapre = "C7E500";

    for (const QString& str : data) {
        bool ok;
        quint16 value = str.toUShort(&ok);

        if (!ok) {
            qWarning() << "Invalid value :" << str;
        }

        QString VienerStr = "";
        QString hexStrhighByte = "00";
        QString hexStrlowByte = "00";

        quint8 highByte = static_cast<quint8>(value >> 8);
        quint8 lowByte = static_cast<quint8>(value & 0xFF);

        hexStrhighByte = QString("%1").arg(highByte, 2, 16, QLatin1Char('0')).toUpper();
        hexStrlowByte =  QString("%1").arg(lowByte, 2, 16, QLatin1Char('0')).toUpper();
        hexStrhighByte += hexStrlowByte;
        VienerStr += hexStrhighByte;

        sendDatapre = sendDatapre+ VienerStr;
    }

    if(services.size() == 0 || characteristics.size() == 0){

        QMessageBox mes(this);
        mes.setText("No Bluetooth device connected");
        mes.exec();
        return;

    }

    bool start = startFPGA();

    if(!start)
    {
        return;
    }

    for (size_t i = 0; i < services.size(); i++) {
        if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
        {
            service = services[i];
            characteristics = service.characteristics();
            break;
        }
    }
    for(int i =0; i < characteristics.size(); i++)
    {
        if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("1f393840-1711-5955-86e6-c1b77090e7fe").toLatin1()))
        {
            characteristic = characteristics[i];
            break;
        }

    }
    SimpleBLE::ByteArray Vienerdata = SimpleBLE::ByteArray::fromHex(sendDatapre.toStdString());
    writeCharacteristic(service,characteristic,Vienerdata);


}

void HomeGui::upThreshold( QByteArray byteArray)
{
    QStringList result = {};

    QString tmp = "";
    for (int i = 0; i < byteArray.size(); i += 2) {
        if (i + 1 < byteArray.size()) {

            quint16 value = (static_cast<quint8>(byteArray[i+1]) << 8) |
                            static_cast<quint8>(byteArray[i]);
            double combined = (static_cast<double>(value) - 32767.0) * 0.195;

            tmp = QString::number(combined);

        } else {

            quint8 value = static_cast<quint8>(byteArray[i]);

            double combined = (static_cast<double>(value) - 32767.0) * 0.195;

            tmp = QString::number(combined);
        }
        result.append(tmp);

    }

    if(result.size()!=128)
    {
        qDebug()<<"The data length read from the underlying layer is abnormal.";

    }
    int index = 0;
    for (int row = 0; row < 8; row++) {
        for (int col = 0; col < 16; col++) {

            QTableWidgetItem *item = ui->tableWidget->item(row, col);
            if (!item) {
                item = new QTableWidgetItem();
                ui->tableWidget->setItem(row, col, item);
            }

            item->setText("");
            QString  value = result[index++];
            item->setText(value);
            item->setTextAlignment(Qt::AlignCenter);
        }
    }

    ui->tableWidget->resizeColumnsToContents();
    ui->tableWidget->horizontalHeader()->setSectionResizeMode(QHeaderView::Stretch);
    byteArrayBuffer.clear();
    // ui->tableWidget->repaint();
}

void HomeGui::onwriteMemory(const QByteArray &value)
{
    Memerydata.writeBLEDataToSharedMemory(value);
}

void HomeGui::onMousePress(QMouseEvent *event)
{
    if (event->button() == Qt::LeftButton)
       {

        if (customPlot->xAxis->selectedParts().testFlag(QCPAxis::spAxis))
          customPlot->axisRect()->setRangeDrag(customPlot->xAxis->orientation());
        else if (customPlot->yAxis->selectedParts().testFlag(QCPAxis::spAxis))
          customPlot->axisRect()->setRangeDrag(customPlot->yAxis->orientation());
        else
        {
            customPlot->axisRect()->setRangeDrag(Qt::Horizontal|Qt::Vertical);

             double y = customPlot->yAxis->pixelToCoord(event->pos().y());
             double thresholdY = m_thresholdLine->point1->coords().y();



             double Ax = customPlot->xAxis->pixelToCoord(event->pos().x());
             double rawBx =-9999999;

             double rawAx  = -9999999;
             if( Rawline !=nullptr)
             {
                 rawAx = Rawline->start->coords().x();
             }
             if( RawlineB !=nullptr)
             {
                 rawBx= RawlineB->start->coords().x();
             }

             if (qAbs(y - thresholdY) < 60)
             {
                 m_draggingThreshold = true;
                 m_dragStartY = thresholdY;
                setCursor(Qt::SizeVerCursor);
                 return;
             }
             else if (qAbs(Ax - rawAx) < 50 && Rawline !=nullptr)
             {
                 m_draggingMarkA = true;
                 return;
             }
             else if (qAbs(Ax - rawBx) < 50 && RawlineB !=nullptr)
             {
                 m_draggingMarkB = true;
                 return;
             }
             else
             {
                 m_draggingThreshold = false;
                 m_draggingMarkA = false;
                 m_draggingMarkB = false;
                setCursor(Qt::ArrowCursor);
             }

        }
       }
       else if (event->button() == Qt::RightButton)
       {

       }

}

void HomeGui::onselectionChanged()
{
    /*
     normally, axis base line, axis tick labels and axis labels are selectable separately, but we want
     the user only to be able to select the axis as a whole, so we tie the selected states of the tick labels
     and the axis base line together. However, the axis label shall be selectable individually.

     The selection state of the left and right axes shall be synchronized as well as the state of the
     bottom and top axes.

     Further, we want to synchronize the selection of the graphs with the selection state of the respective
     legend item belonging to that graph. So the user can select a graph by either clicking on the graph itself
     or on its legend item.
    */

    // make top and bottom axes be selected synchronously, and handle axis and tick labels as one selectable object:
    if (customPlot->xAxis->selectedParts().testFlag(QCPAxis::spAxis) || customPlot->xAxis->selectedParts().testFlag(QCPAxis::spTickLabels) ||
        customPlot->xAxis2->selectedParts().testFlag(QCPAxis::spAxis) || customPlot->xAxis2->selectedParts().testFlag(QCPAxis::spTickLabels))
    {
      customPlot->xAxis2->setSelectedParts(QCPAxis::spAxis|QCPAxis::spTickLabels);
      customPlot->xAxis->setSelectedParts(QCPAxis::spAxis|QCPAxis::spTickLabels);
    }
    // make left and right axes be selected synchronously, and handle axis and tick labels as one selectable object:
    if (customPlot->yAxis->selectedParts().testFlag(QCPAxis::spAxis) || customPlot->yAxis->selectedParts().testFlag(QCPAxis::spTickLabels) ||
        customPlot->yAxis2->selectedParts().testFlag(QCPAxis::spAxis) || customPlot->yAxis2->selectedParts().testFlag(QCPAxis::spTickLabels))
    {
      customPlot->yAxis2->setSelectedParts(QCPAxis::spAxis|QCPAxis::spTickLabels);
      customPlot->yAxis->setSelectedParts(QCPAxis::spAxis|QCPAxis::spTickLabels);
    }

}

void HomeGui::onMouseMove(QMouseEvent *event)
{
        if (m_draggingThreshold)
        {
                double newY = customPlot->yAxis->pixelToCoord(event->pos().y());
                double yMin = customPlot->yAxis->range().lower;
                double yMax = customPlot->yAxis->range().upper;
                newY = qBound(yMin, newY, yMax);
                m_thresholdLine->point1->setCoords(customPlot->xAxis->range().lower, newY);
                m_thresholdLine->point2->setCoords(customPlot->xAxis->range().upper, newY);
                m_thresholdLabel->setText(QString::number(newY, 'f', 2));
                customPlot->replot(QCustomPlot::rpQueuedReplot);
                emit thresholdChanged(newY);
        }
        else if (m_draggingMarkA)
        {
            double newX = customPlot->xAxis->pixelToCoord(event->pos().x());

            double xMin = customPlot->xAxis->range().lower;
            double xMax = customPlot->xAxis->range().upper;
            newX = qBound(xMin, newX, xMax);

            m_MarkA = newX;

            Rawline->start->setCoords(newX, customPlot->yAxis->range().lower);
            Rawline->end->setCoords(newX, customPlot->yAxis->range().upper);

            line_raster->start->setCoords(newX, customPlot->yAxis->range().lower);
            line_raster->end->setCoords(newX, customPlot->yAxis->range().upper);
            customPlot->replot(QCustomPlot::rpQueuedReplot);
            customPlot_Raster->replot(QCustomPlot::rpQueuedReplot);
        }
        else if (m_draggingMarkB)
        {
            double newX = customPlot->xAxis->pixelToCoord(event->pos().x());

            double xMin = customPlot->xAxis->range().lower;
            double xMax = customPlot->xAxis->range().upper;
            newX = qBound(xMin, newX, xMax);
            RawlineB->start->setCoords(newX, customPlot->yAxis->range().lower);
            RawlineB->end->setCoords(newX, customPlot->yAxis->range().upper);
            m_MarkB = newX;
            line_rasterB->start->setCoords(newX, customPlot->yAxis->range().lower);
            line_rasterB->end->setCoords(newX, customPlot->yAxis->range().upper);
            customPlot->replot(QCustomPlot::rpQueuedReplot);
            customPlot_Raster->replot(QCustomPlot::rpQueuedReplot);
        }
        else
        {
        }


}

void HomeGui::onmouseWheel(QWheelEvent *event)
{


    const double zoomFactor = 1.15;
    double currentRange = customPlot->yAxis->range().upper;


    if (event->angleDelta().y() > 0) {

        currentRange /= zoomFactor;
    } else {

        currentRange *= zoomFactor;
    }
    currentRange = qBound(10.0, currentRange, 1000.0);
    customPlot->yAxis->setRange(-currentRange, currentRange);

    if(threshold<-currentRange || threshold>currentRange)
    {
        m_thresholdLine->point1->setCoords(customPlot->xAxis->range().lower, 0);
        m_thresholdLine->point2->setCoords(customPlot->xAxis->range().upper, 0);
        m_thresholdLabel->setText(QString::number(0, 'f', 2));
        customPlot->replot(QCustomPlot::rpQueuedReplot);
        emit thresholdChanged(0);

    }
    event->accept();

}

void HomeGui::onRastermouseWheel(QWheelEvent *event)
{

    QCPRange currentRange = customPlot_Raster->yAxis->range();
    double currentUpper = currentRange.upper;
    const double maxYUpper = channelMax-1;

    if (currentUpper > maxYUpper)
    {
        customPlot_Raster->yAxis->setRange(QCPRange(0, maxYUpper-0.5));
        customPlot_Raster->replot();
    }

}

void HomeGui::onRasterfilemouseWheel(QWheelEvent *event)
{

    QCPRange currentRange = customPlot_Raster_loaddata->yAxis->range();
    double currentUpper = currentRange.upper;
    const double maxYUpper = channelMax-1;
    if (currentUpper > maxYUpper)
    {   
        customPlot_Raster_loaddata->yAxis->setRange(QCPRange(0, maxYUpper-0.5));
        customPlot_Raster_loaddata->replot();
    }
}

void HomeGui::onMouseRelease(QMouseEvent *event)
{
    Q_UNUSED(event);
    m_draggingThresholdfile = false;
    m_draggingThreshold = false;
    m_draggingMarkA = false;
    m_draggingMarkB = false;
    customPlot_loaddata->setInteraction(QCP::iRangeDrag, true);
    setCursor(Qt::ArrowCursor);

}

void HomeGui::onMousePressfile(QMouseEvent *event)
{
    if (event->button() == Qt::LeftButton)
    {

        if (customPlot_loaddata->xAxis->selectedParts().testFlag(QCPAxis::spAxis))
            customPlot_loaddata->axisRect()->setRangeDrag(customPlot_loaddata->xAxis->orientation());
        else if (customPlot_loaddata->yAxis->selectedParts().testFlag(QCPAxis::spAxis))
            customPlot_loaddata->axisRect()->setRangeDrag(customPlot_loaddata->yAxis->orientation());
        else
        {
            customPlot_loaddata->axisRect()->setRangeDrag(Qt::Horizontal|Qt::Vertical);

            double currentRange = customPlot_loaddata->yAxis->range().upper;

            double y = customPlot_loaddata->yAxis->pixelToCoord(event->pos().y());
            double thresholdY = m_thresholdLinefile->point1->coords().y();
            if (qAbs(y - thresholdY) < qAbs(currentRange)/10)
            {
                m_draggingThresholdfile = true;
                m_dragStartY = thresholdY;
                setCursor(Qt::SizeVerCursor);
                customPlot_loaddata->setInteraction(QCP::iRangeDrag, false);
                return;
            }

            else
            {
                m_draggingThresholdfile = false;
                setCursor(Qt::ArrowCursor);
                customPlot_loaddata->setInteraction(QCP::iRangeDrag, true);
            }

        }
    }
    else if (event->button() == Qt::RightButton)
    {


    }

}

void HomeGui::onMouseMovefile(QMouseEvent *event)
{

    double x = customPlot_loaddata->xAxis->pixelToCoord(event->pos().x());
    double y = customPlot_loaddata->yAxis->pixelToCoord(event->pos().y());


    coordTextfile->setText(QString("X: %1 ms\nY: %2 uV").arg(x, 0, 'f', 2).arg(y, 0, 'f', 2));
    coordTextfile->setVisible(true);

    if (m_draggingThresholdfile)
    {
        double newY = customPlot_loaddata->yAxis->pixelToCoord(event->pos().y());
        double yMin = customPlot_loaddata->yAxis->range().lower;
        double yMax = customPlot_loaddata->yAxis->range().upper;
        newY = qBound(yMin, newY, yMax);
        m_thresholdLinefile->point1->setCoords(customPlot_loaddata->xAxis->range().lower, newY);
        m_thresholdLinefile->point2->setCoords(customPlot_loaddata->xAxis->range().upper, newY);
        m_thresholdLabelfile->setText(QString::number(newY, 'f', 2));
        thresholdfile = newY;
        updatespikePlot_file();
        updateISIPlot_file();

    }
    else
    {

    }
     customPlot_loaddata->replot(QCustomPlot::rpQueuedReplot);
}

void HomeGui::onthresholdChanged(double newThreshold)
{

   threshold = newThreshold;

}

void HomeGui::readCharacteristic(SimpleBLE::Service m_service, SimpleBLE::Characteristic m_Ch)
{
    try {
        std::vector<uint8_t> data = connectedPeripheral->read(m_service.uuid(),m_Ch.uuid());
        QMetaObject::invokeMethod(this, [ data]() {
            QString dataStr;
            for (uint8_t byte : data) {
                dataStr += QString("%1 ").arg(byte, 2, 16, QChar('0'));
            }

        }, Qt::QueuedConnection);
    } catch (const std::exception& e) {
        QMetaObject::invokeMethod(this, [ e]() {

        }, Qt::QueuedConnection);
    }

}

void HomeGui::writeCharacteristic( SimpleBLE::Service m_service, SimpleBLE::Characteristic m_Ch, SimpleBLE::ByteArray data)
{
    try {
        if (m_Ch.can_write_request()) {
            connectedPeripheral->write_request(m_service.uuid(),m_Ch.uuid(), data);
        } else {

            connectedPeripheral->write_command(m_service.uuid(),m_Ch.uuid(), data);
        }
        QMetaObject::invokeMethod(this, [this]() {
        }, Qt::QueuedConnection);
    } catch (const std::exception& e) {
        QMetaObject::invokeMethod(this, [this, e]() {
        }, Qt::QueuedConnection);
    }
}

void HomeGui::openNotify(SimpleBLE::Service m_service, SimpleBLE::Characteristic m_Ch)
{
    nextflag = false;
    if (m_Ch.can_notify() || m_Ch.can_indicate()) {
        try {
            SimpleBLE::BluetoothUUID chuuid = m_Ch.uuid();
            connectedPeripheral->notify(m_service.uuid(),m_Ch.uuid(), [this,m_Ch,chuuid](std::vector<uint8_t> data) {
                QString dataStr;

                for (uint8_t byte : data) {
                    dataStr += QString("%1").arg(byte, 2, 16, QChar('0'));
                }
                QMetaObject::invokeMethod(this, [this, dataStr,data,chuuid]() {

                    QByteArray byteArray(reinterpret_cast<const char*>(data.data()), static_cast<int>(data.size()));
                    if(chuuid == SimpleBLE::BluetoothUUID(QString("8a2c6538-4041-5d83-906c-0408bfc7e4f9").toLatin1()))
                    {
                        if(dataStr == "00")
                        {
                            nextflag = true;
                        }
                        else{
                            emit writeMemory(byteArray);
                            if (isSavingData && dataFile.isOpen()) {
                                dataFile.write(byteArray);
                                dataFile.flush();
                            }
                        }
                    }

                    if( chuuid == SimpleBLE::BluetoothUUID(QString("62957be9-eff6-5424-871a-df61e8ef9653").toLatin1()))
                    {
                        Memerydata.writeBLEStatusDataSharedMemory(byteArray);

                        upStatus();
                    }

                    if( chuuid == SimpleBLE::BluetoothUUID(QString("88925663-d236-4757-a167-4a7d58637b24").toLatin1()))
                    {
                        if(byteArray.size()==128)
                        {
                            thflag = true;
                            byteArrayBuffer.append(byteArray);
                            if(byteArrayBuffer.size() == 256)
                            {
                                upThreshold(byteArrayBuffer);
                            }
                        }
                    }

                }, Qt::QueuedConnection);

            });

        } catch (const std::exception& e) {
            qDebug()<<("Subscription notification failed: " + QString::fromStdString(e.what()));
        }
    }

}

void HomeGui::onScanTimeout()
{
    scanTimer->stop();
    adapter.scan_stop();
    if (ui->listWidget_bledevice->count() > 0) {
         qDebug()<<"Scan complete, found " <<QString::number(ui->listWidget_bledevice->count()) + " Device";
    } else {
        qDebug("Scan complete, no devices found.");
    }
}

void HomeGui::onConnectError()
{
    qDebug()<<"device disconnect";
    if (!connectedPeripheral.has_value() || !connectedPeripheral->is_connected()) {
        ui->label_Conectstate->setText("device disconnect");
        ui->label_Conectstate->setStyleSheet("QLabel { color : red; }");
    }
    connectTimer->stop();
}

void HomeGui::onsetSingleChannelFlag(int ch,bool flag)
{
    ch  = ch % 64;
    if(flag == true)
    {
        if (connectedPeripheral.has_value() && connectedPeripheral->is_connected()) {
            if(ch>=0&& ch<=7)
            {
                ch = ch % 8;
                quint8 mask = channelToBitmask(ch);

                QString chstr = QString::number(mask, 16).toUpper().rightJustified(2, '0');
                setFilter("0E",chstr);
                setFilter("0F","00");
                setFilter("10","00");
                setFilter("11","00");
                setFilter("12","00");
                setFilter("13","00");
                setFilter("14","00");
                setFilter("15","00");
            }

            if(ch>=8&& ch<=15)
            {
                ch = ch % 8;
                quint8 mask = channelToBitmask(ch);

                QString chstr = QString::number(mask, 16).toUpper().rightJustified(2, '0');

                qDebug() << "Channel" << ch << "-> Hex: 0x"
                         << chstr;
                setFilter("0E","00");
                setFilter("0F",chstr);
                setFilter("10","00");
                setFilter("11","00");
                setFilter("12","00");
                setFilter("13","00");
                setFilter("14","00");
                setFilter("15","00");
            }

            if(ch>=16&& ch<=23)
            {
                ch = ch % 8;
                quint8 mask = channelToBitmask(ch);

                QString chstr = QString::number(mask, 16).toUpper().rightJustified(2, '0');

                qDebug() << "Channel" << ch << "-> Hex: 0x"
                         << chstr;
                setFilter("0E","00");
                setFilter("0F","00");
                setFilter("10",chstr);
                setFilter("11","00");
                setFilter("12","00");
                setFilter("13","00");
                setFilter("14","00");
                setFilter("15","00");
            }

            if(ch>=24&& ch<=31)
            {
                ch = ch % 8;
                quint8 mask = channelToBitmask(ch);

                QString chstr = QString::number(mask, 16).toUpper().rightJustified(2, '0');

                qDebug() << "Channel" << ch << "-> Hex: 0x"
                         << chstr;
                setFilter("0E","00");
                setFilter("0F","00");
                setFilter("10","00");
                setFilter("11",chstr);
                setFilter("12","00");
                setFilter("13","00");
                setFilter("14","00");
                setFilter("15","00");
            }


            if(ch>=32&& ch<=39)
            {
                ch = ch % 8;
                quint8 mask = channelToBitmask(ch);

                QString chstr = QString::number(mask, 16).toUpper().rightJustified(2, '0');

                qDebug() << "Channel" << ch << "-> Hex: 0x"
                         << chstr;
                setFilter("0E","00");
                setFilter("0F","00");
                setFilter("10","00");
                setFilter("11","00");
                setFilter("12",chstr);
                setFilter("13","00");
                setFilter("14","00");
                setFilter("15","00");
            }

            if(ch>=40&& ch<=47)
            {
                ch = ch % 8;
                quint8 mask = channelToBitmask(ch);

                QString chstr = QString::number(mask, 16).toUpper().rightJustified(2, '0');
                setFilter("0E","00");
                setFilter("0F","00");
                setFilter("10","00");
                setFilter("11","00");
                setFilter("12","00");
                setFilter("13",chstr);
                setFilter("14","00");
                setFilter("15","00");
            }

            if(ch>=48&& ch<=55)
            {
                ch = ch % 8;
                quint8 mask = channelToBitmask(ch);

                QString chstr = QString::number(mask, 16).toUpper().rightJustified(2, '0');

                qDebug() << "Channel" << ch << "-> Hex: 0x"
                         << chstr;
                setFilter("0E","00");
                setFilter("0F","00");
                setFilter("10","00");
                setFilter("11","00");
                setFilter("12","00");
                setFilter("13","00");
                setFilter("14",chstr);
                setFilter("15","00");
            }

            if(ch>=56&& ch<=63)
            {
                ch = ch % 8;
                quint8 mask = channelToBitmask(ch);

                QString chstr = QString::number(mask, 16).toUpper().rightJustified(2, '0');
                setFilter("0E","00");
                setFilter("0F","00");
                setFilter("10","00");
                setFilter("11","00");
                setFilter("12","00");
                setFilter("13","00");
                setFilter("14","00");
                setFilter("15",chstr);
            }
        } else {
            ui->label_Conectstate->setText("No connected device...");
            ui->label_Conectstate->setStyleSheet("QLabel { color : red; }");
        }

    }
    else
    {
        if (connectedPeripheral.has_value() && connectedPeripheral->is_connected()) {

            setFilter("0E","FF");
            setFilter("0F","FF");
            setFilter("10","FF");
            setFilter("11","FF");
            setFilter("12","FF");
            setFilter("13","FF");
            setFilter("14","FF");
            setFilter("15","FF");

        } else {
            ui->label_Conectstate->setText("No connected device...");
            ui->label_Conectstate->setStyleSheet("QLabel { color : red; }");
        }

    }


}

void HomeGui::refreshServices()
{
    if (!connectedPeripheral.has_value() || !connectedPeripheral->is_connected()) {
        qDebug("Please connect to a device first.");
        return;
    }

    connectionFuture = QtConcurrent::run([this]() {
        try {
            connectedPeripheral->connect();
            services = connectedPeripheral->services();

            QMetaObject::invokeMethod(this, [this]() {

                for (size_t i = 0; i < services.size(); i++) {
                    SimpleBLE::Service service = services[i];
                    QString serviceInfo = "service UUID: " + QString::fromStdString(service.uuid());
                    characteristics = service.characteristics();

                    qDebug()<<"service Include:" + QString::number(characteristics.size()) + " characteristics";
                    qDebug()<<serviceInfo;

                    for (size_t i = 0; i < characteristics.size(); i++) {
                        SimpleBLE::Characteristic characteristic = characteristics[i];
                        QString charInfo = "characteristic UUID: " + QString::fromStdString(characteristic.uuid());

                        QString properties;
                        if (characteristic.can_read()) properties += "readable ";
                        if (characteristic.can_write_request()||characteristic.can_write_command()) properties += "writable ";
                        if (characteristic.can_notify()) properties += "Notifiable ";
                        if (characteristic.can_indicate()) properties += "Instructable ";

                        if (!properties.isEmpty()) {
                            charInfo += " [" + properties + "]";
                        }

                    }
                }
            }, Qt::QueuedConnection);
        } catch (const std::exception& e) {
            QMetaObject::invokeMethod(this, [this, e]() {
                qDebug()<<"Discovery service failed: " << QString::fromStdString(e.what());
            }, Qt::QueuedConnection);
        }
    });

}

bool HomeGui::sendDataToFPGA(QByteArray byte)
{
    if (!connectedPeripheral.has_value() || !connectedPeripheral->is_connected())
    {
        QMessageBox mes(this);
        mes.setText("No Bluetooth device connected");
        mes.exec();
        return false;

    }
    for (size_t i = 0; i < services.size(); i++) {
        if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("f046097f-a921-431c-a749-81d17f1add88").toLatin1()))
        {
            service = services[i];
            characteristics = service.characteristics();
            break;
        }
    }
    for(int i =0; i < characteristics.size(); i++)
    {
        if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("39ce7243-d128-48f6-8a0b-0d32f948e464").toLatin1()))
        {
            characteristic = characteristics[i];
            break;
        }

    }
    SimpleBLE::ByteArray data(byte.begin(), byte.end());
    writeCharacteristic(service,characteristic,data);


}

bool HomeGui::sendsoftToMCU(QByteArray byte)
{
    if (!connectedPeripheral.has_value() || !connectedPeripheral->is_connected())
    {
        QMessageBox mes(this);
        mes.setText("No Bluetooth device connected");
        mes.exec();
        return false;

    }
    for (size_t i = 0; i < services.size(); i++) {
        qDebug()<<"services[i].uuid()"<<services[i].uuid();
        if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("8d53dc1d-1db7-4cd3-868b-8a527460aa84").toLatin1()))
        {
            service = services[i];
            characteristics = service.characteristics();
            break;
        }
    }
    for(int i =0; i < characteristics.size(); i++)
    {
        if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("da2e7828-fbce-4e01-ae9e-261174997c48").toLatin1()))
        {
            characteristic = characteristics[i];
            break;
        }
    }
    SimpleBLE::ByteArray data(byte.begin(), byte.end());
    writeCharacteristic(service,characteristic,data);

}

bool HomeGui::sendUpdataFPGA()
{
    for (size_t i = 0; i < services.size(); i++) {
        if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("f046097f-a921-431c-a749-81d17f1add88").toLatin1()))
        {
            service = services[i];
            characteristics = service.characteristics();
            break;
        }
    }
    for(int i =0; i < characteristics.size(); i++)
    {
        if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("c3a02d50-a3d7-4e5d-b8b2-d7b34655023e").toLatin1()))
        {
            characteristic = characteristics[i];
            break;
        }

    }
    QString dataToWrite = "00";
    SimpleBLE::ByteArray data = SimpleBLE::ByteArray::fromHex(dataToWrite.toStdString());
    writeCharacteristic(service,characteristic,data);
    return true;

}

bool HomeGui::sendStopFPGA()
{
    for (size_t i = 0; i < services.size(); i++) {
        if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("f046097f-a921-431c-a749-81d17f1add88").toLatin1()))
        {
            service = services[i];
            characteristics = service.characteristics();
            break;
        }
    }
    for(int i =0; i < characteristics.size(); i++)
    {
        if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("c3a02d50-a3d7-4e5d-b8b2-d7b34655023e").toLatin1()))
        {
            characteristic = characteristics[i];
            break;
        }

    }
    QString dataToWrite = "01";
    SimpleBLE::ByteArray data = SimpleBLE::ByteArray::fromHex(dataToWrite.toStdString());
    writeCharacteristic(service,characteristic,data);
    return true;

}

bool HomeGui::ResetFPGA()
{
    for (size_t i = 0; i < services.size(); i++) {
        if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
        {
            service = services[i];
            characteristics = service.characteristics();
            break;
        }
    }
    for(int i =0; i < characteristics.size(); i++)
    {
        if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("1f393840-1711-5955-86e6-c1b77090e7fe").toLatin1()))
        {
            characteristic = characteristics[i];
            break;
        }
    }
    QString dataToWrite1 = "C7E50900";
    SimpleBLE::ByteArray data1 = SimpleBLE::ByteArray::fromHex(dataToWrite1.toStdString());
    writeCharacteristic(service,characteristic,data1);

    QThread::msleep(50);

    return true;


}

bool HomeGui::readFPGAData()
{

    for (size_t i = 0; i < services.size(); i++) {
        if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
        {
            service = services[i];
            characteristics = service.characteristics();
            break;
        }
    }
    for(int i =0; i < characteristics.size(); i++)
    {
        if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("1f393840-1711-5955-86e6-c1b77090e7fe").toLatin1()))
        {
            characteristic = characteristics[i];
            break;
        }
    }

    QString dataToWrite1 = "C7E5050DC7E5077CC7E50800C7E5050CC7E50710C7E50800C7E50900";
    SimpleBLE::ByteArray data1 = SimpleBLE::ByteArray::fromHex(dataToWrite1.toStdString());
    writeCharacteristic(service,characteristic,data1);

    return true;

}

bool HomeGui::RHDFPGAPowerDown()
{
    for (size_t i = 0; i < services.size(); i++) {
        if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
        {
            service = services[i];
            characteristics = service.characteristics();
            break;
        }
    }
    for(int i =0; i < characteristics.size(); i++)
    {
        if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("1f393840-1711-5955-86e6-c1b77090e7fe").toLatin1()))
        {
            characteristic = characteristics[i];
            break;
        }
    }
    QString dataToWrite1 = "C7E55202";
    SimpleBLE::ByteArray data1 = SimpleBLE::ByteArray::fromHex(dataToWrite1.toStdString());
    writeCharacteristic(service,characteristic,data1);
    QThread::msleep(50);
    return true;

}

bool HomeGui::startFPGA()
{
    if(services.size() == 0 || characteristics.size() == 0){

        QMessageBox mes(this);
        mes.setText("No Bluetooth device connected");
        mes.exec();
        return false;

    }
    for (size_t i = 0; i < services.size(); i++) {
        if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
        {
            service = services[i];
            characteristics = service.characteristics();
            break;
        }
    }
    for(int i =0; i < characteristics.size(); i++)
    {
        if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("8a2c6538-4041-5d83-906c-0408bfc7e4f9").toLatin1()))
        {
            characteristic = characteristics[i];
            break;
        }

    }
    QString dataToWrite = "02";
    SimpleBLE::ByteArray data = SimpleBLE::ByteArray::fromHex(dataToWrite.toStdString());
    openNotify(service,characteristic);
    writeCharacteristic(service,characteristic,data);
    QElapsedTimer timer;
    timer.start();
    nextflag = false;

    while(timer.elapsed() < 4000) {
        QThread::msleep(10);
        QApplication::processEvents();
        if(nextflag)
        {
            QThread::msleep(50);
            return true;
        }
    }
    return false;
}

void HomeGui::on_pbtn_start_clicked()
{
    if(services.size() == 0 || characteristics.size() == 0){
        QMessageBox mes(this);
        mes.setText("No Bluetooth device connected");
        mes.exec();
        return;
    }

    ui->pbtn_start->setEnabled(false);
    ui->pbtn_statusUpdata->setEnabled(false);

    bool start = startFPGA();

    if(start)
    {

        for (size_t i = 0; i < services.size(); i++) {
            if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
            {
                service = services[i];
                characteristics = service.characteristics();
                break;
            }
        }
        for(int i =0; i < characteristics.size(); i++)
        {
            if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("8a2c6538-4041-5d83-906c-0408bfc7e4f9").toLatin1()))
            {
                characteristic = characteristics[i];
                break;
            }

        }
        QString dataToWrite1 = "01"+QString("%1").arg(CurrentMode, 2, 16, QLatin1Char('0')).toUpper();
        SimpleBLE::ByteArray data1 = SimpleBLE::ByteArray::fromHex(dataToWrite1.toStdString());

         writeCharacteristic(service,characteristic,data1);

    }

    statusflag = false;

    plotUpdateTimer->start(50);

}

void HomeGui::on_pbtn_stop_clicked()
{
    ui->pbtn_start->setEnabled(true);
    ui->pbtn_statusUpdata->setEnabled(true);
    m_buffer.clear();
    plotUpdateTimer->stop();
    plotspikeUpdateTimer->stop();
    plotISIUpdateTimer->stop();
    plotRasterUpdateTimer->stop();

    if(services.size() == 0 || characteristics.size() == 0){

        QMessageBox mes(this);
        mes.setText("No Bluetooth device connected");
        mes.exec();
        return;

    }
    closeAutospikeDetection();
    RHDFPGAPowerDown();

    for (size_t i = 0; i < services.size(); i++) {
        if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
        {
            service = services[i];
            characteristics = service.characteristics();
            break;
        }
    }
    for(int i =0; i < characteristics.size(); i++)
    {
        if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("8a2c6538-4041-5d83-906c-0408bfc7e4f9").toLatin1()))
        {
            characteristic = characteristics[i];
            break;
        }

    }

    QString dataToWrite0 = "00";
    SimpleBLE::ByteArray data0 = SimpleBLE::ByteArray::fromHex(dataToWrite0.toStdString());
    writeCharacteristic(service,characteristic,data0);

    QString dataToWrite = "03";
    SimpleBLE::ByteArray data = SimpleBLE::ByteArray::fromHex(dataToWrite.toStdString());
    writeCharacteristic(service,characteristic,data);
    statusflag = true;
}

void HomeGui::stop_clicked()
{
    ui->pbtn_start->setEnabled(true);
    ui->pbtn_statusUpdata->setEnabled(true);
    m_buffer.clear();
    plotUpdateTimer->stop();
    plotspikeUpdateTimer->stop();
    plotISIUpdateTimer->stop();
    plotRasterUpdateTimer->stop();

    if(isSpikeDetection == true)
    {
        spikeUpdateTimer->stop();
    }

    if(services.size() == 0 || characteristics.size() == 0){

        QMessageBox mes(this);
        mes.setText("No Bluetooth device connected");
        mes.exec();
        return;

    }

    for (size_t i = 0; i < services.size(); i++) {
        if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
        {
            service = services[i];
            characteristics = service.characteristics();
            break;
        }
    }
    for(int i =0; i < characteristics.size(); i++)
    {
        if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("8a2c6538-4041-5d83-906c-0408bfc7e4f9").toLatin1()))
        {
            characteristic = characteristics[i];
            break;
        }

    }

    QString dataToWrite0 = "00";
    SimpleBLE::ByteArray data0 = SimpleBLE::ByteArray::fromHex(dataToWrite0.toStdString());

    writeCharacteristic(service,characteristic,data0);
    QString dataToWrite = "03";
    SimpleBLE::ByteArray data = SimpleBLE::ByteArray::fromHex(dataToWrite.toStdString());

    writeCharacteristic(service,characteristic,data);

    statusflag = true;

}

void HomeGui::on_pbtn_impedance_clicked()
{
    if(services.size() == 0 || characteristics.size() == 0){

        QMessageBox mes(this);
        mes.setText("No Bluetooth device connected");
        mes.exec();
        return;

    }
    closeAutospikeDetection();
    bool status = statusflag;

    if(!status){
        stop_clicked();
    }

    if(!statusflag){
        QMessageBox mes(this);
        mes.setText("Please stop the signal acquisition device first");
        mes.exec();
        return;
    }

    ui->pbtn_impedance->setEnabled(false);

    m_buffer.clear();

    impedanceFuture = QtConcurrent::run([this]() {

        bool start = startFPGA();
        if(!start)
        {
            return;
        }

        for (size_t i = 0; i < services.size(); i++) {
            if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
            {
                service = services[i];
                characteristics = service.characteristics();
                break;
            }
        }
        for(int i =0; i < characteristics.size(); i++)
        {
            if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("1f393840-1711-5955-86e6-c1b77090e7fe").toLatin1()))
            {
                characteristic = characteristics[i];
                break;
            }
        }
        QString dataToWrite = "C7E55001";
        SimpleBLE::ByteArray data = SimpleBLE::ByteArray::fromHex(dataToWrite.toStdString());
        writeCharacteristic(service,characteristic,data);

        for (size_t i = 0; i < services.size(); i++) {
            if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
            {
                service = services[i];
                characteristics = service.characteristics();
                break;
            }
        }
        for(int i =0; i < characteristics.size(); i++)
        {
            if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("8a2c6538-4041-5d83-906c-0408bfc7e4f9").toLatin1()))
            {
                characteristic = characteristics[i];
                break;
            }

        }
        QString dataToWrite4 = "01";
        SimpleBLE::ByteArray data4 = SimpleBLE::ByteArray::fromHex(dataToWrite4.toStdString());
        writeCharacteristic(service,characteristic,data4);
        QMetaObject::invokeMethod(this, [this] {
            plotimpedanceTimer->start(100);
        });
    });
}


void HomeGui::on_pbtn_statusUpdata_clicked()
{

  if(!statusflag){
      QMessageBox mes(this);
      mes.setText("Please stop the signal acquisition device first");
      mes.exec();
      return;

  }
    for (size_t i = 0; i < services.size(); i++) {
        if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("855d2600-bdef-51a9-b626-739b4e5b0cd5").toLatin1()))
        {
            service = services[i];
            characteristics = service.characteristics();
            break;
        }
    }
    for(int i =0; i < characteristics.size(); i++)
    {
        if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("62957be9-eff6-5424-871a-df61e8ef9653").toLatin1()))
        {
            characteristic = characteristics[i];
            break;
        }

    }
    openNotify(service,characteristic);
    readCharacteristic(service,characteristic);
}

void HomeGui::on_pbtn_scanStart_clicked()
{

   ui->listWidget_bledevice->clear();
    peripherals.clear();
    adapter.set_callback_on_scan_found([this](SimpleBLE::Peripheral peripheral) {
        {
            peripherals.push_back(peripheral);
            if(QString::fromStdString(peripheral.identifier())!="")
            {
                QString deviceInfo = QString::fromStdString(peripheral.identifier()) +
                                     " (" + QString::fromStdString(peripheral.address()) + ")";
                if (peripheral.rssi() != 0) {
                    deviceInfo += " [RSSI: " + QString::number(peripheral.rssi()) + "]";
                }

                QListWidgetItem* item = new QListWidgetItem(deviceInfo);
                item->setData(Qt::UserRole, QVariant::fromValue(peripherals.size() - 1));
                ui->listWidget_bledevice->addItem(item);
            }

        }
    });
    adapter.scan_start();
    scanTimer->start(20000); // 20秒
}

void HomeGui::on_pbtn_sacnStop_clicked()
{
    if (scanTimer->isActive()) {
        scanTimer->stop();
    }
    adapter.scan_stop();
}

void HomeGui::on_pbtn_connect_clicked()
{

    QList<QListWidgetItem*> selectedItems = ui->listWidget_bledevice->selectedItems();
    if (selectedItems.isEmpty()) {
        ui->label_Conectstate->setText("Please select a device first");
        return;
    }

    int deviceIndex = selectedItems.first()->data(Qt::UserRole).toInt();
    if (deviceIndex >= 0 && deviceIndex < peripherals.size()) {
        connectedPeripheral = peripherals[deviceIndex];
        ui->label_Conectstate->setText("Connecting...");
        ui->label_Conectstate->setStyleSheet("QLabel { color : orange; }");

        connectionFuture = QtConcurrent::run([this, deviceIndex]() {
                try {
                    connectedPeripheral->connect();
                    QMetaObject::invokeMethod(this, [this, deviceIndex]() {
                        QString str = "Successfully connected: "+QString::fromStdString(peripherals[deviceIndex].identifier());
                        qDebug()<<str;
                        refreshServices();
                        ui->label_Conectstate->setText(str);
                        ui->label_Conectstate->setStyleSheet("QLabel { color : blue; }");
                        ui->listWidget_bledevice->setSelectionMode(QAbstractItemView::NoSelection);
                        ui->listWidget_bledevice->setStyleSheet("QListWidget { color: gray; }");

                        connectTimer->start(100);
                    }, Qt::QueuedConnection);
                } catch (const std::exception& e) {
                    QMetaObject::invokeMethod(this, [this, e]() {
                        QString str1 = "Connection failed";
                        qDebug()<<"Connection failed: " << QString::fromStdString(e.what());

                        ui->label_Conectstate->setText(str1);
                        ui->label_Conectstate->setStyleSheet("QLabel { color : red; }");
                        // connectedPeripheral.reset();
                    }, Qt::QueuedConnection);
                }


        });
    }


}

void HomeGui::on_pbtn_disconnect_clicked()
{
    ui->listWidget_bledevice->setSelectionMode(QAbstractItemView::SingleSelection);
     ui->listWidget_bledevice->setStyleSheet("QListWidget { color: black; }");

    if (connectedPeripheral.has_value() && connectedPeripheral->is_connected()) {

        ui->label_Conectstate->setText("Disconnecting...");
        ui->label_Conectstate->setStyleSheet("QLabel { color : black; }");

        connectionFuture = QtConcurrent::run([this]() {
            try {
                connectedPeripheral->disconnect();
                QMetaObject::invokeMethod(this, [this]() {
                    ui->label_Conectstate->setText("BLE Device disConnect ");

                }, Qt::QueuedConnection);
            } catch (const std::exception& e) {
                QMetaObject::invokeMethod(this, [this, e]() {
                    qDebug()<<("Disconnect failed: " + QString::fromStdString(e.what()));
                    ui->label_Conectstate->setText("Disconnect failed ");
                }, Qt::QueuedConnection);
            }
        });
    } else {
        ui->label_Conectstate->setText("No connected device...");
        ui->label_Conectstate->setStyleSheet("QLabel { color : black; }");
    }
}

void HomeGui::onMaxGraphCountChanged(int value)
{
    maxGraphCount = value;
    queue_spike.clear();
}

void HomeGui::handleProcessingFinished()
{
    if (plotUpdateTimer_file->isActive()) {
        plotUpdateTimer_file->stop();
    }
    cleanupThread();
}

void HomeGui::closeEvent(QCloseEvent *event)
{
    QMessageBox::StandardButton resBtn =
            QMessageBox::question(this, "bleController","quit?", QMessageBox::No | QMessageBox::Yes);

    if (resBtn != QMessageBox::Yes) {
        event->ignore();
    } else {

        on_pbtn_disconnect_clicked();
        if (connectionFuture.isRunning()|| impedanceFuture.isRunning()||CalculateThresholdFuture.isRunning()) {
            connectionFuture.cancel();
            impedanceFuture.cancel();
            CalculateThresholdFuture.cancel();
        }
        event->accept();

    }

}
void HomeGui::keyPressEvent(QKeyEvent *event)
{
    if(event->key() == Qt::Key_Plus ||((event->key() == Qt::Key_Equal) && (event->modifiers() & Qt::ShiftModifier)))
    {
        if(currentTableIndex == 0)
        {
            on_pbtn_timeadd_clicked();
        }
        else if(currentTableIndex == 2)
        {
            on_tbtn_IncreaseTime_clicked();
        }

    }
    else if( event->key() == Qt::Key_Minus)
    {
        if(currentTableIndex == 0)
        {
            on_pbtn_timeReduce_clicked();
        }
        else if(currentTableIndex == 2)
        {
            on_tbtn_DecreaseTime_clicked();
        }

    }

    // Key_A
    else if( event->key() == Qt::Key_A)
    {
        double time = customPlot->xAxis->range().upper/2;
        time = time - time/2;
        m_MarkA = time;
        addMark(time, Qt::green);
        qDebug() << "Mark A at:" << time;
    }

    // Key_B
    else if( event->key() == Qt::Key_B)
    {
        double time = customPlot->xAxis->range().upper/2;
        time = time + time/2;
        m_MarkB = time;
        addMarkB(time, Qt::red);
        qDebug() << "Mark B at:" << time;
    }
    else {
    }
    event->accept();
}

void HomeGui::on_cbox_channel_activated(int index)
{

    if(services.size() == 0 || characteristics.size() == 0){
        QMessageBox mes(this);
        mes.setText("No Bluetooth device connected");
        mes.exec();
        return;
    }
    QTimer::singleShot(0, this, [this, index]() {
        if(isSpikeDetection == true)
        {

            QMessageBox *mes = new QMessageBox(this);
            mes->setAttribute(Qt::WA_DeleteOnClose);
            mes->setModal(false);
            mes->setText(QString("channel switched:%1").arg(index));
            mes->show();
        }

    });

    QFuture<void> future = QtConcurrent::run([this, index]() {
        bool status = statusflag;
        if(!statusflag){
            stop_clicked();
        }

        if(!startFPGA()) {
            return;
        }
        for (size_t i = 0; i < services.size(); i++) {
            if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1())) {
                service = services[i];
                characteristics = service.characteristics();
                break;
            }
        }

        for(int i = 0; i < characteristics.size(); i++) {
            if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("1f393840-1711-5955-86e6-c1b77090e7fe").toLatin1())) {
                characteristic = characteristics[i];
                break;
            }
        }

        QString str2 = QString("%1").arg(index, 2, 16, QLatin1Char('0'));
        QString dataToWrite = "C7E547" + str2;
        SimpleBLE::ByteArray data = SimpleBLE::ByteArray::fromHex(dataToWrite.toStdString());

        writeCharacteristic(service, characteristic, data);

        currentChannel = index;

        if(ui->cbox_singleChannel->isChecked()) {
            onsetSingleChannelFlag(currentChannel, true);
            ResetFPGA();
        }
        if(!status) {
            QMetaObject::invokeMethod(this, "on_pbtn_start_clicked", Qt::QueuedConnection);
        }
    });
}


void HomeGui::on_pbtn_readthreshold_clicked()
{

    if(services.size() == 0 || characteristics.size() == 0){

        QMessageBox mes(this);
        mes.setText("Please connect your Bluetooth device first");
        mes.exec();
        return;

    }

    closeAutospikeDetection();

    byteArrayBuffer.clear();
    bool status = statusflag;
    if(!statusflag){
        stop_clicked();
        QThread::msleep(1000);
    }
    if(!statusflag){
        QMessageBox mes(this);
        mes.setText("Please stop signal acquisition first");
        mes.exec();
        return;

    }
    if(!startFPGA()) {
        return;
    }
    for (size_t i = 0; i < services.size(); i++) {
        if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
        {
            service = services[i];
            characteristics = service.characteristics();
            break;
        }
    }
    for(int i =0; i < characteristics.size(); i++)
    {
        if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("1f393840-1711-5955-86e6-c1b77090e7fe").toLatin1()))
        {
            characteristic = characteristics[i];
            break;
        }
    }
    QString dataToWrite = "C7E54902";

    SimpleBLE::ByteArray data = SimpleBLE::ByteArray::fromHex(dataToWrite.toStdString());
    writeCharacteristic(service,characteristic,data);

    for (size_t i = 0; i < services.size(); i++) {
        if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
        {
            service = services[i];
            characteristics = service.characteristics();
            break;
        }
    }
    for(int i =0; i < characteristics.size(); i++)
    {
        if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("88925663-d236-4757-a167-4a7d58637b24").toLatin1()))
        {
            characteristic = characteristics[i];
            break;
        }

    }
    openNotify(service,characteristic);

    QThread::msleep(100);

    QString dataToWrite2 = "01";
    SimpleBLE::ByteArray data2 = SimpleBLE::ByteArray::fromHex(dataToWrite2.toStdString());
    writeCharacteristic(service,characteristic,data2);
    QElapsedTimer timer;
    timer.start();

    thflag = false;

    while(timer.elapsed() < 10000) {
        QThread::msleep(10);
        QApplication::processEvents();
        if(thflag)
        {
            break;
        }
    }

    for (size_t i = 0; i < services.size(); i++) {
        if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
        {
            service = services[i];
            characteristics = service.characteristics();
            break;
        }
    }
    for(int i =0; i < characteristics.size(); i++)
    {
        if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("1f393840-1711-5955-86e6-c1b77090e7fe").toLatin1()))
        {
            characteristic = characteristics[i];
            break;
        }

    }
    QString dataToWrite3 = "C7E54903";
    SimpleBLE::ByteArray data3 = SimpleBLE::ByteArray::fromHex(dataToWrite3.toStdString());
    writeCharacteristic(service,characteristic,data3);

    for (size_t i = 0; i < services.size(); i++) {
        if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
        {
            service = services[i];
            characteristics = service.characteristics();
            break;
        }
    }
    for(int i =0; i < characteristics.size(); i++)
    {
        if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("88925663-d236-4757-a167-4a7d58637b24").toLatin1()))
        {
            characteristic = characteristics[i];
            break;
        }

    }
    openNotify(service,characteristic);

    QThread::msleep(100);
    QString dataToWrite5 = "01";

    SimpleBLE::ByteArray data5 = SimpleBLE::ByteArray::fromHex(dataToWrite5.toStdString());

    writeCharacteristic(service,characteristic,data5);

    QMessageBox mes(this);
    mes.setText(QString("read data completed"));
    mes.exec();
}


void HomeGui::on_pbtn_ConfThreshold_clicked()
{
    if(services.size() == 0 || characteristics.size() == 0){

        QMessageBox mes(this);
        mes.setText("Please connect your Bluetooth device first");
        mes.exec();
        return;

    }

    closeAutospikeDetection();

    bool status = statusflag;
    if(!statusflag){
        stop_clicked();
    }
    if (ui->tableWidget->rowCount() != 8 || ui->tableWidget->columnCount() != 16) {
        qWarning() << "Invalid table size. Expected 4x16, got"
                   << ui->tableWidget->rowCount() << "x" << ui->tableWidget->columnCount();

        return;
    }

    WaitingDialog *dialog = new WaitingDialog(this);
    dialog->show();

    QFutureWatcher<void> *watcher = new QFutureWatcher<void>;
    connect(watcher, &QFutureWatcher<void>::finished, [=]() {
        dialog->close();
        dialog->deleteLater();
        watcher->deleteLater();
    });

    CalculateThresholdFuture = QtConcurrent::run([this]() {
        if(!startFPGA())
        {
            return;
        }
        QString sendDatapre64 = "C7E54800";
        QString sendDatabehind64 = "C7E55100";

        for (int row = 0; row < 4; row++) {
            for (int col = 0; col < 16; col++) {
                QTableWidgetItem *item = ui->tableWidget->item(row, col);
                if (!item) {
                    item = new QTableWidgetItem();
                    item->setText("200");
                    ui->tableWidget->setItem(row, col, item);
                }

                bool ok;
                quint16 value = item->text().toDouble(&ok)/0.195+32767;
                if (!ok) {
                    qWarning() << "Invalid value at row" << row << "col" << col
                               << ":" << item->text();
                }

                QString ChannelThreshold = "C7E5";
                QString hexStrhighByte = "00";
                QString hexStrlowByte = "00";

                quint8 highByte = static_cast<quint8>(value & 0xFF);
                quint8 lowByte = static_cast<quint8>(value >> 8);

                hexStrhighByte = QString("%1").arg(highByte, 2, 16, QLatin1Char('0')).toUpper();
                hexStrlowByte = QString("%1").arg(lowByte, 2, 16, QLatin1Char('0')).toUpper();
                hexStrhighByte += hexStrlowByte;
                ChannelThreshold += hexStrhighByte;

                sendDatapre64 = sendDatapre64+ ChannelThreshold;
            }
        }


        for (int row = 4; row < 8; row++) {
            for (int col = 0; col < 16; col++) {
                QTableWidgetItem *item = ui->tableWidget->item(row, col);
                if (!item) {
                    item = new QTableWidgetItem();
                    item->setText("200");
                    ui->tableWidget->setItem(row, col, item);
                }

                bool ok;

                quint16 value = static_cast<quint16>(item->text().toDouble(&ok)/0.195+32767);


                if (!ok) {
                    qWarning() << "Invalid value at row" << row << "col" << col
                               << ":" << item->text();
                }

                QString ChannelThreshold = "C7E5";
                QString hexStrhighByte = "00";
                QString hexStrlowByte = "00";

                quint8 highByte = static_cast<quint8>(value & 0xFF);
                quint8 lowByte = static_cast<quint8>(value >> 8);

                hexStrhighByte = QString("%1").arg(highByte, 2, 16, QLatin1Char('0')).toUpper();
                hexStrlowByte = QString("%1").arg(lowByte, 2, 16, QLatin1Char('0')).toUpper();
                hexStrhighByte += hexStrlowByte;
                ChannelThreshold += hexStrhighByte;
                sendDatabehind64 = sendDatabehind64+ ChannelThreshold;

            }
        }

        for (size_t i = 0; i < services.size(); i++) {
            if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
            {
                service = services[i];
                characteristics = service.characteristics();
                break;
            }
        }
        for(int i =0; i < characteristics.size(); i++)
        {
            if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("1f393840-1711-5955-86e6-c1b77090e7fe").toLatin1()))
            {
                characteristic = characteristics[i];
                break;
            }

        }

        SimpleBLE::ByteArray datapre = SimpleBLE::ByteArray::fromHex(sendDatapre64.toStdString());
        writeCharacteristic(service,characteristic,datapre);
        QThread::msleep(6000);

        SimpleBLE::ByteArray databind = SimpleBLE::ByteArray::fromHex(sendDatabehind64.toStdString());
        writeCharacteristic(service,characteristic,databind);

        QThread::msleep(2000);

    });

    watcher->setFuture(CalculateThresholdFuture);
}


void HomeGui::on_pBtn_CalculateThreshold_clicked()
{
    if(services.size() == 0 || characteristics.size() == 0){

        QMessageBox mes(this);
        mes.setText("Please connect your Bluetooth device first");
        mes.exec();
        return;
    }
    closeAutospikeDetection();
    byteArrayBuffer.clear();
    stop_clicked();
    if(!statusflag){
        QMessageBox mes(this);
        mes.setText("Please stop signal acquisition first");
        mes.exec();
        return;

    }

    WaitingDialog *dialog = new WaitingDialog(this);
    dialog->show();

    QFutureWatcher<void> *watcher = new QFutureWatcher<void>;
    connect(watcher, &QFutureWatcher<void>::finished, [=]() {
        dialog->close();
        dialog->deleteLater();
        watcher->deleteLater();
    });

    CalculateThresholdFuture = QtConcurrent::run([this]() {
        if(!startFPGA())
        {
            return;
        }

        for (size_t i = 0; i < services.size(); i++) {
            if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
            {
                service = services[i];
                characteristics = service.characteristics();
                break;
            }
        }
        for(int i =0; i < characteristics.size(); i++)
        {
            if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("1f393840-1711-5955-86e6-c1b77090e7fe").toLatin1()))
            {
                characteristic = characteristics[i];
                break;
            }
        }
        QString dataToWrite = "C7E54900";
        SimpleBLE::ByteArray data = SimpleBLE::ByteArray::fromHex(dataToWrite.toStdString());
        writeCharacteristic(service,characteristic,data);
        QThread::msleep(200);
        for (size_t i = 0; i < services.size(); i++) {
            if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
            {
                service = services[i];
                characteristics = service.characteristics();
                break;
            }
        }
        for(int i =0; i < characteristics.size(); i++)
        {
            if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("88925663-d236-4757-a167-4a7d58637b24").toLatin1()))
            {
                characteristic = characteristics[i];
                break;
            }

        }
        openNotify(service,characteristic);
        QString dataToWrite1 = "01";

        SimpleBLE::ByteArray data1 = SimpleBLE::ByteArray::fromHex(dataToWrite1.toStdString());
        writeCharacteristic(service,characteristic,data1);
        QElapsedTimer timer;
        timer.start();

        thflag = false;

        while(timer.elapsed() < 8000) {
            QThread::msleep(100);
            QApplication::processEvents();
            if(thflag)
            {
                break;
            }
        }
        for (size_t i = 0; i < services.size(); i++) {
            if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
            {
                service = services[i];
                characteristics = service.characteristics();
                break;
            }
        }
        for(int i =0; i < characteristics.size(); i++)
        {
            if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("1f393840-1711-5955-86e6-c1b77090e7fe").toLatin1()))
            {
                characteristic = characteristics[i];
                break;
            }

        }
        QString dataToWrite3 = "C7E54901";

        SimpleBLE::ByteArray data3 = SimpleBLE::ByteArray::fromHex(dataToWrite3.toStdString());
        writeCharacteristic(service,characteristic,data3);
        QThread::msleep(200);

        for (size_t i = 0; i < services.size(); i++) {
            if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
            {
                service = services[i];
                characteristics = service.characteristics();
                break;
            }
        }
        for(int i =0; i < characteristics.size(); i++)
        {
            if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("88925663-d236-4757-a167-4a7d58637b24").toLatin1()))
            {
                characteristic = characteristics[i];
                break;
            }

        }
        openNotify(service,characteristic);
        QString dataToWrite5 = "01";

        SimpleBLE::ByteArray data5 = SimpleBLE::ByteArray::fromHex(dataToWrite5.toStdString());

        writeCharacteristic(service,characteristic,data5);
    });


    watcher->setFuture(CalculateThresholdFuture);

}
void HomeGui::on_pBtn_stopImpedance_clicked()
{

    if(services.size() == 0 || characteristics.size() == 0){

        QMessageBox mes(this);
        mes.setText("No Bluetooth device connected");
        mes.exec();
        return;

    }
    closeAutospikeDetection();
    ui->pbtn_impedance->setEnabled(true);
    plotimpedanceTimer->stop();


    impedanceFuture = QtConcurrent::run([this]() {
        for (size_t i = 0; i < services.size(); i++) {
            if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
            {
                service = services[i];
                characteristics = service.characteristics();
                break;
            }
        }
        for(int i =0; i < characteristics.size(); i++)
        {
            if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("1f393840-1711-5955-86e6-c1b77090e7fe").toLatin1()))
            {
                characteristic = characteristics[i];
                break;
            }
        }
        QString dataToWrite = "C7E55000";
        SimpleBLE::ByteArray data = SimpleBLE::ByteArray::fromHex(dataToWrite.toStdString());
        writeCharacteristic(service,characteristic,data);
        for (size_t i = 0; i < services.size(); i++) {
            if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
            {
                service = services[i];
                characteristics = service.characteristics();
                break;
            }
        }
        for(int i =0; i < characteristics.size(); i++)
        {
            if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("8a2c6538-4041-5d83-906c-0408bfc7e4f9").toLatin1()))
            {
                characteristic = characteristics[i];
                break;
            }

        }
        QString dataToWrite4 = "00";
        SimpleBLE::ByteArray data4 = SimpleBLE::ByteArray::fromHex(dataToWrite4.toStdString());
        writeCharacteristic(service,characteristic,data4);
        ResetFPGA();
        stop_clicked();

    });

}


void HomeGui::on_pbtn_shutdown_clicked()
{
    ui->listWidget_bledevice->setSelectionMode(QAbstractItemView::SingleSelection);
    ui->listWidget_bledevice->setStyleSheet("QListWidget { color: black; }");
    QMessageBox::StandardButton resBtn =
        QMessageBox::question(this, "","Shut Down BLE Device Now?", QMessageBox::No | QMessageBox::Yes);

    if (resBtn != QMessageBox::Yes) {

    } else {

        if (connectedPeripheral.has_value() && connectedPeripheral->is_connected())
        {
            for (size_t i = 0; i < services.size(); i++) {
                if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("855d2600-bdef-51a9-b626-739b4e5b0cd5").toLatin1()))
                {
                    service = services[i];
                    characteristics = service.characteristics();
                    break;
                }
            }
            for(int i =0; i < characteristics.size(); i++)
            {
                if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("1fae4fa8-bb46-54f8-97d9-675d632ae901").toLatin1()))
                {
                    characteristic = characteristics[i];
                    break;
                }

            }
            QString dataToWrite = "01";
            SimpleBLE::ByteArray data = SimpleBLE::ByteArray::fromHex(dataToWrite.toStdString());
            writeCharacteristic(service,characteristic,data);
            ui->label_Conectstate->setText(QString("The Device has been shut down"));

        }
        else
        {
            QMessageBox mes(this);
            mes.setText(QString("device disconnected"));
            mes.exec();
        }
    }


}


void HomeGui::on_pbtn_FPGA_clicked()
{
    QString filePath = QFileDialog::getOpenFileName(
        this,
        tr("Select BIN file"),
        QString(),
        tr("BIN (*.bin);;(*.*)")
        );

    if (filePath.isEmpty()) {
        return;
    }
    ui->lineEdit_fpga->setText(filePath);
    m_fpgaFile = new QFile(filePath);
    if (!m_fpgaFile->open(QIODevice::ReadOnly)) {
        QMessageBox::critical(
            this,
            tr("Error"),
            tr("Unable to open file：%1\nerror message：%2")
                .arg(filePath)
                .arg(m_fpgaFile->errorString())
            );
        delete m_fpgaFile;
        m_fpgaFile = nullptr;
        return;
    }

    m_fileSize = m_fpgaFile->size();
    if (m_fileSize <= 0) {
        QMessageBox::warning(this, tr("warn"), tr("The selected file is empty."));
        m_fpgaFile->close();
        delete m_fpgaFile;
        m_fpgaFile = nullptr;
        return;
    }

    closeAutospikeDetection();


    m_totalSent = 0;
    progressBar->setRange(0, m_fileSize);
    progressBar->setValue(0);
    progressBar->setVisible(true);

    sendUpdataFPGA();
    m_sendFpgaFileTimer->start(3000);
}


void HomeGui::on_comboBox_mode_activated(int index)
{
    CurrentMode = index +1;
}


void HomeGui::on_pbtn_timeadd_clicked()
{

    double up = customPlot->xAxis->range().upper;

    up = up+200;

    if(up>10000)
    {

        up = 10000;
    }
    customPlot->xAxis->setRange(0, up);
    customPlot_Raster->xAxis->setRange(0, up);
    customPlot->replot();
    customPlot_Raster->replot();

    Memerydata.packet = int(up/8);
    Memerydata.m_buffer.clear();
    Memerydata.m_Rawbuffer.clear();
    Memerydata.m_spikebuffer.clear();
}


void HomeGui::on_pbtn_timeReduce_clicked()
{
        double up = customPlot->xAxis->range().upper;
        up = up-200;

        if(up<100)
        {
            up = 200;
            customPlot->xAxis->setRange(0, 100);
            customPlot_Raster->xAxis->setRange(0, 100);
        }
        else
        {
            customPlot->xAxis->setRange(0, up);
            customPlot_Raster->xAxis->setRange(0, up);
        }

        customPlot->replot();
        customPlot_Raster->replot();
        Memerydata.packet = int(up/8);
        Memerydata.m_buffer.clear();
        Memerydata.m_Rawbuffer.clear();
        Memerydata.m_spikebuffer.clear();


}


void HomeGui::on_ledit_imtime_textChanged(const QString &arg1)
{
    int up = arg1.toDouble()*1000;

    if(up<200)
    {

        up = 200;
        customPlot_impedance->xAxis->setRange(0, 200);

    }
    if(up>10000)
    {
        up = 10000;
        customPlot_impedance->xAxis->setRange(0, 10000);

    }
    else
    {
        customPlot_impedance->xAxis->setRange(0, up);
    }
    customPlot_impedance->replot();
    m_buffer.clear();
    impedancepacket = int(up/8);

}


void HomeGui::on_pbtn_viener_clicked()
{

    QString filePath = QFileDialog::getOpenFileName(
        this,
        tr("Select Viener Filter"),
        QString(),
        tr("txt (*.txt);; (*.*)")
        );

    if (filePath.isEmpty()) {
        return;
    }

    ui->lineEdit_Viener->setText(filePath);

    int FilterParacount = 256;


    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qDebug() << "Unable to open file:" << file.errorString();
        return;
    }
    QTextStream in(&file);
    QVector<QString> data;
    int count = 0;

    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        line.remove(QRegularExpression("\\s"));
        if (line.isEmpty()) continue;
        data.append(line);
        count++;
        if (count >= FilterParacount) break;
    }

    file.close();
    if (data.size() < FilterParacount) {
        qDebug() << "Error: The file only contains" << data.size() << "data";
        return;
    }
    sendVienerFilter(data);

    QMessageBox mes(this);
    mes.setText(QString("Viener Filter Config successful"));
    mes.exec();
}


void HomeGui::on_radioButton_clicked(bool checked)
{
    if(services.size() == 0 || characteristics.size() == 0){

        QMessageBox mes(this);
        mes.setText("No Bluetooth device connected");
        mes.exec();
        return;
    }

    if(!startFPGA())
    {
        return;
    }

    for (size_t i = 0; i < services.size(); i++) {
        if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
        {
            service = services[i];
            characteristics = service.characteristics();
            break;
        }
    }
    for(int i =0; i < characteristics.size(); i++)
    {
        if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("1f393840-1711-5955-86e6-c1b77090e7fe").toLatin1()))
        {
            characteristic = characteristics[i];
            break;
        }
    }
    QString data ;
    if(checked)
    {
        data =  "C7E55301";
    }
    else
    {
        data =  "C7E55300";
    }
    qDebug()<<"VienerFlagdata:"<<data;
    SimpleBLE::ByteArray VienerFlagdata = SimpleBLE::ByteArray::fromHex(data.toStdString());
    writeCharacteristic(service,characteristic,VienerFlagdata);

}

void HomeGui::on_rbtn_savefile_clicked(bool checked)
{
    closeAutospikeDetection();
    if(checked)
    {

        QString fileName = QString("BLE_Data_%1_mode_%2_ch%3.bin")
                               .arg(QDateTime::currentDateTime().toString("yyyyMMdd_HHmmss"))
                               .arg(CurrentMode)
                               .arg(currentChannel);
        dataFile.setFileName(fileName);

        if (dataFile.open(QIODevice::WriteOnly)) {
            isSavingData = checked;
            qDebug() << "Start saving data to:" << fileName;
        } else {
            qDebug() << "Unable to open file:" << fileName;
        }
    }
    else
    {
        isSavingData = checked;
        if (dataFile.isOpen()) {
            QDataStream out(&dataFile);
            out.setVersion(QDataStream::Qt_5_15);
            out << 3;
            out << m_MarkA;
            out << m_MarkB;
            out << Memerydata.packetloss;
            dataFile.flush();
            dataFile.close();

        }

    }
}

void HomeGui::addMark(double time, QColor color) {

    Rawline = new QCPItemLine(customPlot);
    Rawline->start->setType(QCPItemPosition::ptPlotCoords);
    Rawline->end->setType(QCPItemPosition::ptPlotCoords);
    Rawline->start->setCoords(time, customPlot->yAxis->range().lower);
    Rawline->end->setCoords(time, customPlot->yAxis->range().upper);
    Rawline->setPen(QPen(color, 1, Qt::DashLine));
    Rawlabel= new QCPItemText(customPlot);
    Rawlabel->position->setParentAnchor(Rawline->end);
    Rawlabel->setText("A");
    Rawlabel->setColor(color);
    Rawlabel->setFont(QFont("Arial", 10, QFont::Bold));
    Rawlabel->position->setCoords(-8, 8);

    line_raster = new QCPItemLine(customPlot_Raster);
    line_raster->start->setType(QCPItemPosition::ptPlotCoords);
    line_raster->end->setType(QCPItemPosition::ptPlotCoords);
    line_raster->start->setCoords(time, customPlot_Raster->yAxis->range().lower);
    line_raster->end->setCoords(time, customPlot_Raster->yAxis->range().upper);
    line_raster->setPen(QPen(color, 1, Qt::DashLine));

    customPlot->replot(QCustomPlot::rpQueuedReplot);
    customPlot_Raster->replot(QCustomPlot::rpQueuedReplot);
}

void HomeGui::addMarkB(double time, QColor color) {

    RawlineB = new QCPItemLine(customPlot);
    RawlineB->start->setType(QCPItemPosition::ptPlotCoords);
    RawlineB->end->setType(QCPItemPosition::ptPlotCoords);
    RawlineB->start->setCoords(time, customPlot->yAxis->range().lower);
    RawlineB->end->setCoords(time, customPlot->yAxis->range().upper);
    RawlineB->setPen(QPen(color, 1, Qt::DashLine));

    RawlabelB= new QCPItemText(customPlot);
    RawlabelB->position->setParentAnchor(RawlineB->end);
    RawlabelB->setText("B");
    RawlabelB->setColor(color);
    RawlabelB->setFont(QFont("Arial", 10, QFont::Bold));
    RawlabelB->position->setCoords(-8, 8);
    line_rasterB = new QCPItemLine(customPlot_Raster);
    line_rasterB->start->setType(QCPItemPosition::ptPlotCoords);
    line_rasterB->end->setType(QCPItemPosition::ptPlotCoords);
    line_rasterB->start->setCoords(time, customPlot_Raster->yAxis->range().lower);
    line_rasterB->end->setCoords(time, customPlot_Raster->yAxis->range().upper);
    line_rasterB->setPen(QPen(color, 1, Qt::DashLine));

    customPlot->replot(QCustomPlot::rpQueuedReplot);
    customPlot_Raster->replot(QCustomPlot::rpQueuedReplot);
}

void HomeGui::setFilter(QString ch, QString reg)
{
    for (size_t i = 0; i < services.size(); i++) {
        if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
        {
            service = services[i];
            characteristics = service.characteristics();
            break;
        }
    }
    for(int i =0; i < characteristics.size(); i++)
    {
        if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("1f393840-1711-5955-86e6-c1b77090e7fe").toLatin1()))
        {
            characteristic = characteristics[i];
            break;
        }
    }
    QString dataToWrite1 = "C7E505"+ch;
    QString dataToWrite2 = "C7E507"+reg;
    QString dataToWrite3 = dataToWrite1+dataToWrite2+"C7E50800";

    SimpleBLE::ByteArray data3 = SimpleBLE::ByteArray::fromHex(dataToWrite3.toStdString());
    writeCharacteristic(service,characteristic,data3);
    QThread::msleep(5);



}
QString decimalToHexSafe(const QString &decimalStr) {

    bool ok;
    int decimalValue = decimalStr.toInt(&ok);

    QString hexString = "00";

    if (!ok || decimalValue < 0 || decimalValue > 255) {
        return hexString;
    }
    hexString= QString("%1").arg(decimalValue, 2, 16, QChar('0')).toUpper();
    return hexString;
}


void HomeGui::on_tBtn_FilterConfig_clicked()
{
    QMap<QString, QString> LHPMap {
        {"20 KHz", "08000400"},
        {"15 KHz", "11000800"},
        {"10 KHz", "17000800"},
        {"7.5 KHz", "22002300"},
        {"5 KHz", "33003700"},
        {"3 KHz", "03011301"},
        {"2.5 KHz", "13012501"},
        {"2 KHz", "27014401"},
        {"1.5 KHz", "01022302"},
        {"1 KHz", "46023003"},
        {"750 Hz", "41033604"},
        {"500 Hz", "30054306"},
        {"300 Hz", "06090211"},
        {"250 Hz", "42100513"},
        {"200 Hz", "24130716"},
        {"150 Hz", "44170821"},
        {"100 Hz", "38260531"}
    };

    QMap<QString, QString> FHPMap
    {
        {"500 Hz", "130000"},
        {"300 Hz", "150000"},
        {"250 Hz", "170000"},
        {"200 Hz", "180000"},
        {"150 Hz", "210000"},
        {"100 Hz", "250000"},
        {"75 Hz", "280000"},
        {"50 Hz", "340000"},
        {"30 Hz", "440000"},
        {"25 Hz", "480000"},
        {"20 Hz", "540000"},
        {"15 Hz", "620000"},
        {"10 Hz", "050100"},
        {"7.5 Hz", "180100"},
        {"5.0 Hz", "400100"},
        {"3.0 Hz", "200200"},
        {"2.5 Hz", "420200"},
        {"2.0 Hz", "080300"},
        {"1.5 Hz", "090400"},
        {"1.0 Hz", "440600"},
        {"0.75 Hz", "490900"},
        {"0.50 Hz", "351700"},
        {"0.30 Hz", "014000"},
        {"0.25 Hz", "565400"},
        {"0.10 Hz", "166001"}
    };

    QString LPF = LHPMap[ui->comboBox_LPF_2->currentText()];
    QString HPF = FHPMap[ui->comboBox_HPF->currentText()];
    bool status = statusflag;
    closeAutospikeDetection();

    if(!statusflag){
        stop_clicked();
    }

    if(!startFPGA())
    {
        return;
    }

    for (int i = 0; i < LPF.length(); i += 2) {
        QString substring = decimalToHexSafe(LPF.mid(i, 2));
        if(i == 0)
        {
            qDebug()<<"08"<<substring;
            setFilter("08",substring);
        }
        if(i == 2)
        {
            qDebug()<<"09"<<substring;
            setFilter("09",substring);
        }
        if(i == 4)
        {
            qDebug()<<"0a"<<substring;
            setFilter("0A",substring);
        }
        if(i == 6)
        {
            qDebug()<<"0b"<<substring;
            setFilter("0B",substring);
        }
    }
    QThread::msleep(50);
    for (int i = 0; i < HPF.length(); i += 2) {
        if(i == 0)
        {
            QString substring = decimalToHexSafe(HPF.mid(i, 2));
            qDebug()<<"0c"<<substring;
            setFilter("0C",substring);
        }
        if(i == 2)
        {
            QByteArray substring1 = HPF.mid(i, 2).toLatin1();  // "60"
            QByteArray substring2 = HPF.mid(i+2, 2).toLatin1();  // "01"

            bool ok1, ok2;
            int value1 = QString(substring1).toInt(&ok1);  // 60
            int value2 = QString(substring2).toInt(&ok2);  // 1

            int result = (value2 << 6) | value1;
            QString substring = QString("%1").arg(result, 2, 16, QChar('0')).toUpper();
            qDebug()<<"0d"<<substring;
            setFilter("0D",substring);
        }
    }
    QThread::msleep(50);
    ResetFPGA();

    QMessageBox mes(this);
    mes.setText(QString("Filter Config successful"));
    mes.exec();

    if(!status)
    {
        on_pbtn_start_clicked();
    }
}

quint8 HomeGui::channelToBitmask(int channel) {

    if (channel < 0 || channel > 7) {
        qWarning() << "Invalid channel number:" << channel << "(must be 0-7)";
        return 0x00;
    }
    return static_cast<quint8>(1 << (channel));
}


quint8 HomeGui::channelToBitmask2(int channel) {
    if (channel < 0 || channel > 7) {
        qWarning() << "Invalid channel number:" << channel << "(must be 0-7)";
        return 0x00;
    }
    return static_cast<quint8>( (0x80)>>(channel));
}


void HomeGui::on_cbox_singleChannel_checkStateChanged(const Qt::CheckState &arg1)
{
    bool status = statusflag;
    closeAutospikeDetection();
    if(!statusflag){
        stop_clicked();
    }
    if(arg1 != Qt::Unchecked)
    {
        startFPGA();
        onsetSingleChannelFlag(currentChannel,true);
        ResetFPGA();
    }
    else
    {
        startFPGA();
        onsetSingleChannelFlag(currentChannel,false);
        ResetFPGA();
    }
    if(!status)
    {
        on_pbtn_start_clicked();
    }

}
void HomeGui::on_pBtn_SavethresholdData_clicked()
{
    WaitingDialog *dialog = new WaitingDialog(this);
    dialog->show();

    QString fileName = QString("Threshold_Data_%1_ch%2.csv")
                           .arg(QDateTime::currentDateTime().toString("yyyyMMdd_HHmmss"))
                           .arg(currentChannel);
    QFile file(fileName);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream stream(&file);
        int rowCount = ui->tableWidget->rowCount();
        int colCount = ui->tableWidget->columnCount();

        for (int row = 0; row < rowCount; ++row) {
            QStringList rowData;
            for (int col = 0; col < colCount; ++col) {
                QTableWidgetItem *item = ui->tableWidget->item(row, col);
                if (!item) {
                    qDebug()<<"item:null";

                    return;
                }
                QString text = item->text();
                rowData << text;
            }
            stream << rowData.join(",") << "\n";
        }
        file.close();
    }
    dialog->close();
    dialog->deleteLater();

    QMessageBox mes(this);
    mes.setText(QString("thresholdData save successful"));
    mes.exec();
}


void HomeGui::on_pbtn_soft_clicked()
{
    QString filePath = QFileDialog::getOpenFileName(
        this,
        tr("Select BIN file"),
        QString(),
        tr("BIN (*.bin);;(*.*)")
        );

    if (filePath.isEmpty()) {
        return;
    }

    ui->lineEdit_soft->setText(filePath);
    m_otaFile = new QFile(filePath);
    if (!m_otaFile->open(QIODevice::ReadOnly)) {
        QMessageBox::critical(
            this,
            tr("Error"),
            tr("Unable to open file：%1\nerror message：%2")
                .arg(filePath)
                .arg(m_otaFile->errorString())
            );
        delete m_otaFile;
        m_otaFile = nullptr;
        return;
    }

    m_otafileSize = m_otaFile->size();
    if (m_otafileSize <= 0) {
        QMessageBox::warning(this, tr("warn"), tr("The selected file is empty"));
        m_otaFile->close();
        delete m_otaFile;
        m_otaFile = nullptr;
        return;
    }
    m_otatotalSent = 0;
    progressBar_ota->setRange(0, m_otafileSize);
    progressBar_ota->setValue(0);
    progressBar_ota->setVisible(true);
    m_sendotaFileTimer->start(1000);
}


void HomeGui::on_tbtn_IncreaseTime_clicked()
{
    double currentTime = customPlot_Decoding->xAxis->range().upper;
    currentTime = currentTime+200;
    if(currentTime>20000)
    {

        currentTime = 20000;
    }
    customPlot_Decoding->xAxis->setRange(0, currentTime);
    ui->lineEdit_DecodingTime->setText(QString::number(currentTime));
    customPlot_Decoding->replot();
    Memerydata.wienerpacket = int(currentTime/8);
    Memerydata.m_wienerbuffer.clear();

}


void HomeGui::on_tbtn_DecreaseTime_clicked()
{
    double currentTime = customPlot_Decoding->xAxis->range().upper;
    currentTime = currentTime-200;
    if(currentTime<1000)
    {
        currentTime = 1000;
    }

    customPlot_Decoding->xAxis->setRange(0, currentTime);
    ui->lineEdit_DecodingTime->setText(QString::number(currentTime));
    customPlot_Decoding->replot();
    Memerydata.wienerpacket = int(currentTime/8);
    Memerydata.m_wienerbuffer.clear();

}


void HomeGui::on_tabWidget_currentChanged(int index)
{
    currentTableIndex = index;
    if(index <3 && index >4)
    {
        handleProcessingFinished();
    }
}


void HomeGui::on_pBtn_Decodingstart_clicked()
{
    if(services.size() == 0 || characteristics.size() == 0){

        QMessageBox mes(this);
        mes.setText("No Bluetooth device connected");
        mes.exec();
        return;
    }
    bool start = startFPGA();

    if(start)
    {

        for (size_t i = 0; i < services.size(); i++) {
            if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
            {
                service = services[i];
                characteristics = service.characteristics();
                break;
            }
        }
        for(int i =0; i < characteristics.size(); i++)
        {
            if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("8a2c6538-4041-5d83-906c-0408bfc7e4f9").toLatin1()))
            {
                characteristic = characteristics[i];
                break;
            }

        }
        QString dataToWrite1 = "01"+QString("%1").arg(CurrentMode, 2, 16, QLatin1Char('0')).toUpper();// 将字符串转换为字节数组
        SimpleBLE::ByteArray data1 = SimpleBLE::ByteArray::fromHex(dataToWrite1.toStdString());

        writeCharacteristic(service,characteristic,data1);
    }
    plotDecodingUpdateTimer->start(100);
}



void HomeGui::on_pbtn_Decodingstop_clicked()
{
    plotDecodingUpdateTimer->stop();

    if(services.size() == 0 || characteristics.size() == 0){

        QMessageBox mes(this);
        mes.setText("No Bluetooth device connected");
        mes.exec();
        return;

    }
    for (size_t i = 0; i < services.size(); i++) {
        if(services[i].uuid() == SimpleBLE::BluetoothUUID(QString("230b741d-26cf-4daa-ac6c-802f5de699be").toLatin1()))
        {
            service = services[i];
            characteristics = service.characteristics();
            break;
        }
    }
    for(int i =0; i < characteristics.size(); i++)
    {
        if(characteristics[i].uuid() == SimpleBLE::BluetoothUUID(QString("8a2c6538-4041-5d83-906c-0408bfc7e4f9").toLatin1()))
        {
            characteristic = characteristics[i];
            break;
        }

    }

    QString dataToWrite0 = "00";
    SimpleBLE::ByteArray data0 = SimpleBLE::ByteArray::fromHex(dataToWrite0.toStdString());
    writeCharacteristic(service,characteristic,data0);
    QString dataToWrite = "03";
    SimpleBLE::ByteArray data = SimpleBLE::ByteArray::fromHex(dataToWrite.toStdString());
    writeCharacteristic(service,characteristic,data);
}


void HomeGui::on_pbtn_channelreduce_clicked()
{

    int channel = ui->cbox_channel->currentIndex();

    channel = channel -1;

    if(channel<0)
    {
        channel = 0;
    }
    ui->cbox_channel->setCurrentIndex(channel);
    ui->cbox_channel->activated(channel);
}


void HomeGui::on_pbtn_channeladd_clicked()
{
    int channel = ui->cbox_channel->currentIndex();

    channel = channel  + 1;

    if(channel>channelMax-1)
    {
        channel = channelMax-1;
    }
    ui->cbox_channel->setCurrentIndex(channel);
    ui->cbox_channel->activated(channel);

}

int extractChannelNumber(const QString& filePath)
{
    QFileInfo fileInfo(filePath);
    QString fileName = fileInfo.fileName();

    QRegularExpression regExp("ch(\\d+)");
    QRegularExpressionMatch match = regExp.match(fileName);

    if (match.hasMatch()) {
        return match.captured(1).toInt();
    }
    return -1;
}


void HomeGui::on_pbtn_loadDataFile_clicked()
{
    bool status = statusflag;

    if(!status){
        stop_clicked();
    }

    QString fileName = QFileDialog::getOpenFileName(this, "Open the BIN file", "", "BIN (*.bin)");
    if (fileName.isEmpty()) {
        return;
    }
    ui->lineEdit_dataFile->setText(fileName);
    if (fileName.isEmpty() || !QFile::exists(fileName)) {
        QMessageBox::warning(this, "warn", "Please select a valid file first");
        return;
    }
    filecurrentChannel = extractChannelNumber(fileName);

    if(filecurrentChannel<0)
    {
        return;
    }

    m_workerThread = new QThread();
    m_fileProcessor = new FileProcessor();
    m_fileProcessor->moveToThread(m_workerThread);
    connect(m_workerThread, &QThread::started, [this, fileName]() {
        m_fileProcessor->processFile(fileName);
    });

    m_workerThread->start();
    plotUpdateTimer_file->start(10);
    connect(m_fileProcessor, &FileProcessor::processingFinished, this, &HomeGui::handleProcessingFinished);
    connect(m_workerThread, &QThread::finished, m_fileProcessor, &QObject::deleteLater);
    connect(m_workerThread, &QThread::finished, m_workerThread, &QObject::deleteLater);
    connect(m_workerThread, &QThread::finished, this, [this]() {
        if (plotUpdateTimer_file->isActive()) {
            plotUpdateTimer_file->stop();
        }
    });
}


void HomeGui::on_pBtn_cancel_clicked()
{
    plotUpdateTimer_file->stop();
}


void HomeGui::on_checkBox_LPF_checkStateChanged(const Qt::CheckState &arg1)
{
    bool enableLPF = (arg1 == Qt::Checked);

    if (enableLPF) {

        ui->checkBox_HPF->setCheckState(Qt::Unchecked);
        ui->checkBox_NF->setCheckState(Qt::Unchecked);
        lowPassFilterFlag = true;
        highPassFilterFlag = false;
        notchFilterFlag = false;

    } else {

        lowPassFilterFlag = false;
    }

    // updatePlot_file();

}


void HomeGui::on_checkBox_HPF_checkStateChanged(const Qt::CheckState &arg1)
{
    bool enableHPF = (arg1 == Qt::Checked);
    if (enableHPF) {

        ui->checkBox_LPF->setCheckState(Qt::Unchecked);
        ui->checkBox_NF->setCheckState(Qt::Unchecked);
        lowPassFilterFlag = false;
        highPassFilterFlag = true;
        notchFilterFlag = false;

    } else {

        highPassFilterFlag = false;
    }

}
void HomeGui::on_checkBox_NF_checkStateChanged(const Qt::CheckState &arg1)
{

    bool enableNF = (arg1 == Qt::Checked);

    if (enableNF) {
        ui->checkBox_LPF->setCheckState(Qt::Unchecked);
        ui->checkBox_HPF->setCheckState(Qt::Unchecked);
        lowPassFilterFlag = false;
        highPassFilterFlag = false;
        notchFilterFlag = true;

    } else {

        notchFilterFlag = false;
    }
}


void HomeGui::on_comboBox_LPF_soft_currentTextChanged(const QString &arg1)
{
    QMap<QString, double> LHPMap {
            {"20 KHz", 20000},
            {"15 KHz", 15000},
            {"10 KHz", 10000},
            {"7.5 KHz", 7500},
            {"5 KHz", 5000},
            {"3 KHz", 3000},
            {"2.5 KHz", 2500},
            {"2 KHz", 2000},
            {"1.5 KHz", 1500},
            {"1 KHz", 1000},
            {"750 Hz", 750},
            {"500 Hz", 500},
            {"300 Hz", 300},
            {"250 Hz",250},
            {"200 Hz", 200},
            {"150 Hz", 150},
            {"100 Hz", 100}
        };


    double LPF = LHPMap[arg1];

    lowPassFilter = LPF;

}


void HomeGui::on_comboBox_HPF_soft_currentTextChanged(const QString &arg1)
{
    QMap<QString, double> FHPMap
        {
            {"500 Hz", 500},
            {"300 Hz", 300},
            {"250 Hz", 250},
            {"200 Hz", 200},
            {"150 Hz", 150},
            {"100 Hz", 150},
            {"75 Hz", 75},
            {"50 Hz", 50},
            {"30 Hz", 30},
            {"25 Hz", 25},
            {"20 Hz", 20},
            {"15 Hz", 15},
            {"10 Hz", 10},
            {"7.5 Hz", 7.5},
            {"5.0 Hz", 5},
            {"3.0 Hz", 3},
            {"2.5 Hz", 2.5}
        };

    double HPF = FHPMap[arg1];
    highPassFilter = HPF;
}


void HomeGui::on_horizontalSlider_valueChanged(int value)
{
    double Volume = value /100.0;
    beeper->setVolume(Volume);
}


void HomeGui::on_pushButton_clicked()
{
    if(services.size() == 0 || characteristics.size() == 0){
        QMessageBox mes(this);
        mes.setText("No Bluetooth device connected");
        mes.exec();
        return;
    }
    if(isSpikeDetection){

        QMessageBox mes(this);
        mes.setText("Start spike detection");
        mes.exec();

        isSpikeDetection =false;
        spikeUpdateTimer->start(5000);

    }
    else{
        QMessageBox mes(this);
        mes.setText("Stop performing spike detection");
        mes.exec();
        isSpikeDetection =true;
        spikeUpdateTimer->stop();
    }
}


void HomeGui::on_lineEdit_threshold_factor_textChanged(const QString &arg1)
{
    bool ok;
    double num = arg1.toDouble(&ok);
    if (ok) {
        threshold_factor = num;
    } else {

    }
}



