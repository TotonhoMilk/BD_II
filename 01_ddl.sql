
/* =====================================================================
   PROJETO: Sistema de Matrícula Acadêmica
   DISCIPLINA: Banco de Dados II (CCO072) — IESB 2026/2
   PROFESSOR: Rodrigo Gonçalves
   
   ARQUIVO: 01_ddl.sql
   DESCRIÇÃO: Marco 1 completo em um arquivo só:
              1) DDL: schema, tipos, domínios, tabelas, restrições e
                 triggers de auditoria;
              2) carga: 100 alunos, 6 turmas (2026/2), 300 matrículas e o
                 histórico de 2025/2 e 2026/1, tudo com INSERT ... VALUES.
              Roda de uma vez, do zero.
   
   SGBD: PostgreSQL 17
   BANCO DE DADOS: matricula
   
   AUTORES:
     - Alexandre Vieira
     - Antônio Alexandre - 2512130086
     - Carlos Eduardo
     
   HISTÓRICO DE REVISÕES: Verificar GitHub
     - https://github.com/TotonhoMilk/BD_II
   ===================================================================== */

-- 1. CONFIGURAÇÃO DE SCHEMA E EXTENSÕES
DROP SCHEMA IF EXISTS academico CASCADE;
CREATE SCHEMA academico;
SET search_path TO academico, public;

CREATE EXTENSION IF NOT EXISTS btree_gist;

/* =====================================================================
                ENUMS E TIPOS PERSONALIZADOS
   ===================================================================== */
CREATE TYPE turno_t           AS ENUM ('MATUTINO', 'VESPERTINO', 'NOTURNO', 'INTEGRAL');
CREATE TYPE tipo_disc_t       AS ENUM ('OBRIGATORIA', 'OPTATIVA', 'ELETIVA');
CREATE TYPE vinculo_t         AS ENUM ('PRE_REQUISITO', 'CO_REQUISITO');
CREATE TYPE status_mat_t      AS ENUM ('MATRICULADO', 'TRANCADO', 'CANCELADO', 'CONCLUIDO');
CREATE TYPE tipo_sala_t       AS ENUM ('TEORICA', 'LABORATORIO', 'AUDITORIO', 'GINASIO');
CREATE TYPE tipo_titulacao_t  AS ENUM ('ESPECIALISTA', 'MESTRE', 'DOUTOR', 'POS_DOUTOR');
CREATE TYPE tipo_grau_t       AS ENUM ('BACHARELADO', 'LICENCIATURA', 'TECNOLOGO');
CREATE TYPE tipo_status_t     AS ENUM ('ATIVO', 'TRANCADO', 'CANCELADO', 'FORMADO', 'JUBILADO');
CREATE TYPE tipo_aprov_t      AS ENUM ('EM_ANALISE', 'DEFERIDO', 'INDEFERIDO');
CREATE TYPE tipo_invent_t     AS ENUM ('BOM', 'REGULAR', 'RUIM', 'INSERVIVEL');
CREATE TYPE tipo_evento_t     AS ENUM ('FERIADO', 'AVALIACAO', 'RECESSO', 'PRAZO_MATRICULA', 'OUTRO');
CREATE TYPE tipo_turma_t      AS ENUM ('PRESENCIAL', 'HIBRIDA', 'EAD');
CREATE TYPE tipo_aula_t       AS ENUM ('AGENDADA', 'REALIZADA', 'CANCELADA', 'SUBSTITUIDA');
CREATE TYPE tipo_mensal_t     AS ENUM ('ABERTA', 'PAGA', 'VENCIDA', 'CANCELADA', 'NEGOCIADA');
CREATE TYPE tipo_valid_t      AS ENUM ('PENDENTE', 'DEFERIDO', 'INDEFERIDO');
CREATE TYPE tipo_requer_t     AS ENUM ('ABERTO', 'EM_ANALISE', 'DEFERIDO', 'INDEFERIDO', 'CANCELADO');

-- Criação do Range Type para time
CREATE TYPE timerange AS RANGE (subtype = time);

CREATE DOMAIN nota_t AS numeric(4,2) CHECK (VALUE >= 0 AND VALUE <= 10);
CREATE DOMAIN pct_t  AS numeric(5,2) CHECK (VALUE >= 0 AND VALUE <= 100);


/* =====================================================================
   1. GEOGRAFIA E ESTRUTURA FÍSICA
   ===================================================================== */
CREATE TABLE tb_pais (
    id_pais                    SMALLINT                   GENERATED ALWAYS AS IDENTITY,
    nome_pais                  VARCHAR(60)                NOT NULL,
    sigla_pais                 CHAR(2)                    NOT NULL,

    CONSTRAINT pk_pais PRIMARY KEY (id_pais),
    CONSTRAINT uk_nome_pais UNIQUE (nome_pais),
    CONSTRAINT uk_sigla_pais UNIQUE (sigla_pais)
);

CREATE TABLE tb_estado (
    id_estado                  SMALLINT                   GENERATED ALWAYS AS IDENTITY,
    nome_estado                VARCHAR(60)                NOT NULL,
    sigla_estado               CHAR(2)                    NOT NULL,
    id_pais            		   SMALLINT                   NOT NULL,

    CONSTRAINT pk_estado PRIMARY KEY (id_estado),
    CONSTRAINT fk_estado_pais FOREIGN KEY (id_pais) REFERENCES tb_pais(id_pais) ON DELETE RESTRICT,
    CONSTRAINT uk_nome_pais_estado UNIQUE (nome_estado, id_pais)
);

CREATE TABLE tb_cidade (
    id_cidade                  INT                        GENERATED ALWAYS AS IDENTITY,
    nome_cidade                VARCHAR(60)                NOT NULL,
    id_estado                  SMALLINT                   NOT NULL,

    CONSTRAINT pk_cidade PRIMARY KEY (id_cidade),
    CONSTRAINT fk_cidade_estado FOREIGN KEY (id_estado) REFERENCES tb_estado(id_estado) ON DELETE RESTRICT,
    CONSTRAINT uk_nome_estado_cidade UNIQUE (nome_cidade, id_estado)
);

CREATE TABLE tb_campus (
    id_campus                  SMALLINT                   GENERATED ALWAYS AS IDENTITY,
    nome_campus                VARCHAR(60)                NOT NULL,
    id_cidade                  INT                        NOT NULL,

    CONSTRAINT pk_campus PRIMARY KEY (id_campus),
    CONSTRAINT fk_campus_cidade FOREIGN KEY (id_cidade) REFERENCES tb_cidade(id_cidade) ON DELETE RESTRICT,
    CONSTRAINT uk_nome_campus UNIQUE (nome_campus)
);

CREATE TABLE tb_sala (
    id_sala                    INT                        GENERATED ALWAYS AS IDENTITY,
    id_campus                  SMALLINT                   NOT NULL,
    codigo_sala                VARCHAR(10)                NOT NULL,
    capacidade_sala            SMALLINT                   NOT NULL CHECK (capacidade_sala > 0),
    tipo_sala                  tipo_sala_t                NOT NULL DEFAULT 'TEORICA',

    CONSTRAINT pk_sala PRIMARY KEY (id_sala),
    CONSTRAINT fk_sala_campus FOREIGN KEY (id_campus) REFERENCES tb_campus(id_campus) ON DELETE RESTRICT,
    CONSTRAINT uk_campus_codigo_sala UNIQUE (id_campus, codigo_sala)
);

CREATE TABLE tb_inventario_sala (
    id_inventario_sala                    INT                        GENERATED ALWAYS AS IDENTITY,
    id_sala               INT                        NOT NULL,
    nome_item_inventario_sala             VARCHAR(100)               NOT NULL,
    patrimonio_inventario_sala            VARCHAR(50),
    quantidade_inventario_sala            SMALLINT                   NOT NULL DEFAULT 1 CHECK (quantidade_inventario_sala > 0),
    estado_conservacao_inventario_sala    tipo_invent_t              NOT NULL DEFAULT 'BOM',
    ultima_vistoria_inventario_sala       DATE                       CHECK (ultima_vistoria_inventario_sala <= CURRENT_DATE),

    CONSTRAINT pk_inventario_sala PRIMARY KEY (id_inventario_sala),
    CONSTRAINT fk_inventario_sala_sala FOREIGN KEY (id_sala) REFERENCES tb_sala(id_sala) ON DELETE CASCADE,
    CONSTRAINT uk_patrimonio_inventario_sala UNIQUE (patrimonio_inventario_sala)
);


/* =====================================================================
   2. NÚCLEO DE PESSOAS E ESPECIALIZAÇÕES
   ===================================================================== */
CREATE TABLE tb_pessoa (
    id_pessoa                  INT                        GENERATED ALWAYS AS IDENTITY,
    nome_pessoa                VARCHAR(120)               NOT NULL,
    cpf_pessoa                 CHAR(11)                   NOT NULL CHECK (cpf_pessoa ~ '^[0-9]{11}$'),
    email_pessoa               VARCHAR(120)               NOT NULL,
    telefone_pessoa            VARCHAR(20),
    nascimento_pessoa          DATE                       NOT NULL CHECK (nascimento_pessoa < CURRENT_DATE),
    id_cidade                  INT,

    CONSTRAINT pk_pessoa PRIMARY KEY (id_pessoa),
    CONSTRAINT uk_cpf_pessoa UNIQUE (cpf_pessoa),
    CONSTRAINT uk_email_pessoa UNIQUE (email_pessoa),
    CONSTRAINT fk_pessoa_cidade FOREIGN KEY (id_cidade) REFERENCES tb_cidade(id_cidade) ON DELETE SET NULL
);

CREATE TABLE tb_funcionario (
    id_funcionario                  INT                        GENERATED ALWAYS AS IDENTITY,
    id_pessoa                       INT                        NOT NULL,
    matricula_funcionario           VARCHAR(20)                NOT NULL,
    cargo_funcionario               VARCHAR(60)                NOT NULL,
    data_contratacao_funcionario    DATE                       NOT NULL,
    ativo_funcionario               BOOLEAN                    DEFAULT TRUE,

    CONSTRAINT pk_funcionario PRIMARY KEY (id_funcionario),
    CONSTRAINT uk_matricula_funcionario UNIQUE (matricula_funcionario),
    CONSTRAINT uk_pessoa_funcionario UNIQUE (id_pessoa),
    CONSTRAINT fk_funcionario_pessoa FOREIGN KEY (id_pessoa) REFERENCES tb_pessoa(id_pessoa) ON DELETE CASCADE
);

CREATE TABLE tb_professor (
    id_professor               INT                        NOT NULL,
    titulacao_professor        tipo_titulacao_t           NOT NULL,

    CONSTRAINT pk_professor PRIMARY KEY (id_professor),
    CONSTRAINT fk_professor_funcionario FOREIGN KEY (id_professor) REFERENCES tb_funcionario(id_funcionario) ON DELETE CASCADE
);

CREATE TABLE tb_curso (
    id_curso                   SMALLINT                   GENERATED ALWAYS AS IDENTITY,
    codigo_curso               VARCHAR(10)                NOT NULL,
    nome_curso                 VARCHAR(120)               NOT NULL,
    grau_curso                 tipo_grau_t                NOT NULL,
    id_campus                  SMALLINT                   NOT NULL,

    CONSTRAINT pk_curso PRIMARY KEY (id_curso),
    CONSTRAINT uk_codigo_curso UNIQUE (codigo_curso),
    CONSTRAINT fk_curso_campus FOREIGN KEY (id_campus) REFERENCES tb_campus(id_campus) ON DELETE RESTRICT
);

CREATE TABLE tb_curriculo (
    id_curriculo               INT                        GENERATED ALWAYS AS IDENTITY,
    id_curso                   SMALLINT                   NOT NULL,
    ano_vigencia_curriculo     SMALLINT                   NOT NULL CHECK (ano_vigencia_curriculo BETWEEN 2000 AND 2100),
    ch_total_exigida_curriculo INT                        NOT NULL CHECK (ch_total_exigida_curriculo > 0),
    ativo_curriculo            BOOLEAN                    NOT NULL DEFAULT FALSE,

    CONSTRAINT pk_curriculo PRIMARY KEY (id_curriculo),
    CONSTRAINT fk_curriculo_curso FOREIGN KEY (id_curso) REFERENCES tb_curso(id_curso) ON DELETE CASCADE,
    CONSTRAINT uk_curso_ano_curriculo UNIQUE (id_curso, ano_vigencia_curriculo)
);

CREATE UNIQUE INDEX uq_curriculo_ativo ON tb_curriculo (id_curso) WHERE ativo_curriculo;

CREATE TABLE tb_aluno (
    id_aluno                   INT                        GENERATED ALWAYS AS IDENTITY,
    id_pessoa                  INT                        NOT NULL,
    matricula_aluno            VARCHAR(12)                NOT NULL,
    id_curriculo               INT                        NOT NULL,
    ingresso_aluno             DATE                       NOT NULL,
    status_detalhado_aluno     tipo_status_t              NOT NULL DEFAULT 'ATIVO',

    CONSTRAINT pk_aluno PRIMARY KEY (id_aluno),
    CONSTRAINT uk_matricula_aluno UNIQUE (matricula_aluno),
    CONSTRAINT uk_pessoa_curriculo_aluno UNIQUE (id_pessoa, id_curriculo),
    CONSTRAINT fk_aluno_pessoa FOREIGN KEY (id_pessoa) REFERENCES tb_pessoa(id_pessoa) ON DELETE CASCADE,
    CONSTRAINT fk_aluno_curriculo FOREIGN KEY (id_curriculo) REFERENCES tb_curriculo(id_curriculo) ON DELETE RESTRICT
);


/* =====================================================================
   3. ACADÊMICO E DISCIPLINAS
   ===================================================================== */
CREATE TABLE tb_ementa (
    id_ementa                           INT               GENERATED ALWAYS AS IDENTITY,
    objetivo_ementa                     TEXT              NOT NULL,
    conteudo_programatico_ementa        TEXT              NOT NULL,
    bibliografia_basica_ementa          TEXT              NOT NULL,
    bibliografia_complementar_ementa    TEXT,

    CONSTRAINT pk_ementa PRIMARY KEY (id_ementa)
);

CREATE TABLE tb_disciplina (
    id_disciplina              INT                        GENERATED ALWAYS AS IDENTITY,
    codigo_disciplina          VARCHAR(10)                NOT NULL,
    nome_disciplina            VARCHAR(120)               NOT NULL,
    ch_teorica_disciplina      SMALLINT                   NOT NULL CHECK (ch_teorica_disciplina >= 0),
    ch_pratica_disciplina      SMALLINT                   NOT NULL CHECK (ch_pratica_disciplina >= 0),
    
    -- [FK]
    id_ementa                  INT,

    CONSTRAINT pk_disciplina PRIMARY KEY (id_disciplina),
    CONSTRAINT uk_codigo_disciplina UNIQUE (codigo_disciplina),
    CONSTRAINT fk_disciplina_ementa FOREIGN KEY (id_ementa) REFERENCES tb_ementa(id_ementa) ON DELETE SET NULL,
    CONSTRAINT chk_ch_total_disciplina CHECK (ch_teorica_disciplina + ch_pratica_disciplina > 0)
);

CREATE TABLE tb_curriculo_disciplina (
    periodo_curriculo_disciplina          SMALLINT           NOT NULL CHECK (periodo_curriculo_disciplina BETWEEN 1 AND 12),
    tipo_curriculo_disciplina             tipo_disc_t        NOT NULL DEFAULT 'OBRIGATORIA',

    -- [PK][FK]
    id_curriculo                          INT                NOT NULL,
    id_disciplina                         INT                NOT NULL,

    CONSTRAINT pk_curriculo_disciplina PRIMARY KEY (id_curriculo, id_disciplina),
    CONSTRAINT fk_curriculo_disciplina_curriculo FOREIGN KEY (id_curriculo) REFERENCES tb_curriculo(id_curriculo) ON DELETE CASCADE,
    CONSTRAINT fk_curriculo_disciplina_disciplina FOREIGN KEY (id_disciplina) REFERENCES tb_disciplina(id_disciplina) ON DELETE RESTRICT
);

CREATE TABLE tb_pre_requisito (
    id_disciplina                      INT                      NOT NULL,
    id_requisito                       INT                      NOT NULL,
    vinculo_pre_requisito              vinculo_t                NOT NULL DEFAULT 'PRE_REQUISITO',

    CONSTRAINT pk_pre_requisito PRIMARY KEY (id_disciplina, id_requisito),
    CONSTRAINT fk_pre_requisito_disciplina FOREIGN KEY (id_disciplina) REFERENCES tb_disciplina(id_disciplina) ON DELETE CASCADE,
    CONSTRAINT fk_pre_requisito_requisito FOREIGN KEY (id_requisito) REFERENCES tb_disciplina(id_disciplina) ON DELETE RESTRICT,
    CONSTRAINT chk_pre_requisito_diferente CHECK (id_disciplina <> id_requisito)
);

CREATE TABLE tb_aproveitamento_disciplina (
    id_aproveitamento_disciplina                        INT               GENERATED ALWAYS AS IDENTITY,
    aluno_id_aproveitamento_disciplina                  INT               NOT NULL,
    disciplina_id_aproveitamento_disciplina             INT               NOT NULL,
    instituicao_origem_aproveitamento_disciplina        VARCHAR(120)      NOT NULL,
    ch_aprovada_aproveitamento_disciplina               SMALLINT          NOT NULL CHECK (ch_aprovada_aproveitamento_disciplina > 0),
    nota_origem_aproveitamento_disciplina               NUMERIC(4,2)      CHECK (nota_origem_aproveitamento_disciplina BETWEEN 0.00 AND 10.00),
    status_aprovacao_aproveitamento_disciplina          tipo_aprov_t      NOT NULL DEFAULT 'EM_ANALISE',
    observacao_aproveitamento_disciplina                TEXT,

    CONSTRAINT pk_aproveitamento_disciplina PRIMARY KEY (id_aproveitamento_disciplina),
    CONSTRAINT fk_aproveitamento_aluno FOREIGN KEY (aluno_id_aproveitamento_disciplina) REFERENCES tb_aluno(id_aluno) ON DELETE CASCADE,
    CONSTRAINT fk_aproveitamento_disciplina FOREIGN KEY (disciplina_id_aproveitamento_disciplina) REFERENCES tb_disciplina(id_disciplina) ON DELETE RESTRICT
);


/* =====================================================================
   4. CALENDÁRIO, TURMAS E AULAS
   ===================================================================== */
CREATE TABLE tb_periodo_letivo (
    id_periodo_letivo          SMALLINT                   GENERATED ALWAYS AS IDENTITY,
    ano_periodo_letivo         SMALLINT                   NOT NULL,
    semestre_periodo_letivo    SMALLINT                   NOT NULL CHECK (semestre_periodo_letivo IN (1, 2)),
    bimestre_periodo_letivo    SMALLINT                   NOT NULL CHECK (bimestre_periodo_letivo BETWEEN 1 AND 4),
    data_inicio_periodo_letivo DATE                       NOT NULL,
    data_fim_periodo_letivo    DATE                       NOT NULL,

    CONSTRAINT pk_periodo_letivo PRIMARY KEY (id_periodo_letivo),
    CONSTRAINT uk_ano_semestre_bimestre UNIQUE NULLS NOT DISTINCT (ano_periodo_letivo, semestre_periodo_letivo, bimestre_periodo_letivo),
    CONSTRAINT chk_datas_periodo CHECK (data_fim_periodo_letivo > data_inicio_periodo_letivo)
);

CREATE TABLE tb_calendario_academico (
    id_calendario_academico                   INT                  GENERATED ALWAYS AS IDENTITY,
    data_evento_calendario_academico          DATE                 NOT NULL,
    tipo_evento_calendario_academico          tipo_evento_t        NOT NULL DEFAULT 'FERIADO',
    descricao_calendario_academico            VARCHAR(120)         NOT NULL,
    
    -- [FK]
    id_campus                                 SMALLINT,
    id_periodo_letivo                         SMALLINT             NOT NULL,

    CONSTRAINT pk_calendario_academico PRIMARY KEY (id_calendario_academico),
    CONSTRAINT fk_calendario_periodo FOREIGN KEY (id_periodo_letivo) REFERENCES tb_periodo_letivo(id_periodo_letivo) ON DELETE CASCADE,
    CONSTRAINT fk_calendario_campus FOREIGN KEY (id_campus) REFERENCES tb_campus(id_campus) ON DELETE CASCADE,
    CONSTRAINT uk_evento_campus UNIQUE (data_evento_calendario_academico, id_campus)
);

CREATE TABLE tb_turma (
    -- [PK]
    id_turma                   INT                        GENERATED ALWAYS AS IDENTITY,

    -- [ATRIBUTOS]
    codigo_turma               VARCHAR(15)                NOT NULL,
    turno_turma                turno_t                    NOT NULL,
    vagas_turma                SMALLINT                   NOT NULL CHECK (vagas_turma > 0),

    -- [FK]
    id_disciplina              INT                        NOT NULL,
    id_periodo_letivo          SMALLINT                   NOT NULL,
    id_professor               INT,

    CONSTRAINT pk_turma PRIMARY KEY (id_turma),
    CONSTRAINT uk_turma_periodo_prof UNIQUE (id_turma, id_periodo_letivo, id_professor),
    CONSTRAINT fk_turma_disciplina FOREIGN KEY (id_disciplina) REFERENCES tb_disciplina(id_disciplina) ON DELETE RESTRICT,
    CONSTRAINT fk_turma_periodo FOREIGN KEY (id_periodo_letivo) REFERENCES tb_periodo_letivo(id_periodo_letivo) ON DELETE RESTRICT,
    CONSTRAINT fk_turma_professor FOREIGN KEY (id_professor) REFERENCES tb_professor(id_professor) ON DELETE SET NULL,
    CONSTRAINT uk_codigo_periodo_disciplina UNIQUE (codigo_turma, id_periodo_letivo, id_disciplina)
);

CREATE TABLE tb_turma_horario (
    -- [PK]
    id_turma_horario                  INT                        GENERATED ALWAYS AS IDENTITY,

    -- [ATRIBUTOS]
    dia_semana_turma_horario          SMALLINT                   NOT NULL CHECK (dia_semana_turma_horario BETWEEN 1 AND 7),
    faixa_turma_horario               TIMERANGE                  NOT NULL CHECK (NOT isempty(faixa_turma_horario)),
    modalidade_turma_horario          tipo_turma_t               NOT NULL DEFAULT 'PRESENCIAL',

    -- [FK]
    id_turma                          INT                        NOT NULL,
    id_sala                           INT                        NOT NULL,
    id_professor                      INT,
    id_periodo_letivo                 SMALLINT                   NOT NULL,

    CONSTRAINT pk_turma_horario PRIMARY KEY (id_turma_horario),
    CONSTRAINT fk_turma_horario_turma FOREIGN KEY (id_turma) REFERENCES tb_turma(id_turma) ON DELETE CASCADE,
    CONSTRAINT fk_turma_horario_sala FOREIGN KEY (id_sala) REFERENCES tb_sala(id_sala) ON DELETE RESTRICT,
    CONSTRAINT fk_turma_horario_professor FOREIGN KEY (id_professor) REFERENCES tb_professor(id_professor) ON DELETE SET NULL,
    CONSTRAINT fk_turma_horario_periodo FOREIGN KEY (id_periodo_letivo) REFERENCES tb_periodo_letivo(id_periodo_letivo) ON DELETE RESTRICT,
    
    -- Restrições de Exclusão (Evitam conflitos de sala e professor)
    CONSTRAINT ex_sala_ocupada EXCLUDE USING gist (
        id_sala WITH =,
        id_periodo_letivo WITH =,
        dia_semana_turma_horario WITH =,
        faixa_turma_horario WITH &&
    ),

    CONSTRAINT ex_professor_ocupado EXCLUDE USING gist (
        id_professor WITH =,
        id_periodo_letivo WITH =,
        dia_semana_turma_horario WITH =,
        faixa_turma_horario WITH &&
    ) WHERE (id_professor IS NOT NULL)
);

CREATE TABLE tb_aula (
    -- [PK]
    id_aula                    BIGINT                     GENERATED ALWAYS AS IDENTITY,
    
    data_aula                  DATE                       NOT NULL,
    conteudo_previsto_aula     TEXT                       NOT NULL,
    conteudo_realizado_aula    TEXT,
    status_aula                tipo_aula_t                NOT NULL DEFAULT 'AGENDADA',
    observacoes_aula           TEXT,

    -- [FK]
    id_turma_horario           INT                        NOT NULL,

    CONSTRAINT pk_aula PRIMARY KEY (id_aula),
    CONSTRAINT fk_aula_turma_horario FOREIGN KEY (id_turma_horario) REFERENCES tb_turma_horario(id_turma_horario) ON DELETE CASCADE
);


/* =====================================================================
   5. MATRÍCULA E HISTÓRICO (3FN)
   ===================================================================== */
CREATE TABLE tb_matricula (
    -- [PK]
    id_matricula               INT                        GENERATED ALWAYS AS IDENTITY,

    -- [ATRIBUTOS]
    data_matricula             TIMESTAMPTZ                NOT NULL DEFAULT NOW(),
    status_matricula           status_mat_t               NOT NULL DEFAULT 'MATRICULADO',

    -- [FK]
    id_aluno                   INT                        NOT NULL,
    id_turma                   INT                        NOT NULL,

    CONSTRAINT pk_matricula PRIMARY KEY (id_matricula),
    CONSTRAINT fk_matricula_aluno FOREIGN KEY (id_aluno) REFERENCES tb_aluno(id_aluno) ON DELETE CASCADE,
    CONSTRAINT fk_matricula_turma FOREIGN KEY (id_turma) REFERENCES tb_turma(id_turma) ON DELETE RESTRICT,
    CONSTRAINT uk_aluno_turma UNIQUE (id_aluno, id_turma)
);

CREATE TABLE tb_historico (
    -- [PK]
    id_historico               INT                        GENERATED ALWAYS AS IDENTITY,

    -- [ATRIBUTOS]
    nota_a1_historico          nota_t,
    nota_a2_historico          nota_t,
    nota_p3_historico          nota_t,
    frequencia_historico       pct_t                      NOT NULL DEFAULT 100,
    media_final                NUMERIC(4,2)               GENERATED ALWAYS AS (
        CASE
          WHEN nota_a1_historico IS NULL OR nota_a2_historico IS NULL THEN NULL
          WHEN nota_p3_historico IS NULL THEN round(0.4*nota_a1_historico + 0.6*nota_a2_historico, 2)
          ELSE round(greatest(0.4*nota_p3_historico + 0.6*nota_a2_historico,
                              0.4*nota_a1_historico + 0.6*nota_p3_historico), 2)
        END
    ) STORED,

    -- [FK]
    id_matricula               INT                        NOT NULL,

    CONSTRAINT pk_historico PRIMARY KEY (id_historico),
    CONSTRAINT uk_matricula_historico UNIQUE (id_matricula),
    CONSTRAINT fk_historico_matricula FOREIGN KEY (id_matricula) REFERENCES tb_matricula(id_matricula) ON DELETE CASCADE
);

CREATE TABLE tb_chamada (
    --[ATRIBUTOS]
    presente_chamada            BOOLEAN                    NOT NULL DEFAULT TRUE,
    justificativa_chamada       TEXT,

    -- [PK][FK]
    id_aula                     BIGINT                     NOT NULL,
    id_matricula                INT                        NOT NULL,

    CONSTRAINT pk_chamada PRIMARY KEY (id_aula, id_matricula),
    CONSTRAINT fk_chamada_aula FOREIGN KEY (id_aula) REFERENCES tb_aula(id_aula) ON DELETE CASCADE,
    CONSTRAINT fk_chamada_matricula FOREIGN KEY (id_matricula) REFERENCES tb_matricula(id_matricula) ON DELETE CASCADE
);

CREATE TABLE tb_avaliacao (
    -- [PK]
    id_avaliacao               BIGINT                     GENERATED ALWAYS AS IDENTITY,

    -- [ATRIBUTOS]
    titulo_avaliacao           VARCHAR(100)               NOT NULL,
    peso_avaliacao             NUMERIC(4,2)               NOT NULL DEFAULT 1.0,
    data_avaliacao             DATE,
    
    --[FK]
    id_turma                   INT                        NOT NULL,

    CONSTRAINT pk_avaliacao PRIMARY KEY (id_avaliacao),
    CONSTRAINT fk_avaliacao_turma FOREIGN KEY (id_turma) REFERENCES tb_turma(id_turma) ON DELETE CASCADE
);

CREATE TABLE tb_nota_avaliacao (
    -- [ATRIBUTOS]
    nota_nota_avaliacao           nota_t                  NOT NULL,

    -- [PK][FK]
    id_avaliacao                  BIGINT                  NOT NULL,
    id_matricula                  INT                     NOT NULL,

    CONSTRAINT pk_nota_avaliacao PRIMARY KEY (id_avaliacao, id_matricula),
    CONSTRAINT fk_nota_avaliacao_avaliacao FOREIGN KEY (id_avaliacao) REFERENCES tb_avaliacao(id_avaliacao) ON DELETE CASCADE,
    CONSTRAINT fk_nota_avaliacao_matricula FOREIGN KEY (id_matricula) REFERENCES tb_matricula(id_matricula) ON DELETE CASCADE
);


/* =====================================================================
   6. OBRIGAÇÕES MEC, FINANCEIRO E SECRETARIA
   ===================================================================== */
CREATE TABLE tb_atividade_complementar (
    -- [PK]
    id_atividade_complementar                     INT                   GENERATED ALWAYS AS IDENTITY,

    --[ATRIBUTOS]
    descricao_atividade_complementar              VARCHAR(255)          NOT NULL,
    categoria_atividade_complementar              VARCHAR(50)           NOT NULL,
    ch_solicitada_atividade_complementar          SMALLINT              NOT NULL,
    ch_validada_atividade_complementar            SMALLINT,
    status_validacao_atividade_complementar       tipo_valid_t          NOT NULL DEFAULT 'PENDENTE',
    comprovante_url_atividade_complementar        VARCHAR(255),
    validado_por_atividade_complementar           INT,
    data_validacao_atividade_complementar         DATE,

    -- [FK]
    id_aluno                                      INT                   NOT NULL,

    CONSTRAINT pk_atividade_complementar PRIMARY KEY (id_atividade_complementar),
    CONSTRAINT fk_atividade_complementar_aluno FOREIGN KEY (id_aluno) REFERENCES tb_aluno(id_aluno) ON DELETE CASCADE,
    CONSTRAINT fk_atividade_complementar_funcionario FOREIGN KEY (validado_por_atividade_complementar) REFERENCES tb_funcionario(id_funcionario)
);

CREATE TABLE tb_bolsa_desconto (
    -- [PK]
    id_bolsa_desconto          INT                        GENERATED ALWAYS AS IDENTITY,

    -- [ATRIBUTOS]
    nome_bolsa_desconto        VARCHAR(120)               NOT NULL,
    percentual_bolsa_desconto  pct_t                      NOT NULL,
    ativa_bolsa_desconto       BOOLEAN                    DEFAULT FALSE,

    CONSTRAINT pk_bolsa_desconto PRIMARY KEY (id_bolsa_desconto)
);

CREATE TABLE tb_aluno_bolsa (
    -- [ATRIBUTOS]
    data_concessao_aluno_bolsa DATE                       NOT NULL DEFAULT CURRENT_DATE,
    data_validade_aluno_bolsa  DATE,

    -- [PK][FK]
    id_aluno                   INT                        NOT NULL,
    id_bolsa_desconto          INT                        NOT NULL,

    CONSTRAINT pk_aluno_bolsa PRIMARY KEY (id_aluno, id_bolsa_desconto),
    CONSTRAINT fk_aluno_bolsa_aluno FOREIGN KEY (id_aluno) REFERENCES tb_aluno(id_aluno) ON DELETE CASCADE,
    CONSTRAINT fk_aluno_bolsa_bolsa FOREIGN KEY (id_bolsa_desconto) REFERENCES tb_bolsa_desconto(id_bolsa_desconto) ON DELETE RESTRICT
);

CREATE TABLE tb_mensalidade (
    -- [PK]
    id_mensalidade                  BIGINT                    GENERATED ALWAYS AS IDENTITY,

    -- [ATRIBUTOS]
    valor_original_mensalidade      NUMERIC(10,2)             NOT NULL,
    valor_final_mensalidade         NUMERIC(10,2)             NOT NULL,
    data_vencimento_mensalidade     DATE                      NOT NULL,
    data_pagamento_mensalidade      DATE,
    status_mensalidade              tipo_mensal_t             NOT NULL DEFAULT 'ABERTA',

    -- [FK]
    id_aluno                        INT                       NOT NULL,
    id_periodo_letivo               SMALLINT                  NOT NULL,

    CONSTRAINT pk_mensalidade PRIMARY KEY (id_mensalidade),
    CONSTRAINT fk_mensalidade_aluno FOREIGN KEY (id_aluno) REFERENCES tb_aluno(id_aluno) ON DELETE RESTRICT,
    CONSTRAINT fk_mensalidade_periodo FOREIGN KEY (id_periodo_letivo) REFERENCES tb_periodo_letivo(id_periodo_letivo) ON DELETE RESTRICT
);

CREATE TABLE tb_requerimento (
    -- [PK]
    id_requerimento               BIGINT                     GENERATED ALWAYS AS IDENTITY,

    -- [ATRIBUTOS]
    tipo_requerimento             VARCHAR(60)                NOT NULL,
    data_abertura_requerimento    TIMESTAMPTZ                NOT NULL DEFAULT NOW(),
    data_fechamento_requerimento  TIMESTAMPTZ,
    status_requerimento           tipo_requer_t              NOT NULL DEFAULT 'ABERTO',
    parecer_requerimento          TEXT,

    -- [FK]
    id_aluno                      INT                        NOT NULL,
    id_responsavel                INT,

    CONSTRAINT pk_requerimento PRIMARY KEY (id_requerimento),
    CONSTRAINT fk_requerimento_aluno FOREIGN KEY (id_aluno) REFERENCES tb_aluno(id_aluno) ON DELETE CASCADE,
    CONSTRAINT fk_requerimento_funcionario FOREIGN KEY (id_responsavel) REFERENCES tb_funcionario(id_funcionario)
);


/* =====================================================================
   7. LOG DE MATRÍCULA (tabela log_matricula do modelo do professor)
   Guarda o que aconteceu com cada matrícula: qual matrícula, a ação,
   quando, quem fez e os dados da matrícula em JSON (coluna detalhe).
   A secretaria registra a linha do log junto com a operação, com um
   INSERT normal (exemplos na carga de dados abaixo).
   ===================================================================== */

CREATE TABLE tb_log_matricula (
    -- [PK]
    id_log_matricula          BIGINT          GENERATED ALWAYS AS IDENTITY,

    -- [ATRIBUTOS]
    id_matricula              INT             NOT NULL,   -- sem FK de propósito: o log fica mesmo se a matrícula for apagada
    acao_log_matricula        VARCHAR(20)     NOT NULL CHECK (acao_log_matricula IN ('INSERT', 'UPDATE', 'DELETE')),
    ocorrido_em_log_matricula TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    usuario_log_matricula     NAME            NOT NULL DEFAULT CURRENT_USER,
    detalhe_log_matricula     JSONB,                      -- dados da matrícula em JSON

    CONSTRAINT pk_log_matricula PRIMARY KEY (id_log_matricula)
);


/* ==========================================================================
                       POPULAÇÃO DAS TABELAS (CARGA DE DADOS)
   Todos os dados escritos à mão com INSERT ... VALUES.
   Os ids (id_aluno, id_turma, id_matricula...) são gerados em ordem pelo
   IDENTITY: o 1º aluno inserido é o id 1, o 2º é o id 2, e assim por diante.
   É por isso que as chaves estrangeiras abaixo usam números fixos.
   ========================================================================== */

SET search_path TO academico, public;

-- =====================================================================
-- 1. ESTRUTURA BASE (Geografia, Campus, Cursos, Currículos e Período)
-- =====================================================================
INSERT INTO tb_pais (nome_pais, sigla_pais) VALUES ('Brasil', 'BR');

-- Utiliza 'id_pais' e omite o 'id_estado' para que o PostgreSQL gerencie o valor automaticamente
INSERT INTO tb_estado (nome_estado, sigla_estado, id_pais) 
VALUES ('Distrito Federal', 'DF', 1);

INSERT INTO tb_cidade (nome_cidade, id_estado) 
VALUES ('Brasília', 1);

INSERT INTO tb_campus (nome_campus, id_cidade) 
VALUES ('IESB Sul Brasília', 1);

INSERT INTO tb_curso (codigo_curso, nome_curso, grau_curso, id_campus) 
VALUES 
('CCO', 'Ciência da Computação', 'BACHARELADO', 1),
('ENG', 'Engenharia de Software', 'BACHARELADO', 1);

INSERT INTO tb_curriculo (id_curso, ano_vigencia_curriculo, ch_total_exigida_curriculo, ativo_curriculo) 
VALUES 
(1, 2026, 3200, TRUE),
(2, 2026, 3200, TRUE);

INSERT INTO tb_periodo_letivo (ano_periodo_letivo, semestre_periodo_letivo, bimestre_periodo_letivo, data_inicio_periodo_letivo, data_fim_periodo_letivo)
VALUES (2026, 2, 1, '2026-08-01', '2026-12-20');

-- =====================================================================
-- 2. CALENDÁRIO ACADÊMICO
-- =====================================================================
INSERT INTO tb_calendario_academico (id_periodo_letivo, data_evento_calendario_academico, tipo_evento_calendario_academico, descricao_calendario_academico, id_campus)
VALUES 
(1, '2026-08-01', 'PRAZO_MATRICULA', 'Início das Aulas e Ajuste de Matrícula', 1),
(1, '2026-09-07', 'FERIADO', 'Independência do Brasil', 1),
(1, '2026-10-12', 'FERIADO', 'Nossa Senhora Aparecida', 1),
(1, '2026-10-20', 'AVALIACAO', 'Período das Avaliações Regimentais (A1)', 1),
(1, '2026-11-02', 'FERIADO', 'Finados', 1),
(1, '2026-12-10', 'AVALIACAO', 'Período das Avaliações Finais (A2/P3)', 1),
(1, '2026-12-20', 'RECESSO', 'Encerramento do Semestre Letivo', 1);


-- =====================================================================
-- 3. EMENTAS E DISCIPLINAS
-- =====================================================================
INSERT INTO tb_ementa (objetivo_ementa, conteudo_programatico_ementa, bibliografia_basica_ementa, bibliografia_complementar_ementa)
VALUES 
(
  'Capacitar o aluno na modelagem avançada, otimização de consultas e administração de bancos de dados relacionais e não-relacionais.',
  'Arquitetura de SGDBs; Transações e Controle de Concorrência (ACID); Indexação B-Tree e Hash; Otimização de Queries (EXPLAIN ANALYZE); PL/pgSQL, Triggers e Stored Procedures; Introdução ao NoSQL.',
  'ELMASRI, Ramez; NAVATHE, Shamkant B. Sistemas de Banco de Dados. 7. ed. Pearson, 2018. | SILBERSCHATZ, A.; KORTH, H. F.; SUDARSHAN, S. Sistema de Banco de Dados. 6. ed. Elsevier, 2012.',
  'DATE, C. J. Introdução a Sistemas de Bancos de Dados. Elsevier, 2004. | PostgreSQL Global Development Group. Documentation PostgreSQL 16.'
),
(
  'Apresentar conceitos, processos, metodologias e práticas de engenharia para o desenvolvimento de software com qualidade e dentro de prazos e custos.',
  'Ciclo de vida do software; Metodologias Ágeis (Scrum, Kanban); Levantamento e Gestão de Requisitos; Modelagem UML; Arquitetura e Padrões de Projeto; Garantia de Qualidade e Testes de Software.',
  'PRESSMAN, Roger S.; MAXIM, Bruce R. Engenharia de Software: Uma Abordagem Profissional. 8. ed. McGraw-Hill, 2016. | SOMMERVILLE, Ian. Engenharia de Software. 10. ed. Pearson, 2019.',
  'BECK, Kent. TDD: Desenvolvimento Guiado por Testes. Bookman, 2010. | SCHWABER, Ken. Agile Project Management with Scrum. Microsoft Press, 2004.'
),
(
  'Compreender os frameworks de governança corporativa de TI, alinhamento estratégico, gestão de riscos e otimização de processos de negócio.',
  'Alinhamento Estratégico Negócio-TI; ITIL v4 (Serviços de TI); COBIT 2019; Mapeamento de Processos de Negócio com BPMN 2.0; Indicadores de Desempenho (KPIs); LGPD e Governança de Dados.',
  'MAGALHÃES, Ivan Luizio; PINHEIRO, Walfrido M. Gerenciamento de Serviços de TI na Prática: Uma abordagem com base na ITIL. Novatec, 2007. | ISACA. COBIT 2019 Framework: Governance and Management Objectives.',
  'ABPMP. BPM CBOK Version 4.0: Guia para o Gerenciamento de Processos de Negócio. 2019.'
),
(
  'Fornecer fundamentos teóricos e práticos de inteligência artificial, métodos de busca, aprendizado de máquina e redes neurais.',
  'Histórico e Ética em IA; Agentes Inteligentes e Métodos de Busca (A*, Minimax); Aprendizado de Máquina Supervisionado e Não Supervisonado; Algoritmos de Classificação e Regressão; Redes Neurais Artificiais e Deep Learning.',
  'RUSSELL, Stuart; NORVIG, Peter. Inteligência Artificial: uma abordagem moderna. 4. ed. Elsevier, 2022.',
  'GOODFELLOW, Ian; BENGIO, Yoshua; COURVILLE, Aaron. Deep Learning. MIT Press, 2016. | MITCHELL, Tom. Machine Learning. McGraw-Hill, 1997.'
),
(
  'Dominar o paradigma de programação orientada a objetos, promovendo o reuso, modularidade, encapsulamento e boas práticas de codificação.',
  'Conceitos Fundamentais: Classes, Objetos, Atributos e Métodos; Encapsulamento, Herança e Polimorfismo; Tratamento de Exceções; Coleções e Generics; Padrões de Projeto GoF (Creational, Structural, Behavioral).',
  'DEITEL, Paul; DEITEL, Harvey. Java: Como Programar. 10. ed. Pearson, 2016. | GAMMA, E. et al. Padrões de Projeto: Soluções Reutilizáveis de Software Orientado a Objetos. Bookman, 2000.',
  'BLOCH, Joshua. Java Efetivo. Alta Books, 2018. | MARTIN, Robert C. Código Limpo: Habilidades Práticas do Agile Software. Alta Books, 2009.'
),
(
  'Compreender os conceitos estruturais, arquiteturais e operacionais dos sistemas operacionais modernos e gerenciamento de recursos de hardware.',
  'Estrutura e Funções do Sistema Operacional; Gerenciamento de Processos e Threads; Escalonamento da CPU; Sincronização, Semáforos e Deadlocks; Gerenciamento de Memória Virtual; Sistemas de Arquivos.',
  'TANENBAUM, Andrew S.; BOS, Herbert. Sistemas Operacionais Modernos. 4. ed. Pearson, 2016. | SILBERSCHATZ, Abraham; GALVIN, Peter B.; GAGNE, Greg. Conceitos de Sistemas Operacionais. 9. ed. LTC, 2015.',
  'STALLINGS, William. Operating Systems: Internals and Design Principles. 9th ed. Pearson, 2017.'
);

INSERT INTO tb_disciplina (codigo_disciplina, nome_disciplina, ch_teorica_disciplina, ch_pratica_disciplina, id_ementa)
VALUES 
('CCO072', 'Banco De Dados II', 40, 40, 1),
('ENG010', 'Engenharia De Software', 60, 20, 2),
('CCO080', 'Governança De Ti E Mapeamento De Processos', 40, 0, 3),
('ENG022', 'Inteligência Artificial', 40, 40, 4),
('ENG015', 'Programação Orientada A Objetos', 40, 40, 5),
('ENG030', 'Sistemas Operacionais', 40, 40, 6);


-- =====================================================================
-- 4. CURRÍCULO DISCIPLINA E PRÉ-REQUISITOS
-- =====================================================================
-- Ciência da Computação
INSERT INTO tb_curriculo_disciplina (id_curriculo, id_disciplina, periodo_curriculo_disciplina, tipo_curriculo_disciplina) VALUES
(1, 1, 4, 'OBRIGATORIA'), (1, 2, 3, 'OBRIGATORIA'), (1, 3, 5, 'OPTATIVA'),
(1, 4, 6, 'OBRIGATORIA'), (1, 5, 2, 'OBRIGATORIA'), (1, 6, 4, 'OBRIGATORIA');

-- Engenharia de Software
INSERT INTO tb_curriculo_disciplina (id_curriculo, id_disciplina, periodo_curriculo_disciplina, tipo_curriculo_disciplina) VALUES
(2, 1, 4, 'OBRIGATORIA'), (2, 2, 2, 'OBRIGATORIA'), (2, 3, 4, 'OBRIGATORIA'),
(2, 4, 6, 'OPTATIVA'),   (2, 5, 2, 'OBRIGATORIA'), (2, 6, 5, 'OBRIGATORIA');

INSERT INTO tb_pre_requisito (id_disciplina, id_requisito, vinculo_pre_requisito)
VALUES 
(1, 5, 'PRE_REQUISITO'),
(4, 5, 'PRE_REQUISITO'),
(4, 1, 'PRE_REQUISITO'), -- IA também exige BD II (deixa a árvore com 2 níveis: IA -> BD II -> POO)
(2, 3, 'CO_REQUISITO');


-- =====================================================================
-- 5. ESTRUTURA FÍSICA: SALAS E INVENTÁRIO
-- =====================================================================
INSERT INTO tb_sala (id_campus, codigo_sala, capacidade_sala, tipo_sala) VALUES
(1, 'SALA-101', 20, 'TEORICA'),
(1, 'SALA-102', 20, 'TEORICA'),
(1, 'SALA-103', 20, 'TEORICA'),
(1, 'LAB-201',  20, 'LABORATORIO'),
(1, 'LAB-202',  20, 'LABORATORIO'),
(1, 'LAB-203',  20, 'LABORATORIO');

-- Inventário para as Salas Teóricas (SALA-101, SALA-102, SALA-103)
-- SALA-101
INSERT INTO tb_inventario_sala (id_sala, nome_item_inventario_sala, patrimonio_inventario_sala, quantidade_inventario_sala, estado_conservacao_inventario_sala, ultima_vistoria_inventario_sala) VALUES
(1, 'Carteira Escolar Individual com Prancheta', 'PAT-CART-SALA-101', 20, 'BOM', '2026-08-01'),
(1, 'Mesa de Professor', 'PAT-MESA-SALA-101', 1, 'BOM', '2026-08-01'),
(1, 'Quadro Branco Panorâmico', 'PAT-QUAD-SALA-101', 1, 'BOM', '2026-08-01'),
(1, 'Projetor Multimídia HD', 'PAT-PROJ-SALA-101', 1, 'REGULAR', '2026-08-01');

-- SALA-102
INSERT INTO tb_inventario_sala (id_sala, nome_item_inventario_sala, patrimonio_inventario_sala, quantidade_inventario_sala, estado_conservacao_inventario_sala, ultima_vistoria_inventario_sala) VALUES
(2, 'Carteira Escolar Individual com Prancheta', 'PAT-CART-SALA-102', 20, 'BOM', '2026-08-01'),
(2, 'Mesa de Professor', 'PAT-MESA-SALA-102', 1, 'BOM', '2026-08-01'),
(2, 'Quadro Branco Panorâmico', 'PAT-QUAD-SALA-102', 1, 'BOM', '2026-08-01'),
(2, 'Projetor Multimídia HD', 'PAT-PROJ-SALA-102', 1, 'REGULAR', '2026-08-01');

-- SALA-103
INSERT INTO tb_inventario_sala (id_sala, nome_item_inventario_sala, patrimonio_inventario_sala, quantidade_inventario_sala, estado_conservacao_inventario_sala, ultima_vistoria_inventario_sala) VALUES
(3, 'Carteira Escolar Individual com Prancheta', 'PAT-CART-SALA-103', 20, 'BOM', '2026-08-01'),
(3, 'Mesa de Professor', 'PAT-MESA-SALA-103', 1, 'BOM', '2026-08-01'),
(3, 'Quadro Branco Panorâmico', 'PAT-QUAD-SALA-103', 1, 'BOM', '2026-08-01'),
(3, 'Projetor Multimídia HD', 'PAT-PROJ-SALA-103', 1, 'REGULAR', '2026-08-01');

-- Inventário para os Laboratórios (LAB-201, LAB-202, LAB-203)
INSERT INTO tb_inventario_sala (id_sala, nome_item_inventario_sala, patrimonio_inventario_sala, quantidade_inventario_sala, estado_conservacao_inventario_sala, ultima_vistoria_inventario_sala) VALUES
(4, 'Computador Desktop Core i7 16GB RAM 512GB SSD', 'PAT-PC-LAB-201-01', 1, 'BOM', '2026-08-01'),
(4, 'Computador Desktop Core i7 16GB RAM 512GB SSD', 'PAT-PC-LAB-201-02', 1, 'BOM', '2026-08-01'),
(4, 'Mesa Ergonômica para Computador', 'PAT-MLAB-LAB-201', 20, 'BOM', '2026-08-01'),
(4, 'Switch de Rede 24 Portas Gigabit', 'PAT-SWT-LAB-201', 1, 'BOM', '2026-08-01'),
(4, 'Ar Condicionado Split 36000 BTU', 'PAT-AC-LAB-201', 2, 'BOM', '2026-08-01');

--  LAB-202
INSERT INTO tb_inventario_sala (id_sala, nome_item_inventario_sala, patrimonio_inventario_sala, quantidade_inventario_sala, estado_conservacao_inventario_sala, ultima_vistoria_inventario_sala) VALUES
(5, 'Computador Desktop Core i7 16GB RAM 512GB SSD', 'PAT-PC-LAB-202-01', 1, 'BOM', '2026-08-01'),
(5, 'Computador Desktop Core i7 16GB RAM 512GB SSD', 'PAT-PC-LAB-202-02', 1, 'BOM', '2026-08-01'),
(5, 'Mesa Ergonômica para Computador', 'PAT-MLAB-LAB-202', 20, 'BOM', '2026-08-01'),
(5, 'Switch de Rede 24 Portas Gigabit', 'PAT-SWT-LAB-202', 1, 'BOM', '2026-08-01'),
(5, 'Ar Condicionado Split 36000 BTU', 'PAT-AC-LAB-202', 2, 'BOM', '2026-08-01');

-- LAB-203
INSERT INTO tb_inventario_sala (id_sala, nome_item_inventario_sala, patrimonio_inventario_sala, quantidade_inventario_sala, estado_conservacao_inventario_sala, ultima_vistoria_inventario_sala) VALUES
(6, 'Computador Desktop Core i7 16GB RAM 512GB SSD', 'PAT-PC-LAB-203-01', 1, 'BOM', '2026-08-01'),
(6, 'Computador Desktop Core i7 16GB RAM 512GB SSD', 'PAT-PC-LAB-203-02', 1, 'BOM', '2026-08-01'),
(6, 'Mesa Ergonômica para Computador', 'PAT-MLAB-LAB-203', 20, 'BOM', '2026-08-01'),
(6, 'Switch de Rede 24 Portas Gigabit', 'PAT-SWT-LAB-203', 1, 'BOM', '2026-08-01'),
(6, 'Ar Condicionado Split 36000 BTU', 'PAT-AC-LAB-203', 2, 'BOM', '2026-08-01');

-- =====================================================================
-- 6. PESSOAS (10 Funcionários/Professores + 100 Alunos)
-- =====================================================================
-- =====================================================================
-- FUNCIONÁRIOS E PROFESSORES
-- =====================================================================

-- Funcionários 1 a 6 são os professores. A pessoa, o funcionário e o
-- professor são 3 tabelas: primeiro a pessoa (id 1 a 6), depois o
-- funcionário apontando para ela, depois o professor (id = id_funcionario).
INSERT INTO tb_pessoa (nome_pessoa, cpf_pessoa, email_pessoa, telefone_pessoa, nascimento_pessoa, id_cidade) VALUES
('Lucas Silva', '11122233301', 'lucas.silva1@iesb.edu.br', '(61) 98888-1001', '1980-01-15', 1),
('Gabriel Santos', '22233344402', 'gabriel.santos2@iesb.edu.br', '(61) 98888-1002', '1982-03-20', 1),
('Matheus Oliveira', '33344455503', 'matheus.oliveira3@iesb.edu.br', '(61) 98888-1003', '1975-06-10', 1),
('Pedro Souza', '44455566604', 'pedro.souza4@iesb.edu.br', '(61) 98888-1004', '1985-09-05', 1),
('Guilherme Rodrigues', '55566677705', 'guilherme.rodrigues5@iesb.edu.br', '(61) 98888-1005', '1978-12-01', 1),
('Gustavo Ferreira', '66677788806', 'gustavo.ferreira6@iesb.edu.br', '(61) 98888-1006', '1983-07-22', 1);

INSERT INTO tb_funcionario (id_pessoa, matricula_funcionario, cargo_funcionario, data_contratacao_funcionario) VALUES
(1, 'FUNC0001', 'Professor Titular', '2018-02-01'),
(2, 'FUNC0002', 'Professor Titular', '2018-02-01'),
(3, 'FUNC0003', 'Professor Titular', '2018-02-01'),
(4, 'FUNC0004', 'Professor Titular', '2018-02-01'),
(5, 'FUNC0005', 'Professor Titular', '2018-02-01'),
(6, 'FUNC0006', 'Professor Titular', '2018-02-01');

INSERT INTO tb_professor (id_professor, titulacao_professor) VALUES
(1, 'DOUTOR'),
(2, 'DOUTOR'),
(3, 'DOUTOR'),
(4, 'DOUTOR'),
(5, 'DOUTOR'),
(6, 'DOUTOR');

-- Funcionários 7 a 10 (Analistas Administrativos - Apenas Funcionários)
INSERT INTO tb_pessoa (nome_pessoa, cpf_pessoa, email_pessoa, telefone_pessoa, nascimento_pessoa, id_cidade) VALUES
('Felipe Alves', '77788899907', 'felipe.alves7@iesb.edu.br', '(61) 98888-1007', '1990-04-12', 1),
('Rafael Pereira', '88899900008', 'rafael.pereira8@iesb.edu.br', '(61) 98888-1008', '1992-08-18', 1),
('João Lima', '99900011109', 'joao.lima9@iesb.edu.br', '(61) 98888-1009', '1988-11-30', 1),
('Enzo Gomes', '00011122210', 'enzo.gomes10@iesb.edu.br', '(61) 98888-1010', '1995-02-25', 1);

INSERT INTO tb_funcionario (id_pessoa, matricula_funcionario, cargo_funcionario, data_contratacao_funcionario) VALUES
(7, 'FUNC0007', 'Analista Administrativo', '2019-05-10'),
(8, 'FUNC0008', 'Analista Administrativo', '2019-05-10'),
(9, 'FUNC0009', 'Analista Administrativo', '2020-01-15'),
(10, 'FUNC0010', 'Analista Administrativo', '2021-03-01');



-- =====================================================================
-- CARGA DOS 100 ALUNOS
-- =====================================================================

-- Passo 1: Inserção em lote das pessoas (Alunos)
INSERT INTO tb_pessoa (nome_pessoa, cpf_pessoa, email_pessoa, telefone_pessoa, nascimento_pessoa, id_cidade) VALUES
('Lucas Silva', '10000000001', 'lucas.silva1@aluno.iesb.edu.br', '(61) 98888-0001', '2000-02-20', 1),
('Gabriel Santos', '10000000002', 'gabriel.santos2@aluno.iesb.edu.br', '(61) 98888-0002', '2000-04-10', 1),
('Matheus Oliveira', '10000000003', 'matheus.oliveira3@aluno.iesb.edu.br', '(61) 98888-0003', '2000-05-30', 1),
('Pedro Souza', '10000000004', 'pedro.souza4@aluno.iesb.edu.br', '(61) 98888-0004', '2000-07-19', 1),
('Guilherme Rodrigues', '10000000005', 'guilherme.rodrigues5@aluno.iesb.edu.br', '(61) 98888-0005', '2000-09-07', 1),
('Gustavo Ferreira', '10000000006', 'gustavo.ferreira6@aluno.iesb.edu.br', '(61) 98888-0006', '2000-10-27', 1),
('Felipe Alves', '10000000007', 'felipe.alves7@aluno.iesb.edu.br', '(61) 98888-0007', '2000-12-16', 1),
('Rafael Pereira', '10000000008', 'rafael.pereira8@aluno.iesb.edu.br', '(61) 98888-0008', '2001-02-04', 1),
('João Lima', '10000000009', 'joao.lima9@aluno.iesb.edu.br', '(61) 98888-0009', '2001-03-26', 1),
('Enzo Gomes', '10000000010', 'enzo.gomes10@aluno.iesb.edu.br', '(61) 98888-0010', '2001-05-15', 1),
('Arthur Costa', '10000000011', 'arthur.costa11@aluno.iesb.edu.br', '(61) 98888-0011', '2001-07-04', 1),
('Diego Ribeiro', '10000000012', 'diego.ribeiro12@aluno.iesb.edu.br', '(61) 98888-0012', '2001-08-23', 1),
('Bruno Martins', '10000000013', 'bruno.martins13@aluno.iesb.edu.br', '(61) 98888-0013', '2001-10-12', 1),
('Rodrigo Carvalho', '10000000014', 'rodrigo.carvalho14@aluno.iesb.edu.br', '(61) 98888-0014', '2001-12-01', 1),
('Thiago Almeida', '10000000015', 'thiago.almeida15@aluno.iesb.edu.br', '(61) 98888-0015', '2002-01-20', 1),
('Luan Lopes', '10000000016', 'luan.lopes16@aluno.iesb.edu.br', '(61) 98888-0016', '2002-03-11', 1),
('Vitor Soares', '10000000017', 'vitor.soares17@aluno.iesb.edu.br', '(61) 98888-0017', '2002-04-30', 1),
('Leonardo Fernandes', '10000000018', 'leonardo.fernandes18@aluno.iesb.edu.br', '(61) 98888-0018', '2002-06-19', 1),
('Caio Vieira', '10000000019', 'caio.vieira19@aluno.iesb.edu.br', '(61) 98888-0019', '2002-08-08', 1),
('Daniel Barbosa', '10000000020', 'daniel.barbosa20@aluno.iesb.edu.br', '(61) 98888-0020', '2002-09-27', 1),
('Maria Silva', '10000000021', 'maria.silva21@aluno.iesb.edu.br', '(61) 98888-0021', '2002-11-16', 1),
('Ana Santos', '10000000022', 'ana.santos22@aluno.iesb.edu.br', '(61) 98888-0022', '2003-01-05', 1),
('Julia Oliveira', '10000000023', 'julia.oliveira23@aluno.iesb.edu.br', '(61) 98888-0023', '2003-02-24', 1),
('Sophia Souza', '10000000024', 'sophia.souza24@aluno.iesb.edu.br', '(61) 98888-0024', '2003-04-15', 1),
('Larissa Rodrigues', '10000000025', 'larissa.rodrigues25@aluno.iesb.edu.br', '(61) 98888-0025', '2003-06-04', 1),
('Beatriz Ferreira', '10000000026', 'beatriz.ferreira26@aluno.iesb.edu.br', '(61) 98888-0026', '2003-07-24', 1),
('Mariana Alves', '10000000027', 'mariana.alves27@aluno.iesb.edu.br', '(61) 98888-0027', '2003-09-12', 1),
('Gabriela Pereira', '10000000028', 'gabriela.pereira28@aluno.iesb.edu.br', '(61) 98888-0028', '2003-11-01', 1),
('Camila Lima', '10000000029', 'camila.lima29@aluno.iesb.edu.br', '(61) 98888-0029', '2003-12-21', 1),
('Leticia Gomes', '10000000030', 'leticia.gomes30@aluno.iesb.edu.br', '(61) 98888-0030', '2004-02-09', 1),
('Lucas Costa', '10000000031', 'lucas.costa31@aluno.iesb.edu.br', '(61) 98888-0031', '2004-03-30', 1),
('Gabriel Ribeiro', '10000000032', 'gabriel.ribeiro32@aluno.iesb.edu.br', '(61) 98888-0032', '2004-05-19', 1),
('Matheus Martins', '10000000033', 'matheus.martins33@aluno.iesb.edu.br', '(61) 98888-0033', '2004-07-08', 1),
('Pedro Carvalho', '10000000034', 'pedro.carvalho34@aluno.iesb.edu.br', '(61) 98888-0034', '2004-08-27', 1),
('Guilherme Almeida', '10000000035', 'guilherme.almeida35@aluno.iesb.edu.br', '(61) 98888-0035', '2004-10-16', 1),
('Gustavo Lopes', '10000000036', 'gustavo.lopes36@aluno.iesb.edu.br', '(61) 98888-0036', '2004-12-05', 1),
('Felipe Soares', '10000000037', 'felipe.soares37@aluno.iesb.edu.br', '(61) 98888-0037', '2005-01-24', 1),
('Rafael Fernandes', '10000000038', 'rafael.fernandes38@aluno.iesb.edu.br', '(61) 98888-0038', '2005-03-15', 1),
('João Vieira', '10000000039', 'joao.vieira39@aluno.iesb.edu.br', '(61) 98888-0039', '2005-05-04', 1),
('Enzo Barbosa', '10000000040', 'enzo.barbosa40@aluno.iesb.edu.br', '(61) 98888-0040', '2005-06-23', 1),
('Arthur Silva', '10000000041', 'arthur.silva41@aluno.iesb.edu.br', '(61) 98888-0041', '2005-08-12', 1),
('Diego Santos', '10000000042', 'diego.santos42@aluno.iesb.edu.br', '(61) 98888-0042', '2005-10-01', 1),
('Bruno Oliveira', '10000000043', 'bruno.oliveira43@aluno.iesb.edu.br', '(61) 98888-0043', '2005-11-20', 1),
('Rodrigo Souza', '10000000044', 'rodrigo.souza44@aluno.iesb.edu.br', '(61) 98888-0044', '2006-01-09', 1),
('Thiago Rodrigues', '10000000045', 'thiago.rodrigues45@aluno.iesb.edu.br', '(61) 98888-0045', '2006-02-28', 1),
('Luan Ferreira', '10000000046', 'luan.ferreira46@aluno.iesb.edu.br', '(61) 98888-0046', '2006-04-19', 1),
('Vitor Alves', '10000000047', 'vitor.alves47@aluno.iesb.edu.br', '(61) 98888-0047', '2006-06-08', 1),
('Leonardo Pereira', '10000000048', 'leonardo.pereira48@aluno.iesb.edu.br', '(61) 98888-0048', '2006-07-27', 1),
('Caio Lima', '10000000049', 'caio.lima49@aluno.iesb.edu.br', '(61) 98888-0049', '2006-09-15', 1),
('Daniel Gomes', '10000000050', 'daniel.gomes50@aluno.iesb.edu.br', '(61) 98888-0050', '2006-11-04', 1),
('Maria Costa', '10000000051', 'maria.costa51@aluno.iesb.edu.br', '(61) 98888-0051', '2006-12-24', 1),
('Ana Ribeiro', '10000000052', 'ana.ribeiro52@aluno.iesb.edu.br', '(61) 98888-0052', '2007-02-12', 1),
('Julia Martins', '10000000053', 'julia.martins53@aluno.iesb.edu.br', '(61) 98888-0053', '2007-04-03', 1),
('Sophia Carvalho', '10000000054', 'sophia.carvalho54@aluno.iesb.edu.br', '(61) 98888-0054', '2007-05-23', 1),
('Larissa Almeida', '10000000055', 'larissa.almeida55@aluno.iesb.edu.br', '(61) 98888-0055', '2007-07-12', 1),
('Beatriz Lopes', '10000000056', 'beatriz.lopes56@aluno.iesb.edu.br', '(61) 98888-0056', '2007-08-31', 1),
('Mariana Soares', '10000000057', 'mariana.soares57@aluno.iesb.edu.br', '(61) 98888-0057', '2007-10-20', 1),
('Gabriela Fernandes', '10000000058', 'gabriela.fernandes58@aluno.iesb.edu.br', '(61) 98888-0058', '2007-12-09', 1),
('Camila Vieira', '10000000059', 'camila.vieira59@aluno.iesb.edu.br', '(61) 98888-0059', '2008-01-28', 1),
('Leticia Barbosa', '10000000060', 'leticia.barbosa60@aluno.iesb.edu.br', '(61) 98888-0060', '2008-03-18', 1),
('Lucas Silva', '10000000061', 'lucas.silva61@aluno.iesb.edu.br', '(61) 98888-0061', '2008-05-07', 1),
('Gabriel Santos', '10000000062', 'gabriel.santos62@aluno.iesb.edu.br', '(61) 98888-0062', '2008-06-26', 1),
('Matheus Oliveira', '10000000063', 'matheus.oliveira63@aluno.iesb.edu.br', '(61) 98888-0063', '2008-08-15', 1),
('Pedro Souza', '10000000064', 'pedro.souza64@aluno.iesb.edu.br', '(61) 98888-0064', '2008-10-04', 1),
('Guilherme Rodrigues', '10000000065', 'guilherme.rodrigues65@aluno.iesb.edu.br', '(61) 98888-0065', '2008-11-23', 1),
('Gustavo Ferreira', '10000000066', 'gustavo.ferreira66@aluno.iesb.edu.br', '(61) 98888-0066', '2009-01-12', 1),
('Felipe Alves', '10000000067', 'felipe.alves67@aluno.iesb.edu.br', '(61) 98888-0067', '2009-03-03', 1),
('Rafael Pereira', '10000000068', 'rafael.pereira68@aluno.iesb.edu.br', '(61) 98888-0068', '2009-04-22', 1),
('João Lima', '10000000069', 'joao.lima69@aluno.iesb.edu.br', '(61) 98888-0069', '2009-06-11', 1),
('Enzo Gomes', '10000000070', 'enzo.gomes70@aluno.iesb.edu.br', '(61) 98888-0070', '2009-07-31', 1),
('Arthur Costa', '10000000071', 'arthur.costa71@aluno.iesb.edu.br', '(61) 98888-0071', '2009-09-19', 1),
('Diego Ribeiro', '10000000072', 'diego.ribeiro72@aluno.iesb.edu.br', '(61) 98888-0072', '2009-11-08', 1),
('Bruno Martins', '10000000073', 'bruno.martins73@aluno.iesb.edu.br', '(61) 98888-0073', '2009-12-28', 1),
('Rodrigo Carvalho', '10000000074', 'rodrigo.carvalho74@aluno.iesb.edu.br', '(61) 98888-0074', '2010-02-16', 1),
('Thiago Almeida', '10000000075', 'thiago.almeida75@aluno.iesb.edu.br', '(61) 98888-0075', '2010-04-07', 1),
('Luan Lopes', '10000000076', 'luan.lopes76@aluno.iesb.edu.br', '(61) 98888-0076', '2010-05-27', 1),
('Vitor Soares', '10000000077', 'vitor.soares77@aluno.iesb.edu.br', '(61) 98888-0077', '2010-07-16', 1),
('Leonardo Fernandes', '10000000078', 'leonardo.fernandes78@aluno.iesb.edu.br', '(61) 98888-0078', '2010-09-04', 1),
('Caio Vieira', '10000000079', 'caio.vieira79@aluno.iesb.edu.br', '(61) 98888-0079', '2010-10-24', 1),
('Daniel Barbosa', '10000000080', 'daniel.barbosa80@aluno.iesb.edu.br', '(61) 98888-0080', '2010-12-13', 1),
('Maria Silva', '10000000081', 'maria.silva81@aluno.iesb.edu.br', '(61) 98888-0081', '2011-02-01', 1),
('Ana Santos', '10000000082', 'ana.santos82@aluno.iesb.edu.br', '(61) 98888-0082', '2011-03-23', 1),
('Julia Oliveira', '10000000083', 'julia.oliveira83@aluno.iesb.edu.br', '(61) 98888-0083', '2011-05-12', 1),
('Sophia Souza', '10000000084', 'sophia.souza84@aluno.iesb.edu.br', '(61) 98888-0084', '2011-07-01', 1),
('Larissa Rodrigues', '10000000085', 'larissa.rodrigues85@aluno.iesb.edu.br', '(61) 98888-0085', '2011-08-20', 1),
('Beatriz Ferreira', '10000000086', 'beatriz.ferreira86@aluno.iesb.edu.br', '(61) 98888-0086', '2011-10-09', 1),
('Mariana Alves', '10000000087', 'mariana.alves87@aluno.iesb.edu.br', '(61) 98888-0087', '2011-11-28', 1),
('Gabriela Pereira', '10000000088', 'gabriela.pereira88@aluno.iesb.edu.br', '(61) 98888-0088', '2012-01-17', 1),
('Camila Lima', '10000000089', 'camila.lima89@aluno.iesb.edu.br', '(61) 98888-0089', '2012-03-07', 1),
('Leticia Gomes', '10000000090', 'leticia.gomes90@aluno.iesb.edu.br', '(61) 98888-0090', '2012-04-26', 1),
('Lucas Costa', '10000000091', 'lucas.costa91@aluno.iesb.edu.br', '(61) 98888-0091', '2012-06-15', 1),
('Gabriel Ribeiro', '10000000092', 'gabriel.ribeiro92@aluno.iesb.edu.br', '(61) 98888-0092', '2012-08-04', 1),
('Matheus Martins', '10000000093', 'matheus.martins93@aluno.iesb.edu.br', '(61) 98888-0093', '2012-09-23', 1),
('Pedro Carvalho', '10000000094', 'pedro.carvalho94@aluno.iesb.edu.br', '(61) 98888-0094', '2012-11-12', 1),
('Guilherme Almeida', '10000000095', 'guilherme.almeida95@aluno.iesb.edu.br', '(61) 98888-0095', '2013-01-01', 1),
('Gustavo Lopes', '10000000096', 'gustavo.lopes96@aluno.iesb.edu.br', '(61) 98888-0096', '2013-02-20', 1),
('Felipe Soares', '10000000097', 'felipe.soares97@aluno.iesb.edu.br', '(61) 98888-0097', '2013-04-11', 1),
('Rafael Fernandes', '10000000098', 'rafael.fernandes98@aluno.iesb.edu.br', '(61) 98888-0098', '2013-05-31', 1),
('João Vieira', '10000000099', 'joao.vieira99@aluno.iesb.edu.br', '(61) 98888-0099', '2013-07-20', 1),
('Enzo Barbosa', '10000000100', 'enzo.barbosa100@aluno.iesb.edu.br', '(61) 98888-0100', '2013-09-08', 1);

-- Passo 2: Inserção dos alunos na tabela tb_aluno utilizando subconsultas por CPF
-- (Currículo 1 = Ciência da Computação, Currículo 2 = Engenharia de Software)

-- =====================================================================
-- CARGA COMPLETA DOS 100 ALUNOS NA TABELA TB_ALUNO
-- =====================================================================

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(11, '202612000001', 1, '2026-02-01', 'ATIVO'),
(12, '202612000002', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(13, '202612000003', 1, '2026-02-01', 'ATIVO'),
(14, '202612000004', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(15, '202612000005', 1, '2026-02-01', 'ATIVO'),
(16, '202612000006', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(17, '202612000007', 1, '2026-02-01', 'ATIVO'),
(18, '202612000008', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(19, '202612000009', 1, '2026-02-01', 'ATIVO'),
(20, '202612000010', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(21, '202612000011', 1, '2026-02-01', 'ATIVO'),
(22, '202612000012', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(23, '202612000013', 1, '2026-02-01', 'ATIVO'),
(24, '202612000014', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(25, '202612000015', 1, '2026-02-01', 'ATIVO'),
(26, '202612000016', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(27, '202612000017', 1, '2026-02-01', 'ATIVO'),
(28, '202612000018', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(29, '202612000019', 1, '2026-02-01', 'ATIVO'),
(30, '202612000020', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(31, '202612000021', 1, '2026-02-01', 'ATIVO'),
(32, '202612000022', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(33, '202612000023', 1, '2026-02-01', 'ATIVO'),
(34, '202612000024', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(35, '202612000025', 1, '2026-02-01', 'ATIVO'),
(36, '202612000026', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(37, '202612000027', 1, '2026-02-01', 'ATIVO'),
(38, '202612000028', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(39, '202612000029', 1, '2026-02-01', 'ATIVO'),
(40, '202612000030', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(41, '202612000031', 1, '2026-02-01', 'ATIVO'),
(42, '202612000032', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(43, '202612000033', 1, '2026-02-01', 'ATIVO'),
(44, '202612000034', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(45, '202612000035', 1, '2026-02-01', 'ATIVO'),
(46, '202612000036', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(47, '202612000037', 1, '2026-02-01', 'ATIVO'),
(48, '202612000038', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(49, '202612000039', 1, '2026-02-01', 'ATIVO'),
(50, '202612000040', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(51, '202612000041', 1, '2026-02-01', 'ATIVO'),
(52, '202612000042', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(53, '202612000043', 1, '2026-02-01', 'ATIVO'),
(54, '202612000044', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(55, '202612000045', 1, '2026-02-01', 'ATIVO'),
(56, '202612000046', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(57, '202612000047', 1, '2026-02-01', 'ATIVO'),
(58, '202612000048', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(59, '202612000049', 1, '2026-02-01', 'ATIVO'),
(60, '202612000050', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(61, '202612000051', 1, '2026-02-01', 'ATIVO'),
(62, '202612000052', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(63, '202612000053', 1, '2026-02-01', 'ATIVO'),
(64, '202612000054', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(65, '202612000055', 1, '2026-02-01', 'ATIVO'),
(66, '202612000056', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(67, '202612000057', 1, '2026-02-01', 'ATIVO'),
(68, '202612000058', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(69, '202612000059', 1, '2026-02-01', 'ATIVO'),
(70, '202612000060', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(71, '202612000061', 1, '2026-02-01', 'ATIVO'),
(72, '202612000062', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(73, '202612000063', 1, '2026-02-01', 'ATIVO'),
(74, '202612000064', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(75, '202612000065', 1, '2026-02-01', 'ATIVO'),
(76, '202612000066', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(77, '202612000067', 1, '2026-02-01', 'ATIVO'),
(78, '202612000068', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(79, '202612000069', 1, '2026-02-01', 'ATIVO'),
(80, '202612000070', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(81, '202612000071', 1, '2026-02-01', 'ATIVO'),
(82, '202612000072', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(83, '202612000073', 1, '2026-02-01', 'ATIVO'),
(84, '202612000074', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(85, '202612000075', 1, '2026-02-01', 'ATIVO'),
(86, '202612000076', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(87, '202612000077', 1, '2026-02-01', 'ATIVO'),
(88, '202612000078', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(89, '202612000079', 1, '2026-02-01', 'ATIVO'),
(90, '202612000080', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(91, '202612000081', 1, '2026-02-01', 'ATIVO'),
(92, '202612000082', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(93, '202612000083', 1, '2026-02-01', 'ATIVO'),
(94, '202612000084', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(95, '202612000085', 1, '2026-02-01', 'ATIVO'),
(96, '202612000086', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(97, '202612000087', 1, '2026-02-01', 'ATIVO'),
(98, '202612000088', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(99, '202612000089', 1, '2026-02-01', 'ATIVO'),
(100, '202612000090', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(101, '202612000091', 1, '2026-02-01', 'ATIVO'),
(102, '202612000092', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(103, '202612000093', 1, '2026-02-01', 'ATIVO'),
(104, '202612000094', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(105, '202612000095', 1, '2026-02-01', 'ATIVO'),
(106, '202612000096', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(107, '202612000097', 1, '2026-02-01', 'ATIVO'),
(108, '202612000098', 2, '2026-02-01', 'ATIVO');

INSERT INTO tb_aluno (id_pessoa, matricula_aluno, id_curriculo, ingresso_aluno, status_detalhado_aluno) VALUES
(109, '202612000099', 1, '2026-02-01', 'ATIVO'),
(110, '202612000100', 2, '2026-02-01', 'ATIVO');


-- =====================================================================
-- 7. TURMAS E HORÁRIOS NOTURNOS
-- =====================================================================
INSERT INTO tb_turma (codigo_turma, id_disciplina, id_periodo_letivo, id_professor, turno_turma, vagas_turma)
VALUES 
('CCONM2B', 1, 1, 1, 'NOTURNO', 60),
('ENGCNM2B', 2, 1, 2, 'NOTURNO', 60),
('CCONM2B', 3, 1, 3, 'NOTURNO', 60),
('ENGCNM2B', 4, 1, 4, 'NOTURNO', 60),
('ENGCNM2B', 5, 1, 5, 'NOTURNO', 60),
('ENGCNM3B', 6, 1, 6, 'NOTURNO', 60);

INSERT INTO tb_turma_horario (id_turma, id_periodo_letivo, id_professor, id_sala, dia_semana_turma_horario, faixa_turma_horario, modalidade_turma_horario)
VALUES 
(1, 1, 1, 1, 2, timerange('19:15:00', '22:00:00'), 'PRESENCIAL'),
(2, 1, 2, 2, 3, timerange('19:15:00', '22:00:00'), 'PRESENCIAL'),
(3, 1, 3, 3, 4, timerange('19:15:00', '22:00:00'), 'PRESENCIAL'),
(4, 1, 4, 4, 5, timerange('19:15:00', '22:00:00'), 'PRESENCIAL'),
(5, 1, 5, 5, 6, timerange('19:15:00', '22:00:00'), 'PRESENCIAL'),
(6, 1, 6, 6, 7, timerange('19:15:00', '22:00:00'), 'PRESENCIAL');


-- =====================================================================
-- 8. MATRÍCULAS E HISTÓRICO ACADÊMICO (300 Matrículas)
-- =====================================================================


-- Cada aluno foi matriculado em 3 turmas diferentes (100 x 3 = 300 matrículas).
-- Nenhuma turma passa de 60 vagas.

-- Turma 1 - Banco De Dados II (49 alunos)
INSERT INTO tb_matricula (id_aluno, id_turma, data_matricula, status_matricula) VALUES
(1, 1, '2026-08-03', 'MATRICULADO'), (5, 1, '2026-08-03', 'MATRICULADO'), (6, 1, '2026-08-03', 'MATRICULADO'), (7, 1, '2026-08-03', 'MATRICULADO'),
(11, 1, '2026-08-03', 'MATRICULADO'), (12, 1, '2026-08-03', 'MATRICULADO'), (13, 1, '2026-08-03', 'MATRICULADO'), (17, 1, '2026-08-03', 'MATRICULADO'),
(18, 1, '2026-08-03', 'MATRICULADO'), (19, 1, '2026-08-03', 'MATRICULADO'), (23, 1, '2026-08-03', 'MATRICULADO'), (24, 1, '2026-08-03', 'MATRICULADO'),
(25, 1, '2026-08-03', 'MATRICULADO'), (29, 1, '2026-08-03', 'MATRICULADO'), (30, 1, '2026-08-03', 'MATRICULADO'), (31, 1, '2026-08-03', 'MATRICULADO'),
(35, 1, '2026-08-03', 'MATRICULADO'), (36, 1, '2026-08-03', 'MATRICULADO'), (37, 1, '2026-08-03', 'MATRICULADO'), (41, 1, '2026-08-03', 'MATRICULADO'),
(42, 1, '2026-08-03', 'MATRICULADO'), (43, 1, '2026-08-03', 'MATRICULADO'), (47, 1, '2026-08-03', 'MATRICULADO'), (48, 1, '2026-08-03', 'MATRICULADO'),
(49, 1, '2026-08-03', 'MATRICULADO'), (53, 1, '2026-08-03', 'MATRICULADO'), (54, 1, '2026-08-03', 'MATRICULADO'), (55, 1, '2026-08-03', 'MATRICULADO'),
(59, 1, '2026-08-03', 'MATRICULADO'), (60, 1, '2026-08-03', 'MATRICULADO'), (61, 1, '2026-08-03', 'MATRICULADO'), (65, 1, '2026-08-03', 'MATRICULADO'),
(66, 1, '2026-08-03', 'MATRICULADO'), (67, 1, '2026-08-03', 'MATRICULADO'), (71, 1, '2026-08-03', 'MATRICULADO'), (72, 1, '2026-08-03', 'MATRICULADO'),
(73, 1, '2026-08-03', 'MATRICULADO'), (77, 1, '2026-08-03', 'MATRICULADO'), (78, 1, '2026-08-03', 'MATRICULADO'), (79, 1, '2026-08-03', 'MATRICULADO'),
(83, 1, '2026-08-03', 'MATRICULADO'), (84, 1, '2026-08-03', 'MATRICULADO'), (85, 1, '2026-08-03', 'MATRICULADO'), (89, 1, '2026-08-03', 'MATRICULADO'),
(90, 1, '2026-08-03', 'MATRICULADO'), (91, 1, '2026-08-03', 'MATRICULADO'), (95, 1, '2026-08-03', 'MATRICULADO'), (96, 1, '2026-08-03', 'MATRICULADO'),
(97, 1, '2026-08-03', 'MATRICULADO');

-- Turma 2 - Engenharia De Software (50 alunos)
INSERT INTO tb_matricula (id_aluno, id_turma, data_matricula, status_matricula) VALUES
(1, 2, '2026-08-03', 'MATRICULADO'), (2, 2, '2026-08-03', 'MATRICULADO'), (6, 2, '2026-08-03', 'MATRICULADO'), (7, 2, '2026-08-03', 'MATRICULADO'),
(8, 2, '2026-08-03', 'MATRICULADO'), (12, 2, '2026-08-03', 'MATRICULADO'), (13, 2, '2026-08-03', 'MATRICULADO'), (14, 2, '2026-08-03', 'MATRICULADO'),
(18, 2, '2026-08-03', 'MATRICULADO'), (19, 2, '2026-08-03', 'MATRICULADO'), (20, 2, '2026-08-03', 'MATRICULADO'), (24, 2, '2026-08-03', 'MATRICULADO'),
(25, 2, '2026-08-03', 'MATRICULADO'), (26, 2, '2026-08-03', 'MATRICULADO'), (30, 2, '2026-08-03', 'MATRICULADO'), (31, 2, '2026-08-03', 'MATRICULADO'),
(32, 2, '2026-08-03', 'MATRICULADO'), (36, 2, '2026-08-03', 'MATRICULADO'), (37, 2, '2026-08-03', 'MATRICULADO'), (38, 2, '2026-08-03', 'MATRICULADO'),
(42, 2, '2026-08-03', 'MATRICULADO'), (43, 2, '2026-08-03', 'MATRICULADO'), (44, 2, '2026-08-03', 'MATRICULADO'), (48, 2, '2026-08-03', 'MATRICULADO'),
(49, 2, '2026-08-03', 'MATRICULADO'), (50, 2, '2026-08-03', 'MATRICULADO'), (54, 2, '2026-08-03', 'MATRICULADO'), (55, 2, '2026-08-03', 'MATRICULADO'),
(56, 2, '2026-08-03', 'MATRICULADO'), (60, 2, '2026-08-03', 'MATRICULADO'), (61, 2, '2026-08-03', 'MATRICULADO'), (62, 2, '2026-08-03', 'MATRICULADO'),
(66, 2, '2026-08-03', 'MATRICULADO'), (67, 2, '2026-08-03', 'MATRICULADO'), (68, 2, '2026-08-03', 'MATRICULADO'), (72, 2, '2026-08-03', 'MATRICULADO'),
(73, 2, '2026-08-03', 'MATRICULADO'), (74, 2, '2026-08-03', 'MATRICULADO'), (78, 2, '2026-08-03', 'MATRICULADO'), (79, 2, '2026-08-03', 'MATRICULADO'),
(80, 2, '2026-08-03', 'MATRICULADO'), (84, 2, '2026-08-03', 'MATRICULADO'), (85, 2, '2026-08-03', 'MATRICULADO'), (86, 2, '2026-08-03', 'MATRICULADO'),
(90, 2, '2026-08-03', 'MATRICULADO'), (91, 2, '2026-08-03', 'MATRICULADO'), (92, 2, '2026-08-03', 'MATRICULADO'), (96, 2, '2026-08-03', 'MATRICULADO'),
(97, 2, '2026-08-03', 'MATRICULADO'), (98, 2, '2026-08-03', 'MATRICULADO');

-- Turma 3 - Governança De TI (51 alunos)
INSERT INTO tb_matricula (id_aluno, id_turma, data_matricula, status_matricula) VALUES
(1, 3, '2026-08-04', 'MATRICULADO'), (2, 3, '2026-08-04', 'MATRICULADO'), (3, 3, '2026-08-04', 'MATRICULADO'), (7, 3, '2026-08-04', 'MATRICULADO'),
(8, 3, '2026-08-04', 'MATRICULADO'), (9, 3, '2026-08-04', 'MATRICULADO'), (13, 3, '2026-08-04', 'MATRICULADO'), (14, 3, '2026-08-04', 'MATRICULADO'),
(15, 3, '2026-08-04', 'MATRICULADO'), (19, 3, '2026-08-04', 'MATRICULADO'), (20, 3, '2026-08-04', 'MATRICULADO'), (21, 3, '2026-08-04', 'MATRICULADO'),
(25, 3, '2026-08-04', 'MATRICULADO'), (26, 3, '2026-08-04', 'MATRICULADO'), (27, 3, '2026-08-04', 'MATRICULADO'), (31, 3, '2026-08-04', 'MATRICULADO'),
(32, 3, '2026-08-04', 'MATRICULADO'), (33, 3, '2026-08-04', 'MATRICULADO'), (37, 3, '2026-08-04', 'MATRICULADO'), (38, 3, '2026-08-04', 'MATRICULADO'),
(39, 3, '2026-08-04', 'MATRICULADO'), (43, 3, '2026-08-04', 'MATRICULADO'), (44, 3, '2026-08-04', 'MATRICULADO'), (45, 3, '2026-08-04', 'MATRICULADO'),
(49, 3, '2026-08-04', 'MATRICULADO'), (50, 3, '2026-08-04', 'MATRICULADO'), (51, 3, '2026-08-04', 'MATRICULADO'), (55, 3, '2026-08-04', 'MATRICULADO'),
(56, 3, '2026-08-04', 'MATRICULADO'), (57, 3, '2026-08-04', 'MATRICULADO'), (61, 3, '2026-08-04', 'MATRICULADO'), (62, 3, '2026-08-04', 'MATRICULADO'),
(63, 3, '2026-08-04', 'MATRICULADO'), (67, 3, '2026-08-04', 'MATRICULADO'), (68, 3, '2026-08-04', 'MATRICULADO'), (69, 3, '2026-08-04', 'MATRICULADO'),
(73, 3, '2026-08-04', 'MATRICULADO'), (74, 3, '2026-08-04', 'MATRICULADO'), (75, 3, '2026-08-04', 'MATRICULADO'), (79, 3, '2026-08-04', 'MATRICULADO'),
(80, 3, '2026-08-04', 'MATRICULADO'), (81, 3, '2026-08-04', 'MATRICULADO'), (85, 3, '2026-08-04', 'MATRICULADO'), (86, 3, '2026-08-04', 'MATRICULADO'),
(87, 3, '2026-08-04', 'MATRICULADO'), (91, 3, '2026-08-04', 'MATRICULADO'), (92, 3, '2026-08-04', 'MATRICULADO'), (93, 3, '2026-08-04', 'MATRICULADO'),
(97, 3, '2026-08-04', 'MATRICULADO'), (98, 3, '2026-08-04', 'MATRICULADO'), (99, 3, '2026-08-04', 'MATRICULADO');

-- Turma 4 - Inteligência Artificial (51 alunos)
INSERT INTO tb_matricula (id_aluno, id_turma, data_matricula, status_matricula) VALUES
(2, 4, '2026-08-04', 'MATRICULADO'), (3, 4, '2026-08-04', 'MATRICULADO'), (4, 4, '2026-08-04', 'MATRICULADO'), (8, 4, '2026-08-04', 'MATRICULADO'),
(9, 4, '2026-08-04', 'MATRICULADO'), (10, 4, '2026-08-04', 'MATRICULADO'), (14, 4, '2026-08-04', 'MATRICULADO'), (15, 4, '2026-08-04', 'MATRICULADO'),
(16, 4, '2026-08-04', 'MATRICULADO'), (20, 4, '2026-08-04', 'MATRICULADO'), (21, 4, '2026-08-04', 'MATRICULADO'), (22, 4, '2026-08-04', 'MATRICULADO'),
(26, 4, '2026-08-04', 'MATRICULADO'), (27, 4, '2026-08-04', 'MATRICULADO'), (28, 4, '2026-08-04', 'MATRICULADO'), (32, 4, '2026-08-04', 'MATRICULADO'),
(33, 4, '2026-08-04', 'MATRICULADO'), (34, 4, '2026-08-04', 'MATRICULADO'), (38, 4, '2026-08-04', 'MATRICULADO'), (39, 4, '2026-08-04', 'MATRICULADO'),
(40, 4, '2026-08-04', 'MATRICULADO'), (44, 4, '2026-08-04', 'MATRICULADO'), (45, 4, '2026-08-04', 'MATRICULADO'), (46, 4, '2026-08-04', 'MATRICULADO'),
(50, 4, '2026-08-04', 'MATRICULADO'), (51, 4, '2026-08-04', 'MATRICULADO'), (52, 4, '2026-08-04', 'MATRICULADO'), (56, 4, '2026-08-04', 'MATRICULADO'),
(57, 4, '2026-08-04', 'MATRICULADO'), (58, 4, '2026-08-04', 'MATRICULADO'), (62, 4, '2026-08-04', 'MATRICULADO'), (63, 4, '2026-08-04', 'MATRICULADO'),
(64, 4, '2026-08-04', 'MATRICULADO'), (68, 4, '2026-08-04', 'MATRICULADO'), (69, 4, '2026-08-04', 'MATRICULADO'), (70, 4, '2026-08-04', 'MATRICULADO'),
(74, 4, '2026-08-04', 'MATRICULADO'), (75, 4, '2026-08-04', 'MATRICULADO'), (76, 4, '2026-08-04', 'MATRICULADO'), (80, 4, '2026-08-04', 'MATRICULADO'),
(81, 4, '2026-08-04', 'MATRICULADO'), (82, 4, '2026-08-04', 'MATRICULADO'), (86, 4, '2026-08-04', 'MATRICULADO'), (87, 4, '2026-08-04', 'MATRICULADO'),
(88, 4, '2026-08-04', 'MATRICULADO'), (92, 4, '2026-08-04', 'MATRICULADO'), (93, 4, '2026-08-04', 'MATRICULADO'), (94, 4, '2026-08-04', 'MATRICULADO'),
(98, 4, '2026-08-04', 'MATRICULADO'), (99, 4, '2026-08-04', 'MATRICULADO'), (100, 4, '2026-08-04', 'MATRICULADO');

-- Turma 5 - Programação Orientada A Objetos (50 alunos)
INSERT INTO tb_matricula (id_aluno, id_turma, data_matricula, status_matricula) VALUES
(3, 5, '2026-08-05', 'MATRICULADO'), (4, 5, '2026-08-05', 'MATRICULADO'), (5, 5, '2026-08-05', 'MATRICULADO'), (9, 5, '2026-08-05', 'MATRICULADO'),
(10, 5, '2026-08-05', 'MATRICULADO'), (11, 5, '2026-08-05', 'MATRICULADO'), (15, 5, '2026-08-05', 'MATRICULADO'), (16, 5, '2026-08-05', 'MATRICULADO'),
(17, 5, '2026-08-05', 'MATRICULADO'), (21, 5, '2026-08-05', 'MATRICULADO'), (22, 5, '2026-08-05', 'MATRICULADO'), (23, 5, '2026-08-05', 'MATRICULADO'),
(27, 5, '2026-08-05', 'MATRICULADO'), (28, 5, '2026-08-05', 'MATRICULADO'), (29, 5, '2026-08-05', 'MATRICULADO'), (33, 5, '2026-08-05', 'MATRICULADO'),
(34, 5, '2026-08-05', 'MATRICULADO'), (35, 5, '2026-08-05', 'MATRICULADO'), (39, 5, '2026-08-05', 'MATRICULADO'), (40, 5, '2026-08-05', 'MATRICULADO'),
(41, 5, '2026-08-05', 'MATRICULADO'), (45, 5, '2026-08-05', 'MATRICULADO'), (46, 5, '2026-08-05', 'MATRICULADO'), (47, 5, '2026-08-05', 'MATRICULADO'),
(51, 5, '2026-08-05', 'MATRICULADO'), (52, 5, '2026-08-05', 'MATRICULADO'), (53, 5, '2026-08-05', 'MATRICULADO'), (57, 5, '2026-08-05', 'MATRICULADO'),
(58, 5, '2026-08-05', 'MATRICULADO'), (59, 5, '2026-08-05', 'MATRICULADO'), (63, 5, '2026-08-05', 'MATRICULADO'), (64, 5, '2026-08-05', 'MATRICULADO'),
(65, 5, '2026-08-05', 'MATRICULADO'), (69, 5, '2026-08-05', 'MATRICULADO'), (70, 5, '2026-08-05', 'MATRICULADO'), (71, 5, '2026-08-05', 'MATRICULADO'),
(75, 5, '2026-08-05', 'MATRICULADO'), (76, 5, '2026-08-05', 'MATRICULADO'), (77, 5, '2026-08-05', 'MATRICULADO'), (81, 5, '2026-08-05', 'MATRICULADO'),
(82, 5, '2026-08-05', 'MATRICULADO'), (83, 5, '2026-08-05', 'MATRICULADO'), (87, 5, '2026-08-05', 'MATRICULADO'), (88, 5, '2026-08-05', 'MATRICULADO'),
(89, 5, '2026-08-05', 'MATRICULADO'), (93, 5, '2026-08-05', 'MATRICULADO'), (94, 5, '2026-08-05', 'MATRICULADO'), (95, 5, '2026-08-05', 'MATRICULADO'),
(99, 5, '2026-08-05', 'MATRICULADO'), (100, 5, '2026-08-05', 'MATRICULADO');

-- Turma 6 - Sistemas Operacionais (49 alunos)
INSERT INTO tb_matricula (id_aluno, id_turma, data_matricula, status_matricula) VALUES
(4, 6, '2026-08-05', 'MATRICULADO'), (5, 6, '2026-08-05', 'MATRICULADO'), (6, 6, '2026-08-05', 'MATRICULADO'), (10, 6, '2026-08-05', 'MATRICULADO'),
(11, 6, '2026-08-05', 'MATRICULADO'), (12, 6, '2026-08-05', 'MATRICULADO'), (16, 6, '2026-08-05', 'MATRICULADO'), (17, 6, '2026-08-05', 'MATRICULADO'),
(18, 6, '2026-08-05', 'MATRICULADO'), (22, 6, '2026-08-05', 'MATRICULADO'), (23, 6, '2026-08-05', 'MATRICULADO'), (24, 6, '2026-08-05', 'MATRICULADO'),
(28, 6, '2026-08-05', 'MATRICULADO'), (29, 6, '2026-08-05', 'MATRICULADO'), (30, 6, '2026-08-05', 'MATRICULADO'), (34, 6, '2026-08-05', 'MATRICULADO'),
(35, 6, '2026-08-05', 'MATRICULADO'), (36, 6, '2026-08-05', 'MATRICULADO'), (40, 6, '2026-08-05', 'MATRICULADO'), (41, 6, '2026-08-05', 'MATRICULADO'),
(42, 6, '2026-08-05', 'MATRICULADO'), (46, 6, '2026-08-05', 'MATRICULADO'), (47, 6, '2026-08-05', 'MATRICULADO'), (48, 6, '2026-08-05', 'MATRICULADO'),
(52, 6, '2026-08-05', 'MATRICULADO'), (53, 6, '2026-08-05', 'MATRICULADO'), (54, 6, '2026-08-05', 'MATRICULADO'), (58, 6, '2026-08-05', 'MATRICULADO'),
(59, 6, '2026-08-05', 'MATRICULADO'), (60, 6, '2026-08-05', 'MATRICULADO'), (64, 6, '2026-08-05', 'MATRICULADO'), (65, 6, '2026-08-05', 'MATRICULADO'),
(66, 6, '2026-08-05', 'MATRICULADO'), (70, 6, '2026-08-05', 'MATRICULADO'), (71, 6, '2026-08-05', 'MATRICULADO'), (72, 6, '2026-08-05', 'MATRICULADO'),
(76, 6, '2026-08-05', 'MATRICULADO'), (77, 6, '2026-08-05', 'MATRICULADO'), (78, 6, '2026-08-05', 'MATRICULADO'), (82, 6, '2026-08-05', 'MATRICULADO'),
(83, 6, '2026-08-05', 'MATRICULADO'), (84, 6, '2026-08-05', 'MATRICULADO'), (88, 6, '2026-08-05', 'MATRICULADO'), (89, 6, '2026-08-05', 'MATRICULADO'),
(90, 6, '2026-08-05', 'MATRICULADO'), (94, 6, '2026-08-05', 'MATRICULADO'), (95, 6, '2026-08-05', 'MATRICULADO'), (96, 6, '2026-08-05', 'MATRICULADO'),
(100, 6, '2026-08-05', 'MATRICULADO');

-- Log das 5 primeiras matrículas (exemplo de como a secretaria registra)
INSERT INTO tb_log_matricula (id_matricula, acao_log_matricula, ocorrido_em_log_matricula, usuario_log_matricula, detalhe_log_matricula) VALUES
(1, 'INSERT', '2026-08-03 10:00:00-03', 'sec_maria', '{"id_aluno": 1, "id_turma": 1, "status_matricula": "MATRICULADO"}'),
(2, 'INSERT', '2026-08-03 10:00:00-03', 'sec_maria', '{"id_aluno": 5, "id_turma": 1, "status_matricula": "MATRICULADO"}'),
(3, 'INSERT', '2026-08-03 10:00:00-03', 'sec_maria', '{"id_aluno": 6, "id_turma": 1, "status_matricula": "MATRICULADO"}'),
(4, 'INSERT', '2026-08-03 10:00:00-03', 'sec_maria', '{"id_aluno": 7, "id_turma": 1, "status_matricula": "MATRICULADO"}'),
(5, 'INSERT', '2026-08-03 10:00:00-03', 'sec_maria', '{"id_aluno": 11, "id_turma": 1, "status_matricula": "MATRICULADO"}');

-- 2. Inserção no Histórico (Notas e Frequência vinculadas às matrículas criadas)
-- Histórico para a primeira matrícula (A1 = 7.50, A2 = 8.00, P3 = NULL, Frequência = 90.00)
INSERT INTO tb_historico (id_matricula, nota_a1_historico, nota_a2_historico, nota_p3_historico, frequencia_historico) VALUES
(1, 7.50, 8.00, NULL, 90.00);

-- Histórico para a segunda matrícula (A1 = 5.00, A2 = 6.00, P3 = 7.00, Frequência = 85.00)
INSERT INTO tb_historico (id_matricula, nota_a1_historico, nota_a2_historico, nota_p3_historico, frequencia_historico) VALUES
(51, 5.00, 6.00, 7.00, 85.00);

-- Histórico para a terceira matrícula (A1 = 8.50, A2 = 9.00, P3 = NULL, Frequência = 95.00)
INSERT INTO tb_historico (id_matricula, nota_a1_historico, nota_a2_historico, nota_p3_historico, frequencia_historico) VALUES
(102, 8.50, 9.00, NULL, 95.00);


-- =====================================================================
-- 9. AULAS E REGISTROS DE CHAMADA
-- =====================================================================
-- 1. Cria apenas UMA aula para cada horário cadastrado
INSERT INTO tb_aula (id_turma_horario, data_aula, conteudo_previsto_aula, conteudo_realizado_aula, status_aula, observacoes_aula) VALUES
(1, '2026-08-08', 'Aula Inaugural', 'Conteúdo ministrado', 'REALIZADA', 'Sem observações'),
(2, '2026-08-08', 'Aula Inaugural', 'Conteúdo ministrado', 'REALIZADA', 'Sem observações'),
(3, '2026-08-08', 'Aula Inaugural', 'Conteúdo ministrado', 'REALIZADA', 'Sem observações'),
(4, '2026-08-08', 'Aula Inaugural', 'Conteúdo ministrado', 'REALIZADA', 'Sem observações'),
(5, '2026-08-08', 'Aula Inaugural', 'Conteúdo ministrado', 'REALIZADA', 'Sem observações'),
(6, '2026-08-08', 'Aula Inaugural', 'Conteúdo ministrado', 'REALIZADA', 'Sem observações');

-- 2. Presença (TRUE) para todos os alunos matriculados: (id_aula, id_matricula, presente)
INSERT INTO tb_chamada (id_aula, id_matricula, presente_chamada) VALUES
(1, 1, TRUE), (1, 2, TRUE), (1, 3, TRUE), (1, 4, TRUE), (1, 5, TRUE), (1, 6, TRUE), (1, 7, TRUE), (1, 8, TRUE),
(1, 9, TRUE), (1, 10, TRUE), (1, 11, TRUE), (1, 12, TRUE), (1, 13, TRUE), (1, 14, TRUE), (1, 15, TRUE),
(1, 16, TRUE), (1, 17, TRUE), (1, 18, TRUE), (1, 19, TRUE), (1, 20, TRUE), (1, 21, TRUE), (1, 22, TRUE),
(1, 23, TRUE), (1, 24, TRUE), (1, 25, TRUE), (1, 26, TRUE), (1, 27, TRUE), (1, 28, TRUE), (1, 29, TRUE),
(1, 30, TRUE), (1, 31, TRUE), (1, 32, TRUE), (1, 33, TRUE), (1, 34, TRUE), (1, 35, TRUE), (1, 36, TRUE),
(1, 37, TRUE), (1, 38, TRUE), (1, 39, TRUE), (1, 40, TRUE), (1, 41, TRUE), (1, 42, TRUE), (1, 43, TRUE),
(1, 44, TRUE), (1, 45, TRUE), (1, 46, TRUE), (1, 47, TRUE), (1, 48, TRUE), (1, 49, TRUE), (2, 50, TRUE),
(2, 51, TRUE), (2, 52, TRUE), (2, 53, TRUE), (2, 54, TRUE), (2, 55, TRUE), (2, 56, TRUE), (2, 57, TRUE),
(2, 58, TRUE), (2, 59, TRUE), (2, 60, TRUE), (2, 61, TRUE), (2, 62, TRUE), (2, 63, TRUE), (2, 64, TRUE),
(2, 65, TRUE), (2, 66, TRUE), (2, 67, TRUE), (2, 68, TRUE), (2, 69, TRUE), (2, 70, TRUE), (2, 71, TRUE),
(2, 72, TRUE), (2, 73, TRUE), (2, 74, TRUE), (2, 75, TRUE), (2, 76, TRUE), (2, 77, TRUE), (2, 78, TRUE),
(2, 79, TRUE), (2, 80, TRUE), (2, 81, TRUE), (2, 82, TRUE), (2, 83, TRUE), (2, 84, TRUE), (2, 85, TRUE),
(2, 86, TRUE), (2, 87, TRUE), (2, 88, TRUE), (2, 89, TRUE), (2, 90, TRUE), (2, 91, TRUE), (2, 92, TRUE),
(2, 93, TRUE), (2, 94, TRUE), (2, 95, TRUE), (2, 96, TRUE), (2, 97, TRUE), (2, 98, TRUE), (2, 99, TRUE),
(3, 100, TRUE), (3, 101, TRUE), (3, 102, TRUE), (3, 103, TRUE), (3, 104, TRUE), (3, 105, TRUE), (3, 106, TRUE),
(3, 107, TRUE), (3, 108, TRUE), (3, 109, TRUE), (3, 110, TRUE), (3, 111, TRUE), (3, 112, TRUE), (3, 113, TRUE),
(3, 114, TRUE), (3, 115, TRUE), (3, 116, TRUE), (3, 117, TRUE), (3, 118, TRUE), (3, 119, TRUE), (3, 120, TRUE),
(3, 121, TRUE), (3, 122, TRUE), (3, 123, TRUE), (3, 124, TRUE), (3, 125, TRUE), (3, 126, TRUE), (3, 127, TRUE),
(3, 128, TRUE), (3, 129, TRUE), (3, 130, TRUE), (3, 131, TRUE), (3, 132, TRUE), (3, 133, TRUE), (3, 134, TRUE),
(3, 135, TRUE), (3, 136, TRUE), (3, 137, TRUE), (3, 138, TRUE), (3, 139, TRUE), (3, 140, TRUE), (3, 141, TRUE),
(3, 142, TRUE), (3, 143, TRUE), (3, 144, TRUE), (3, 145, TRUE), (3, 146, TRUE), (3, 147, TRUE), (3, 148, TRUE),
(3, 149, TRUE), (3, 150, TRUE), (4, 151, TRUE), (4, 152, TRUE), (4, 153, TRUE), (4, 154, TRUE), (4, 155, TRUE),
(4, 156, TRUE), (4, 157, TRUE), (4, 158, TRUE), (4, 159, TRUE), (4, 160, TRUE), (4, 161, TRUE), (4, 162, TRUE),
(4, 163, TRUE), (4, 164, TRUE), (4, 165, TRUE), (4, 166, TRUE), (4, 167, TRUE), (4, 168, TRUE), (4, 169, TRUE),
(4, 170, TRUE), (4, 171, TRUE), (4, 172, TRUE), (4, 173, TRUE), (4, 174, TRUE), (4, 175, TRUE), (4, 176, TRUE),
(4, 177, TRUE), (4, 178, TRUE), (4, 179, TRUE), (4, 180, TRUE), (4, 181, TRUE), (4, 182, TRUE), (4, 183, TRUE),
(4, 184, TRUE), (4, 185, TRUE), (4, 186, TRUE), (4, 187, TRUE), (4, 188, TRUE), (4, 189, TRUE), (4, 190, TRUE),
(4, 191, TRUE), (4, 192, TRUE), (4, 193, TRUE), (4, 194, TRUE), (4, 195, TRUE), (4, 196, TRUE), (4, 197, TRUE),
(4, 198, TRUE), (4, 199, TRUE), (4, 200, TRUE), (4, 201, TRUE), (5, 202, TRUE), (5, 203, TRUE), (5, 204, TRUE),
(5, 205, TRUE), (5, 206, TRUE), (5, 207, TRUE), (5, 208, TRUE), (5, 209, TRUE), (5, 210, TRUE), (5, 211, TRUE),
(5, 212, TRUE), (5, 213, TRUE), (5, 214, TRUE), (5, 215, TRUE), (5, 216, TRUE), (5, 217, TRUE), (5, 218, TRUE),
(5, 219, TRUE), (5, 220, TRUE), (5, 221, TRUE), (5, 222, TRUE), (5, 223, TRUE), (5, 224, TRUE), (5, 225, TRUE),
(5, 226, TRUE), (5, 227, TRUE), (5, 228, TRUE), (5, 229, TRUE), (5, 230, TRUE), (5, 231, TRUE), (5, 232, TRUE),
(5, 233, TRUE), (5, 234, TRUE), (5, 235, TRUE), (5, 236, TRUE), (5, 237, TRUE), (5, 238, TRUE), (5, 239, TRUE),
(5, 240, TRUE), (5, 241, TRUE), (5, 242, TRUE), (5, 243, TRUE), (5, 244, TRUE), (5, 245, TRUE), (5, 246, TRUE),
(5, 247, TRUE), (5, 248, TRUE), (5, 249, TRUE), (5, 250, TRUE), (5, 251, TRUE), (6, 252, TRUE), (6, 253, TRUE),
(6, 254, TRUE), (6, 255, TRUE), (6, 256, TRUE), (6, 257, TRUE), (6, 258, TRUE), (6, 259, TRUE), (6, 260, TRUE),
(6, 261, TRUE), (6, 262, TRUE), (6, 263, TRUE), (6, 264, TRUE), (6, 265, TRUE), (6, 266, TRUE), (6, 267, TRUE),
(6, 268, TRUE), (6, 269, TRUE), (6, 270, TRUE), (6, 271, TRUE), (6, 272, TRUE), (6, 273, TRUE), (6, 274, TRUE),
(6, 275, TRUE), (6, 276, TRUE), (6, 277, TRUE), (6, 278, TRUE), (6, 279, TRUE), (6, 280, TRUE), (6, 281, TRUE),
(6, 282, TRUE), (6, 283, TRUE), (6, 284, TRUE), (6, 285, TRUE), (6, 286, TRUE), (6, 287, TRUE), (6, 288, TRUE),
(6, 289, TRUE), (6, 290, TRUE), (6, 291, TRUE), (6, 292, TRUE), (6, 293, TRUE), (6, 294, TRUE), (6, 295, TRUE),
(6, 296, TRUE), (6, 297, TRUE), (6, 298, TRUE), (6, 299, TRUE), (6, 300, TRUE);


-- =====================================================================
-- 10. AVALIAÇÕES E NOTAS DETALHADAS
-- =====================================================================

-- AVALIAÇÃO A1
-- Cria o cabeçalho da Prova A1 para todas as turmas (Peso 0.40)
INSERT INTO tb_avaliacao (id_turma, titulo_avaliacao, peso_avaliacao, data_avaliacao) VALUES
(1, 'Avaliação Regimental A1', 0.40, '2026-10-20'), (2, 'Avaliação Regimental A1', 0.40, '2026-10-20'),
(3, 'Avaliação Regimental A1', 0.40, '2026-10-20'), (4, 'Avaliação Regimental A1', 0.40, '2026-10-20'),
(5, 'Avaliação Regimental A1', 0.40, '2026-10-20'), (6, 'Avaliação Regimental A1', 0.40, '2026-10-20');

-- Notas da Prova A1 (de 5.00 a 10.00): (id_avaliacao, id_matricula, nota)
INSERT INTO tb_nota_avaliacao (id_avaliacao, id_matricula, nota_nota_avaliacao) VALUES
(1, 1, 8.70), (1, 2, 7.30), (1, 3, 5.90), (1, 4, 9.60), (1, 5, 8.20), (1, 6, 6.80), (1, 7, 5.40), (1, 8, 9.10),
(1, 9, 7.70), (1, 10, 6.30), (1, 11, 10.00), (1, 12, 8.60), (1, 13, 7.20), (1, 14, 5.80), (1, 15, 9.50),
(1, 16, 8.10), (1, 17, 6.70), (1, 18, 5.30), (1, 19, 9.00), (1, 20, 7.60), (1, 21, 6.20), (1, 22, 9.90),
(1, 23, 8.50), (1, 24, 7.10), (1, 25, 5.70), (1, 26, 9.40), (1, 27, 8.00), (1, 28, 6.60), (1, 29, 5.20),
(1, 30, 8.90), (1, 31, 7.50), (1, 32, 6.10), (1, 33, 9.80), (1, 34, 8.40), (1, 35, 7.00), (1, 36, 5.60),
(1, 37, 9.30), (1, 38, 7.90), (1, 39, 6.50), (1, 40, 5.10), (1, 41, 8.80), (1, 42, 7.40), (1, 43, 6.00),
(1, 44, 9.70), (1, 45, 8.30), (1, 46, 6.90), (1, 47, 5.50), (1, 48, 9.20), (1, 49, 7.80), (2, 50, 6.40),
(2, 51, 5.00), (2, 52, 8.70), (2, 53, 7.30), (2, 54, 5.90), (2, 55, 9.60), (2, 56, 8.20), (2, 57, 6.80),
(2, 58, 5.40), (2, 59, 9.10), (2, 60, 7.70), (2, 61, 6.30), (2, 62, 10.00), (2, 63, 8.60), (2, 64, 7.20),
(2, 65, 5.80), (2, 66, 9.50), (2, 67, 8.10), (2, 68, 6.70), (2, 69, 5.30), (2, 70, 9.00), (2, 71, 7.60),
(2, 72, 6.20), (2, 73, 9.90), (2, 74, 8.50), (2, 75, 7.10), (2, 76, 5.70), (2, 77, 9.40), (2, 78, 8.00),
(2, 79, 6.60), (2, 80, 5.20), (2, 81, 8.90), (2, 82, 7.50), (2, 83, 6.10), (2, 84, 9.80), (2, 85, 8.40),
(2, 86, 7.00), (2, 87, 5.60), (2, 88, 9.30), (2, 89, 7.90), (2, 90, 6.50), (2, 91, 5.10), (2, 92, 8.80),
(2, 93, 7.40), (2, 94, 6.00), (2, 95, 9.70), (2, 96, 8.30), (2, 97, 6.90), (2, 98, 5.50), (2, 99, 9.20),
(3, 100, 7.80), (3, 101, 6.40), (3, 102, 5.00), (3, 103, 8.70), (3, 104, 7.30), (3, 105, 5.90), (3, 106, 9.60),
(3, 107, 8.20), (3, 108, 6.80), (3, 109, 5.40), (3, 110, 9.10), (3, 111, 7.70), (3, 112, 6.30),
(3, 113, 10.00), (3, 114, 8.60), (3, 115, 7.20), (3, 116, 5.80), (3, 117, 9.50), (3, 118, 8.10),
(3, 119, 6.70), (3, 120, 5.30), (3, 121, 9.00), (3, 122, 7.60), (3, 123, 6.20), (3, 124, 9.90), (3, 125, 8.50),
(3, 126, 7.10), (3, 127, 5.70), (3, 128, 9.40), (3, 129, 8.00), (3, 130, 6.60), (3, 131, 5.20), (3, 132, 8.90),
(3, 133, 7.50), (3, 134, 6.10), (3, 135, 9.80), (3, 136, 8.40), (3, 137, 7.00), (3, 138, 5.60), (3, 139, 9.30),
(3, 140, 7.90), (3, 141, 6.50), (3, 142, 5.10), (3, 143, 8.80), (3, 144, 7.40), (3, 145, 6.00), (3, 146, 9.70),
(3, 147, 8.30), (3, 148, 6.90), (3, 149, 5.50), (3, 150, 9.20), (4, 151, 7.80), (4, 152, 6.40), (4, 153, 5.00),
(4, 154, 8.70), (4, 155, 7.30), (4, 156, 5.90), (4, 157, 9.60), (4, 158, 8.20), (4, 159, 6.80), (4, 160, 5.40),
(4, 161, 9.10), (4, 162, 7.70), (4, 163, 6.30), (4, 164, 10.00), (4, 165, 8.60), (4, 166, 7.20),
(4, 167, 5.80), (4, 168, 9.50), (4, 169, 8.10), (4, 170, 6.70), (4, 171, 5.30), (4, 172, 9.00), (4, 173, 7.60),
(4, 174, 6.20), (4, 175, 9.90), (4, 176, 8.50), (4, 177, 7.10), (4, 178, 5.70), (4, 179, 9.40), (4, 180, 8.00),
(4, 181, 6.60), (4, 182, 5.20), (4, 183, 8.90), (4, 184, 7.50), (4, 185, 6.10), (4, 186, 9.80), (4, 187, 8.40),
(4, 188, 7.00), (4, 189, 5.60), (4, 190, 9.30), (4, 191, 7.90), (4, 192, 6.50), (4, 193, 5.10), (4, 194, 8.80),
(4, 195, 7.40), (4, 196, 6.00), (4, 197, 9.70), (4, 198, 8.30), (4, 199, 6.90), (4, 200, 5.50), (4, 201, 9.20),
(5, 202, 7.80), (5, 203, 6.40), (5, 204, 5.00), (5, 205, 8.70), (5, 206, 7.30), (5, 207, 5.90), (5, 208, 9.60),
(5, 209, 8.20), (5, 210, 6.80), (5, 211, 5.40), (5, 212, 9.10), (5, 213, 7.70), (5, 214, 6.30),
(5, 215, 10.00), (5, 216, 8.60), (5, 217, 7.20), (5, 218, 5.80), (5, 219, 9.50), (5, 220, 8.10),
(5, 221, 6.70), (5, 222, 5.30), (5, 223, 9.00), (5, 224, 7.60), (5, 225, 6.20), (5, 226, 9.90), (5, 227, 8.50),
(5, 228, 7.10), (5, 229, 5.70), (5, 230, 9.40), (5, 231, 8.00), (5, 232, 6.60), (5, 233, 5.20), (5, 234, 8.90),
(5, 235, 7.50), (5, 236, 6.10), (5, 237, 9.80), (5, 238, 8.40), (5, 239, 7.00), (5, 240, 5.60), (5, 241, 9.30),
(5, 242, 7.90), (5, 243, 6.50), (5, 244, 5.10), (5, 245, 8.80), (5, 246, 7.40), (5, 247, 6.00), (5, 248, 9.70),
(5, 249, 8.30), (5, 250, 6.90), (5, 251, 5.50), (6, 252, 9.20), (6, 253, 7.80), (6, 254, 6.40), (6, 255, 5.00),
(6, 256, 8.70), (6, 257, 7.30), (6, 258, 5.90), (6, 259, 9.60), (6, 260, 8.20), (6, 261, 6.80), (6, 262, 5.40),
(6, 263, 9.10), (6, 264, 7.70), (6, 265, 6.30), (6, 266, 10.00), (6, 267, 8.60), (6, 268, 7.20),
(6, 269, 5.80), (6, 270, 9.50), (6, 271, 8.10), (6, 272, 6.70), (6, 273, 5.30), (6, 274, 9.00), (6, 275, 7.60),
(6, 276, 6.20), (6, 277, 9.90), (6, 278, 8.50), (6, 279, 7.10), (6, 280, 5.70), (6, 281, 9.40), (6, 282, 8.00),
(6, 283, 6.60), (6, 284, 5.20), (6, 285, 8.90), (6, 286, 7.50), (6, 287, 6.10), (6, 288, 9.80), (6, 289, 8.40),
(6, 290, 7.00), (6, 291, 5.60), (6, 292, 9.30), (6, 293, 7.90), (6, 294, 6.50), (6, 295, 5.10), (6, 296, 8.80),
(6, 297, 7.40), (6, 298, 6.00), (6, 299, 9.70), (6, 300, 8.30); -- Garante que a nota vai para a prova certa

-- AVALIAÇÃO A2
-- Cria o cabeçalho da Prova A2 para todas as turmas (Peso 0.60)
INSERT INTO tb_avaliacao (id_turma, titulo_avaliacao, peso_avaliacao, data_avaliacao) VALUES
(1, 'Avaliação Regimental A2', 0.60, '2026-12-10'), (2, 'Avaliação Regimental A2', 0.60, '2026-12-10'),
(3, 'Avaliação Regimental A2', 0.60, '2026-12-10'), (4, 'Avaliação Regimental A2', 0.60, '2026-12-10'),
(5, 'Avaliação Regimental A2', 0.60, '2026-12-10'), (6, 'Avaliação Regimental A2', 0.60, '2026-12-10');

-- Notas da Prova A2 (de 5.00 a 10.00): (id_avaliacao, id_matricula, nota)
INSERT INTO tb_nota_avaliacao (id_avaliacao, id_matricula, nota_nota_avaliacao) VALUES
(7, 1, 5.20), (7, 2, 5.40), (7, 3, 5.60), (7, 4, 5.80), (7, 5, 6.00), (7, 6, 6.20), (7, 7, 6.40), (7, 8, 6.60),
(7, 9, 6.80), (7, 10, 7.00), (7, 11, 7.20), (7, 12, 7.40), (7, 13, 7.60), (7, 14, 7.80), (7, 15, 8.00),
(7, 16, 8.20), (7, 17, 8.40), (7, 18, 8.60), (7, 19, 8.80), (7, 20, 9.00), (7, 21, 9.20), (7, 22, 9.40),
(7, 23, 9.60), (7, 24, 9.80), (7, 25, 10.00), (7, 26, 5.10), (7, 27, 5.30), (7, 28, 5.50), (7, 29, 5.70),
(7, 30, 5.90), (7, 31, 6.10), (7, 32, 6.30), (7, 33, 6.50), (7, 34, 6.70), (7, 35, 6.90), (7, 36, 7.10),
(7, 37, 7.30), (7, 38, 7.50), (7, 39, 7.70), (7, 40, 7.90), (7, 41, 8.10), (7, 42, 8.30), (7, 43, 8.50),
(7, 44, 8.70), (7, 45, 8.90), (7, 46, 9.10), (7, 47, 9.30), (7, 48, 9.50), (7, 49, 9.70), (8, 50, 9.90),
(8, 51, 5.00), (8, 52, 5.20), (8, 53, 5.40), (8, 54, 5.60), (8, 55, 5.80), (8, 56, 6.00), (8, 57, 6.20),
(8, 58, 6.40), (8, 59, 6.60), (8, 60, 6.80), (8, 61, 7.00), (8, 62, 7.20), (8, 63, 7.40), (8, 64, 7.60),
(8, 65, 7.80), (8, 66, 8.00), (8, 67, 8.20), (8, 68, 8.40), (8, 69, 8.60), (8, 70, 8.80), (8, 71, 9.00),
(8, 72, 9.20), (8, 73, 9.40), (8, 74, 9.60), (8, 75, 9.80), (8, 76, 10.00), (8, 77, 5.10), (8, 78, 5.30),
(8, 79, 5.50), (8, 80, 5.70), (8, 81, 5.90), (8, 82, 6.10), (8, 83, 6.30), (8, 84, 6.50), (8, 85, 6.70),
(8, 86, 6.90), (8, 87, 7.10), (8, 88, 7.30), (8, 89, 7.50), (8, 90, 7.70), (8, 91, 7.90), (8, 92, 8.10),
(8, 93, 8.30), (8, 94, 8.50), (8, 95, 8.70), (8, 96, 8.90), (8, 97, 9.10), (8, 98, 9.30), (8, 99, 9.50),
(9, 100, 9.70), (9, 101, 9.90), (9, 102, 5.00), (9, 103, 5.20), (9, 104, 5.40), (9, 105, 5.60), (9, 106, 5.80),
(9, 107, 6.00), (9, 108, 6.20), (9, 109, 6.40), (9, 110, 6.60), (9, 111, 6.80), (9, 112, 7.00), (9, 113, 7.20),
(9, 114, 7.40), (9, 115, 7.60), (9, 116, 7.80), (9, 117, 8.00), (9, 118, 8.20), (9, 119, 8.40), (9, 120, 8.60),
(9, 121, 8.80), (9, 122, 9.00), (9, 123, 9.20), (9, 124, 9.40), (9, 125, 9.60), (9, 126, 9.80),
(9, 127, 10.00), (9, 128, 5.10), (9, 129, 5.30), (9, 130, 5.50), (9, 131, 5.70), (9, 132, 5.90),
(9, 133, 6.10), (9, 134, 6.30), (9, 135, 6.50), (9, 136, 6.70), (9, 137, 6.90), (9, 138, 7.10), (9, 139, 7.30),
(9, 140, 7.50), (9, 141, 7.70), (9, 142, 7.90), (9, 143, 8.10), (9, 144, 8.30), (9, 145, 8.50), (9, 146, 8.70),
(9, 147, 8.90), (9, 148, 9.10), (9, 149, 9.30), (9, 150, 9.50), (10, 151, 9.70), (10, 152, 9.90),
(10, 153, 5.00), (10, 154, 5.20), (10, 155, 5.40), (10, 156, 5.60), (10, 157, 5.80), (10, 158, 6.00),
(10, 159, 6.20), (10, 160, 6.40), (10, 161, 6.60), (10, 162, 6.80), (10, 163, 7.00), (10, 164, 7.20),
(10, 165, 7.40), (10, 166, 7.60), (10, 167, 7.80), (10, 168, 8.00), (10, 169, 8.20), (10, 170, 8.40),
(10, 171, 8.60), (10, 172, 8.80), (10, 173, 9.00), (10, 174, 9.20), (10, 175, 9.40), (10, 176, 9.60),
(10, 177, 9.80), (10, 178, 10.00), (10, 179, 5.10), (10, 180, 5.30), (10, 181, 5.50), (10, 182, 5.70),
(10, 183, 5.90), (10, 184, 6.10), (10, 185, 6.30), (10, 186, 6.50), (10, 187, 6.70), (10, 188, 6.90),
(10, 189, 7.10), (10, 190, 7.30), (10, 191, 7.50), (10, 192, 7.70), (10, 193, 7.90), (10, 194, 8.10),
(10, 195, 8.30), (10, 196, 8.50), (10, 197, 8.70), (10, 198, 8.90), (10, 199, 9.10), (10, 200, 9.30),
(10, 201, 9.50), (11, 202, 9.70), (11, 203, 9.90), (11, 204, 5.00), (11, 205, 5.20), (11, 206, 5.40),
(11, 207, 5.60), (11, 208, 5.80), (11, 209, 6.00), (11, 210, 6.20), (11, 211, 6.40), (11, 212, 6.60),
(11, 213, 6.80), (11, 214, 7.00), (11, 215, 7.20), (11, 216, 7.40), (11, 217, 7.60), (11, 218, 7.80),
(11, 219, 8.00), (11, 220, 8.20), (11, 221, 8.40), (11, 222, 8.60), (11, 223, 8.80), (11, 224, 9.00),
(11, 225, 9.20), (11, 226, 9.40), (11, 227, 9.60), (11, 228, 9.80), (11, 229, 10.00), (11, 230, 5.10),
(11, 231, 5.30), (11, 232, 5.50), (11, 233, 5.70), (11, 234, 5.90), (11, 235, 6.10), (11, 236, 6.30),
(11, 237, 6.50), (11, 238, 6.70), (11, 239, 6.90), (11, 240, 7.10), (11, 241, 7.30), (11, 242, 7.50),
(11, 243, 7.70), (11, 244, 7.90), (11, 245, 8.10), (11, 246, 8.30), (11, 247, 8.50), (11, 248, 8.70),
(11, 249, 8.90), (11, 250, 9.10), (11, 251, 9.30), (12, 252, 9.50), (12, 253, 9.70), (12, 254, 9.90),
(12, 255, 5.00), (12, 256, 5.20), (12, 257, 5.40), (12, 258, 5.60), (12, 259, 5.80), (12, 260, 6.00),
(12, 261, 6.20), (12, 262, 6.40), (12, 263, 6.60), (12, 264, 6.80), (12, 265, 7.00), (12, 266, 7.20),
(12, 267, 7.40), (12, 268, 7.60), (12, 269, 7.80), (12, 270, 8.00), (12, 271, 8.20), (12, 272, 8.40),
(12, 273, 8.60), (12, 274, 8.80), (12, 275, 9.00), (12, 276, 9.20), (12, 277, 9.40), (12, 278, 9.60),
(12, 279, 9.80), (12, 280, 10.00), (12, 281, 5.10), (12, 282, 5.30), (12, 283, 5.50), (12, 284, 5.70),
(12, 285, 5.90), (12, 286, 6.10), (12, 287, 6.30), (12, 288, 6.50), (12, 289, 6.70), (12, 290, 6.90),
(12, 291, 7.10), (12, 292, 7.30), (12, 293, 7.50), (12, 294, 7.70), (12, 295, 7.90), (12, 296, 8.10),
(12, 297, 8.30), (12, 298, 8.50), (12, 299, 8.70), (12, 300, 8.90); -- Garante que a nota vai para a prova certa


-- =====================================================================
-- 11. FINANCEIRO E BOLSAS DE DESCONTO (62% com desconto de 20% a 50%)
-- =====================================================================

-- IMPRIMIR OS CUPONS (Tipos de Bolsas)
INSERT INTO tb_bolsa_desconto (nome_bolsa_desconto, percentual_bolsa_desconto, ativa_bolsa_desconto) VALUES
('Bolsa Mérito Acadêmico 20%', 20.00, TRUE),
('Bolsa Incentivo Estudantil 30%', 30.00, TRUE),
('Bolsa Parceria Institucional 40%', 40.00, TRUE),
('Bolsa Social 50%', 50.00, TRUE);

-- ENTREGAR OS CUPONS PARA OS 62 PRIMEIROS
INSERT INTO tb_aluno_bolsa (id_aluno, id_bolsa_desconto, data_concessao_aluno_bolsa) VALUES
(1, 2, '2026-08-01'), (2, 3, '2026-08-01'), (3, 4, '2026-08-01'), (4, 1, '2026-08-01'), (5, 2, '2026-08-01'),
(6, 3, '2026-08-01'), (7, 4, '2026-08-01'), (8, 1, '2026-08-01'), (9, 2, '2026-08-01'), (10, 3, '2026-08-01'),
(11, 4, '2026-08-01'), (12, 1, '2026-08-01'), (13, 2, '2026-08-01'), (14, 3, '2026-08-01'),
(15, 4, '2026-08-01'), (16, 1, '2026-08-01'), (17, 2, '2026-08-01'), (18, 3, '2026-08-01'),
(19, 4, '2026-08-01'), (20, 1, '2026-08-01'), (21, 2, '2026-08-01'), (22, 3, '2026-08-01'),
(23, 4, '2026-08-01'), (24, 1, '2026-08-01'), (25, 2, '2026-08-01'), (26, 3, '2026-08-01'),
(27, 4, '2026-08-01'), (28, 1, '2026-08-01'), (29, 2, '2026-08-01'), (30, 3, '2026-08-01'),
(31, 4, '2026-08-01'), (32, 1, '2026-08-01'), (33, 2, '2026-08-01'), (34, 3, '2026-08-01'),
(35, 4, '2026-08-01'), (36, 1, '2026-08-01'), (37, 2, '2026-08-01'), (38, 3, '2026-08-01'),
(39, 4, '2026-08-01'), (40, 1, '2026-08-01'), (41, 2, '2026-08-01'), (42, 3, '2026-08-01'),
(43, 4, '2026-08-01'), (44, 1, '2026-08-01'), (45, 2, '2026-08-01'), (46, 3, '2026-08-01'),
(47, 4, '2026-08-01'), (48, 1, '2026-08-01'), (49, 2, '2026-08-01'), (50, 3, '2026-08-01'),
(51, 4, '2026-08-01'), (52, 1, '2026-08-01'), (53, 2, '2026-08-01'), (54, 3, '2026-08-01'),
(55, 4, '2026-08-01'), (56, 1, '2026-08-01'), (57, 2, '2026-08-01'), (58, 3, '2026-08-01'),
(59, 4, '2026-08-01'), (60, 1, '2026-08-01'), (61, 2, '2026-08-01'), (62, 3, '2026-08-01'); -- Só carimba para quem está até a posição 62 da fila

-- Gerar Mensalidades
-- Quem tem desconto
INSERT INTO tb_mensalidade (id_aluno, id_periodo_letivo, valor_original_mensalidade, valor_final_mensalidade, data_vencimento_mensalidade, status_mensalidade) VALUES
(1, 1, 2500.00, 1750.00, '2026-08-10', 'PAGA'),
(2, 1, 2500.00, 1500.00, '2026-08-10', 'PAGA'),
(3, 1, 2500.00, 1250.00, '2026-08-10', 'PAGA'),
(4, 1, 2500.00, 2000.00, '2026-08-10', 'PAGA'),
(5, 1, 2500.00, 1750.00, '2026-08-10', 'PAGA'),
(6, 1, 2500.00, 1500.00, '2026-08-10', 'PAGA'),
(7, 1, 2500.00, 1250.00, '2026-08-10', 'PAGA'),
(8, 1, 2500.00, 2000.00, '2026-08-10', 'PAGA'),
(9, 1, 2500.00, 1750.00, '2026-08-10', 'PAGA'),
(10, 1, 2500.00, 1500.00, '2026-08-10', 'PAGA'),
(11, 1, 2500.00, 1250.00, '2026-08-10', 'PAGA'),
(12, 1, 2500.00, 2000.00, '2026-08-10', 'PAGA'),
(13, 1, 2500.00, 1750.00, '2026-08-10', 'PAGA'),
(14, 1, 2500.00, 1500.00, '2026-08-10', 'PAGA'),
(15, 1, 2500.00, 1250.00, '2026-08-10', 'PAGA'),
(16, 1, 2500.00, 2000.00, '2026-08-10', 'PAGA'),
(17, 1, 2500.00, 1750.00, '2026-08-10', 'PAGA'),
(18, 1, 2500.00, 1500.00, '2026-08-10', 'PAGA'),
(19, 1, 2500.00, 1250.00, '2026-08-10', 'PAGA'),
(20, 1, 2500.00, 2000.00, '2026-08-10', 'PAGA'),
(21, 1, 2500.00, 1750.00, '2026-08-10', 'PAGA'),
(22, 1, 2500.00, 1500.00, '2026-08-10', 'PAGA'),
(23, 1, 2500.00, 1250.00, '2026-08-10', 'PAGA'),
(24, 1, 2500.00, 2000.00, '2026-08-10', 'PAGA'),
(25, 1, 2500.00, 1750.00, '2026-08-10', 'PAGA'),
(26, 1, 2500.00, 1500.00, '2026-08-10', 'PAGA'),
(27, 1, 2500.00, 1250.00, '2026-08-10', 'PAGA'),
(28, 1, 2500.00, 2000.00, '2026-08-10', 'PAGA'),
(29, 1, 2500.00, 1750.00, '2026-08-10', 'PAGA'),
(30, 1, 2500.00, 1500.00, '2026-08-10', 'PAGA'),
(31, 1, 2500.00, 1250.00, '2026-08-10', 'PAGA'),
(32, 1, 2500.00, 2000.00, '2026-08-10', 'PAGA'),
(33, 1, 2500.00, 1750.00, '2026-08-10', 'PAGA'),
(34, 1, 2500.00, 1500.00, '2026-08-10', 'PAGA'),
(35, 1, 2500.00, 1250.00, '2026-08-10', 'PAGA'),
(36, 1, 2500.00, 2000.00, '2026-08-10', 'PAGA'),
(37, 1, 2500.00, 1750.00, '2026-08-10', 'PAGA'),
(38, 1, 2500.00, 1500.00, '2026-08-10', 'PAGA'),
(39, 1, 2500.00, 1250.00, '2026-08-10', 'PAGA'),
(40, 1, 2500.00, 2000.00, '2026-08-10', 'PAGA'),
(41, 1, 2500.00, 1750.00, '2026-08-10', 'PAGA'),
(42, 1, 2500.00, 1500.00, '2026-08-10', 'PAGA'),
(43, 1, 2500.00, 1250.00, '2026-08-10', 'PAGA'),
(44, 1, 2500.00, 2000.00, '2026-08-10', 'PAGA'),
(45, 1, 2500.00, 1750.00, '2026-08-10', 'PAGA'),
(46, 1, 2500.00, 1500.00, '2026-08-10', 'PAGA'),
(47, 1, 2500.00, 1250.00, '2026-08-10', 'PAGA'),
(48, 1, 2500.00, 2000.00, '2026-08-10', 'PAGA'),
(49, 1, 2500.00, 1750.00, '2026-08-10', 'PAGA'),
(50, 1, 2500.00, 1500.00, '2026-08-10', 'PAGA'),
(51, 1, 2500.00, 1250.00, '2026-08-10', 'PAGA'),
(52, 1, 2500.00, 2000.00, '2026-08-10', 'PAGA'),
(53, 1, 2500.00, 1750.00, '2026-08-10', 'PAGA'),
(54, 1, 2500.00, 1500.00, '2026-08-10', 'PAGA'),
(55, 1, 2500.00, 1250.00, '2026-08-10', 'PAGA'),
(56, 1, 2500.00, 2000.00, '2026-08-10', 'PAGA'),
(57, 1, 2500.00, 1750.00, '2026-08-10', 'PAGA'),
(58, 1, 2500.00, 1500.00, '2026-08-10', 'PAGA'),
(59, 1, 2500.00, 1250.00, '2026-08-10', 'PAGA'),
(60, 1, 2500.00, 2000.00, '2026-08-10', 'PAGA'),
(61, 1, 2500.00, 1750.00, '2026-08-10', 'PAGA'),
(62, 1, 2500.00, 1500.00, '2026-08-10', 'PAGA');

-- Quem não tem desconto
INSERT INTO tb_mensalidade (id_aluno, id_periodo_letivo, valor_original_mensalidade, valor_final_mensalidade, data_vencimento_mensalidade, status_mensalidade) VALUES
(63, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'), (64, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'),
(65, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'), (66, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'),
(67, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'), (68, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'),
(69, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'), (70, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'),
(71, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'), (72, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'),
(73, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'), (74, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'),
(75, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'), (76, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'),
(77, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'), (78, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'),
(79, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'), (80, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'),
(81, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'), (82, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'),
(83, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'), (84, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'),
(85, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'), (86, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'),
(87, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'), (88, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'),
(89, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'), (90, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'),
(91, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'), (92, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'),
(93, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'), (94, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'),
(95, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'), (96, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'),
(97, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'), (98, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'),
(99, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'), (100, 1, 2500.00, 2500.00, '2026-08-10', 'PAGA'); -- O "NOT IN" significa: "Pegue os alunos que NÃO ESTÃO na lista de bolsas"

-- =====================================================================
-- 12. APROVEITAMENTO DE DISCIPLINAS (3 Alunos)
-- =====================================================================
INSERT INTO tb_aproveitamento_disciplina 
(aluno_id_aproveitamento_disciplina, disciplina_id_aproveitamento_disciplina, instituicao_origem_aproveitamento_disciplina, ch_aprovada_aproveitamento_disciplina, nota_origem_aproveitamento_disciplina, status_aprovacao_aproveitamento_disciplina, observacao_aproveitamento_disciplina)
VALUES 
(1, 5, 'Universidade de Brasília (UnB)', 80, 9.50, 'DEFERIDO', 'Aproveitamento deferido conforme equivalência de matriz curricular.'),
(2, 2, 'Pontifícia Universidade Católica (PUC-GO)', 80, 8.80, 'DEFERIDO', 'Aproveitamento deferido por equivalência total de ementa.'),
(3, 6, 'Instituto Federal de Brasília (IFB)', 80, 8.00, 'DEFERIDO', 'Deferido após análise técnica do colegiado.');


-- =====================================================================
-- 13. ATIVIDADES COMPLEMENTARES E REQUERIMENTOS
-- =====================================================================
INSERT INTO tb_atividade_complementar (id_aluno, descricao_atividade_complementar, categoria_atividade_complementar, ch_solicitada_atividade_complementar, ch_validada_atividade_complementar, status_validacao_atividade_complementar, comprovante_url_atividade_complementar, validado_por_atividade_complementar, data_validacao_atividade_complementar) VALUES
(1, 'Participação na Semana de Tecnologia e Computação', 'ACADÊMICO-CULTURAL', 30, 30, 'DEFERIDO', 'https://iesb.edu.br/comprovantes/cert_1.pdf', 7, '2026-09-15'),
(2, 'Participação na Semana de Tecnologia e Computação', 'ACADÊMICO-CULTURAL', 30, 30, 'DEFERIDO', 'https://iesb.edu.br/comprovantes/cert_2.pdf', 7, '2026-09-15'),
(3, 'Participação na Semana de Tecnologia e Computação', 'ACADÊMICO-CULTURAL', 30, 30, 'DEFERIDO', 'https://iesb.edu.br/comprovantes/cert_3.pdf', 7, '2026-09-15'),
(4, 'Participação na Semana de Tecnologia e Computação', 'ACADÊMICO-CULTURAL', 30, 30, 'DEFERIDO', 'https://iesb.edu.br/comprovantes/cert_4.pdf', 7, '2026-09-15'),
(5, 'Participação na Semana de Tecnologia e Computação', 'ACADÊMICO-CULTURAL', 30, 30, 'DEFERIDO', 'https://iesb.edu.br/comprovantes/cert_5.pdf', 7, '2026-09-15'),
(6, 'Participação na Semana de Tecnologia e Computação', 'ACADÊMICO-CULTURAL', 30, 30, 'DEFERIDO', 'https://iesb.edu.br/comprovantes/cert_6.pdf', 7, '2026-09-15'),
(7, 'Participação na Semana de Tecnologia e Computação', 'ACADÊMICO-CULTURAL', 30, 30, 'DEFERIDO', 'https://iesb.edu.br/comprovantes/cert_7.pdf', 7, '2026-09-15'),
(8, 'Participação na Semana de Tecnologia e Computação', 'ACADÊMICO-CULTURAL', 30, 30, 'DEFERIDO', 'https://iesb.edu.br/comprovantes/cert_8.pdf', 7, '2026-09-15'),
(9, 'Participação na Semana de Tecnologia e Computação', 'ACADÊMICO-CULTURAL', 30, 30, 'DEFERIDO', 'https://iesb.edu.br/comprovantes/cert_9.pdf', 7, '2026-09-15'),
(10, 'Participação na Semana de Tecnologia e Computação', 'ACADÊMICO-CULTURAL', 30, 30, 'DEFERIDO', 'https://iesb.edu.br/comprovantes/cert_10.pdf', 7, '2026-09-15'),
(11, 'Participação na Semana de Tecnologia e Computação', 'ACADÊMICO-CULTURAL', 30, 30, 'DEFERIDO', 'https://iesb.edu.br/comprovantes/cert_11.pdf', 7, '2026-09-15'),
(12, 'Participação na Semana de Tecnologia e Computação', 'ACADÊMICO-CULTURAL', 30, 30, 'DEFERIDO', 'https://iesb.edu.br/comprovantes/cert_12.pdf', 7, '2026-09-15'),
(13, 'Participação na Semana de Tecnologia e Computação', 'ACADÊMICO-CULTURAL', 30, 30, 'DEFERIDO', 'https://iesb.edu.br/comprovantes/cert_13.pdf', 7, '2026-09-15'),
(14, 'Participação na Semana de Tecnologia e Computação', 'ACADÊMICO-CULTURAL', 30, 30, 'DEFERIDO', 'https://iesb.edu.br/comprovantes/cert_14.pdf', 7, '2026-09-15'),
(15, 'Participação na Semana de Tecnologia e Computação', 'ACADÊMICO-CULTURAL', 30, 30, 'DEFERIDO', 'https://iesb.edu.br/comprovantes/cert_15.pdf', 7, '2026-09-15'),
(16, 'Participação na Semana de Tecnologia e Computação', 'ACADÊMICO-CULTURAL', 30, 30, 'DEFERIDO', 'https://iesb.edu.br/comprovantes/cert_16.pdf', 7, '2026-09-15'),
(17, 'Participação na Semana de Tecnologia e Computação', 'ACADÊMICO-CULTURAL', 30, 30, 'DEFERIDO', 'https://iesb.edu.br/comprovantes/cert_17.pdf', 7, '2026-09-15'),
(18, 'Participação na Semana de Tecnologia e Computação', 'ACADÊMICO-CULTURAL', 30, 30, 'DEFERIDO', 'https://iesb.edu.br/comprovantes/cert_18.pdf', 7, '2026-09-15'),
(19, 'Participação na Semana de Tecnologia e Computação', 'ACADÊMICO-CULTURAL', 30, 30, 'DEFERIDO', 'https://iesb.edu.br/comprovantes/cert_19.pdf', 7, '2026-09-15'),
(20, 'Participação na Semana de Tecnologia e Computação', 'ACADÊMICO-CULTURAL', 30, 30, 'DEFERIDO', 'https://iesb.edu.br/comprovantes/cert_20.pdf', 7, '2026-09-15');

INSERT INTO tb_requerimento (id_aluno, tipo_requerimento, data_abertura_requerimento, data_fechamento_requerimento, status_requerimento, parecer_requerimento, id_responsavel)
VALUES 
(1, 'Aproveitamento de Disciplina', '2026-08-05 10:00:00-03', '2026-08-10 15:30:00-03', 'DEFERIDO', 'Solicitação deferida após análise da documentação.', 7),
(2, 'Aproveitamento de Disciplina', '2026-08-06 11:20:00-03', '2026-08-11 16:00:00-03', 'DEFERIDO', 'Disciplinas equivalentes e aprovadas pelo colegiado.', 7),
(3, 'Aproveitamento de Disciplina', '2026-08-07 14:10:00-03', '2026-08-12 09:45:00-03', 'DEFERIDO', 'Grade curricular analisada e deferida.', 7),
(4, 'Declaração de Matrícula', '2026-09-01 09:00:00-03', '2026-09-01 09:05:00-03', 'DEFERIDO', 'Emitido automaticamente pelo portal.', 8),
(5, 'Revisão de Prova', '2026-10-22 16:00:00-03', '2026-10-25 11:00:00-03', 'INDEFERIDO', 'Mantida a nota atribuída originalmente.', 1);


-- =====================================================================
-- 14. SEMESTRES ANTERIORES (2025/2 e 2026/1) - HISTÓRICO CONCLUÍDO
-- =====================================================================
-- Precisamos de mais de um período com notas fechadas para as consultas
-- de ranking/percentil e para o LAG (evolução do aluno de um semestre
-- para o outro). Regra usada: aprovado com média >= 5,0 e frequência >= 75%.

INSERT INTO tb_periodo_letivo (ano_periodo_letivo, semestre_periodo_letivo, bimestre_periodo_letivo, data_inicio_periodo_letivo, data_fim_periodo_letivo)
VALUES
(2025, 2, 1, '2025-08-01', '2025-12-20'), -- id 2
(2026, 1, 1, '2026-02-01', '2026-06-30'); -- id 3

-- Turmas 7 e 8 em 2025/2 (POO e Governança), 9 e 10 em 2026/1 (Eng. Software e SO)
INSERT INTO tb_turma (codigo_turma, id_disciplina, id_periodo_letivo, id_professor, turno_turma, vagas_turma)
VALUES
('CCONM1A', 5, 2, 5, 'NOTURNO', 120),
('CCONM1A', 3, 2, 3, 'NOTURNO', 120),
('CCONM1B', 2, 3, 2, 'NOTURNO', 120),
('CCONM1B', 6, 3, 6, 'NOTURNO', 120);

-- Todos os 100 alunos cursaram as 4 turmas (matrículas 301 a 700)
INSERT INTO tb_matricula (id_aluno, id_turma, data_matricula, status_matricula) VALUES
(1, 7, '2025-08-04', 'CONCLUIDO'), (2, 7, '2025-08-04', 'CONCLUIDO'), (3, 7, '2025-08-04', 'CONCLUIDO'), (4, 7, '2025-08-04', 'CONCLUIDO'),
(5, 7, '2025-08-04', 'CONCLUIDO'), (6, 7, '2025-08-04', 'CONCLUIDO'), (7, 7, '2025-08-04', 'CONCLUIDO'), (8, 7, '2025-08-04', 'CONCLUIDO'),
(9, 7, '2025-08-04', 'CONCLUIDO'), (10, 7, '2025-08-04', 'CONCLUIDO'), (11, 7, '2025-08-04', 'CONCLUIDO'), (12, 7, '2025-08-04', 'CONCLUIDO'),
(13, 7, '2025-08-04', 'CONCLUIDO'), (14, 7, '2025-08-04', 'CONCLUIDO'), (15, 7, '2025-08-04', 'CONCLUIDO'), (16, 7, '2025-08-04', 'CONCLUIDO'),
(17, 7, '2025-08-04', 'CONCLUIDO'), (18, 7, '2025-08-04', 'CONCLUIDO'), (19, 7, '2025-08-04', 'CONCLUIDO'), (20, 7, '2025-08-04', 'CONCLUIDO'),
(21, 7, '2025-08-04', 'CONCLUIDO'), (22, 7, '2025-08-04', 'CONCLUIDO'), (23, 7, '2025-08-04', 'CONCLUIDO'), (24, 7, '2025-08-04', 'CONCLUIDO'),
(25, 7, '2025-08-04', 'CONCLUIDO'), (26, 7, '2025-08-04', 'CONCLUIDO'), (27, 7, '2025-08-04', 'CONCLUIDO'), (28, 7, '2025-08-04', 'CONCLUIDO'),
(29, 7, '2025-08-04', 'CONCLUIDO'), (30, 7, '2025-08-04', 'CONCLUIDO'), (31, 7, '2025-08-04', 'CONCLUIDO'), (32, 7, '2025-08-04', 'CONCLUIDO'),
(33, 7, '2025-08-04', 'CONCLUIDO'), (34, 7, '2025-08-04', 'CONCLUIDO'), (35, 7, '2025-08-04', 'CONCLUIDO'), (36, 7, '2025-08-04', 'CONCLUIDO'),
(37, 7, '2025-08-04', 'CONCLUIDO'), (38, 7, '2025-08-04', 'CONCLUIDO'), (39, 7, '2025-08-04', 'CONCLUIDO'), (40, 7, '2025-08-04', 'CONCLUIDO'),
(41, 7, '2025-08-04', 'CONCLUIDO'), (42, 7, '2025-08-04', 'CONCLUIDO'), (43, 7, '2025-08-04', 'CONCLUIDO'), (44, 7, '2025-08-04', 'CONCLUIDO'),
(45, 7, '2025-08-04', 'CONCLUIDO'), (46, 7, '2025-08-04', 'CONCLUIDO'), (47, 7, '2025-08-04', 'CONCLUIDO'), (48, 7, '2025-08-04', 'CONCLUIDO'),
(49, 7, '2025-08-04', 'CONCLUIDO'), (50, 7, '2025-08-04', 'CONCLUIDO'), (51, 7, '2025-08-04', 'CONCLUIDO'), (52, 7, '2025-08-04', 'CONCLUIDO'),
(53, 7, '2025-08-04', 'CONCLUIDO'), (54, 7, '2025-08-04', 'CONCLUIDO'), (55, 7, '2025-08-04', 'CONCLUIDO'), (56, 7, '2025-08-04', 'CONCLUIDO'),
(57, 7, '2025-08-04', 'CONCLUIDO'), (58, 7, '2025-08-04', 'CONCLUIDO'), (59, 7, '2025-08-04', 'CONCLUIDO'), (60, 7, '2025-08-04', 'CONCLUIDO'),
(61, 7, '2025-08-04', 'CONCLUIDO'), (62, 7, '2025-08-04', 'CONCLUIDO'), (63, 7, '2025-08-04', 'CONCLUIDO'), (64, 7, '2025-08-04', 'CONCLUIDO'),
(65, 7, '2025-08-04', 'CONCLUIDO'), (66, 7, '2025-08-04', 'CONCLUIDO'), (67, 7, '2025-08-04', 'CONCLUIDO'), (68, 7, '2025-08-04', 'CONCLUIDO'),
(69, 7, '2025-08-04', 'CONCLUIDO'), (70, 7, '2025-08-04', 'CONCLUIDO'), (71, 7, '2025-08-04', 'CONCLUIDO'), (72, 7, '2025-08-04', 'CONCLUIDO'),
(73, 7, '2025-08-04', 'CONCLUIDO'), (74, 7, '2025-08-04', 'CONCLUIDO'), (75, 7, '2025-08-04', 'CONCLUIDO'), (76, 7, '2025-08-04', 'CONCLUIDO'),
(77, 7, '2025-08-04', 'CONCLUIDO'), (78, 7, '2025-08-04', 'CONCLUIDO'), (79, 7, '2025-08-04', 'CONCLUIDO'), (80, 7, '2025-08-04', 'CONCLUIDO'),
(81, 7, '2025-08-04', 'CONCLUIDO'), (82, 7, '2025-08-04', 'CONCLUIDO'), (83, 7, '2025-08-04', 'CONCLUIDO'), (84, 7, '2025-08-04', 'CONCLUIDO'),
(85, 7, '2025-08-04', 'CONCLUIDO'), (86, 7, '2025-08-04', 'CONCLUIDO'), (87, 7, '2025-08-04', 'CONCLUIDO'), (88, 7, '2025-08-04', 'CONCLUIDO'),
(89, 7, '2025-08-04', 'CONCLUIDO'), (90, 7, '2025-08-04', 'CONCLUIDO'), (91, 7, '2025-08-04', 'CONCLUIDO'), (92, 7, '2025-08-04', 'CONCLUIDO'),
(93, 7, '2025-08-04', 'CONCLUIDO'), (94, 7, '2025-08-04', 'CONCLUIDO'), (95, 7, '2025-08-04', 'CONCLUIDO'), (96, 7, '2025-08-04', 'CONCLUIDO'),
(97, 7, '2025-08-04', 'CONCLUIDO'), (98, 7, '2025-08-04', 'CONCLUIDO'), (99, 7, '2025-08-04', 'CONCLUIDO'), (100, 7, '2025-08-04', 'CONCLUIDO');

INSERT INTO tb_matricula (id_aluno, id_turma, data_matricula, status_matricula) VALUES
(1, 8, '2025-08-04', 'CONCLUIDO'), (2, 8, '2025-08-04', 'CONCLUIDO'), (3, 8, '2025-08-04', 'CONCLUIDO'), (4, 8, '2025-08-04', 'CONCLUIDO'),
(5, 8, '2025-08-04', 'CONCLUIDO'), (6, 8, '2025-08-04', 'CONCLUIDO'), (7, 8, '2025-08-04', 'CONCLUIDO'), (8, 8, '2025-08-04', 'CONCLUIDO'),
(9, 8, '2025-08-04', 'CONCLUIDO'), (10, 8, '2025-08-04', 'CONCLUIDO'), (11, 8, '2025-08-04', 'CONCLUIDO'), (12, 8, '2025-08-04', 'CONCLUIDO'),
(13, 8, '2025-08-04', 'CONCLUIDO'), (14, 8, '2025-08-04', 'CONCLUIDO'), (15, 8, '2025-08-04', 'CONCLUIDO'), (16, 8, '2025-08-04', 'CONCLUIDO'),
(17, 8, '2025-08-04', 'CONCLUIDO'), (18, 8, '2025-08-04', 'CONCLUIDO'), (19, 8, '2025-08-04', 'CONCLUIDO'), (20, 8, '2025-08-04', 'CONCLUIDO'),
(21, 8, '2025-08-04', 'CONCLUIDO'), (22, 8, '2025-08-04', 'CONCLUIDO'), (23, 8, '2025-08-04', 'CONCLUIDO'), (24, 8, '2025-08-04', 'CONCLUIDO'),
(25, 8, '2025-08-04', 'CONCLUIDO'), (26, 8, '2025-08-04', 'CONCLUIDO'), (27, 8, '2025-08-04', 'CONCLUIDO'), (28, 8, '2025-08-04', 'CONCLUIDO'),
(29, 8, '2025-08-04', 'CONCLUIDO'), (30, 8, '2025-08-04', 'CONCLUIDO'), (31, 8, '2025-08-04', 'CONCLUIDO'), (32, 8, '2025-08-04', 'CONCLUIDO'),
(33, 8, '2025-08-04', 'CONCLUIDO'), (34, 8, '2025-08-04', 'CONCLUIDO'), (35, 8, '2025-08-04', 'CONCLUIDO'), (36, 8, '2025-08-04', 'CONCLUIDO'),
(37, 8, '2025-08-04', 'CONCLUIDO'), (38, 8, '2025-08-04', 'CONCLUIDO'), (39, 8, '2025-08-04', 'CONCLUIDO'), (40, 8, '2025-08-04', 'CONCLUIDO'),
(41, 8, '2025-08-04', 'CONCLUIDO'), (42, 8, '2025-08-04', 'CONCLUIDO'), (43, 8, '2025-08-04', 'CONCLUIDO'), (44, 8, '2025-08-04', 'CONCLUIDO'),
(45, 8, '2025-08-04', 'CONCLUIDO'), (46, 8, '2025-08-04', 'CONCLUIDO'), (47, 8, '2025-08-04', 'CONCLUIDO'), (48, 8, '2025-08-04', 'CONCLUIDO'),
(49, 8, '2025-08-04', 'CONCLUIDO'), (50, 8, '2025-08-04', 'CONCLUIDO'), (51, 8, '2025-08-04', 'CONCLUIDO'), (52, 8, '2025-08-04', 'CONCLUIDO'),
(53, 8, '2025-08-04', 'CONCLUIDO'), (54, 8, '2025-08-04', 'CONCLUIDO'), (55, 8, '2025-08-04', 'CONCLUIDO'), (56, 8, '2025-08-04', 'CONCLUIDO'),
(57, 8, '2025-08-04', 'CONCLUIDO'), (58, 8, '2025-08-04', 'CONCLUIDO'), (59, 8, '2025-08-04', 'CONCLUIDO'), (60, 8, '2025-08-04', 'CONCLUIDO'),
(61, 8, '2025-08-04', 'CONCLUIDO'), (62, 8, '2025-08-04', 'CONCLUIDO'), (63, 8, '2025-08-04', 'CONCLUIDO'), (64, 8, '2025-08-04', 'CONCLUIDO'),
(65, 8, '2025-08-04', 'CONCLUIDO'), (66, 8, '2025-08-04', 'CONCLUIDO'), (67, 8, '2025-08-04', 'CONCLUIDO'), (68, 8, '2025-08-04', 'CONCLUIDO'),
(69, 8, '2025-08-04', 'CONCLUIDO'), (70, 8, '2025-08-04', 'CONCLUIDO'), (71, 8, '2025-08-04', 'CONCLUIDO'), (72, 8, '2025-08-04', 'CONCLUIDO'),
(73, 8, '2025-08-04', 'CONCLUIDO'), (74, 8, '2025-08-04', 'CONCLUIDO'), (75, 8, '2025-08-04', 'CONCLUIDO'), (76, 8, '2025-08-04', 'CONCLUIDO'),
(77, 8, '2025-08-04', 'CONCLUIDO'), (78, 8, '2025-08-04', 'CONCLUIDO'), (79, 8, '2025-08-04', 'CONCLUIDO'), (80, 8, '2025-08-04', 'CONCLUIDO'),
(81, 8, '2025-08-04', 'CONCLUIDO'), (82, 8, '2025-08-04', 'CONCLUIDO'), (83, 8, '2025-08-04', 'CONCLUIDO'), (84, 8, '2025-08-04', 'CONCLUIDO'),
(85, 8, '2025-08-04', 'CONCLUIDO'), (86, 8, '2025-08-04', 'CONCLUIDO'), (87, 8, '2025-08-04', 'CONCLUIDO'), (88, 8, '2025-08-04', 'CONCLUIDO'),
(89, 8, '2025-08-04', 'CONCLUIDO'), (90, 8, '2025-08-04', 'CONCLUIDO'), (91, 8, '2025-08-04', 'CONCLUIDO'), (92, 8, '2025-08-04', 'CONCLUIDO'),
(93, 8, '2025-08-04', 'CONCLUIDO'), (94, 8, '2025-08-04', 'CONCLUIDO'), (95, 8, '2025-08-04', 'CONCLUIDO'), (96, 8, '2025-08-04', 'CONCLUIDO'),
(97, 8, '2025-08-04', 'CONCLUIDO'), (98, 8, '2025-08-04', 'CONCLUIDO'), (99, 8, '2025-08-04', 'CONCLUIDO'), (100, 8, '2025-08-04', 'CONCLUIDO');

INSERT INTO tb_matricula (id_aluno, id_turma, data_matricula, status_matricula) VALUES
(1, 9, '2026-02-03', 'CONCLUIDO'), (2, 9, '2026-02-03', 'CONCLUIDO'), (3, 9, '2026-02-03', 'CONCLUIDO'), (4, 9, '2026-02-03', 'CONCLUIDO'),
(5, 9, '2026-02-03', 'CONCLUIDO'), (6, 9, '2026-02-03', 'CONCLUIDO'), (7, 9, '2026-02-03', 'CONCLUIDO'), (8, 9, '2026-02-03', 'CONCLUIDO'),
(9, 9, '2026-02-03', 'CONCLUIDO'), (10, 9, '2026-02-03', 'CONCLUIDO'), (11, 9, '2026-02-03', 'CONCLUIDO'), (12, 9, '2026-02-03', 'CONCLUIDO'),
(13, 9, '2026-02-03', 'CONCLUIDO'), (14, 9, '2026-02-03', 'CONCLUIDO'), (15, 9, '2026-02-03', 'CONCLUIDO'), (16, 9, '2026-02-03', 'CONCLUIDO'),
(17, 9, '2026-02-03', 'CONCLUIDO'), (18, 9, '2026-02-03', 'CONCLUIDO'), (19, 9, '2026-02-03', 'CONCLUIDO'), (20, 9, '2026-02-03', 'CONCLUIDO'),
(21, 9, '2026-02-03', 'CONCLUIDO'), (22, 9, '2026-02-03', 'CONCLUIDO'), (23, 9, '2026-02-03', 'CONCLUIDO'), (24, 9, '2026-02-03', 'CONCLUIDO'),
(25, 9, '2026-02-03', 'CONCLUIDO'), (26, 9, '2026-02-03', 'CONCLUIDO'), (27, 9, '2026-02-03', 'CONCLUIDO'), (28, 9, '2026-02-03', 'CONCLUIDO'),
(29, 9, '2026-02-03', 'CONCLUIDO'), (30, 9, '2026-02-03', 'CONCLUIDO'), (31, 9, '2026-02-03', 'CONCLUIDO'), (32, 9, '2026-02-03', 'CONCLUIDO'),
(33, 9, '2026-02-03', 'CONCLUIDO'), (34, 9, '2026-02-03', 'CONCLUIDO'), (35, 9, '2026-02-03', 'CONCLUIDO'), (36, 9, '2026-02-03', 'CONCLUIDO'),
(37, 9, '2026-02-03', 'CONCLUIDO'), (38, 9, '2026-02-03', 'CONCLUIDO'), (39, 9, '2026-02-03', 'CONCLUIDO'), (40, 9, '2026-02-03', 'CONCLUIDO'),
(41, 9, '2026-02-03', 'CONCLUIDO'), (42, 9, '2026-02-03', 'CONCLUIDO'), (43, 9, '2026-02-03', 'CONCLUIDO'), (44, 9, '2026-02-03', 'CONCLUIDO'),
(45, 9, '2026-02-03', 'CONCLUIDO'), (46, 9, '2026-02-03', 'CONCLUIDO'), (47, 9, '2026-02-03', 'CONCLUIDO'), (48, 9, '2026-02-03', 'CONCLUIDO'),
(49, 9, '2026-02-03', 'CONCLUIDO'), (50, 9, '2026-02-03', 'CONCLUIDO'), (51, 9, '2026-02-03', 'CONCLUIDO'), (52, 9, '2026-02-03', 'CONCLUIDO'),
(53, 9, '2026-02-03', 'CONCLUIDO'), (54, 9, '2026-02-03', 'CONCLUIDO'), (55, 9, '2026-02-03', 'CONCLUIDO'), (56, 9, '2026-02-03', 'CONCLUIDO'),
(57, 9, '2026-02-03', 'CONCLUIDO'), (58, 9, '2026-02-03', 'CONCLUIDO'), (59, 9, '2026-02-03', 'CONCLUIDO'), (60, 9, '2026-02-03', 'CONCLUIDO'),
(61, 9, '2026-02-03', 'CONCLUIDO'), (62, 9, '2026-02-03', 'CONCLUIDO'), (63, 9, '2026-02-03', 'CONCLUIDO'), (64, 9, '2026-02-03', 'CONCLUIDO'),
(65, 9, '2026-02-03', 'CONCLUIDO'), (66, 9, '2026-02-03', 'CONCLUIDO'), (67, 9, '2026-02-03', 'CONCLUIDO'), (68, 9, '2026-02-03', 'CONCLUIDO'),
(69, 9, '2026-02-03', 'CONCLUIDO'), (70, 9, '2026-02-03', 'CONCLUIDO'), (71, 9, '2026-02-03', 'CONCLUIDO'), (72, 9, '2026-02-03', 'CONCLUIDO'),
(73, 9, '2026-02-03', 'CONCLUIDO'), (74, 9, '2026-02-03', 'CONCLUIDO'), (75, 9, '2026-02-03', 'CONCLUIDO'), (76, 9, '2026-02-03', 'CONCLUIDO'),
(77, 9, '2026-02-03', 'CONCLUIDO'), (78, 9, '2026-02-03', 'CONCLUIDO'), (79, 9, '2026-02-03', 'CONCLUIDO'), (80, 9, '2026-02-03', 'CONCLUIDO'),
(81, 9, '2026-02-03', 'CONCLUIDO'), (82, 9, '2026-02-03', 'CONCLUIDO'), (83, 9, '2026-02-03', 'CONCLUIDO'), (84, 9, '2026-02-03', 'CONCLUIDO'),
(85, 9, '2026-02-03', 'CONCLUIDO'), (86, 9, '2026-02-03', 'CONCLUIDO'), (87, 9, '2026-02-03', 'CONCLUIDO'), (88, 9, '2026-02-03', 'CONCLUIDO'),
(89, 9, '2026-02-03', 'CONCLUIDO'), (90, 9, '2026-02-03', 'CONCLUIDO'), (91, 9, '2026-02-03', 'CONCLUIDO'), (92, 9, '2026-02-03', 'CONCLUIDO'),
(93, 9, '2026-02-03', 'CONCLUIDO'), (94, 9, '2026-02-03', 'CONCLUIDO'), (95, 9, '2026-02-03', 'CONCLUIDO'), (96, 9, '2026-02-03', 'CONCLUIDO'),
(97, 9, '2026-02-03', 'CONCLUIDO'), (98, 9, '2026-02-03', 'CONCLUIDO'), (99, 9, '2026-02-03', 'CONCLUIDO'), (100, 9, '2026-02-03', 'CONCLUIDO');

INSERT INTO tb_matricula (id_aluno, id_turma, data_matricula, status_matricula) VALUES
(1, 10, '2026-02-03', 'CONCLUIDO'), (2, 10, '2026-02-03', 'CONCLUIDO'), (3, 10, '2026-02-03', 'CONCLUIDO'), (4, 10, '2026-02-03', 'CONCLUIDO'),
(5, 10, '2026-02-03', 'CONCLUIDO'), (6, 10, '2026-02-03', 'CONCLUIDO'), (7, 10, '2026-02-03', 'CONCLUIDO'), (8, 10, '2026-02-03', 'CONCLUIDO'),
(9, 10, '2026-02-03', 'CONCLUIDO'), (10, 10, '2026-02-03', 'CONCLUIDO'), (11, 10, '2026-02-03', 'CONCLUIDO'), (12, 10, '2026-02-03', 'CONCLUIDO'),
(13, 10, '2026-02-03', 'CONCLUIDO'), (14, 10, '2026-02-03', 'CONCLUIDO'), (15, 10, '2026-02-03', 'CONCLUIDO'), (16, 10, '2026-02-03', 'CONCLUIDO'),
(17, 10, '2026-02-03', 'CONCLUIDO'), (18, 10, '2026-02-03', 'CONCLUIDO'), (19, 10, '2026-02-03', 'CONCLUIDO'), (20, 10, '2026-02-03', 'CONCLUIDO'),
(21, 10, '2026-02-03', 'CONCLUIDO'), (22, 10, '2026-02-03', 'CONCLUIDO'), (23, 10, '2026-02-03', 'CONCLUIDO'), (24, 10, '2026-02-03', 'CONCLUIDO'),
(25, 10, '2026-02-03', 'CONCLUIDO'), (26, 10, '2026-02-03', 'CONCLUIDO'), (27, 10, '2026-02-03', 'CONCLUIDO'), (28, 10, '2026-02-03', 'CONCLUIDO'),
(29, 10, '2026-02-03', 'CONCLUIDO'), (30, 10, '2026-02-03', 'CONCLUIDO'), (31, 10, '2026-02-03', 'CONCLUIDO'), (32, 10, '2026-02-03', 'CONCLUIDO'),
(33, 10, '2026-02-03', 'CONCLUIDO'), (34, 10, '2026-02-03', 'CONCLUIDO'), (35, 10, '2026-02-03', 'CONCLUIDO'), (36, 10, '2026-02-03', 'CONCLUIDO'),
(37, 10, '2026-02-03', 'CONCLUIDO'), (38, 10, '2026-02-03', 'CONCLUIDO'), (39, 10, '2026-02-03', 'CONCLUIDO'), (40, 10, '2026-02-03', 'CONCLUIDO'),
(41, 10, '2026-02-03', 'CONCLUIDO'), (42, 10, '2026-02-03', 'CONCLUIDO'), (43, 10, '2026-02-03', 'CONCLUIDO'), (44, 10, '2026-02-03', 'CONCLUIDO'),
(45, 10, '2026-02-03', 'CONCLUIDO'), (46, 10, '2026-02-03', 'CONCLUIDO'), (47, 10, '2026-02-03', 'CONCLUIDO'), (48, 10, '2026-02-03', 'CONCLUIDO'),
(49, 10, '2026-02-03', 'CONCLUIDO'), (50, 10, '2026-02-03', 'CONCLUIDO'), (51, 10, '2026-02-03', 'CONCLUIDO'), (52, 10, '2026-02-03', 'CONCLUIDO'),
(53, 10, '2026-02-03', 'CONCLUIDO'), (54, 10, '2026-02-03', 'CONCLUIDO'), (55, 10, '2026-02-03', 'CONCLUIDO'), (56, 10, '2026-02-03', 'CONCLUIDO'),
(57, 10, '2026-02-03', 'CONCLUIDO'), (58, 10, '2026-02-03', 'CONCLUIDO'), (59, 10, '2026-02-03', 'CONCLUIDO'), (60, 10, '2026-02-03', 'CONCLUIDO'),
(61, 10, '2026-02-03', 'CONCLUIDO'), (62, 10, '2026-02-03', 'CONCLUIDO'), (63, 10, '2026-02-03', 'CONCLUIDO'), (64, 10, '2026-02-03', 'CONCLUIDO'),
(65, 10, '2026-02-03', 'CONCLUIDO'), (66, 10, '2026-02-03', 'CONCLUIDO'), (67, 10, '2026-02-03', 'CONCLUIDO'), (68, 10, '2026-02-03', 'CONCLUIDO'),
(69, 10, '2026-02-03', 'CONCLUIDO'), (70, 10, '2026-02-03', 'CONCLUIDO'), (71, 10, '2026-02-03', 'CONCLUIDO'), (72, 10, '2026-02-03', 'CONCLUIDO'),
(73, 10, '2026-02-03', 'CONCLUIDO'), (74, 10, '2026-02-03', 'CONCLUIDO'), (75, 10, '2026-02-03', 'CONCLUIDO'), (76, 10, '2026-02-03', 'CONCLUIDO'),
(77, 10, '2026-02-03', 'CONCLUIDO'), (78, 10, '2026-02-03', 'CONCLUIDO'), (79, 10, '2026-02-03', 'CONCLUIDO'), (80, 10, '2026-02-03', 'CONCLUIDO'),
(81, 10, '2026-02-03', 'CONCLUIDO'), (82, 10, '2026-02-03', 'CONCLUIDO'), (83, 10, '2026-02-03', 'CONCLUIDO'), (84, 10, '2026-02-03', 'CONCLUIDO'),
(85, 10, '2026-02-03', 'CONCLUIDO'), (86, 10, '2026-02-03', 'CONCLUIDO'), (87, 10, '2026-02-03', 'CONCLUIDO'), (88, 10, '2026-02-03', 'CONCLUIDO'),
(89, 10, '2026-02-03', 'CONCLUIDO'), (90, 10, '2026-02-03', 'CONCLUIDO'), (91, 10, '2026-02-03', 'CONCLUIDO'), (92, 10, '2026-02-03', 'CONCLUIDO'),
(93, 10, '2026-02-03', 'CONCLUIDO'), (94, 10, '2026-02-03', 'CONCLUIDO'), (95, 10, '2026-02-03', 'CONCLUIDO'), (96, 10, '2026-02-03', 'CONCLUIDO'),
(97, 10, '2026-02-03', 'CONCLUIDO'), (98, 10, '2026-02-03', 'CONCLUIDO'), (99, 10, '2026-02-03', 'CONCLUIDO'), (100, 10, '2026-02-03', 'CONCLUIDO');

-- Notas do histórico: (id_matricula, A1, A2, P3, frequência). P3 só para quem precisou.
INSERT INTO tb_historico (id_matricula, nota_a1_historico, nota_a2_historico, nota_p3_historico, frequencia_historico) VALUES
(301, 5.00, 4.00, 4.50, 80.00), (302, 6.00, 6.50, NULL, 80.00), (303, 7.00, 7.50, NULL, 90.00),
(304, 7.50, 9.50, NULL, 80.00), (305, 4.50, 4.00, NULL, 70.00), (306, 4.00, 3.50, NULL, 85.00),
(307, 7.00, 7.00, NULL, 80.00), (308, 5.50, 7.00, NULL, 90.00), (309, 8.00, 8.00, NULL, 60.00),
(310, 6.50, 6.50, NULL, 70.00), (311, 7.50, 6.50, NULL, 90.00), (312, 6.50, 7.50, NULL, 95.00),
(313, 8.00, 8.50, NULL, 60.00), (314, 7.50, 7.00, NULL, 95.00), (315, 5.00, 4.00, NULL, 90.00),
(316, 8.00, 6.00, NULL, 90.00), (317, 3.00, 4.00, NULL, 90.00), (318, 7.50, 6.50, NULL, 60.00),
(319, 5.00, 5.50, NULL, 95.00), (320, 8.50, 8.00, NULL, 85.00), (321, 6.50, 7.00, NULL, 70.00),
(322, 7.50, 7.50, NULL, 85.00), (323, 4.00, 4.00, 6.50, 95.00), (324, 5.50, 6.00, NULL, 70.00),
(325, 10.00, 8.00, NULL, 90.00), (326, 10.00, 8.00, NULL, 60.00), (327, 8.50, 9.00, NULL, 65.00),
(328, 9.50, 8.50, NULL, 95.00), (329, 5.50, 6.00, NULL, 75.00), (330, 5.00, 4.00, 5.00, 60.00),
(331, 7.00, 4.50, NULL, 95.00), (332, 5.50, 5.50, NULL, 85.00), (333, 5.50, 6.50, NULL, 90.00),
(334, 4.50, 6.50, NULL, 85.00), (335, 8.00, 8.00, NULL, 85.00), (336, 8.00, 8.00, NULL, 60.00),
(337, 7.00, 7.00, NULL, 80.00), (338, 4.00, 3.50, 3.50, 100.00), (339, 6.00, 7.50, NULL, 85.00),
(340, 5.00, 5.00, NULL, 70.00), (341, 6.00, 7.00, NULL, 80.00), (342, 4.50, 7.00, NULL, 80.00),
(343, 7.50, 6.00, NULL, 80.00), (344, 7.00, 5.50, NULL, 70.00), (345, 5.00, 4.50, 4.00, 60.00),
(346, 7.00, 7.50, NULL, 60.00), (347, 9.00, 7.50, NULL, 85.00), (348, 8.00, 6.00, NULL, 90.00),
(349, 5.50, 5.50, NULL, 85.00), (350, 8.50, 8.50, NULL, 80.00), (351, 6.00, 5.50, NULL, 90.00),
(352, 5.00, 6.00, NULL, 95.00), (353, 8.50, 7.00, NULL, 85.00), (354, 7.00, 7.00, NULL, 70.00),
(355, 6.00, 5.00, NULL, 95.00), (356, 2.50, 3.50, NULL, 95.00), (357, 5.50, 3.50, NULL, 80.00),
(358, 3.50, 5.50, 5.00, 85.00), (359, 3.50, 5.00, 5.00, 95.00), (360, 9.00, 6.00, NULL, 95.00),
(361, 9.00, 8.00, NULL, 90.00), (362, 3.50, 5.00, 4.00, 90.00), (363, 6.50, 6.50, NULL, 60.00),
(364, 7.50, 5.00, NULL, 60.00), (365, 6.50, 7.00, NULL, 70.00), (366, 4.50, 4.50, NULL, 80.00),
(367, 7.50, 8.50, NULL, 95.00), (368, 6.50, 6.00, NULL, 100.00), (369, 7.00, 6.00, NULL, 60.00),
(370, 6.50, 4.50, NULL, 85.00), (371, 7.50, 8.00, NULL, 80.00), (372, 8.00, 9.50, NULL, 60.00),
(373, 5.50, 6.00, NULL, 95.00), (374, 7.50, 7.50, NULL, 85.00), (375, 6.50, 6.50, NULL, 95.00),
(376, 4.50, 6.50, NULL, 95.00), (377, 8.00, 7.00, NULL, 85.00), (378, 7.00, 6.00, NULL, 75.00),
(379, 5.50, 5.00, NULL, 95.00), (380, 9.50, 9.00, NULL, 90.00), (381, 6.50, 5.00, NULL, 65.00),
(382, 5.00, 5.50, NULL, 85.00), (383, 6.00, 5.50, NULL, 80.00), (384, 3.50, 2.50, NULL, 90.00),
(385, 8.00, 8.50, NULL, 85.00), (386, 6.50, 7.50, NULL, 85.00), (387, 5.00, 6.00, NULL, 75.00),
(388, 7.00, 5.50, NULL, 90.00), (389, 5.50, 5.00, NULL, 90.00), (390, 9.50, 8.50, NULL, 60.00),
(391, 5.00, 4.00, 5.00, 95.00), (392, 5.50, 6.50, NULL, 70.00), (393, 6.00, 5.00, NULL, 60.00),
(394, 7.50, 8.00, NULL, 95.00), (395, 8.50, 9.00, NULL, 70.00), (396, 7.50, 8.00, NULL, 70.00),
(397, 9.50, 8.50, NULL, 85.00), (398, 7.50, 7.50, NULL, 85.00), (399, 6.00, 4.00, 5.50, 65.00),
(400, 9.00, 9.00, NULL, 80.00), (401, 5.00, 4.00, 5.50, 70.00), (402, 5.00, 7.50, NULL, 90.00),
(403, 6.00, 7.00, NULL, 80.00), (404, 8.50, 8.50, NULL, 85.00), (405, 3.00, 4.50, 3.50, 95.00),
(406, 3.50, 6.00, NULL, 80.00), (407, 6.00, 7.50, NULL, 60.00), (408, 6.00, 7.00, NULL, 60.00),
(409, 8.00, 8.00, NULL, 60.00), (410, 5.50, 6.00, NULL, 85.00), (411, 6.00, 7.50, NULL, 80.00),
(412, 9.00, 9.00, NULL, 80.00), (413, 8.00, 7.00, NULL, 85.00), (414, 6.00, 6.50, NULL, 80.00),
(415, 6.00, 6.00, NULL, 100.00), (416, 7.50, 6.00, NULL, 80.00), (417, 5.00, 3.50, NULL, 90.00),
(418, 7.50, 8.00, NULL, 70.00), (419, 5.50, 5.00, NULL, 100.00), (420, 9.00, 9.00, NULL, 60.00),
(421, 8.00, 8.00, NULL, 70.00), (422, 7.50, 8.50, NULL, 80.00), (423, 5.00, 5.50, NULL, 80.00),
(424, 5.00, 5.00, NULL, 70.00), (425, 8.50, 8.00, NULL, 80.00), (426, 9.50, 7.50, NULL, 90.00),
(427, 9.50, 9.50, NULL, 70.00), (428, 9.00, 8.50, NULL, 95.00), (429, 7.50, 8.00, NULL, 100.00),
(430, 4.00, 3.00, 4.50, 80.00), (431, 4.50, 6.50, NULL, 60.00), (432, 6.50, 6.50, NULL, 85.00),
(433, 4.50, 5.50, NULL, 80.00), (434, 6.50, 6.00, NULL, 95.00), (435, 8.50, 9.00, NULL, 95.00),
(436, 8.00, 6.50, NULL, 70.00), (437, 7.00, 7.50, NULL, 100.00), (438, 3.00, 3.00, NULL, 95.00),
(439, 6.50, 7.50, NULL, 85.00), (440, 4.50, 4.50, 7.00, 70.00), (441, 5.00, 6.00, NULL, 80.00),
(442, 7.00, 7.00, NULL, 90.00), (443, 6.00, 6.50, NULL, 80.00), (444, 5.00, 7.00, NULL, 85.00),
(445, 3.00, 3.50, NULL, 60.00), (446, 6.00, 5.00, NULL, 85.00), (447, 8.00, 8.00, NULL, 90.00),
(448, 6.50, 5.50, NULL, 80.00), (449, 5.50, 7.00, NULL, 85.00), (450, 9.00, 7.50, NULL, 95.00),
(451, 4.00, 5.50, 5.50, 80.00), (452, 7.50, 5.50, NULL, 85.00), (453, 8.50, 8.00, NULL, 90.00),
(454, 7.50, 6.50, NULL, 65.00), (455, 7.50, 6.50, NULL, 80.00), (456, 2.50, 5.00, NULL, 95.00),
(457, 5.50, 4.50, 6.00, 95.00), (458, 3.00, 4.50, 6.00, 85.00), (459, 2.50, 5.00, 5.50, 90.00),
(460, 6.50, 7.00, NULL, 100.00), (461, 8.50, 8.50, NULL, 90.00), (462, 5.00, 4.00, 5.50, 80.00),
(463, 6.00, 6.50, NULL, 65.00), (464, 6.50, 6.50, NULL, 60.00), (465, 6.50, 5.50, NULL, 90.00),
(466, 6.00, 3.50, 5.50, 80.00), (467, 9.50, 9.50, NULL, 90.00), (468, 6.50, 5.50, NULL, 100.00),
(469, 4.50, 7.50, NULL, 75.00), (470, 5.00, 7.00, NULL, 75.00), (471, 10.00, 9.00, NULL, 80.00),
(472, 7.50, 10.00, NULL, 60.00), (473, 5.00, 6.00, NULL, 95.00), (474, 6.50, 6.00, NULL, 100.00),
(475, 8.00, 6.00, NULL, 75.00), (476, 5.50, 6.00, NULL, 85.00), (477, 8.50, 7.50, NULL, 80.00),
(478, 5.50, 7.00, NULL, 80.00), (479, 6.50, 6.00, NULL, 80.00), (480, 9.50, 8.00, NULL, 100.00),
(481, 6.00, 6.00, NULL, 65.00), (482, 4.00, 4.00, 5.50, 80.00), (483, 3.50, 6.50, NULL, 85.00),
(484, 4.50, 4.00, NULL, 90.00), (485, 6.50, 7.00, NULL, 90.00), (486, 7.50, 8.00, NULL, 75.00),
(487, 4.50, 6.50, NULL, 80.00), (488, 5.50, 6.50, NULL, 75.00), (489, 6.00, 5.50, NULL, 95.00),
(490, 8.50, 8.50, NULL, 60.00), (491, 6.00, 6.00, NULL, 85.00), (492, 6.00, 4.50, NULL, 90.00),
(493, 5.00, 7.00, NULL, 95.00), (494, 8.00, 9.50, NULL, 95.00), (495, 7.00, 9.50, NULL, 100.00),
(496, 5.50, 7.50, NULL, 60.00), (497, 8.50, 9.50, NULL, 80.00), (498, 8.50, 7.50, NULL, 60.00),
(499, 5.00, 6.50, NULL, 70.00), (500, 10.00, 10.00, NULL, 90.00), (501, 4.00, 5.00, 3.00, 70.00),
(502, 5.50, 6.00, NULL, 90.00), (503, 7.50, 6.00, NULL, 90.00), (504, 7.00, 9.00, NULL, 80.00),
(505, 3.00, 4.50, 4.50, 100.00), (506, 6.50, 5.50, NULL, 85.00), (507, 8.00, 7.50, NULL, 100.00),
(508, 7.50, 8.00, NULL, 80.00), (509, 8.50, 7.00, NULL, 60.00), (510, 4.50, 5.00, NULL, 85.00),
(511, 6.50, 7.50, NULL, 95.00), (512, 8.00, 6.50, NULL, 95.00), (513, 7.50, 6.00, NULL, 75.00),
(514, 8.50, 8.50, NULL, 80.00), (515, 6.00, 4.00, NULL, 95.00), (516, 7.00, 6.00, NULL, 100.00),
(517, 4.00, 2.00, 4.00, 70.00), (518, 7.00, 7.00, NULL, 65.00), (519, 5.00, 7.00, NULL, 100.00),
(520, 10.00, 8.50, NULL, 85.00), (521, 7.50, 8.00, NULL, 75.00), (522, 8.50, 9.00, NULL, 75.00),
(523, 3.50, 5.00, 4.00, 60.00), (524, 4.50, 5.50, NULL, 95.00), (525, 9.00, 9.50, NULL, 95.00),
(526, 10.00, 10.00, NULL, 70.00), (527, 8.50, 7.50, NULL, 60.00), (528, 10.00, 9.00, NULL, 85.00),
(529, 7.00, 4.50, NULL, 75.00), (530, 3.00, 2.50, 3.00, 75.00), (531, 4.50, 5.00, 7.50, 85.00),
(532, 9.00, 7.50, NULL, 80.00), (533, 7.00, 7.50, NULL, 90.00), (534, 6.00, 6.50, NULL, 80.00),
(535, 8.50, 8.50, NULL, 95.00), (536, 5.50, 7.00, NULL, 60.00), (537, 5.50, 7.00, NULL, 60.00),
(538, 5.50, 5.50, NULL, 90.00), (539, 10.00, 9.50, NULL, 95.00), (540, 7.50, 6.00, NULL, 95.00),
(541, 6.50, 6.50, NULL, 85.00), (542, 4.00, 5.00, NULL, 80.00), (543, 9.00, 8.00, NULL, 85.00),
(544, 8.50, 7.50, NULL, 95.00), (545, 5.00, 3.50, 5.00, 60.00), (546, 8.50, 8.00, NULL, 95.00),
(547, 7.00, 7.00, NULL, 80.00), (548, 7.50, 7.00, NULL, 60.00), (549, 6.00, 7.50, NULL, 85.00),
(550, 9.00, 10.00, NULL, 90.00), (551, 6.00, 5.00, NULL, 80.00), (552, 6.00, 6.00, NULL, 80.00),
(553, 7.00, 8.50, NULL, 75.00), (554, 7.50, 8.50, NULL, 65.00), (555, 6.00, 5.50, NULL, 100.00),
(556, 3.50, 3.50, 5.50, 90.00), (557, 5.00, 4.50, NULL, 100.00), (558, 4.00, 4.50, 5.50, 95.00),
(559, 2.50, 2.00, 2.50, 95.00), (560, 6.50, 7.50, NULL, 80.00), (561, 8.50, 8.50, NULL, 70.00),
(562, 2.50, 3.00, 3.50, 95.00), (563, 7.50, 7.00, NULL, 65.00), (564, 6.00, 4.00, 7.00, 80.00),
(565, 8.50, 7.00, NULL, 95.00), (566, 4.00, 4.50, 6.00, 95.00), (567, 10.00, 9.50, NULL, 85.00),
(568, 7.00, 5.00, NULL, 100.00), (569, 7.00, 6.00, NULL, 95.00), (570, 6.00, 5.00, NULL, 80.00),
(571, 8.00, 7.00, NULL, 100.00), (572, 9.00, 9.00, NULL, 60.00), (573, 6.50, 7.50, NULL, 90.00),
(574, 5.50, 5.50, NULL, 95.00), (575, 5.50, 6.00, NULL, 75.00), (576, 5.50, 4.00, NULL, 95.00),
(577, 10.00, 9.00, NULL, 95.00), (578, 5.00, 6.00, NULL, 75.00), (579, 7.50, 6.00, NULL, 85.00),
(580, 10.00, 10.00, NULL, 90.00), (581, 5.00, 7.00, NULL, 70.00), (582, 5.00, 6.00, NULL, 100.00),
(583, 4.50, 3.50, 5.00, 90.00), (584, 3.50, 6.00, NULL, 60.00), (585, 8.50, 7.50, NULL, 80.00),
(586, 5.50, 5.50, NULL, 95.00), (587, 7.50, 5.50, NULL, 90.00), (588, 7.50, 7.00, NULL, 85.00),
(589, 7.00, 8.00, NULL, 95.00), (590, 10.00, 9.50, NULL, 65.00), (591, 4.50, 4.50, 6.50, 85.00),
(592, 8.00, 7.00, NULL, 85.00), (593, 6.50, 6.00, NULL, 85.00), (594, 8.00, 7.50, NULL, 90.00),
(595, 9.00, 6.50, NULL, 85.00), (596, 5.50, 6.00, NULL, 60.00), (597, 7.50, 9.50, NULL, 100.00),
(598, 7.00, 7.50, NULL, 90.00), (599, 4.50, 6.00, NULL, 70.00), (600, 8.00, 8.00, NULL, 100.00),
(601, 2.00, 2.50, NULL, 75.00), (602, 7.00, 6.00, NULL, 75.00), (603, 7.50, 7.50, NULL, 100.00),
(604, 8.00, 7.50, NULL, 85.00), (605, 3.50, 5.00, 4.00, 95.00), (606, 7.50, 7.50, NULL, 60.00),
(607, 8.00, 7.00, NULL, 80.00), (608, 8.50, 8.50, NULL, 90.00), (609, 7.50, 7.50, NULL, 70.00),
(610, 6.50, 5.50, NULL, 100.00), (611, 7.00, 6.00, NULL, 70.00), (612, 9.50, 8.00, NULL, 75.00),
(613, 6.50, 5.50, NULL, 80.00), (614, 9.00, 7.50, NULL, 80.00), (615, 4.50, 5.50, NULL, 100.00),
(616, 6.50, 8.00, NULL, 95.00), (617, 3.00, 2.50, NULL, 80.00), (618, 7.50, 6.00, NULL, 60.00),
(619, 7.00, 7.00, NULL, 100.00), (620, 10.00, 8.50, NULL, 85.00), (621, 5.00, 6.00, NULL, 95.00),
(622, 9.50, 7.00, NULL, 75.00), (623, 5.00, 3.50, 4.50, 95.00), (624, 5.00, 5.50, NULL, 80.00),
(625, 8.50, 9.00, NULL, 80.00), (626, 9.50, 10.00, NULL, 95.00), (627, 7.50, 7.50, NULL, 65.00),
(628, 10.00, 9.50, NULL, 75.00), (629, 6.00, 5.50, NULL, 90.00), (630, 4.50, 5.00, 5.50, 75.00),
(631, 4.50, 7.50, NULL, 80.00), (632, 6.00, 7.50, NULL, 90.00), (633, 7.00, 6.50, NULL, 100.00),
(634, 7.50, 5.00, NULL, 80.00), (635, 9.00, 10.00, NULL, 60.00), (636, 5.50, 6.00, NULL, 65.00),
(637, 7.50, 7.00, NULL, 95.00), (638, 4.00, 3.50, 6.00, 100.00), (639, 10.00, 8.00, NULL, 85.00),
(640, 5.50, 6.00, NULL, 90.00), (641, 7.50, 4.50, NULL, 85.00), (642, 4.00, 5.50, 5.00, 80.00),
(643, 8.50, 8.00, NULL, 80.00), (644, 8.50, 6.50, NULL, 85.00), (645, 6.00, 5.50, NULL, 65.00),
(646, 9.00, 7.50, NULL, 85.00), (647, 6.00, 8.00, NULL, 85.00), (648, 6.00, 8.00, NULL, 80.00),
(649, 7.50, 7.00, NULL, 85.00), (650, 9.00, 9.50, NULL, 70.00), (651, 5.00, 5.00, NULL, 100.00),
(652, 4.50, 6.00, NULL, 100.00), (653, 8.50, 6.50, NULL, 95.00), (654, 8.50, 7.50, NULL, 60.00),
(655, 6.00, 6.00, NULL, 85.00), (656, 5.00, 3.00, 3.50, 90.00), (657, 4.00, 4.00, NULL, 100.00),
(658, 4.00, 6.00, NULL, 80.00), (659, 3.00, 2.00, NULL, 70.00), (660, 6.50, 6.50, NULL, 75.00),
(661, 7.50, 7.50, NULL, 85.00), (662, 3.00, 5.00, 4.00, 85.00), (663, 6.50, 6.50, NULL, 60.00),
(664, 5.50, 6.00, NULL, 75.00), (665, 8.50, 9.00, NULL, 90.00), (666, 6.00, 6.50, NULL, 90.00),
(667, 10.00, 10.00, NULL, 85.00), (668, 6.50, 7.50, NULL, 60.00), (669, 5.50, 5.00, NULL, 95.00),
(670, 5.50, 7.00, NULL, 90.00), (671, 9.00, 8.50, NULL, 80.00), (672, 8.00, 8.50, NULL, 70.00),
(673, 8.50, 6.50, NULL, 95.00), (674, 6.00, 5.00, NULL, 80.00), (675, 6.50, 8.00, NULL, 85.00),
(676, 6.00, 4.50, NULL, 60.00), (677, 8.50, 8.00, NULL, 60.00), (678, 6.00, 4.00, 7.00, 90.00),
(679, 8.00, 7.50, NULL, 85.00), (680, 10.00, 9.00, NULL, 70.00), (681, 5.50, 6.50, NULL, 60.00),
(682, 6.00, 5.50, NULL, 80.00), (683, 4.00, 6.00, NULL, 60.00), (684, 6.00, 3.00, 4.50, 90.00),
(685, 8.00, 7.50, NULL, 95.00), (686, 6.50, 6.00, NULL, 80.00), (687, 7.00, 7.00, NULL, 100.00),
(688, 6.00, 8.50, NULL, 60.00), (689, 5.00, 6.00, NULL, 95.00), (690, 8.50, 10.00, NULL, 60.00),
(691, 4.50, 3.00, NULL, 90.00), (692, 8.00, 7.50, NULL, 80.00), (693, 5.50, 5.50, NULL, 85.00),
(694, 8.00, 7.00, NULL, 90.00), (695, 8.00, 8.00, NULL, 80.00), (696, 6.50, 6.50, NULL, 95.00),
(697, 9.50, 9.50, NULL, 85.00), (698, 9.00, 9.00, NULL, 90.00), (699, 4.50, 4.50, 5.00, 60.00),
(700, 9.00, 10.00, NULL, 100.00);
