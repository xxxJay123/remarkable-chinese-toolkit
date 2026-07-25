#pragma once

#include <QByteArray>
#include <QObject>
#include <QVariantList>

#include <rime_api.h>

class RimeController final : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(QString preedit READ preedit NOTIFY preeditChanged)
    Q_PROPERTY(QVariantList candidates READ candidates NOTIFY candidatesChanged)
    Q_PROPERTY(QVariantList schemas READ schemas NOTIFY schemasChanged)
    Q_PROPERTY(QString currentSchema READ currentSchema NOTIFY currentSchemaChanged)

public:
    explicit RimeController(QObject* parent = nullptr);
    ~RimeController() override;

    bool ready() const;
    QString error() const;
    QString preedit() const;
    QVariantList candidates() const;
    QVariantList schemas() const;
    QString currentSchema() const;

    Q_INVOKABLE bool initialize();
    Q_INVOKABLE void processKey(const QString& key);
    Q_INVOKABLE void selectCandidate(int index);
    Q_INVOKABLE void clearComposition();
    Q_INVOKABLE bool selectSchema(const QString& schemaId);

signals:
    void readyChanged();
    void errorChanged();
    void preeditChanged();
    void candidatesChanged();
    void schemasChanged();
    void currentSchemaChanged();
    void committed(const QString& text);

private:
    void setError(const QString& message);
    void refreshState();
    void refreshSchemas();
    void emitFallbackCommit(const QString& key);
    static int rimeKeyCode(const QString& key);

    RimeApi* m_api = nullptr;
    RimeSessionId m_session = 0;
    RimeTraits m_traits{};
    QByteArray m_sharedDataDir;
    QByteArray m_userDataDir;

    bool m_initialized = false;
    bool m_ready = false;
    QString m_error;
    QString m_preedit;
    QVariantList m_candidates;
    QVariantList m_schemas;
    QString m_currentSchema;
};
