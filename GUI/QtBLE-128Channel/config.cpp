#include "config.h"
#include "ui_config.h"

Config::Config(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::Config)
{
    ui->setupUi(this);

    selectedFilePath = "";
    progressBar = new QProgressBar(this);


}

Config::~Config()
{
    delete ui;
}

void Config::on_pbtn_FPGA_clicked()
{
    QString filePath = QFileDialog::getOpenFileName(this, "select BIN file", "", "(*.bin);; (*.*)");
    if (!filePath.isEmpty()) {
        ui->lineEdit_fpga->setText(filePath);
        selectedFilePath = filePath;
    }

}

void Config::on_pbtn_sendfpga_clicked()
{

    if (selectedFilePath.isEmpty()) {
               QMessageBox::warning(this, "Error", "Please select the BIN file first.");
               return;
           }

           QFile file(selectedFilePath);
           if (!file.open(QIODevice::ReadOnly)) {
               QMessageBox::critical(this, "Error", "Unable to open file");
               return;
           }

           QByteArray fileData = file.readAll();
           file.close();

           if (fileData.isEmpty()) {
               QMessageBox::warning(this, "Error", "File is empty");
               return;
           }

           const int chunkSize = 1024;
           for (int i = 0; i < fileData.size(); i += chunkSize) {
                QByteArray chunk = fileData.mid(i, chunkSize);

                progressBar->setValue(i + chunk.size());
                QApplication::processEvents();
            }
}
