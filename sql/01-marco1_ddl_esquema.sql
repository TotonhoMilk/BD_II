/* =====================================================================
   PROJETO: Sistema de Matrícula Acadêmica
   DISCIPLINA: Banco de Dados II (CCO072) — IESB 2026/2
   PROFESSOR: Rodrigo Gonçalves
   
   ARQUIVO: 01_marco1_ddl_esquema.sql
   DESCRIÇÃO: Script DDL de criação das tabelas, chaves primárias/estrangeiras,
              constraints e índices do Modelo Lógico (Marco 1).
   
   SGBD: PostgreSQL 17
   BANCO DE DADOS: matricula
   
   AUTORES:
     - Alexandre ... (A preencher)
     - Antônio Alexandre Cavalcante Leite - 2512130086
     - Carlos Eduardo ... (A preencher)

   DATA DE CRIAÇÃO:   18/09/2026
   DATA DE ALTERAÇÃO: 18/09/2026

   HISTÓRICO DE REVISÕES: Verificar GitHub
     - https://github.com/TotonhoMilk/BD_II
   ===================================================================== */


/* =====================================================================
                CONFIGURAÇÃO DO AMBIENTE DE BD
   ===================================================================== */

-- =====================================================================
-- PARTE A - Configuração do ambiente de banco de dados em PostgreSQL
--
-- OBJETIVO DO BLOCO: Garantir a usabilidade do script, sem demonstração
-- de erros de execução, enquanto o objeto final do script não tiver sido
-- corrigido e aprovado pelo Prof. Rodrigo Gonçalves.
-- =====================================================================

-- Atenção a essa linha. Não rodar em produção. Essa linha existe qui
-- apenas para realização do script. Favor comentá-la em produção.

-- Remove o esquema "academico" se ele existir, apagando automaticamente 
-- todas as tabelas e objetos vinculados a ele (CASCADE).
DROP SCHEMA IF EXISTS academico CASCADE  

-- Cria o esquema "academico" no banco de dados para organizar e agrupar
-- as tabelas e objetos do Sistema de Matrícula Acadêmica.
CREATE SCHEMA academico;

-- Garante que comandos subsequentes criem/consultem objetos no esquema
-- "academico" por padrão. Caso o banco não possua o esquema "public",
-- retire o termo da linha de comando.
SET search_path TO academico, public;

-- Cria a extensão "btree_gist" para viabilizar o suporte a 
-- índices GiST em tipos tradicionais de dados, essencial para a validação 
-- de restrições avançadas de integridade.
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- =====================================================================



/* =====================================================================
            DEFINIÇÃO DE TIPOS ENUMERADOS E DOMÍNIOS
   ===================================================================== */

-- =====================================================================
-- PARTE A - Tipos Personalizados e Validações de Dados
--
-- OBJETIVO: Definir tipos enumerados (ENUM) para restringir valores 
-- aceitos em campos de status, turnos e classificações, além de criar
-- domínios customizados (DOMAIN) com regras de verificação (CHECK) 
-- para garantir a integridade dos dados numéricos (notas e porcentagens).
-- =====================================================================

-- Tipos enumerados (ENUM) para padronização de domínios discretos
CREATE TYPE turno_t       AS ENUM ('MATUTINO','VESPERTINO','NOTURNO');
CREATE TYPE tipo_disc_t   AS ENUM ('OBRIGATORIA','OPTATIVA');
CREATE TYPE vinculo_t     AS ENUM ('PRE_REQUISITO','CO_REQUISITO');
CREATE TYPE status_mat_t  AS ENUM ('MATRICULADO','TRANCADO','CANCELADO');
CREATE TYPE situacao_t    AS ENUM ('CURSANDO','APROVADO','REPROVADO_NOTA','REPROVADO_FALTA');
CREATE TYPE tipo_sala_t   AS ENUM ('TEORICA','LABORATORIO');

-- Domínios (DOMAIN) com restrição CHECK para integridade de dados numéricos
CREATE DOMAIN nota_t AS numeric(4, 2) CHECK (VALUE >= 0 AND VALUE <= 10);
CREATE DOMAIN pct_t  AS numeric(5, 2) CHECK (VALUE >= 0 AND VALUE <= 100);

-- =====================================================================
-- PARTE B - Tipo de intervalo de tempo
--
-- OBJETIVO: Definir o tipo personalizado "timerange" baseado no subtipo 
-- TIME, permitindo trabalhar com intervalos de horários (início e fim) 
-- para validação de chocamento de horários em turmas e alocação de salas.
-- =====================================================================

-- Cria o tipo customizado de intervalo de tempo (timerange) para 
-- manipular faixas de horários (TIME)
CREATE TYPE timerange AS RANGE (subtype = time);

-- =====================================================================



/* =====================================================================
                CRIAÇÃO DAS TABELAS E INTEGRIDADE (DDL)
   ===================================================================== */

-- =====================================================================
-- PARTE A - Estruturação de Tabelas, Chaves e Restrições 
--
-- OBJETIVO DO BLOCO: 
-- Implementar a estrutura relacional do Sistema de Matrícula Acadêmica,
-- definindo a criação de cada tabela juntamente com suas Chaves Primárias 
-- (PK), Chaves Estrangeiras (FK), Restrições de Verificação (CHECK) e 
-- Unicidade (UNIQUE).
--
-- ALERTAS DE EXECUÇÃO:
-- 1. ORDEM DE EXECUÇÃO E DEPENDÊNCIAS:
--    A ordem de criação das tabelas deve respeitar estritamente a hierarquia
--    de dependências do modelo relacional (tabelas "pai" / fortes devem 
--    ser criadas antes das tabelas "filho" / fracas que as referenciam via FK).
--
-- 2. INTEGRIDADE REFERENCIAL E AÇÕES EM CASCATA:
--    Fique atento às regras de integridade referencial definidas nas FKs 
--    (ex: ON DELETE CASCADE, ON DELETE RESTRICT, ON UPDATE CASCADE). 
--    Elas ditarão o comportamento do banco de dados na exclusão ou 
--    alteração de registros correlacionados.
--
-- 3. USO DOS TIPOS PERSONALIZADOS E DOMÍNIOS:
--    Utilize os tipos ENUM (turno_t, tipo_disc_t, etc.) e DOMAIN (nota_t, pct_t)
--    criados na seção anterior para garantir consistência dos atributos.
--
-- 4. RESTRIÇÕES AVANÇADAS E EXCLUSÕES TEMPORAIS:
--    A validação de choques de horário ou alocação de salas pode utilizar 
--    o tipo 'timerange' e restrições 'EXCLUDE USING GIST' (viabilizadas pela
--    extensão btree_gist habilitada na Parte A).
-- =====================================================================


/* ---------------------------------------------------------------------
   TABELA 1: CAMPUS
   --------------------------------------------------------------------- */

CREATE TABLE campus (                                                 -- Cria a tabela campus.
    campus_id      smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Cria o campo id como chave primária.
    campus_nome    varchar(60) NOT NULL UNIQUE,                       -- Cria o campo nome, único e não nulo.
    campus_cidade  varchar(60) NOT NULL                               -- Cria o campo cidade não nulo.
);
-- ---------------------------------------------------------------------


/* ---------------------------------------------------------------------
   TABELA 2: CURSO
   --------------------------------------------------------------------- */




-- ---------------------------------------------------------------------
