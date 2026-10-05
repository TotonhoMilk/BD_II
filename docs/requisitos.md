# Requisitos — Sistema Acadêmico

Banco de Dados II (CCO072) · 2026/2 · Prof. Rodrigo Gonçalves
Grupo: Alexandre Vieira, Antônio Alexandre, Carlos Eduardo

## Escopo

Banco de dados acadêmico completo, tendo o portal do IESB como
referência de realidade — não um recorte de matrícula.

O modelo lógico fornecido pelo professor é guia de escopo e orientação,
não especificação a copiar. O processo é do grupo: requisitos,
conceitual, lógico e SQL.

Fontes, em ordem de autoridade:

1. Telas do portal do IESB — ver docs/levantamento-portal.md
2. Enunciado do Projeto Acadêmico
3. Modelo lógico do professor, como referência do núcleo
4. Plano de ensino e regulamento acadêmico

Cada requisito cita a regra acadêmica que o origina. O modelo de dados é
consequência do requisito, nunca o contrário.


## Convenções adotadas

Decisão do grupo, a partir da última aula:

| Elemento | Convenção | Exemplo |
|----------|-----------|---------|
| Tabela | prefixo tb_ | tb_aluno |
| Chave primária | tabela_id | aluno_id |
| Coluna | prefixo da entidade | aluno_nome, aluno_cpf |

O professor aceitou tanto id_tabela quanto tabela_id. O grupo adota
tabela_id, que já está no DDL existente.


## Índice dos requisitos

### Localização e estrutura física

| ID | Requisito |
|----|-----------|
| RL1 | Endereço é hierárquico: país, estado, cidade |
| RL2 | Campus pertence a uma cidade |
| RL3 | Campus tem prédios; prédio tem blocos; bloco tem salas |
| RL4 | Sala tem capacidade e tipo |

### Estrutura acadêmica

| ID | Requisito |
|----|-----------|
| RA1 | Curso tem código institucional e ato de reconhecimento do MEC |
| RA2 | Curso exige carga de disciplinas e de atividades complementares |
| RA3 | Currículo é versionado por ano, semestre e grade |
| RA4 | Apenas um currículo vigente por curso |
| RA5 | Disciplina tem carga teórica, prática e total derivada |
| RA6 | Disciplina pertence a currículos, com período sugerido |
| RA7 | Pré-requisito é grafo com dois tipos de vínculo |
| RA8 | Uma disciplina pode ser ofertada a mais de um curso |
| RA9 | Cada currículo define sua própria organização em ciclos e módulos |
| RA10 | Currículo tem modalidade e periodicidade próprias |
| RA11 | Componente curricular tem natureza e eixo formativo |
| RA12 | Disciplina tem modalidade de oferta própria |

### Pessoas

| ID | Requisito |
|----|-----------|
| RP1 | Aluno tem RA, CPF e e-mail únicos |
| RP2 | Aluno ingressa por uma forma registrada |
| RP3 | Aluno vincula-se a um curso e a um currículo |
| RP4 | Aluno tem série e período de progresso |
| RP5 | Professor tem titulação |
| RP6 | Funcionário é distinto de professor |

### Oferta

| ID | Requisito |
|----|-----------|
| RO1 | Período letivo tem ano, semestre e datas |
| RO2 | Calendário registra eventos e feriados por campus |
| RO3 | Turma oferta uma disciplina num período, com docente e vagas |
| RO4 | Turma tem um ou mais encontros semanais |
| RO5 | Uma sala não recebe duas turmas em horários sobrepostos |
| RO6 | Um professor não leciona duas turmas no mesmo horário |
| RO7 | A capacidade da sala comporta as vagas da turma |

### Matrícula e histórico

| ID | Requisito |
|----|-----------|
| RM1 | Matrícula só é aceita se houver vaga |
| RM2 | Aluno não se matricula duas vezes na mesma turma |
| RM3 | Matrícula exige pré-requisitos cumpridos |
| RM4 | Trancamento e cancelamento liberam a vaga |
| RM5 | Histórico é um por matrícula |
| RM6 | Média final é derivada das notas |
| RM7 | Menção é derivada da média |
| RM8 | Frequência mínima é condição de aprovação |
| RM9 | Carga horária cumprida é derivada do histórico |

### Atividades complementares

| ID | Requisito |
|----|-----------|
| RC1 | Atividade tem categoria e carga solicitada |
| RC2 | A carga só conta depois de validada |
| RC3 | A validação registra quem validou e quando |

### Requerimentos

| ID | Requisito |
|----|-----------|
| RR1 | Requerimento tem tipo, abertura, análise e parecer |
| RR2 | Requerimento deferido produz efeito no sistema |

### Avaliação

| ID | Requisito |
|----|-----------|
| RV1 | Turma define suas avaliações, com peso e data |
| RV2 | A nota do aluno é lançada por avaliação |
| RV3 | A soma dos pesos das avaliações de uma turma é consistente |
| RV4 | Frequência é apurada por presença em aula |

### Faturamento e benefícios

| ID | Requisito |
|----|-----------|
| RF1 | Mensalidade é gerada por vínculo e período letivo |
| RF2 | O valor da mensalidade deriva da carga matriculada ou do curso |
| RF3 | Bolsa é desconto percentual com vigência |
| RF4 | O valor final aplica os descontos vigentes na competência |
| RF5 | Mensalidade tem vencimento, pagamento e situação |

### Auditoria e segurança

| ID | Requisito |
|----|-----------|
| RS1 | Toda alteração sensível é auditada |
| RS2 | A auditoria registra valor antigo e valor novo |
| RS3 | O log é somente-inserção |
| RS4 | Aluno só enxerga os próprios dados |
| RS5 | Aluno não altera nota nem frequência |


# Histórias de usuário

Cada história detalha requisitos em critérios testáveis — verificáveis
por consulta ou por tentativa de violação.


## HISTÓRIA 0 — Pessoa e seus vínculos

Como instituição,
quero registrar a pessoa uma única vez e seus vínculos separadamente,
para que quem acumula papéis não tenha cadastros duplicados.

Origem: RP1 a RP6.

### O raciocínio

Pessoa é a entidade; aluno, professor e funcionário são papéis que uma
pessoa exerce. Todo aluno é uma pessoa, mas nem toda pessoa é aluno — e
a mesma pessoa pode ser aluno e funcionário ao mesmo tempo, ou aluno de
graduação e professor de outro nível.

O que diferencia os papéis é a MATRÍCULA, não a identidade: o RA
pertence ao vínculo, não à pessoa.

### Critérios de aceite

CA1. Os dados pessoais — nome, CPF, nascimento — são registrados uma
vez, na pessoa.

CA2. O CPF é único entre pessoas, não entre alunos.

    Consequência. Registrar o CPF em cada papel permitiria a mesma
    pessoa existir três vezes com o mesmo documento, e nenhuma
    restrição detectaria a duplicidade.

CA3. Uma pessoa pode ter vários vínculos de aluno simultâneos, um por
curso.
Ex.: a mesma pessoa cursando Ciência da Computação, Engenharia de
Software e Matemática tem três RAs, três históricos, três currículos.

CA4. O RA identifica o VÍNCULO, e é único no sistema.

CA5. Histórico, matrícula em turma, atividade complementar e
requerimento pertencem ao vínculo, não à pessoa.

    Consequência. Uma disciplina cursada no vínculo de Ciência da
    Computação não aparece no histórico de Matemática, ainda que seja
    a mesma pessoa.

CA6. Pessoa existe antes de qualquer vínculo.
Ex.: o candidato do processo seletivo é pessoa; torna-se aluno ao se
matricular.

CA7. Uma pessoa pode acumular papéis de naturezas distintas.
Ex.: aluno de graduação que também é funcionário da instituição.

CA8. O encerramento de um vínculo não apaga a pessoa nem os demais
vínculos.


## HISTÓRIA 1 — Matrícula em turma com vaga

Como aluno,
quero me matricular em uma turma que tenha vaga,
para cursar a disciplina no período corrente.

Origem: RM1, RM2, RM4. Renovação de Matrícula no portal.

### Critérios de aceite

CA1. A matrícula só é aceita se o número de matrículas ativas na turma
for MENOR que o total de vagas.
Ex.: turma com 40 vagas e 40 matriculados recusa a 41ª.

CA2. O limite é verificado no momento da gravação, não antes. Duas
matrículas simultâneas na última vaga não podem ambas ser aceitas.

    Nota de implementação, Marco 2. É onde a anomalia de concorrência
    se manifesta: contar e depois inserir, em transações concorrentes,
    lê o mesmo valor e grava duas vezes. O enunciado exige reproduzir
    e corrigir de duas formas distintas.

CA3. Trancamento e cancelamento LIBERAM a vaga; conclusão não, porque a
turma já terminou.

CA4. Um aluno não pode ter duas matrículas ativas na mesma turma.
Ex.: se já está matriculado, recusa; se havia cancelado, permite.

CA5. A matrícula é recusada se algum pré-requisito não estiver
cumprido — ver História 2.


## HISTÓRIA 2 — Disciplinas que o aluno pode cursar

Como aluno,
quero saber quais disciplinas do meu currículo já posso cursar,
para escolher a matrícula sem tentar o que será recusado.

Origem: RA7, RM3.

### Critérios de aceite

CA1. Uma disciplina é elegível quando TODOS os seus pré-requisitos
foram concluídos com aprovação.

CA2. A verificação percorre a árvore inteira, não apenas o nível
imediato.
Ex.: se C exige B e B exige A, quem só cursou A não pode cursar C,
ainda que C não referencie A diretamente.

    Nota de implementação. Consulta recursiva sobre o grafo de
    pré-requisitos, partindo das disciplinas concluídas pelo aluno.

CA3. Co-requisito NÃO impede a matrícula: exige cursar junto, não antes.

CA4. Disciplina já concluída com aprovação não aparece como elegível.

CA5. A resposta considera o currículo VIGENTE DO ALUNO, que pode não
ser o currículo ativo do curso — ver História 5.

CA6. Disciplina de outro curso é elegível se estiver no currículo do
aluno.
Ex.: o portal mostra aluno de Ciência da Computação cursando turmas de
Engenharia.


## HISTÓRIA 3 — Aprovação, média e menção

Como coordenação,
quero que a situação seja calculada pelo banco a partir das notas e da
frequência,
para que nenhum lançamento manual produza resultado inconsistente.

Origem: RM6, RM7, RM8. Tela de histórico do portal.

### Critérios de aceite

CA1. A média final é coluna GERADA, calculada pelo banco.

    Nota. O enunciado lista colunas geradas entre os itens
    obrigatórios do DDL. Uma coluna gerada não viola a 3FN: não é
    atributo armazenado de forma independente, é derivação que o banco
    garante e na qual não se escreve. Não há anomalia de atualização
    possível, que é o que a normalização protege.

CA2. A menção é derivada da média, pela escala institucional:

    SS  9,0 a 10,0
    MS  7,0 a 8,9
    MM  5,0 a 6,9
    MI  3,0 a 4,9
    II  0,1 a 2,9
    SR  0,0

CA3. A situação depende de média E frequência. Frequência abaixo do
mínimo reprova independentemente da nota.
Ex.: média 9,0 com frequência 60% resulta em reprovado por falta.

CA4. Enquanto houver nota pendente, a situação é cursando, não
reprovado.
Ex.: aluno com a primeira nota lançada e a segunda nula não é
reprovado por média zero.

CA5. A nota substitutiva substitui a menor entre as duas regulares,
adotando a combinação mais favorável ao aluno.

CA6. Nota fora de 0 a 10 e frequência fora de 0 a 100 são rejeitadas
pelo domínio do tipo, não por validação de aplicação.


## HISTÓRIA 4 — Oferta sem conflito

Como secretaria,
quero que o sistema impeça alocações impossíveis,
para não descobrir o conflito no primeiro dia de aula.

Origem: RO5, RO6, RO7. Tela de horários do portal.

### Critérios de aceite

CA1. Duas turmas não ocupam a mesma sala, no mesmo dia, em faixas de
horário sobrepostas.
Ex.: sala PIA2, segunda-feira, 19:15–20:30 e 20:00–21:00 conflitam.

    Nota de implementação. Restrição EXCLUDE com índice GiST sobre o
    tipo de intervalo, exigindo a extensão btree_gist. É restrição de
    integridade, não verificação de aplicação.

CA2. Faixas que apenas se tocam nos extremos NÃO conflitam.
Ex.: 19:15–20:30 e 20:45–22:00 coexistem — é o caso real do portal,
com intervalo entre os dois encontros.

CA3. A mesma regra vale para o professor: ninguém leciona duas turmas
simultâneas.

CA4. A capacidade da sala comporta as vagas da turma.

CA5. Aula não é agendada em feriado do campus da sala.


## HISTÓRIA 5 — Currículo versionado

Como coordenação,
quero manter versões de currículo por ano, semestre e grade,
para que a mudança de grade não altere a exigência de quem já ingressou.

Origem: RA3, RA4, RP3. Campo "2023/1 Grade B" no portal.

### Critérios de aceite

CA1. Um curso tem vários currículos; apenas um está vigente.

    Nota de implementação. Índice único parcial com predicado sobre a
    coluna de vigência. Atende ao requisito de ao menos um índice
    parcial do Marco 2.

CA2. O currículo é identificado por ano, semestre e grade.
Ex.: 2023/1 Grade B é distinto de 2023/1 Grade A.

CA3. O aluno permanece vinculado ao currículo do seu ingresso. Mudar o
currículo vigente do curso não altera os alunos existentes.

CA4. Curso e currículo do aluno são registrados de forma independente.

    Nota sobre normalização. Há redundância aparente: o curso seria
    derivável do currículo. Mas as dimensões são independentes pelo
    CA3 — o vínculo com o curso é permanente, o com o currículo é
    versionado, e a migração de grade não troca o curso.

CA5. A migração de currículo é ato registrado, não alteração
silenciosa.


## HISTÓRIA 5.1 — Organização do currículo em ciclos e módulos

Como coordenação,
quero que cada currículo defina sua própria estrutura de ciclos e
módulos,
para que cursos com organizações diferentes coexistam sem exceção no
modelo.

Origem: RA9, RA10, RA11, RA12. Matrizes curriculares de Ciência da
Computação, Engenharia de Software e Matemática.

### A evidência

Três matrizes do mesmo IESB, com estruturas incompatíveis entre si:

| | Ciência da Computação | Engenharia de Software | Matemática |
|---|---|---|---|
| modalidade | presencial | EAD | EAD |
| ciclos | 4 | 4 | 4 |
| módulos por ciclo | 2 (A e B) | 4 (numerados 1 a 16) | 4 (numerados 1 a 16) |
| CH por disciplina | 60h | 90 a 100h | 90 a 150h |
| periodicidade | semestral | trimestral | trimestral |

Fixar ciclo e módulo como colunas de valor único atenderia a um curso e
quebraria nos outros. A organização é propriedade do currículo, não do
sistema.

### Critérios de aceite

CA1. O currículo declara quantos ciclos possui e quantos módulos há em
cada ciclo.
Ex.: Ciência da Computação 2020/1 tem 4 ciclos de 2 módulos;
Engenharia de Software EAD tem 4 ciclos de 4 módulos.

CA2. O módulo é entidade do currículo, não número solto na disciplina.

    Nota de implementação. A cadeia é currículo, ciclo, módulo,
    componente. Um curso com organização diferente entra como dado,
    sem alteração de tabela.

CA3. O currículo declara modalidade e periodicidade.
Ex.: presencial semestral; EAD trimestral.

CA4. Há currículos em que não existe pré-requisito entre módulos do
mesmo ciclo.

    Evidência. As matrizes EAD declaram: "Ciclos são compostos de
    módulos nos quais as disciplinas dialogam de forma articulada
    entre si. Não existe pré-requisito entre os módulos do mesmo
    ciclo." A matriz presencial de Ciência da Computação não faz essa
    ressalva e tem pré-requisitos encadeados.

CA5. O componente curricular tem natureza, e a natureza determina como
ele conta para a integralização:

    obrigatoria     compõe a carga do núcleo
    eletiva         escolha entre as ofertadas pelo currículo
    optativa        escolha aberta, inclusive de outro curso
    livre           cursada por interesse, com limite de quantidade
    estagio         carga própria, exigência separada

CA6. O componente tem eixo formativo, para relatório de integralização.
Ex.: Fundamentos da Área, Profissionalizante, Prática e Carreira.

CA7. A disciplina tem modalidade de oferta própria, independente da
modalidade do currículo.
Ex.: em curso presencial, há disciplinas digitais com encontro de 3h a
cada 45 dias e outras a cada 20 dias — e o resumo de carga horária as
contabiliza em linhas distintas.

CA8. Disciplina livre tem limite de quantidade e ciclo mínimo.
Ex.: "O aluno poderá cursar até quatro disciplinas livres, de forma
gratuita, a partir do 2º ciclo."

CA9. A optativa cursada em outro curso integra o histórico do vínculo
pelo qual o aluno se matriculou.
Ex.: aluno de Ciência da Computação cursa disciplina de Engenharia como
optativa; a nota entra no histórico do RA de Ciência da Computação.


## HISTÓRIA 6 — Progresso do aluno no curso

Como aluno,
quero saber quanto já cumpri e quanto falta,
para planejar quantos semestres restam.

Origem: RA2, RM9, RP4. Bloco de carga horária do portal.

### Critérios de aceite

CA1. A carga cumprida é a soma da carga das disciplinas aprovadas.
Ex.: exigida 3.300,00 e cumprida 870,00.

CA2. A carga cumprida é DERIVADA, não informada. Não pode divergir do
histórico.

    Nota de implementação. View, não coluna armazenada no aluno.
    Coluna materializada exigiria gatilho a cada lançamento de nota e
    poderia divergir.

CA3. Atividade complementar é contabilizada em separado, com exigência
própria.
Ex.: 120,00 exigidas, 75,00 cumpridas.

CA4. Disciplina cursada e reprovada não conta carga horária.

CA5. Disciplina aproveitada de outra instituição conta carga, e a
origem fica registrada.


## HISTÓRIA 7 — Atividades complementares

Como aluno,
quero submeter atividades e acompanhar a validação,
para cumprir a carga exigida pelo curso.

Origem: RC1, RC2, RC3. Serviço de atividades complementares no portal.

### Critérios de aceite

CA1. A atividade tem categoria, descrição, carga solicitada e
comprovante.

CA2. A carga SOLICITADA é distinta da VALIDADA. Só a validada conta.
Ex.: o aluno solicita 40h de curso; a coordenação valida 20h pelo
limite da categoria.

CA3. Enquanto pendente, a atividade não soma carga.

CA4. A validação registra o responsável e a data.

CA5. Cada categoria tem limite máximo de horas aproveitáveis.


## HISTÓRIA 8 — Requerimentos da secretaria

Como aluno,
quero abrir requerimentos e acompanhar o andamento,
para resolver questões acadêmicas sem presença física.

Origem: RR1, RR2. Os 24 serviços acadêmicos do portal.

### Critérios de aceite

CA1. O requerimento tem tipo, data de abertura, situação e parecer.

CA2. A situação percorre aberto, em análise, deferido ou indeferido.

CA3. O requerimento deferido produz efeito no sistema.
Ex.: trancamento deferido muda o status da matrícula e libera a vaga.

CA4. O parecer registra o responsável e a data da decisão.

CA5. Requerimento indeferido mantém o estado anterior inalterado.


## HISTÓRIA 8.1 — Avaliações e lançamento de notas

Como professor,
quero definir as avaliações da minha turma e lançar as notas por
avaliação,
para que a média seja composta pelo que de fato foi avaliado.

Origem: RV1 a RV4. Menu "Avaliação" do portal.

### Critérios de aceite

CA1. A turma define suas avaliações, cada uma com título, peso e data.
Ex.: A1 com peso 0,4 e A2 com peso 0,6, conforme o plano de ensino.

CA2. A nota é lançada por avaliação e por aluno, não diretamente no
histórico.

    Consequência. A média do histórico passa a ser derivada das notas
    das avaliações, e não informada. Um lançamento corrigido recalcula
    a média sem intervenção.

CA3. Nota lançada fora da faixa válida é rejeitada pelo domínio do
tipo.

CA4. A frequência é apurada pelo registro de presença nas aulas da
turma.

    Nota. Presença por aula é o dado primário; a frequência percentual
    é derivada da razão entre presenças e aulas ministradas.

CA5. Aula em data de feriado do campus não é contabilizada no
denominador da frequência.

CA6. A alteração de nota já lançada é registrada na auditoria, com
valor antigo e valor novo — ver História 10.


## HISTÓRIA 8.2 — Mensalidade e bolsas

Como setor financeiro,
quero que as mensalidades sejam geradas automaticamente e os descontos
aplicados conforme a vigência,
para que o faturamento não dependa de lançamento manual.

Origem: RF1 a RF5. Menus "Financeiro" e "Serviços Financeiros" do
portal; Módulo 3 do documento de escopo.

### Critérios de aceite

CA1. A mensalidade é gerada por vínculo de aluno e período letivo
corrente.

    Consequência. Uma pessoa com três vínculos tem três faturamentos
    independentes — ver História 0.

CA2. O valor original deriva da carga horária matriculada no período ou
do valor fixo do curso, conforme a política vigente.

CA3. A bolsa é um desconto percentual, com data de concessão e de
validade.

CA4. O valor final aplica os descontos VIGENTES na competência da
mensalidade.

    Consequência. Bolsa que venceu em junho não reduz a mensalidade de
    agosto, ainda que o registro da concessão permaneça no sistema.

CA5. A mensalidade tem vencimento, situação e, quando quitada, data de
pagamento.

CA6. O percentual de desconto está limitado à faixa de zero a cem, pelo
domínio do tipo.

CA7. Mensalidade paga não é alterada; correção se faz por lançamento
novo.


## HISTÓRIA 9 — Privacidade do histórico

Como aluno,
quero que meus dados acadêmicos não sejam visíveis a outros alunos,
para que meu desempenho seja meu.

Origem: RS3, RS4. Exigência do enunciado.

### Critérios de aceite

CA1. Um aluno autenticado enxerga apenas as próprias linhas de
histórico, matrícula e requerimento.

CA2. A restrição é do BANCO, não da aplicação. Consulta direta com
credencial de aluno já vem filtrada.

    Nota de implementação. Row-level security com política comparando
    o aluno da linha com o usuário corrente. O enunciado exige
    demonstrar ao vivo.

CA3. Secretaria e coordenação enxergam todos os registros.

CA4. Nenhum papel de aluno altera nota ou frequência; apenas lê.


## HISTÓRIA 10 — Rastreabilidade de alterações sensíveis

Como coordenação,
quero saber quem alterou um dado sensível, quando e o que mudou,
para apurar divergências sem depender de memória.

Origem: RS1, RS2, RS3. Módulo 4 do documento de escopo.

### Critérios de aceite

CA1. Toda inserção, alteração e exclusão em dado sensível gera registro
de log.

    São sensíveis, no mínimo: matrícula em turma, nota de avaliação,
    frequência e situação do histórico.

CA2. O registro guarda o VALOR ANTIGO e o VALOR NOVO.

    Consequência. Saber que a nota mudou não basta: a apuração precisa
    do que ela era. Registrar apenas a ação tornaria o log inútil para
    contestação.

CA3. O usuário e o instante são obtidos do próprio servidor, não
informados pela aplicação.

    Consequência. Uma aplicação comprometida não consegue forjar a
    autoria do registro.

CA4. O detalhe é armazenado em formato semiestruturado, permitindo
estrutura variável conforme a tabela e a ação auditada.

CA5. O log é somente-inserção: nenhum papel altera ou apaga linhas já
gravadas.

CA6. A exclusão de uma matrícula preserva o registro de auditoria.

    Consequência. O log não pode depender por chave estrangeira do
    registro auditado, sob pena de o rastro desaparecer junto com o
    que deveria documentar.


# Requisitos não funcionais

| ID | Requisito | Origem |
|----|-----------|--------|
| RNF1 | Carga mínima: 100 alunos, 6 turmas, 300 matrículas | enunciado 4.1 |
| RNF2 | O SQL executa de uma vez, do zero, sem intervenção | aviso do professor |
| RNF3 | Consultas com ganho medido por EXPLAIN ANALYZE | enunciado 4.2 |
| RNF4 | Ambiente: contêiner Docker com PostgreSQL 17 | enunciado 9 |
| RNF5 | Scripts numerados na ordem de execução | enunciado 4.3 |
| RNF6 | README que suba o banco do zero | enunciado 4.3 |
| RNF7 | Backup e restauração reproduzíveis | enunciado 4.2 |
| RNF8 | Histórico de commits distribuído entre os integrantes | enunciado 4.3 |


# Decisões de modelagem registradas

## D1. Ciclo e módulo, não período

O documento de escopo do Módulo 1 fala em "Disciplinas organizadas por
períodos". As matrizes curriculares reais mostram ciclos compostos de
módulos, com quantidades diferentes por curso.

Adotou-se ciclo e módulo, que é a estrutura observada. O período, quando
necessário, é derivado da posição do módulo na sequência — o caminho
inverso não seria possível.

## D2. Financeiro dentro do escopo

O Módulo 3 do documento de escopo o inclui explicitamente. O modelo
lógico do professor não o contempla, por ser um recorte do núcleo
acadêmico.

## D3. Pessoa separada de seus papéis

Ver História 0. O CPF pertence à pessoa; o RA, ao vínculo. Decorre do
caso real de uma pessoa cursando três graduações simultâneas.

## D4. Nota lançada por avaliação, não no histórico

Ver História 8.1. A média do histórico passa a ser derivada das notas
das avaliações. O modelo do professor lança direto no histórico, o que
impede rastrear a composição da média.


# Rastreamento: história e entregável

| História | Marco 1 | Marco 2 |
|----------|---------|---------|
| 0 pessoa e vínculos | DDL e carga | — |
| 1 matrícula | restrição de vagas | anomalia e duas correções |
| 2 elegibilidade | consulta recursiva | — |
| 3 aprovação | coluna gerada, domínios | view de histórico |
| 4 oferta | EXCLUDE com GiST | índice, view de oferta |
| 5 currículo | índice parcial | — |
| 5.1 ciclos e módulos | DDL e carga | — |
| 6 progresso | consulta de agregação | view de progresso |
| 7 ativ. complementares | DDL e carga | — |
| 8 requerimentos | DDL e carga | gatilho de efeito |
| 8.1 avaliações | DDL e carga | view de composição da média |
| 8.2 mensalidade e bolsas | DDL e carga | view de faturamento |
| 9 privacidade | — | RLS e papéis |
| 10 rastreabilidade | tabela de log | gatilho com valor antigo e novo |
