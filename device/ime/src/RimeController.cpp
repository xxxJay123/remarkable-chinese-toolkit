#include "RimeController.h"

#include <QDir>
#include <QVariantMap>

namespace {

constexpr int kXkBackSpace = 0xff08;
constexpr int kXkReturn = 0xff0d;
constexpr int kXkEscape = 0xff1b;
constexpr int kXkPageUp = 0xff55;
constexpr int kXkPageDown = 0xff56;

const char* kRimeModules[] = {"default", nullptr};

QString environmentOrDefault(const char* name, const char* fallback) {
    const QString value = qEnvironmentVariable(name);
    return value.isEmpty() ? QString::fromUtf8(fallback) : value;
}

}  // namespace

RimeController::RimeController(QObject* parent)
    : QObject(parent) {
    RIME_STRUCT_INIT(RimeTraits, m_traits);
}

RimeController::~RimeController() {
    if (m_api && m_session) {
        m_api->destroy_session(m_session);
        m_session = 0;
    }
    if (m_api && m_initialized) {
        m_api->finalize();
    }
}

bool RimeController::ready() const {
    return m_ready;
}

QString RimeController::error() const {
    return m_error;
}

QString RimeController::preedit() const {
    return m_preedit;
}

QVariantList RimeController::candidates() const {
    return m_candidates;
}

QVariantList RimeController::schemas() const {
    return m_schemas;
}

QString RimeController::currentSchema() const {
    return m_currentSchema;
}

bool RimeController::initialize() {
    if (m_ready) {
        return true;
    }

    const QString sharedPath = environmentOrDefault(
        "RM_CHINESE_IME_SHARED_DATA",
        "/home/root/.local/share/remarkable-chinese-toolkit/rime/shared"
    );
    const QString userPath = environmentOrDefault(
        "RM_CHINESE_IME_USER_DATA",
        "/home/root/.local/share/remarkable-chinese-toolkit/rime/user"
    );

    if (!QDir().mkpath(sharedPath) || !QDir().mkpath(userPath)) {
        setError(QStringLiteral("無法建立 Rime data 目錄"));
        return false;
    }

    m_sharedDataDir = sharedPath.toUtf8();
    m_userDataDir = userPath.toUtf8();
    m_traits.shared_data_dir = m_sharedDataDir.constData();
    m_traits.user_data_dir = m_userDataDir.constData();
    m_traits.distribution_name = "reMarkable Chinese Toolkit";
    m_traits.distribution_code_name = "remarkable-chinese-toolkit";
    m_traits.distribution_version = "0.1.0";
    m_traits.app_name = "rime.remarkable-chinese-toolkit";
    m_traits.modules = kRimeModules;
    m_traits.min_log_level = 1;

    m_api = rime_get_api();
    if (!m_api) {
        setError(QStringLiteral("無法載入 librime API"));
        return false;
    }

    m_api->setup(&m_traits);
    m_api->initialize(&m_traits);
    m_initialized = true;

    if (m_api->start_maintenance(True)) {
        m_api->join_maintenance_thread();
    }

    m_session = m_api->create_session();
    if (!m_session) {
        setError(QStringLiteral("無法建立 Rime session；請檢查 schema data"));
        return false;
    }

    const QString requestedSchema = qEnvironmentVariable("RM_CHINESE_IME_SCHEMA");
    if (!requestedSchema.isEmpty()) {
        m_api->select_schema(m_session, requestedSchema.toUtf8().constData());
    }

    m_ready = true;
    emit readyChanged();
    refreshSchemas();
    refreshState();

    if (m_schemas.isEmpty()) {
        setError(QStringLiteral("未找到 Rime schema；請先部署粵拼、拼音、倉頡或速成資料"));
    } else {
        setError(QString());
    }

    return true;
}

void RimeController::processKey(const QString& key) {
    if (!m_ready || !m_api || !m_session) {
        setError(QStringLiteral("Rime engine 尚未準備好"));
        return;
    }

    const int keyCode = rimeKeyCode(key);
    if (keyCode < 0) {
        setError(QStringLiteral("不支援嘅按鍵：%1").arg(key));
        return;
    }

    const bool handled = m_api->process_key(m_session, keyCode, 0);
    refreshState();

    if (!handled) {
        emitFallbackCommit(key);
    } else {
        setError(QString());
    }
}

void RimeController::selectCandidate(int index) {
    if (!m_ready || index < 0 || index >= m_candidates.size()) {
        return;
    }

    if (!m_api->select_candidate_on_current_page(
            m_session,
            static_cast<size_t>(index))) {
        setError(QStringLiteral("無法選擇候選字"));
        return;
    }

    refreshState();
    setError(QString());
}

void RimeController::clearComposition() {
    if (!m_ready) {
        return;
    }
    m_api->clear_composition(m_session);
    refreshState();
}

bool RimeController::selectSchema(const QString& schemaId) {
    if (!m_ready || schemaId.isEmpty()) {
        return false;
    }

    m_api->clear_composition(m_session);
    if (!m_api->select_schema(m_session, schemaId.toUtf8().constData())) {
        setError(QStringLiteral("無法切換輸入方案：%1").arg(schemaId));
        return false;
    }

    refreshState();
    setError(QString());
    return true;
}

void RimeController::setError(const QString& message) {
    if (m_error == message) {
        return;
    }
    m_error = message;
    emit errorChanged();
}

void RimeController::refreshState() {
    if (!m_api || !m_session) {
        return;
    }

    RIME_STRUCT(RimeCommit, commit);
    if (m_api->get_commit(m_session, &commit)) {
        if (commit.text) {
            emit committed(QString::fromUtf8(commit.text));
        }
        m_api->free_commit(&commit);
    }

    QString nextPreedit;
    QVariantList nextCandidates;

    RIME_STRUCT(RimeContext, context);
    if (m_api->get_context(m_session, &context)) {
        if (context.composition.preedit) {
            nextPreedit = QString::fromUtf8(context.composition.preedit);
        }

        for (int i = 0; i < context.menu.num_candidates; ++i) {
            const RimeCandidate& candidate = context.menu.candidates[i];
            QVariantMap item;
            item.insert(QStringLiteral("index"), i);
            item.insert(
                QStringLiteral("text"),
                candidate.text ? QString::fromUtf8(candidate.text) : QString()
            );
            item.insert(
                QStringLiteral("comment"),
                candidate.comment ? QString::fromUtf8(candidate.comment) : QString()
            );
            nextCandidates.append(item);
        }
        m_api->free_context(&context);
    }

    if (m_preedit != nextPreedit) {
        m_preedit = nextPreedit;
        emit preeditChanged();
    }
    if (m_candidates != nextCandidates) {
        m_candidates = nextCandidates;
        emit candidatesChanged();
    }

    QString nextSchema;
    RIME_STRUCT(RimeStatus, status);
    if (m_api->get_status(m_session, &status)) {
        if (status.schema_id) {
            nextSchema = QString::fromUtf8(status.schema_id);
        }
        m_api->free_status(&status);
    }

    if (m_currentSchema != nextSchema) {
        m_currentSchema = nextSchema;
        emit currentSchemaChanged();
    }
}

void RimeController::refreshSchemas() {
    QVariantList nextSchemas;
    RimeSchemaList schemaList{};

    if (m_api->get_schema_list(&schemaList)) {
        for (size_t i = 0; i < schemaList.size; ++i) {
            const RimeSchemaListItem& schema = schemaList.list[i];
            QVariantMap item;
            item.insert(
                QStringLiteral("id"),
                schema.schema_id ? QString::fromUtf8(schema.schema_id) : QString()
            );
            item.insert(
                QStringLiteral("name"),
                schema.name ? QString::fromUtf8(schema.name) : QString()
            );
            nextSchemas.append(item);
        }
        m_api->free_schema_list(&schemaList);
    }

    if (m_schemas != nextSchemas) {
        m_schemas = nextSchemas;
        emit schemasChanged();
    }
}

void RimeController::emitFallbackCommit(const QString& key) {
    if (key == QStringLiteral("space")) {
        emit committed(QStringLiteral(" "));
    } else if (key == QStringLiteral("enter")) {
        emit committed(QStringLiteral("\n"));
    } else if (key.size() == 1) {
        emit committed(key);
    }
}

int RimeController::rimeKeyCode(const QString& key) {
    if (key == QStringLiteral("backspace")) {
        return kXkBackSpace;
    }
    if (key == QStringLiteral("enter")) {
        return kXkReturn;
    }
    if (key == QStringLiteral("escape")) {
        return kXkEscape;
    }
    if (key == QStringLiteral("pageUp")) {
        return kXkPageUp;
    }
    if (key == QStringLiteral("pageDown")) {
        return kXkPageDown;
    }
    if (key == QStringLiteral("space")) {
        return ' ';
    }
    if (key.size() == 1 && key.at(0).unicode() < 128) {
        return key.at(0).unicode();
    }
    return -1;
}
