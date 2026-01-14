#include "waitingdialog.h"

WaitingDialog::WaitingDialog(QWidget *parent) : QDialog(parent) {
    setWindowTitle("Wait");
    setFixedSize(200, 120);
    setModal(true);

    QVBoxLayout *layout = new QVBoxLayout(this);

    movie = new QMovie(":/loading.gif");
    label = new QLabel(this);
    label->setText("Processing...");
    label->setAlignment(Qt::AlignCenter);

    layout->addWidget(label);
    movie->start();
}

WaitingDialog::~WaitingDialog() {
    delete movie;
}
