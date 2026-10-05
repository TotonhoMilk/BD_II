# ==============================================================================
# GERADOR DO DER — Sistema Academico IESB
# ==============================================================================
#   python gerar_der.py
#
# Produz der-conceitual.drawio, que abre no draw.io para edicao manual.
#
# POR QUE GERAR EM VEZ DE DESENHAR
# Com 30+ entidades, posicionar a mao e lento e o resultado fica
# irregular. Aqui o layout e calculado: as faixas tem altura proporcional
# ao conteudo, as entidades se alinham na grade, e refazer depois de uma
# mudanca de escopo custa uma reexecucao.
#
# O arquivo gerado e um .drawio comum — depois de aberto, pode ser
# editado normalmente. Este script nao precisa ser executado de novo
# para o diagrama funcionar.
#
# ORGANIZACAO
# Sete faixas horizontais, na ordem de DEPENDENCIA, nao de importancia:
# nada na faixa 4 existe sem as faixas 1 a 3.
#
#   1 GEOGRAFIA E ESTRUTURA FISICA   pais -> ... -> sala
#   2 ESTRUTURA ACADEMICA            curso -> curriculo -> ciclo -> modulo
#   3 PESSOAS                        pessoa -> aluno | professor | funcionario
#   4 OFERTA                         periodo letivo, turma, horario, aula
#   5 VIDA ACADEMICA                 matricula, historico, avaliacao
#   6 FINANCEIRO                     mensalidade, bolsa
#   7 SECRETARIA E AUDITORIA         requerimento, atividade, log
#
# As faixas 1 a 3 ficam lado a lado no topo, porque sao independentes
# entre si. As demais ocupam a largura inteira, porque atravessam blocos.

import html
import os

SAIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                     "der-conceitual.drawio")

# ------------------------------------------------------------------ cores
# Escolhidas para manter contraste quando impressas em tons de cinza: a
# luminosidade e crescente do bloco 1 ao 7.
CORES = {
    "geo":    ("#DAE8FC", "#6C8EBF"),   # preenchimento, borda
    "acad":   ("#D5E8D4", "#82B366"),
    "pessoa": ("#FFE6CC", "#D79B00"),
    "oferta": ("#FFF2CC", "#D6B656"),
    "vida":   ("#F8CECC", "#B85450"),
    "fin":    ("#E1D5E7", "#9673A6"),
    "sec":    ("#F5F5F5", "#666666"),
}

FAIXA_TITULO = "#FFFFFF"


def esc(s):
    return html.escape(str(s), quote=True)


class Der:
    """Acumula celulas e monta o XML no fim."""

    def __init__(self):
        self.cells = []
        self.n = 10           # ids 0 e 1 sao reservados pelo drawio

    def _id(self):
        self.n += 1
        return str(self.n)

    def faixa(self, titulo, x, y, w, h, cor):
        """Retangulo de fundo que agrupa um bloco tematico."""
        fill, stroke = CORES[cor]
        i = self._id()
        self.cells.append(
            f'<mxCell id="{i}" value="{esc(titulo)}" '
            f'style="rounded=0;whiteSpace=wrap;html=1;fillColor={fill};'
            f'strokeColor={stroke};opacity=30;verticalAlign=top;'
            f'fontSize=20;fontStyle=1;fontColor={stroke};align=left;'
            f'spacingLeft=16;spacingTop=8;" vertex="1" parent="1">'
            f'<mxGeometry x="{x}" y="{y}" width="{w}" height="{h}" '
            f'as="geometry"/></mxCell>')
        return i

    def entidade(self, nome, atributos, x, y, cor, largura=220,
                 associativa=False, referencia=False):
        """Uma entidade, como swimlane: o titulo e a lista de atributos
        ficam em celulas separadas, o que permite editar cada linha no
        draw.io sem mexer no resto."""
        fill, stroke = CORES[cor]
        if referencia:
            fill, stroke = "#FAFAFA", "#B3B3B3"
        tracejado = "dashed=1;dashPattern=8 8;" if (associativa or referencia) else ""

        altura = 30 + len(atributos) * 22
        i = self._id()
        rotulo = nome + ("  (ref)" if referencia else "")
        self.cells.append(
            f'<mxCell id="{i}" value="{esc(rotulo)}" '
            f'style="swimlane;fontStyle=1;childLayout=stackLayout;'
            f'horizontal=1;startSize=30;fillColor={fill};'
            f'strokeColor={stroke};{tracejado}horizontalStack=0;'
            f'resizeParent=1;resizeLast=0;collapsible=0;marginBottom=0;'
            f'html=1;fontSize=13;" vertex="1" parent="1">'
            f'<mxGeometry x="{x}" y="{y}" width="{largura}" '
            f'height="{altura}" as="geometry"/></mxCell>')

        for k, attr in enumerate(atributos):
            ai = self._id()
            # PK em negrito, FK em italico, derivado com barra
            if attr.startswith("#"):          # PK
                texto, fonte = attr[1:], "fontStyle=1;"
            elif attr.startswith("*"):        # FK
                texto, fonte = attr[1:], "fontStyle=2;"
            elif attr.startswith("/"):        # derivado
                texto, fonte = attr, "fontStyle=2;fontColor=#666666;"
            else:
                texto, fonte = attr, ""
            self.cells.append(
                f'<mxCell id="{ai}" value="{esc(texto)}" '
                f'style="text;strokeColor=none;fillColor=none;align=left;'
                f'verticalAlign=middle;spacingLeft=8;html=1;fontSize=12;'
                f'{fonte}" vertex="1" parent="{i}">'
                f'<mxGeometry y="{30 + k*22}" width="{largura}" '
                f'height="22" as="geometry"/></mxCell>')
        return i

    # Lados de conexão, como (x, y) relativos à caixa. Declarar por onde a
    # linha sai e entra é o que evita o draw.io escolher sozinho — e ele
    # escolhe mal: contorna a entidade e cruza o que estiver no caminho.
    LADO = {
        "dir":   (1, 0.5),      # direita, meio
        "esq":   (0, 0.5),      # esquerda, meio
        "cima":  (0.5, 0),
        "baixo": (0.5, 1),
        "dir_alto":   (1, 0.25),
        "dir_baixo":  (1, 0.75),
        "esq_alto":   (0, 0.25),
        "esq_baixo":  (0, 0.75),
    }

    def liga(self, origem, destino, card_o="1", card_d="N", rotulo="",
             especializacao=False, sai="dir", entra="esq", pontos=None):
        """Relacionamento com roteamento controlado.

        sai/entra   por qual lado de cada caixa a linha parte e chega
        pontos      lista de (x, y) absolutos por onde a linha passa,
                    para as ligações longas que precisam contornar
        """
        i = self._id()
        ex, ey = self.LADO[sai]
        nx, ny = self.LADO[entra]
        conexao = (f"exitX={ex};exitY={ey};exitDx=0;exitDy=0;"
                   f"entryX={nx};entryY={ny};entryDx=0;entryDy=0;")

        if especializacao:
            ponta = "endArrow=block;endFill=0;endSize=14;"
        else:
            ponta = "endArrow=ERmany;startArrow=ERone;"

        estilo = (f"{ponta}html=1;edgeStyle=orthogonalEdgeStyle;rounded=1;"
                  f"arcSize=12;strokeColor=#5A5A5A;strokeWidth=1.4;"
                  f"jumpStyle=arc;jumpSize=8;{conexao}")

        geo = '<mxGeometry relative="1" as="geometry">'
        if pontos:
            geo += '<Array as="points">'
            geo += "".join(f'<mxPoint x="{px}" y="{py}"/>' for px, py in pontos)
            geo += "</Array>"
        geo += "</mxGeometry>"

        self.cells.append(
            f'<mxCell id="{i}" value="{esc(rotulo)}" style="{estilo}" '
            f'edge="1" parent="1" source="{origem}" target="{destino}">'
            f'{geo}</mxCell>')

        if not especializacao:
            # Rótulos de cardinalidade afastados da caixa, para não colarem
            # no texto dos atributos.
            for valor, pos in ((card_o, -0.6), (card_d, 0.6)):
                if not valor:
                    continue
                li = self._id()
                self.cells.append(
                    f'<mxCell id="{li}" value="{esc(valor)}" '
                    f'style="edgeLabel;html=1;align=center;'
                    f'verticalAlign=middle;fontSize=11;fontColor=#444444;'
                    f'labelBackgroundColor=#FFFFFF;" '
                    f'vertex="1" connectable="0" parent="{i}">'
                    f'<mxGeometry x="{pos}" relative="1" as="geometry">'
                    f'<mxPoint as="offset"/></mxGeometry></mxCell>')
        return i

    def texto(self, conteudo, x, y, w=300, h=30, tamanho=12, negrito=False):
        i = self._id()
        self.cells.append(
            f'<mxCell id="{i}" value="{esc(conteudo)}" '
            f'style="text;html=1;align=left;verticalAlign=top;'
            f'fontSize={tamanho};{"fontStyle=1;" if negrito else ""}" '
            f'vertex="1" parent="1">'
            f'<mxGeometry x="{x}" y="{y}" width="{w}" height="{h}" '
            f'as="geometry"/></mxCell>')
        return i

    def salvar(self, caminho, largura, altura):
        corpo = "\n        ".join(self.cells)
        xml = f'''<mxfile host="app.diagrams.net" agent="gerar_der.py">
  <diagram id="der" name="DER Conceitual">
    <mxGraphModel dx="1400" dy="900" grid="1" gridSize="10" guides="1"
        tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1"
        pageWidth="{largura}" pageHeight="{altura}" math="0" shadow="0">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        {corpo}
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
'''
        with open(caminho, "w", encoding="utf-8") as f:
            f.write(xml)


# ==============================================================================
# ESQUELETO — as sete faixas e a legenda
# ==============================================================================
def main():
    d = Der()
    L, A = 3450, 3100          # dimensoes da pagina

    # --- cabecalho ---------------------------------------------------------
    d.texto("Sistema Acadêmico IESB — Modelo Conceitual", 40, 24, 1200, 40,
            tamanho=26, negrito=True)
    d.texto("Banco de Dados II (CCO072) · 2026/2 · "
            "Alexandre Vieira, Antônio Alexandre, Carlos Eduardo",
            40, 64, 1200, 24, tamanho=13)

    # --- faixas 1 a 3: lado a lado, sao independentes entre si -------------
    y0, h0 = 120, 760
    d.faixa("1 · GEOGRAFIA E ESTRUTURA FÍSICA", 40, y0, 1060, h0, "geo")
    d.faixa("2 · ESTRUTURA ACADÊMICA",          1130, y0, 1180, h0, "acad")
    d.faixa("3 · PESSOAS",                      2340, y0, 1020, h0, "pessoa")

    # --- faixas 4 a 7: largura inteira, atravessam blocos ------------------
    # A faixa 5 e a mais alta: o arranjo em estrela ocupa tres niveis.
    y1 = y0 + h0 + 60
    d.faixa("4 · OFERTA", 40, y1, 3320, 460, "oferta")

    y2 = y1 + 500
    d.faixa("5 · VIDA ACADÊMICA", 40, y2, 3320, 700, "vida")

    y3 = y2 + 740
    d.faixa("6 · FINANCEIRO",              40, y3, 1540, 400, "fin")
    d.faixa("7 · SECRETARIA E AUDITORIA", 1620, y3, 1740, 400, "sec")

    # ======================================================================
    # BLOCO 1 — GEOGRAFIA E ESTRUTURA FÍSICA
    # ======================================================================
    # Cadeia estritamente hierárquica, cada nível com um pai só:
    #     país > estado > cidade > campus > prédio > bloco > sala
    #
    # A hierarquia geográfica existe porque `cidade` como texto livre
    # aceitaria "Brasília", "brasilia" e "BSB" como lugares diferentes.
    # A predial vem dos códigos de sala do portal (PIA2, PJB1, PJB5), em
    # que P é prédio, a letra seguinte é bloco e o número é a sala.
    gx, gy = 80, 190

    e_pais = d.entidade("PAÍS", [
        "#pais_id", "nome", "sigla"], gx, gy, "geo", 200)

    e_estado = d.entidade("ESTADO", [
        "#estado_id", "*pais_id", "nome", "uf"], gx, gy + 140, "geo", 200)

    e_cidade = d.entidade("CIDADE", [
        "#cidade_id", "*estado_id", "nome"], gx, gy + 300, "geo", 200)

    e_campus = d.entidade("CAMPUS", [
        "#campus_id", "*cidade_id", "nome", "endereço"],
        gx, gy + 440, "geo", 200)

    e_predio = d.entidade("PRÉDIO", [
        "#predio_id", "*campus_id", "nome", "sigla"],
        gx + 280, gy + 440, "geo", 200)

    e_bloco = d.entidade("BLOCO", [
        "#bloco_id", "*predio_id", "nome", "sigla"],
        gx + 560, gy + 440, "geo", 200)

    e_sala = d.entidade("SALA", [
        "#sala_id", "*bloco_id", "código", "capacidade", "tipo"],
        gx + 560, gy + 190, "geo", 220)

    # A cadeia desce pela coluna da esquerda e vira para a direita no
    # campus: cada ligacao usa o lado natural, sem contorno.
    d.liga(e_pais,   e_estado, sai="baixo", entra="cima")
    d.liga(e_estado, e_cidade, sai="baixo", entra="cima")
    d.liga(e_cidade, e_campus, sai="baixo", entra="cima")
    d.liga(e_campus, e_predio, sai="dir",   entra="esq")
    d.liga(e_predio, e_bloco,  sai="dir",   entra="esq")
    d.liga(e_bloco,  e_sala,   sai="cima",  entra="baixo")

    d.texto("Código de sala PIA2 = Prédio I, bloco A, sala 2",
            gx + 280, gy + 620, 300, 40, tamanho=11)

    # ======================================================================
    # BLOCO 2 — ESTRUTURA ACADÊMICA
    # ======================================================================
    # A cadeia currículo > ciclo > módulo > componente é o que permite
    # cursos com organizações diferentes coexistirem: Ciência da
    # Computação tem 4 ciclos de 2 módulos; Engenharia de Software e
    # Matemática, 4 ciclos de 4 módulos. Ver História 5.1.
    ax, ay = 1170, 190

    e_curso = d.entidade("CURSO", [
        "#curso_id", "*campus_id", "código", "nome", "grau",
        "ch_exigida", "ch_ativ_compl", "ato_mec"], ax, ay, "acad", 230)

    e_curriculo = d.entidade("CURRÍCULO", [
        "#curriculo_id", "*curso_id", "ano_vigência", "semestre",
        "grade", "modalidade", "periodicidade", "vigente"],
        ax, ay + 250, "acad", 230)

    e_ciclo = d.entidade("CICLO", [
        "#ciclo_id", "*curriculo_id", "ordem", "nome"],
        ax + 290, ay + 250, "acad", 200)

    e_modulo = d.entidade("MÓDULO", [
        "#modulo_id", "*ciclo_id", "ordem", "nome"],
        ax + 290, ay + 420, "acad", 200)

    e_disciplina = d.entidade("DISCIPLINA", [
        "#disciplina_id", "código", "nome", "ch_teórica", "ch_prática",
        "/ch_total", "modalidade", "ementa"], ax + 580, ay, "acad", 230)

    e_comp = d.entidade("COMPONENTE CURRICULAR", [
        "#componente_id", "*modulo_id", "*disciplina_id",
        "natureza", "eixo"], ax + 580, ay + 300, "acad", 230,
        associativa=True)

    e_prereq = d.entidade("PRÉ-REQUISITO", [
        "*disciplina_id", "*requisito_id", "vínculo"],
        ax + 580, ay + 500, "acad", 230, associativa=True)

    d.liga(e_curso,      e_curriculo, sai="baixo", entra="cima")
    d.liga(e_curriculo,  e_ciclo,     sai="dir",   entra="esq")
    d.liga(e_ciclo,      e_modulo,    sai="baixo", entra="cima")
    d.liga(e_modulo,     e_comp,      sai="dir",   entra="esq")
    d.liga(e_disciplina, e_comp,      sai="baixo", entra="cima")
    # auto-relacionamento: sai e volta pela direita, contornando por fora
    d.liga(e_disciplina, e_prereq, "1", "N", "exige",
           sai="dir_baixo", entra="dir_alto",
           pontos=[(ax + 880, ay + 120), (ax + 880, ay + 520)])

    d.texto("natureza: obrigatória | eletiva | optativa | livre | estágio\n"
            "vínculo: pré-requisito | co-requisito",
            ax + 580, ay + 620, 340, 50, tamanho=11)

    # ======================================================================
    # BLOCO 3 — PESSOAS
    # ======================================================================
    # Especialização: pessoa é a entidade, aluno/professor/funcionário
    # são papéis. Todo aluno é pessoa; nem toda pessoa é aluno; e a mesma
    # pessoa pode acumular papéis.
    #
    # O CPF fica na PESSOA e o RA no VÍNCULO DE ALUNO. É o que permite
    # três graduações simultâneas com um cadastro só. Ver História 0.
    px, py = 2380, 190

    e_pessoa = d.entidade("PESSOA", [
        "#pessoa_id", "*cidade_id", "nome", "cpf", "nascimento",
        "email", "telefone"], px + 290, py, "pessoa", 230)

    e_aluno = d.entidade("ALUNO", [
        "#aluno_id", "*pessoa_id", "*curso_id", "*curriculo_id",
        "ra", "forma_ingresso", "ingresso", "/série", "ativo"],
        px, py + 290, "pessoa", 230)

    e_prof = d.entidade("PROFESSOR", [
        "#professor_id", "*pessoa_id", "matrícula", "titulação"],
        px + 290, py + 290, "pessoa", 220)

    e_func = d.entidade("FUNCIONÁRIO", [
        "#funcionario_id", "*pessoa_id", "matrícula", "cargo", "setor"],
        px + 560, py + 290, "pessoa", 220)

    # As tres especializacoes sobem para PESSOA. O triangulo vazado
    # aponta para a generalizacao, como manda a notacao.
    d.liga(e_aluno, e_pessoa, especializacao=True,
           sai="cima", entra="esq", pontos=[(px + 115, py + 120)])
    d.liga(e_prof,  e_pessoa, especializacao=True,
           sai="cima", entra="baixo")
    d.liga(e_func,  e_pessoa, especializacao=True,
           sai="cima", entra="dir", pontos=[(px + 670, py + 120)])

    # As referências evitam puxar linha do outro extremo da página.
    r_curriculo = d.entidade("CURRÍCULO", ["#curriculo_id"],
                             px, py + 520, "acad", 200, referencia=True)
    d.liga(r_curriculo, e_aluno, "1", "N", "segue",
           sai="cima", entra="baixo")

    d.texto("O RA pertence ao VÍNCULO, não à pessoa:\n"
            "três graduações = três alunos, uma pessoa, um CPF.",
            px + 290, py + 500, 340, 50, tamanho=11)

    # ======================================================================
    # BLOCO 4 — OFERTA
    # ======================================================================
    # A turma é a oferta concreta de uma disciplina num período, com
    # docente, vagas e horários. O horário é que amarra sala e faixa de
    # tempo — e é onde mora a restrição antichoque.
    ox, oy = 80, y1 + 60

    e_periodo = d.entidade("PERÍODO LETIVO", [
        "#periodo_id", "ano", "semestre", "data_início", "data_fim"],
        ox, oy, "oferta", 210)

    e_calend = d.entidade("EVENTO DE CALENDÁRIO", [
        "#evento_id", "*campus_id", "data", "descrição", "tipo"],
        ox, oy + 180, "oferta", 230)

    e_turma = d.entidade("TURMA", [
        "#turma_id", "*disciplina_id", "*periodo_id", "*professor_id",
        "código", "turno", "vagas"], ox + 280, oy, "oferta", 230)

    e_horario = d.entidade("HORÁRIO DE TURMA", [
        "#horario_id", "*turma_id", "*sala_id", "dia_semana", "faixa"],
        ox + 570, oy, "oferta", 230, associativa=True)

    e_aula = d.entidade("AULA", [
        "#aula_id", "*horario_id", "data", "conteúdo", "ministrada"],
        ox + 860, oy, "oferta", 220)

    r_disc_o = d.entidade("DISCIPLINA", ["#disciplina_id"],
                          ox + 280, oy + 230, "acad", 200, referencia=True)
    r_prof_o = d.entidade("PROFESSOR", ["#professor_id"],
                          ox + 520, oy + 230, "pessoa", 200, referencia=True)
    r_sala_o = d.entidade("SALA", ["#sala_id"],
                          ox + 760, oy + 230, "geo", 180, referencia=True)

    d.liga(e_periodo,  e_turma,   sai="dir",  entra="esq")
    d.liga(e_turma,    e_horario, sai="dir",  entra="esq")
    d.liga(e_horario,  e_aula,    sai="dir",  entra="esq")
    d.liga(r_disc_o,   e_turma,   "1", "N", "ofertada em",
           sai="cima", entra="baixo")
    d.liga(r_prof_o,   e_turma,   "1", "N", "leciona",
           sai="cima", entra="baixo")
    d.liga(r_sala_o,   e_horario, "1", "N", "ocupa",
           sai="cima", entra="baixo")

    d.texto("ANTICHOQUE: nenhuma sala e nenhum professor em duas turmas "
            "no mesmo intervalo — restrição de exclusão no banco, não na "
            "aplicação.", ox + 1120, oy + 40, 420, 60, tamanho=11)

    # ======================================================================
    # BLOCO 5 — VIDA ACADÊMICA
    # ======================================================================
    # Matrícula liga o vínculo de aluno à turma. O histórico consolida o
    # resultado; as notas são lançadas por avaliação, e a média do
    # histórico é derivada delas. Ver História 8.1 e decisão D4.
    vx, vy = 80, y2 + 60

    # MATRICULA e o centro de cinco ligacoes. Dispor tudo na mesma linha
    # horizontal obrigaria as linhas a atravessarem HISTORICO e AVALIACAO.
    # Em estrela, cada ligacao usa um lado livre da caixa central.
    #
    #                    HISTORICO
    #                        |
    #   ALUNO ---------- MATRICULA ---------- APROVEITAMENTO
    #   TURMA ---------/     |         #                     NOTA   PRESENCA
    #
    mcx, mcy = vx + 640, vy + 180          # centro da estrela

    e_matricula = d.entidade("MATRÍCULA", [
        "#matricula_id", "*aluno_id", "*turma_id", "data", "status"],
        mcx, mcy, "vida", 230)

    e_historico = d.entidade("HISTÓRICO", [
        "#historico_id", "*matricula_id", "/media_final", "/menção",
        "/frequência", "situação"], mcx, vy - 20, "vida", 230)

    e_nota = d.entidade("NOTA DE AVALIAÇÃO", [
        "*avaliacao_id", "*matricula_id", "nota"],
        mcx - 60, mcy + 230, "vida", 220, associativa=True)

    e_presenca = d.entidade("PRESENÇA", [
        "*aula_id", "*matricula_id", "presente", "justificativa"],
        mcx + 280, mcy + 230, "vida", 220, associativa=True)

    e_avaliacao = d.entidade("AVALIAÇÃO", [
        "#avaliacao_id", "*turma_id", "título", "peso", "data"],
        mcx - 400, mcy + 230, "vida", 220)

    e_aproveit = d.entidade("APROVEITAMENTO", [
        "#aproveitamento_id", "*aluno_id", "*disciplina_id",
        "instituição_origem", "ch_aproveitada", "deferido"],
        mcx + 640, mcy - 40, "vida", 250)

    # Referencias na coluna da esquerda, alinhadas com quem as consome.
    r_aluno_v = d.entidade("ALUNO", ["#aluno_id"],
                           vx + 60, mcy - 40, "pessoa", 190, referencia=True)
    r_turma_v = d.entidade("TURMA", ["#turma_id"],
                           vx + 60, mcy + 90, "oferta", 190, referencia=True)
    r_aula_v  = d.entidade("AULA", ["#aula_id"],
                           mcx + 640, mcy + 230, "oferta", 190,
                           referencia=True)

    # Do centro para fora, cada uma por um lado distinto
    d.liga(r_aluno_v,   e_matricula, "1", "N", "cursa",
           sai="dir", entra="esq_alto")
    d.liga(r_turma_v,   e_matricula, "1", "N", "recebe",
           sai="dir", entra="esq_baixo")
    d.liga(e_matricula, e_historico, "1", "1",
           sai="cima", entra="baixo")
    d.liga(e_matricula, e_nota, "1", "N",
           sai="baixo", entra="cima")
    d.liga(e_matricula, e_presenca, "1", "N",
           sai="dir_baixo", entra="cima",
           pontos=[(mcx + 480, mcy + 120)])
    d.liga(e_avaliacao, e_nota, "1", "N",
           sai="dir", entra="esq")
    d.liga(r_aula_v,    e_presenca, "1", "N",
           sai="esq", entra="dir")
    d.liga(r_aluno_v,   e_aproveit, "1", "N",
           sai="cima", entra="cima",
           pontos=[(vx + 155, vy - 60), (mcx + 765, vy - 60)])

    d.texto("A média do histórico é DERIVADA das notas das avaliações, "
            "e a menção, da média. Corrigir um lançamento recalcula tudo "
            "sem intervenção.", vx + 1700, vy + 300, 420, 60, tamanho=11)

    # ======================================================================
    # BLOCO 6 — FINANCEIRO
    # ======================================================================
    # A mensalidade é por VÍNCULO e período: três graduações produzem
    # três faturamentos independentes. A bolsa é percentual com vigência,
    # e só desconta na competência em que está vigente.
    fx, fy = 80, y3 + 60

    e_mensal = d.entidade("MENSALIDADE", [
        "#mensalidade_id", "*aluno_id", "*periodo_id", "competência",
        "valor_original", "/valor_final", "vencimento", "pagamento",
        "situação"], fx + 280, fy, "fin", 230)

    e_bolsa = d.entidade("BOLSA", [
        "#bolsa_id", "nome", "percentual", "ativa"],
        fx + 570, fy, "fin", 200)

    e_alunobolsa = d.entidade("BOLSA DO ALUNO", [
        "*aluno_id", "*bolsa_id", "concessão", "validade"],
        fx + 840, fy, "fin", 220, associativa=True)

    r_aluno_f = d.entidade("ALUNO", ["#aluno_id"],
                           fx, fy, "pessoa", 190, referencia=True)
    r_per_f = d.entidade("PERÍODO LETIVO", ["#periodo_id"],
                         fx, fy + 120, "oferta", 190, referencia=True)

    d.liga(r_aluno_f, e_mensal, "1", "N", sai="dir", entra="esq_alto")
    d.liga(r_per_f,   e_mensal, "1", "N", sai="dir", entra="esq_baixo")
    d.liga(e_bolsa,   e_alunobolsa, "1", "N", sai="dir", entra="esq")
    # contorna por baixo, para nao atravessar MENSALIDADE
    d.liga(r_aluno_f, e_alunobolsa, "1", "N",
           sai="baixo", entra="baixo",
           pontos=[(fx + 95, fy + 300), (fx + 950, fy + 300)])

    d.texto("valor_final aplica os descontos VIGENTES na competência.",
            fx + 280, fy + 250, 420, 30, tamanho=11)

    # ======================================================================
    # BLOCO 7 — SECRETARIA E AUDITORIA
    # ======================================================================
    # O log registra valor antigo e novo, e NÃO tem chave estrangeira
    # para o registro auditado: se a matrícula for excluída, o rastro
    # precisa sobreviver. Ver História 10, CA6.
    sx, sy = 1660, y3 + 60

    e_requer = d.entidade("REQUERIMENTO", [
        "#requerimento_id", "*aluno_id", "*funcionario_id", "tipo",
        "abertura", "situação", "parecer", "decisão"],
        sx + 260, sy, "sec", 230)

    e_ativcompl = d.entidade("ATIVIDADE COMPLEMENTAR", [
        "#atividade_id", "*aluno_id", "*funcionario_id", "categoria",
        "descrição", "ch_solicitada", "ch_validada", "situação"],
        sx + 550, sy, "sec", 250)

    e_log = d.entidade("LOG DE AUDITORIA", [
        "#log_id", "tabela", "registro_id", "ação", "ocorrido_em",
        "usuário", "valor_antigo", "valor_novo"],
        sx + 860, sy, "sec", 230)

    r_aluno_s = d.entidade("ALUNO", ["#aluno_id"],
                           sx, sy, "pessoa", 180, referencia=True)
    r_func_s = d.entidade("FUNCIONÁRIO", ["#funcionario_id"],
                          sx, sy + 120, "pessoa", 180, referencia=True)

    d.liga(r_aluno_s, e_requer, "1", "N", "abre",
           sai="dir", entra="esq_alto")
    d.liga(r_func_s,  e_requer, "1", "N", "analisa",
           sai="dir", entra="esq_baixo")
    d.liga(r_aluno_s, e_ativcompl, "1", "N",
           sai="cima", entra="cima",
           pontos=[(sx + 90, sy - 30), (sx + 675, sy - 30)])

    d.texto("O log NÃO tem FK para o registro auditado: o rastro precisa "
            "sobreviver à exclusão do que documenta.",
            sx + 860, sy + 250, 420, 50, tamanho=11)

    # --- legenda -----------------------------------------------------------
    ly = y3 + 440
    d.texto("LEGENDA", 40, ly, 300, 24, tamanho=14, negrito=True)
    legenda = [
        "borda sólida .................. entidade",
        "borda tracejada ............... entidade associativa (N:N)",
        "cinza tracejado com (ref) ..... repetição de entidade distante",
        "negrito ....................... chave primária",
        "itálico ....................... chave estrangeira",
        "/ antes do nome ............... atributo derivado (coluna gerada)",
        "triângulo vazado .............. especialização (é um)",
        "pé de galinha ................. cardinalidade do relacionamento",
    ]
    for k, linha in enumerate(legenda):
        d.texto(linha, 40, ly + 30 + k * 22, 620, 20, tamanho=12)

    d.texto("A ordem das faixas é de DEPENDÊNCIA, não de importância: "
            "nada na faixa 4 existe sem as faixas 1 a 3.",
            700, ly + 30, 900, 40, tamanho=12)

    d.salvar(SAIDA, L, A)
    print(f"  gerado: {SAIDA}")
    print(f"  celulas: {len(d.cells)}")


if __name__ == "__main__":
    main()
