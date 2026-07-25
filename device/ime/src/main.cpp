#include <cstdlib>

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <qqml.h>

#include "RimeController.h"

int main(int argc, char* argv[]) {
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("reMarkable Chinese IME"));
    app.setOrganizationName(QStringLiteral("reMarkable Chinese Toolkit"));

    qmlRegisterType<RimeController>(
        "Remarkable.ChineseToolkit.Ime",
        1,
        0,
        "RimeEngine"
    );

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(EXIT_FAILURE); },
        Qt::QueuedConnection
    );
    engine.loadFromModule("Remarkable.ChineseToolkit.Ime", "Main");

    return app.exec();
}
