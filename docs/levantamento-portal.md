# Levantamento — portal acadêmico do IESB

Fonte primária dos requisitos: telas do portal do aluno, capturadas em
29/09/2026.

Este documento registra o que foi OBSERVADO, separado do que foi
INFERIDO. A distinção importa: o observado é evidência; o inferido é
hipótese que precisa de confirmação antes de virar requisito.


## Telas analisadas

| # | Tela | O que revela |
|---|------|--------------|
| 1 | Menu lateral | os subsistemas do portal |
| 2 | Cabeçalho do aluno | RA, curso, série, período, turma, status |
| 3 | Submenu Disciplina | matriculadas, histórico, horários, quadro do curso |
| 4 | Histórico | dados do aluno, CH, atividades complementares, menções |
| 5 | Horários de aulas | dia, disciplina, turma, sala, faixa de horário |
| 6 | Disciplinas matriculadas | turma, disciplina, docente, início, plano de ensino |
| 7 | Serviços acadêmicos | 24 processos disponíveis ao aluno |


## Subsistemas identificados no menu

Os itens do menu lateral delimitam o escopo do sistema real:

| Item do menu | Subsistema |
|--------------|-----------|
| Aviso | comunicação institucional |
| Manuais | documentação |
| Avaliação | notas e avaliações |
| Disciplina | oferta, histórico, horários |
| Cadastro | dados pessoais |
| Secretaria Virtual | requerimentos |
| Financeiro | mensalidades, negociação |
| Canal Direto | atendimento |
| Calendário | calendário acadêmico |
| Normas Acadêmicas | regulamentos |
| Serviços Acadêmicos | os 24 processos |
| Serviços Financeiros | boletos, negociação |
| Renovação de Matrícula | processo periódico |
| Avaliações Institucionais | pesquisa institucional |


## OBSERVADO — o que as telas mostram

### O1. Identificação do aluno

    RA: 2512130008
    Curso: 2130 - Ciência da Computação
    Série: 3   Período: 2   Turma: CCON3A
    Status: Ativo

O curso tem código numérico próprio (2130) além do nome.

O aluno tem SÉRIE e PERÍODO, que são posição na grade, não o mesmo que
período letivo. E tem uma turma de vínculo principal (CCON3A), distinta
das turmas de cada disciplina.

### O2. Currículo é versionado com grade

    Currículo: 2023/1 Grade B

Não é apenas ano de vigência: há ano, semestre e identificação de grade.
Duas grades podem coexistir no mesmo ano.

### O3. Ingresso tem forma

    Ingresso: 12/11/2024 por Vestibular

A forma de ingresso é registrada — vestibular, transferência, ENEM,
segunda graduação, portador de diploma.

### O4. Reconhecimento do curso pelo MEC

    Port./Decreto: Renovação de Reconhecimento: Portaria SERES/MEC
                   nº 150, de 21/06/2023, publicada no DOU nº 117
                   em 22/06/2023, Seção 1, pág. 183.
    Public. D.O.U.: Aug 26 2010

Dado obrigatório no histórico oficial. O curso carrega o ato legal que o
reconhece.

### O5. Carga horária é acumulada e comparada

    CH Exigida:  3.300,00
    CH Cumprida:   870,00

A CH cumprida é derivada: soma da carga horária das disciplinas
aprovadas. A exigida vem do curso.

### O6. Atividades complementares têm carga própria

    Ativ. Compl. Exigidas:  120,00
    Ativ. Compl. Cumpridas:  75,00

Contabilizadas separadamente da CH de disciplinas, com exigência própria
do curso. Requerem validação (há "Atividades complementares" nos
serviços).

### O7. O desempenho é expresso em MENÇÃO, não em nota

    Disciplina                                    Média   Situação
    MDC118 - Algoritmos e Programação I            MS      Aprovado
    MDCI010 - Cultura, Sociedade e Política        MM      Aprovado

A coluna "Média" mostra MS, MM — menções, não números. Pelo plano de
ensino de POO, a escala é:

    SS  9,0 a 10,0   Superior
    MS  7,0 a 8,9    Médio Superior
    MM  5,0 a 6,9    Médio
    MI  3,0 a 4,9    Médio Inferior
    II  0,1 a 2,9    Inferior
    SR  0,0          Sem rendimento

A situação ("Aprovado") é campo distinto da menção.

### O8. O histórico registra período e série da disciplina

    Período  Série  Disciplina                    Créditos  CH
    1/2025   1      MDC118 - Algoritmos I          60.00    60.00

Créditos e CH são campos distintos, ambos 60,00 neste caso.

### O9. Uma disciplina tem múltiplos encontros semanais

    Segunda-Feira  CCO072 - Banco de Dados II  CCONM2B  PIA2  19:15-20:30
    Segunda-Feira  CCO072 - Banco de Dados II  CCONM2B  PIA2  20:45-22:00

Dois encontros no MESMO dia, mesma sala, faixas diferentes, com
intervalo entre eles. Isso confirma o modelo turma_horario com uma linha
por encontro.

### O10. Sala tem código curto e pertence a um bloco

    PIA2, PJB1, PJB5

O padrão sugere: P = prédio, I/J = bloco, número = sala. Coerente com o
quadro da aula (TB_PREDIO, TB_BLOCO, TB_SALA).

### O11. O aluno cursa turmas de cursos e séries diferentes

    CCONM2B  Banco de Dados II          (Ciência da Computação, 2ª série)
    ENGCNM2B Engenharia de Software     (Engenharia, 2ª série)
    ENGCNM3B Sistemas Operacionais      (Engenharia, 3ª série)

O código da turma carrega curso, turno, série e letra. O aluno de um
curso cursa turmas ofertadas por outro — disciplinas compartilhadas
entre cursos.

### O12. Turma tem docente e data de início

    Turma     Disciplina                  Docente                Início
    CCONM2B   CCO072 - Banco de Dados II  Rodrigo Gonçalves      03/08/2026

E tem plano de ensino vinculado (botão "Visualizar").

### O13. Um docente leciona várias disciplinas

Rodrigo Gonçalves aparece em Banco de Dados II e Inteligência
Artificial; Marcelo Paiva em Governança de TI e Sistemas Operacionais.

### O14. Vinte e quatro serviços acadêmicos

    Cancelamento de Matrícula      Requerimento de Exercício Domiciliar
    Trancamento de Matrícula       Ajuste de Matrícula Fora do Prazo
    Cursos Livres                  ENADE Estágio
    Agendamento de Prova           Atendimento Agendado
    Atividades complementares      Biblioteca
    Carteirinha digital            Confirmar Token
    Declarações                    Entregar Documentos
    Exame Proficiência             Mudança de Turno
    NAADE Carreiras                Orientador TCC
    Reabertura de Matrícula        Requerimento de Matrícula Fora de Prazo
    Requerimento Aproveitamento de Estudos
    Revisão de Menção              Solicitação de Diploma
    Solicitação de Ementas

Cada um é um requerimento com fluxo próprio: abertura, análise, parecer,
deferimento ou indeferimento.


## INFERIDO — hipóteses a confirmar

### I1. Menção é derivada da média numérica

A média numérica provavelmente existe no banco e a menção é calculada
por faixa. O portal exibe só a menção, mas "Revisão de Menção" nos
serviços sugere que há um valor revisável por trás.

Alternativa: a menção é o dado primário e a média não é armazenada.
Menos provável, porque impediria cálculo de coeficiente de rendimento.

### I2. CH cumprida é coluna derivada ou view

870,00 é a soma das disciplinas aprovadas. Pode ser coluna
materializada no aluno, atualizada por trigger, ou calculada em view.

A segunda é mais correta: coluna derivada armazenada pode divergir.

### I3. Série do aluno é derivada do progresso

"Série: 3" provavelmente resulta do maior período de disciplina
concluída, ou é atribuída na renovação de matrícula.

### I4. Sala tem tipo

Não visível nas telas, mas o modelo do professor tem tipo_sala_t
(TEORICA, LABORATORIO). O IESB tem laboratórios.

### I5. Pré-requisito existe mas não aparece no portal do aluno

O portal não mostra a árvore de pré-requisitos, mas a renovação de
matrícula precisa validá-la. É regra de negócio invisível na interface.


## Impacto no escopo

As telas confirmam subsistemas que o modelo lógico do professor não tem:

| Subsistema | No modelo do professor | Confirmado no portal |
|------------|------------------------|----------------------|
| Localização (país/estado/cidade) | não | parcialmente (campus) |
| Estrutura física (prédio/bloco) | não | sim (códigos de sala) |
| Menção | não | sim |
| CH cumprida | não | sim |
| Atividades complementares | não | sim |
| Requerimentos | não | sim (24 serviços) |
| Financeiro | não | sim (menu) |
| Forma de ingresso | não | sim |
| Reconhecimento MEC | não | sim |

O modelo do professor é, portanto, um recorte didático — o núcleo de
matrícula. O escopo definido pelo grupo é o banco acadêmico completo,
com o portal como referência de realidade.
