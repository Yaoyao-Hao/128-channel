#ifndef WAITINGDIALOG_H
#define WAITINGDIALOG_H

#include <QDialog>
#include <QLabel>
#include <QMovie>
#include <QVBoxLayout>

class WaitingDialog : public QDialog {
    Q_OBJECT
public:
    explicit WaitingDialog(QWidget *parent = nullptr);
    ~WaitingDialog();

private:
    QLabel *label;
    QMovie *movie;
};

#endif // WAITINGDIALOG_H
