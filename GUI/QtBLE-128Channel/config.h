#ifndef CONFIG_H
#define CONFIG_H

#include <QWidget>

#include <QFileDialog>
#include <QFile>
#include <QMessageBox>
#include <QProgressBar>

namespace Ui {
class Config;
}

class Config : public QWidget
{
    Q_OBJECT

public:
    explicit Config(QWidget *parent = nullptr);
    ~Config();

private slots:
    void on_pbtn_FPGA_clicked();

    void on_pbtn_sendfpga_clicked();

private:
    Ui::Config *ui;

    QProgressBar *progressBar;

    QString selectedFilePath;
};

#endif // CONFIG_H
