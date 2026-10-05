# ==============================================================================
# GERADOR DO MODELO LOGICO — Sistema Academico IESB
# ==============================================================================
#   python gerar_logico.py
#
# Produz modelo-logico.drawio.
#
# FORMA ADOTADA
# O professor especificou a forma "Internal Storage" (shape=internalStorage,
# o retangulo com duas barras em L), organizada como tabela relacional.
#
# A forma sozinha e um retangulo unico, sem linhas — o que impediria uma
# FK de conectar no atributo exato. Aqui ela e usada como CONTAINER: a
# aparencia e a do Internal Storage, e cada atributo entra como celula
# filha posicionada, ganhando ancora propria.
#
# Resultado: visual pedido, com o mapa ligado atributo a atributo.
#
# O QUE O LOGICO ACRESCENTA AO CONCEITUAL
#   entidade      -> tabela com prefixo tb_
#   atributo      -> coluna com tipo, NOT NULL, UNIQUE
#   relacionamento-> chave estrangeira explicita, ligada linha a linha
#   N:N           -> tabela associativa com chave primaria composta
#   especializacao-> FK com UNIQUE
#   derivado      -> GENERATED ALWAYS AS ... STORED

import html
import os

SAIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                     "modelo-logico.drawio")

CORES = {
    "geo":    ("#DAE8FC", "#6C8EBF"),
    "acad":   ("#D5E8D4", "#82B366"),
    "pessoa": ("#FFE6CC", "#D79B00"),
    "oferta": ("#FFF2CC", "#D6B656"),
    "vida":   ("#F8CECC", "#B85450"),
    "fin":    ("#E1D5E7", "#9673A6"),
    "sec":    ("#F5F5F5", "#666666"),
}

LARGURA_PADRAO = 300
ALTURA_TITULO = 34           # a barra horizontal do Internal Storage
ALTURA_LINHA = 20


def esc(s):
    return html.escape(str(s), quote=True)


class Logico:

    def __init__(self):
        self.cells = []
        self.n = 10
        self.linhas = {}      # (tabela, coluna) -> indice da linha

    def _id(self):
        self.n += 1
        return str(self.n)

    def faixa(self, titulo, x, y, w, h, cor):
        fill, stroke = CORES[cor]
        i = self._id()
        self.cells.append(
            f'<mxCell id="{i}" value="{esc(titulo)}" '
            f'style="rounded=0;whiteSpace=wrap;html=1;fillColor={fill};'
            f'strokeColor={stroke};opacity=25;verticalAlign=top;'
            f'fontSize=20;fontStyle=1;fontColor={stroke};align=left;'
            f'spacingLeft=16;spacingTop=8;" vertex="1" parent="1">'
            f'<mxGeometry x="{x}" y="{y}" width="{w}" height="{h}" '
            f'as="geometry"/></mxCell>')
        return i

    def tabela(self, nome, colunas, x, y, cor, largura=LARGURA_PADRAO):
        """Uma tabela no formato Internal Storage.

        Cada coluna e uma tupla (marca, nome, tipo):
            marca  'PK' | 'FK' | 'PF' (ambos) | 'U' | 'G' (gerada) | ''
        """
        fill, stroke = CORES[cor]
        altura = ALTURA_TITULO + len(colunas) * ALTURA_LINHA + 8

        i = self._id()
        # dx e dy posicionam as barras do Internal Storage: dy alinha a
        # barra horizontal com o fim do titulo; dx mantem a vertical
        # estreita, so como marcador visual da forma.
        self.cells.append(
            f'<mxCell id="{i}" value="{esc(nome)}" '
            f'style="shape=internalStorage;whiteSpace=wrap;html=1;'
            f'dx={28};dy={ALTURA_TITULO};fillColor={fill};'
            f'strokeColor={stroke};verticalAlign=top;align=center;'
            f'fontSize=13;fontStyle=1;spacingTop=4;" '
            f'vertex="1" parent="1">'
            f'<mxGeometry x="{x}" y="{y}" width="{largura}" '
            f'height="{altura}" as="geometry"/></mxCell>')

        for k, (marca, coluna, tipo) in enumerate(colunas):
            self.linhas[(nome, coluna)] = k

            if marca == "PK":
                rotulo, estilo = f"PK  {coluna}", "fontStyle=5;"      # negrito+sublinhado
            elif marca == "PF":
                rotulo, estilo = f"PF  {coluna}", "fontStyle=5;fontColor=#8A4B08;"
            elif marca == "FK":
                rotulo, estilo = f"FK  {coluna}", "fontStyle=2;fontColor=#8A4B08;"
            elif marca == "U":
                rotulo, estilo = f"U   {coluna}", "fontStyle=0;"
            elif marca == "G":
                rotulo, estilo = f"/   {coluna}", "fontStyle=2;fontColor=#666666;"
            else:
                rotulo, estilo = f"    {coluna}", ""

            ai = self._id()
            self.cells.append(
                f'<mxCell id="{ai}" value="{esc(rotulo + "  :  " + tipo)}" '
                f'style="text;html=1;strokeColor=none;fillColor=none;'
                f'align=left;verticalAlign=middle;spacingLeft=34;'
                f'fontSize=11;{estilo}" vertex="1" parent="{i}">'
                f'<mxGeometry x="0" y="{ALTURA_TITULO + k*ALTURA_LINHA}" '
                f'width="{largura}" height="{ALTURA_LINHA}" '
                f'as="geometry"/></mxCell>')
        return i

    def altura_de(self, n_colunas):
        return ALTURA_TITULO + n_colunas * ALTURA_LINHA + 8

    def y_da_linha(self, n_colunas, indice):
        """Posicao relativa (0 a 1) do centro de uma linha, para ancorar
        a FK no atributo exato e nao na caixa inteira."""
        h = self.altura_de(n_colunas)
        return (ALTURA_TITULO + indice * ALTURA_LINHA + ALTURA_LINHA/2) / h

    # ------------------------------------------------------------------
    # GERENCIA DE LINHAS
    # ------------------------------------------------------------------
    # Com 44 chaves estrangeiras, deixar o roteamento a cargo do draw.io
    # produz linhas sobre tabelas e trajetos compartilhados. A solucao e
    # tratar os espacos vazios como CORREDORES e alocar uma raia por
    # ligacao, como cabos num eletroduto.
    #
    # Uma raia e uma coordenada — x para corredor vertical, y para
    # horizontal — reservada a uma unica linha naquele trecho. Duas
    # ligacoes nunca compartilham a mesma raia no mesmo intervalo.

    CORREDORES = {}          # nome -> proxima posicao livre

    def raia(self, corredor, base, passo=18):
        """Reserva a proxima posicao livre do corredor e devolve.

        base   coordenada inicial do corredor
        passo  distancia entre raias vizinhas
        """
        n = self.CORREDORES.get(corredor, 0)
        self.CORREDORES[corredor] = n + 1
        return base + n * passo

    # Espessura e estilo por natureza da ligacao
    TRACO = {
        "interna": (1.2, ""),                       # dentro do bloco
        "externa": (1.8, ""),                       # entre blocos
        "heranca": (2.0, "dashed=1;dashPattern=6 4;"),
    }

    def fk(self, org_id, org_ncols, org_idx, dst_id, dst_ncols, dst_idx,
           lado_org="dir", lado_dst="esq", pontos=None, rotulo="",
           cor="sec", tipo="interna"):
        """Liga a coluna FK da origem a coluna PK do destino.

        cor    bloco de ORIGEM — a linha herda sua cor, o que permite
               seguir o trajeto sem rastrear ponta a ponta
        tipo   interna | externa | heranca
        """
        ex = 1.0 if lado_org == "dir" else (0.0 if lado_org == "esq" else 0.5)
        ey = self.y_da_linha(org_ncols, org_idx)
        if lado_org == "cima":
            ey = 0.0
        elif lado_org == "baixo":
            ey = 1.0

        nx = 0.0 if lado_dst == "esq" else (1.0 if lado_dst == "dir" else 0.5)
        ny = self.y_da_linha(dst_ncols, dst_idx)
        if lado_dst == "cima":
            ny = 0.0
        elif lado_dst == "baixo":
            ny = 1.0

        largura, extra = self.TRACO[tipo]
        _, stroke = CORES.get(cor, CORES["sec"])
        if tipo == "heranca":
            stroke = "#444444"

        i = self._id()
        geo = '<mxGeometry relative="1" as="geometry">'
        if pontos:
            geo += '<Array as="points">'
            geo += "".join(f'<mxPoint x="{px}" y="{py}"/>' for px, py in pontos)
            geo += "</Array>"
        geo += "</mxGeometry>"

        self.cells.append(
            f'<mxCell id="{i}" value="{esc(rotulo)}" '
            f'style="endArrow=ERone;startArrow=ERmany;html=1;'
            f'edgeStyle=orthogonalEdgeStyle;rounded=1;arcSize=8;'
            f'strokeColor={stroke};strokeWidth={largura};{extra}'
            f'jumpStyle=arc;jumpSize=10;'
            f'exitX={ex};exitY={ey:.4f};exitDx=0;exitDy=0;'
            f'entryX={nx};entryY={ny:.4f};entryDx=0;entryDy=0;" '
            f'edge="1" parent="1" source="{org_id}" target="{dst_id}">'
            f'{geo}</mxCell>')
        return i

    def texto(self, conteudo, x, y, w=320, h=30, tamanho=11, negrito=False):
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
        xml = f'''<mxfile host="app.diagrams.net" agent="gerar_logico.py">
  <diagram id="logico" name="Modelo Lógico">
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
# O MODELO
# ==============================================================================
def main():
    d = Logico()
    L, A = 5400, 4800

    d.texto("Sistema Acadêmico IESB — Modelo Lógico", 40, 24, 1400, 40,
            tamanho=26, negrito=True)
    d.texto("Banco de Dados II (CCO072) · 2026/2 · "
            "Alexandre Vieira, Antônio Alexandre, Carlos Eduardo",
            40, 64, 1400, 24, tamanho=13)

    # As faixas deixam entre si um CORREDOR de 200px, por onde correm as
    # ligacoes entre blocos — cada uma em sua raia, sem compartilhar
    # trajeto com outra.
    y0, h0 = 140, 1020
    d.faixa("1 · GEOGRAFIA E ESTRUTURA FÍSICA",   60, y0, 1380, h0, "geo")
    d.faixa("2 · ESTRUTURA ACADÊMICA",          1540, y0, 1820, h0, "acad")
    d.faixa("3 · PESSOAS",                      3460, y0, 1800, h0, "pessoa")

    y1 = y0 + h0 + 200          # corredor horizontal 1
    d.faixa("4 · OFERTA", 60, y1, 5200, 560, "oferta")

    y2 = y1 + 560 + 220         # corredor horizontal 2
    d.faixa("5 · VIDA ACADÊMICA", 60, y2, 5200, 820, "vida")

    y3 = y2 + 820 + 220         # corredor horizontal 3
    d.faixa("6 · FINANCEIRO",              60, y3, 2420, 500, "fin")
    d.faixa("7 · SECRETARIA E AUDITORIA", 2560, y3, 2700, 500, "sec")

    # Bases dos corredores: as ligacoes entre blocos alocam raias aqui.
    cor_h1 = y1 - 180           # entre faixas 1-3 e a 4
    cor_h2 = y2 - 200           # entre a 4 e a 5
    cor_h3 = y3 - 200

    # =========================================================== BLOCO 1
    # Cadeia hierarquica. As FKs sobem pela coluna da esquerda, cada uma
    # em sua raia, sem encostar nas tabelas.
    gx, gy = 110, 215
    COL = 460          # passo entre colunas: 300 de tabela + 160 de corredor
    LIN = 220          # passo entre linhas

    c_pais = [("PK", "pais_id", "SMALLINT"),
              ("U",  "pais_nome", "VARCHAR(60)"),
              ("U",  "pais_sigla", "CHAR(2)")]
    t_pais = d.tabela("tb_pais", c_pais, gx, gy, "geo", 300)

    c_estado = [("PK", "estado_id", "SMALLINT"),
                ("FK", "pais_id", "SMALLINT"),
                ("",   "estado_nome", "VARCHAR(60)"),
                ("U",  "estado_uf", "CHAR(2)")]
    t_estado = d.tabela("tb_estado", c_estado, gx, gy + LIN, "geo", 300)

    c_cidade = [("PK", "cidade_id", "INTEGER"),
                ("FK", "estado_id", "SMALLINT"),
                ("",   "cidade_nome", "VARCHAR(60)")]
    t_cidade = d.tabela("tb_cidade", c_cidade, gx, gy + 2*LIN, "geo", 300)

    c_campus = [("PK", "campus_id", "SMALLINT"),
                ("FK", "cidade_id", "INTEGER"),
                ("U",  "campus_nome", "VARCHAR(60)"),
                ("",   "campus_endereco", "VARCHAR(120)")]
    t_campus = d.tabela("tb_campus", c_campus, gx, gy + 3*LIN, "geo", 300)

    c_predio = [("PK", "predio_id", "SMALLINT"),
                ("FK", "campus_id", "SMALLINT"),
                ("",   "predio_nome", "VARCHAR(60)"),
                ("",   "predio_sigla", "CHAR(2)")]
    t_predio = d.tabela("tb_predio", c_predio, gx + COL, gy + 3*LIN,
                        "geo", 300)

    c_bloco = [("PK", "bloco_id", "SMALLINT"),
               ("FK", "predio_id", "SMALLINT"),
               ("",   "bloco_nome", "VARCHAR(60)"),
               ("",   "bloco_sigla", "CHAR(2)")]
    t_bloco = d.tabela("tb_bloco", c_bloco, gx + COL, gy + 2*LIN,
                       "geo", 300)

    c_sala = [("PK", "sala_id", "INTEGER"),
              ("FK", "bloco_id", "SMALLINT"),
              ("U",  "sala_codigo", "VARCHAR(10)"),
              ("",   "sala_capacidade", "SMALLINT"),
              ("",   "sala_tipo", "tipo_sala_t")]
    t_sala = d.tabela("tb_sala", c_sala, gx + COL, gy + LIN, "geo", 300)

    # corredor vertical esquerdo do bloco 1
    cv1 = lambda: d.raia("geo_esq", gx - 70, 20)

    d.fk(t_estado, len(c_estado), 1, t_pais, len(c_pais), 0, "esq", "esq",
         cor="geo", pontos=[(cv1(), gy + LIN + 55), (gx - 70, gy + 55)])
    d.fk(t_cidade, len(c_cidade), 1, t_estado, len(c_estado), 0,
         "esq", "esq", cor="geo",
         pontos=[(gx - 45, gy + 2*LIN + 55), (gx - 45, gy + LIN + 55)])
    d.fk(t_campus, len(c_campus), 1, t_cidade, len(c_cidade), 0,
         "esq", "esq", cor="geo",
         pontos=[(gx - 20, gy + 3*LIN + 55), (gx - 20, gy + 2*LIN + 55)])
    d.fk(t_predio, len(c_predio), 1, t_campus, len(c_campus), 0,
         "esq", "dir", cor="geo")
    d.fk(t_bloco, len(c_bloco), 1, t_predio, len(c_predio), 0, "dir", "dir",
         cor="geo", pontos=[(gx + COL + 350, gy + 2*LIN + 55),
                            (gx + COL + 350, gy + 3*LIN + 55)])
    d.fk(t_sala, len(c_sala), 1, t_bloco, len(c_bloco), 0, "dir", "dir",
         cor="geo", pontos=[(gx + COL + 380, gy + LIN + 55),
                            (gx + COL + 380, gy + 2*LIN + 55)])

    d.texto("Código PIA2 = prédio I, bloco A, sala 2. A hierarquia "
            "impede que a mesma cidade exista como 'Brasília', "
            "'brasilia' e 'BSB'.", gx, gy + 4*LIN, 460, 60)

    # =========================================================== BLOCO 2
    ax, ay = 1590, 215

    c_curso = [("PK", "curso_id", "SMALLINT"),
               ("FK", "campus_id", "SMALLINT"),
               ("U",  "curso_codigo", "VARCHAR(10)"),
               ("",   "curso_nome", "VARCHAR(120)"),
               ("",   "curso_grau", "grau_t"),
               ("",   "curso_ch_exigida", "INTEGER"),
               ("",   "curso_ch_ativ_compl", "INTEGER"),
               ("",   "curso_ato_mec", "TEXT")]
    t_curso = d.tabela("tb_curso", c_curso, ax, ay, "acad", 320)

    c_curric = [("PK", "curriculo_id", "INTEGER"),
                ("FK", "curso_id", "SMALLINT"),
                ("",   "curriculo_ano", "SMALLINT"),
                ("",   "curriculo_semestre", "SMALLINT"),
                ("",   "curriculo_grade", "CHAR(1)"),
                ("",   "curriculo_modalidade", "modalidade_t"),
                ("",   "curriculo_periodicidade", "periodicidade_t"),
                ("",   "curriculo_vigente", "BOOLEAN")]
    t_curric = d.tabela("tb_curriculo", c_curric, ax, ay + 300, "acad", 320)

    c_ciclo = [("PK", "ciclo_id", "INTEGER"),
               ("FK", "curriculo_id", "INTEGER"),
               ("",   "ciclo_ordem", "SMALLINT"),
               ("",   "ciclo_nome", "VARCHAR(40)")]
    t_ciclo = d.tabela("tb_ciclo", c_ciclo, ax, ay + 620, "acad", 320)

    c_modulo = [("PK", "modulo_id", "INTEGER"),
                ("FK", "ciclo_id", "INTEGER"),
                ("",   "modulo_ordem", "SMALLINT"),
                ("",   "modulo_nome", "VARCHAR(40)")]
    t_modulo = d.tabela("tb_modulo", c_modulo, ax + 480, ay + 620,
                        "acad", 320)

    c_disc = [("PK", "disciplina_id", "INTEGER"),
              ("U",  "disciplina_codigo", "VARCHAR(10)"),
              ("",   "disciplina_nome", "VARCHAR(120)"),
              ("",   "disciplina_ch_teorica", "SMALLINT"),
              ("",   "disciplina_ch_pratica", "SMALLINT"),
              ("G",  "disciplina_ch_total", "SMALLINT GENERATED"),
              ("",   "disciplina_modalidade", "modalidade_t"),
              ("",   "disciplina_ementa", "TEXT")]
    t_disc = d.tabela("tb_disciplina", c_disc, ax + 960, ay, "acad", 340)

    c_comp = [("PF", "modulo_id", "INTEGER"),
              ("PF", "disciplina_id", "INTEGER"),
              ("",   "componente_natureza", "natureza_t"),
              ("",   "componente_eixo", "eixo_t")]
    t_comp = d.tabela("tb_componente_curricular", c_comp,
                      ax + 960, ay + 620, "acad", 340)

    c_prereq = [("PF", "disciplina_id", "INTEGER"),
                ("PF", "requisito_id", "INTEGER"),
                ("",   "prerequisito_vinculo", "vinculo_t")]
    t_prereq = d.tabela("tb_pre_requisito", c_prereq,
                        ax + 960, ay + 340, "acad", 340)

    d.fk(t_curric, len(c_curric), 1, t_curso, len(c_curso), 0, "esq", "esq",
         cor="acad", pontos=[(ax - 30, ay + 355), (ax - 30, ay + 55)])
    d.fk(t_ciclo, len(c_ciclo), 1, t_curric, len(c_curric), 0, "esq", "esq",
         cor="acad", pontos=[(ax - 55, ay + 675), (ax - 55, ay + 355)])
    d.fk(t_modulo, len(c_modulo), 1, t_ciclo, len(c_ciclo), 0, "esq", "dir",
         cor="acad")
    d.fk(t_comp, len(c_comp), 0, t_modulo, len(c_modulo), 0, "esq", "dir",
         cor="acad")
    d.fk(t_comp, len(c_comp), 1, t_disc, len(c_disc), 0, "dir", "dir",
         cor="acad", pontos=[(ax + 1370, ay + 665), (ax + 1370, ay + 55)])
    # auto-relacionamento: as duas FKs contornam por raias distintas
    d.fk(t_prereq, len(c_prereq), 0, t_disc, len(c_disc), 0, "esq", "esq",
         cor="acad", pontos=[(ax + 930, ay + 395), (ax + 930, ay + 55)])
    d.fk(t_prereq, len(c_prereq), 1, t_disc, len(c_disc), 0, "dir", "dir",
         cor="acad", pontos=[(ax + 1340, ay + 415), (ax + 1340, ay + 35)])

    d.texto("natureza: obrigatória, eletiva, optativa, livre, estágio.\n"
            "O currículo define ciclos e módulos próprios: CCO tem 4x2, "
            "Engenharia e Matemática têm 4x4.",
            ax, ay + 830, 520, 60)

    # =========================================================== BLOCO 3
    px, py = 3510, 215

    c_pessoa = [("PK", "pessoa_id", "INTEGER"),
                ("FK", "cidade_id", "INTEGER"),
                ("",   "pessoa_nome", "VARCHAR(120)"),
                ("U",  "pessoa_cpf", "CHAR(11)"),
                ("",   "pessoa_nascimento", "DATE"),
                ("U",  "pessoa_email", "VARCHAR(120)"),
                ("",   "pessoa_telefone", "VARCHAR(20)")]
    t_pessoa = d.tabela("tb_pessoa", c_pessoa, px + 480, py, "pessoa", 320)

    c_aluno = [("PK", "aluno_id", "INTEGER"),
               ("FK", "pessoa_id", "INTEGER"),
               ("FK", "curso_id", "SMALLINT"),
               ("FK", "curriculo_id", "INTEGER"),
               ("U",  "aluno_ra", "VARCHAR(12)"),
               ("",   "aluno_forma_ingresso", "ingresso_t"),
               ("",   "aluno_ingresso", "DATE"),
               ("",   "aluno_ativo", "BOOLEAN")]
    t_aluno = d.tabela("tb_aluno", c_aluno, px, py + 420, "pessoa", 320)

    c_prof = [("PK", "professor_id", "INTEGER"),
              ("FK", "pessoa_id", "INTEGER"),
              ("U",  "professor_matricula", "VARCHAR(12)"),
              ("",   "professor_titulacao", "titulacao_t")]
    t_prof = d.tabela("tb_professor", c_prof, px + 480, py + 420,
                      "pessoa", 320)

    c_func = [("PK", "funcionario_id", "INTEGER"),
              ("FK", "pessoa_id", "INTEGER"),
              ("U",  "funcionario_matricula", "VARCHAR(12)"),
              ("",   "funcionario_cargo", "VARCHAR(60)"),
              ("",   "funcionario_setor", "VARCHAR(60)")]
    t_func = d.tabela("tb_funcionario", c_func, px + 960, py + 420,
                      "pessoa", 320)

    # Especializacao: tracejado, converge para tb_pessoa
    d.fk(t_aluno, len(c_aluno), 1, t_pessoa, len(c_pessoa), 0, "cima", "esq",
         tipo="heranca", pontos=[(px + 160, py + 330), (px + 440, py + 330),
                                 (px + 440, py + 55)])
    d.fk(t_prof, len(c_prof), 1, t_pessoa, len(c_pessoa), 0, "cima", "baixo",
         tipo="heranca")
    d.fk(t_func, len(c_func), 1, t_pessoa, len(c_pessoa), 0, "cima", "dir",
         tipo="heranca", pontos=[(px + 1120, py + 330),
                                 (px + 840, py + 330), (px + 840, py + 55)])

    d.texto("O CPF pertence à PESSOA e o RA ao VÍNCULO.\n"
            "Três graduações = três linhas em tb_aluno, um só CPF.",
            px, py + 660, 460, 50)

    # =========================================================== BLOCO 4
    ox, oy = 110, y1 + 80

    c_periodo = [("PK", "periodo_id", "SMALLINT"),
                 ("",  "periodo_ano", "SMALLINT"),
                 ("",  "periodo_semestre", "SMALLINT"),
                 ("",  "periodo_inicio", "DATE"),
                 ("",  "periodo_fim", "DATE")]
    t_periodo = d.tabela("tb_periodo_letivo", c_periodo, ox, oy,
                         "oferta", 310)

    c_evento = [("PK", "evento_id", "INTEGER"),
                ("FK", "campus_id", "SMALLINT"),
                ("",   "evento_data", "DATE"),
                ("",   "evento_descricao", "VARCHAR(120)"),
                ("",   "evento_tipo", "evento_t")]
    t_evento = d.tabela("tb_evento_calendario", c_evento, ox, oy + 250,
                        "oferta", 310)

    c_turma = [("PK", "turma_id", "INTEGER"),
               ("FK", "disciplina_id", "INTEGER"),
               ("FK", "periodo_id", "SMALLINT"),
               ("FK", "professor_id", "INTEGER"),
               ("U",  "turma_codigo", "VARCHAR(15)"),
               ("",   "turma_turno", "turno_t"),
               ("",   "turma_vagas", "SMALLINT")]
    t_turma = d.tabela("tb_turma", c_turma, ox + 470, oy, "oferta", 310)

    c_horario = [("PK", "horario_id", "INTEGER"),
                 ("FK", "turma_id", "INTEGER"),
                 ("FK", "sala_id", "INTEGER"),
                 ("",   "horario_dia_semana", "SMALLINT"),
                 ("",   "horario_faixa", "TIMERANGE")]
    t_horario = d.tabela("tb_turma_horario", c_horario, ox + 940, oy,
                         "oferta", 310)

    c_aula = [("PK", "aula_id", "BIGINT"),
              ("FK", "horario_id", "INTEGER"),
              ("",   "aula_data", "DATE"),
              ("",   "aula_conteudo", "TEXT"),
              ("",   "aula_ministrada", "BOOLEAN")]
    t_aula = d.tabela("tb_aula", c_aula, ox + 1410, oy, "oferta", 310)

    d.fk(t_turma, len(c_turma), 2, t_periodo, len(c_periodo), 0,
         "esq", "dir", cor="oferta")
    d.fk(t_horario, len(c_horario), 1, t_turma, len(c_turma), 0,
         "esq", "dir", cor="oferta")
    d.fk(t_aula, len(c_aula), 1, t_horario, len(c_horario), 0,
         "esq", "dir", cor="oferta")

    # Ligacoes que SOBEM para os blocos 1 a 3, cada uma em sua raia do
    # corredor horizontal 1.
    r = lambda: d.raia("h1", cor_h1, 26)
    d.fk(t_turma, len(c_turma), 1, t_disc, len(c_disc), 0, "cima", "baixo",
         cor="oferta", tipo="externa",
         pontos=[(ox + 625, (v := r())), (ax + 1130, v)])
    d.fk(t_turma, len(c_turma), 3, t_prof, len(c_prof), 0, "dir", "baixo",
         cor="oferta", tipo="externa",
         pontos=[(ox + 830, oy + 100), (ox + 830, (v := r())),
                 (px + 640, v)])
    d.fk(t_horario, len(c_horario), 2, t_sala, len(c_sala), 0,
         "cima", "baixo", cor="oferta", tipo="externa",
         pontos=[(ox + 1095, (v := r())), (gx + COL + 150, v)])
    d.fk(t_evento, len(c_evento), 1, t_campus, len(c_campus), 0,
         "esq", "baixo", cor="oferta", tipo="externa",
         pontos=[(ox - 40, oy + 305), (ox - 40, (v := r())), (gx + 150, v)])

    d.texto("ANTICHOQUE: EXCLUDE USING gist sobre (sala_id, dia_semana, "
            "faixa) e sobre (professor_id, dia_semana, faixa). "
            "É restrição do banco, não da aplicação.",
            ox + 1880, oy + 40, 520, 80)

    # =========================================================== BLOCO 5
    vx, vy = 110, y2 + 90

    c_matric = [("PK", "matricula_id", "INTEGER"),
                ("FK", "aluno_id", "INTEGER"),
                ("FK", "turma_id", "INTEGER"),
                ("",   "matricula_data", "TIMESTAMPTZ"),
                ("",   "matricula_status", "status_mat_t")]
    t_matric = d.tabela("tb_matricula", c_matric, vx + 640, vy + 260,
                        "vida", 310)

    c_hist = [("PK", "historico_id", "INTEGER"),
              ("FK", "matricula_id", "INTEGER"),
              ("G",  "historico_media", "NUMERIC(4,2) GEN"),
              ("G",  "historico_mencao", "mencao_t GEN"),
              ("",   "historico_frequencia", "pct_t"),
              ("",   "historico_situacao", "situacao_t")]
    t_hist = d.tabela("tb_historico", c_hist, vx + 640, vy, "vida", 340)

    c_aval = [("PK", "avaliacao_id", "BIGINT"),
              ("FK", "turma_id", "INTEGER"),
              ("",   "avaliacao_titulo", "VARCHAR(60)"),
              ("",   "avaliacao_peso", "NUMERIC(4,2)"),
              ("",   "avaliacao_data", "DATE")]
    t_aval = d.tabela("tb_avaliacao", c_aval, vx, vy + 260, "vida", 310)

    c_nota = [("PF", "avaliacao_id", "BIGINT"),
              ("PF", "matricula_id", "INTEGER"),
              ("",   "nota_valor", "nota_t")]
    t_nota = d.tabela("tb_nota_avaliacao", c_nota, vx + 640, vy + 540,
                      "vida", 310)

    c_pres = [("PF", "aula_id", "BIGINT"),
              ("PF", "matricula_id", "INTEGER"),
              ("",   "presenca_presente", "BOOLEAN"),
              ("",   "presenca_justificativa", "TEXT")]
    t_pres = d.tabela("tb_presenca", c_pres, vx + 1110, vy + 540,
                      "vida", 320)

    c_aprov = [("PK", "aproveitamento_id", "INTEGER"),
               ("FK", "aluno_id", "INTEGER"),
               ("FK", "disciplina_id", "INTEGER"),
               ("",   "aproveitamento_origem", "VARCHAR(120)"),
               ("",   "aproveitamento_ch", "SMALLINT"),
               ("",   "aproveitamento_deferido", "BOOLEAN")]
    t_aprov = d.tabela("tb_aproveitamento", c_aprov, vx + 1600, vy + 200,
                       "vida", 320)

    d.fk(t_hist, len(c_hist), 1, t_matric, len(c_matric), 0, "esq", "esq",
         cor="vida", pontos=[(vx + 600, vy + 55), (vx + 600, vy + 315)])
    d.fk(t_nota, len(c_nota), 0, t_aval, len(c_aval), 0, "esq", "baixo",
         cor="vida", pontos=[(vx + 590, vy + 585), (vx + 155, vy + 585)])
    d.fk(t_nota, len(c_nota), 1, t_matric, len(c_matric), 0, "dir", "baixo",
         cor="vida", pontos=[(vx + 1000, vy + 605), (vx + 795, vy + 605)])
    d.fk(t_pres, len(c_pres), 1, t_matric, len(c_matric), 0, "cima", "dir",
         cor="vida", pontos=[(vx + 1270, vy + 335)])

    # Sobem pelo corredor horizontal 2
    r2 = lambda: d.raia("h2", cor_h2, 26)
    d.fk(t_matric, len(c_matric), 1, t_aluno, len(c_aluno), 0,
         "cima", "baixo", cor="vida", tipo="externa",
         pontos=[(vx + 795, (v := r2())), (px + 160, v)])
    d.fk(t_matric, len(c_matric), 2, t_turma, len(c_turma), 0,
         "esq", "baixo", cor="vida", tipo="externa",
         pontos=[(vx + 600, vy + 335), (vx + 600, (v := r2())),
                 (ox + 625, v)])
    d.fk(t_aval, len(c_aval), 1, t_turma, len(c_turma), 0, "cima", "baixo",
         cor="vida", tipo="externa",
         pontos=[(vx + 155, (v := r2())), (ox + 625, v)])
    d.fk(t_pres, len(c_pres), 0, t_aula, len(c_aula), 0, "dir", "baixo",
         cor="vida", tipo="externa",
         pontos=[(vx + 1500, vy + 565), (vx + 1500, (v := r2())),
                 (ox + 1565, v)])
    d.fk(t_aprov, len(c_aprov), 1, t_aluno, len(c_aluno), 0, "cima", "baixo",
         cor="vida", tipo="externa",
         pontos=[(vx + 1760, (v := r2())), (px + 160, v)])
    d.fk(t_aprov, len(c_aprov), 2, t_disc, len(c_disc), 0, "dir", "baixo",
         cor="vida", tipo="externa",
         pontos=[(vx + 2000, vy + 255), (vx + 2000, (v := r2())),
                 (ax + 1130, v)])

    d.texto("A média é DERIVADA das notas das avaliações e a menção, da "
            "média. Corrigir um lançamento recalcula tudo.",
            vx + 2050, vy + 420, 480, 60)

    # =========================================================== BLOCO 6
    fx, fy = 110, y3 + 80

    c_mensal = [("PK", "mensalidade_id", "BIGINT"),
                ("FK", "aluno_id", "INTEGER"),
                ("FK", "periodo_id", "SMALLINT"),
                ("",   "mensalidade_competencia", "DATE"),
                ("",   "mensalidade_valor_orig", "NUMERIC(10,2)"),
                ("G",  "mensalidade_valor_final", "NUMERIC(10,2) GEN"),
                ("",   "mensalidade_vencimento", "DATE"),
                ("",   "mensalidade_pagamento", "DATE"),
                ("",   "mensalidade_situacao", "situacao_fin_t")]
    t_mensal = d.tabela("tb_mensalidade", c_mensal, fx, fy, "fin", 340)

    c_alubolsa = [("PF", "aluno_id", "INTEGER"),
                  ("PF", "bolsa_id", "SMALLINT"),
                  ("",   "concessao_data", "DATE"),
                  ("",   "concessao_validade", "DATE")]
    t_alubolsa = d.tabela("tb_aluno_bolsa", c_alubolsa, fx + 500, fy,
                          "fin", 320)

    c_bolsa = [("PK", "bolsa_id", "SMALLINT"),
               ("U",  "bolsa_nome", "VARCHAR(120)"),
               ("",   "bolsa_percentual", "pct_t"),
               ("",   "bolsa_ativa", "BOOLEAN")]
    t_bolsa = d.tabela("tb_bolsa", c_bolsa, fx + 980, fy, "fin", 310)

    d.fk(t_alubolsa, len(c_alubolsa), 1, t_bolsa, len(c_bolsa), 0,
         "dir", "esq", cor="fin")

    r3 = lambda: d.raia("h3", cor_h3, 26)
    d.fk(t_mensal, len(c_mensal), 1, t_aluno, len(c_aluno), 0,
         "cima", "baixo", cor="fin", tipo="externa",
         pontos=[(fx + 170, (v := r3())), (px + 160, v)])
    d.fk(t_mensal, len(c_mensal), 2, t_periodo, len(c_periodo), 0,
         "esq", "esq", cor="fin", tipo="externa",
         pontos=[(fx - 50, fy + 75), (fx - 50, oy + 55)])
    d.fk(t_alubolsa, len(c_alubolsa), 0, t_aluno, len(c_aluno), 0,
         "cima", "baixo", cor="fin", tipo="externa",
         pontos=[(fx + 660, (v := r3())), (px + 160, v)])

    d.texto("valor_final aplica os descontos VIGENTES na competência.",
            fx, fy + 300, 480, 30)

    # =========================================================== BLOCO 7
    sx, sy = 2610, y3 + 80

    c_requer = [("PK", "requerimento_id", "BIGINT"),
                ("FK", "aluno_id", "INTEGER"),
                ("FK", "funcionario_id", "INTEGER"),
                ("",   "requerimento_tipo", "VARCHAR(60)"),
                ("",   "requerimento_abertura", "TIMESTAMPTZ"),
                ("",   "requerimento_situacao", "situacao_req_t"),
                ("",   "requerimento_parecer", "TEXT"),
                ("",   "requerimento_decisao", "TIMESTAMPTZ")]
    t_requer = d.tabela("tb_requerimento", c_requer, sx, sy, "sec", 330)

    c_ativ = [("PK", "atividade_id", "INTEGER"),
              ("FK", "aluno_id", "INTEGER"),
              ("FK", "funcionario_id", "INTEGER"),
              ("",   "atividade_categoria", "VARCHAR(60)"),
              ("",   "atividade_descricao", "VARCHAR(255)"),
              ("",   "atividade_ch_solicitada", "SMALLINT"),
              ("",   "atividade_ch_validada", "SMALLINT"),
              ("",   "atividade_situacao", "situacao_req_t")]
    t_ativ = d.tabela("tb_atividade_complementar", c_ativ, sx + 490, sy,
                      "sec", 350)

    c_log = [("PK", "log_id", "BIGINT"),
             ("",  "log_tabela", "VARCHAR(60)"),
             ("",  "log_registro_id", "BIGINT"),
             ("",  "log_acao", "VARCHAR(20)"),
             ("",  "log_ocorrido_em", "TIMESTAMPTZ"),
             ("",  "log_usuario", "NAME"),
             ("",  "log_valor_antigo", "JSONB"),
             ("",  "log_valor_novo", "JSONB")]
    t_log = d.tabela("tb_log_auditoria", c_log, sx + 1000, sy, "sec", 330)

    d.fk(t_requer, len(c_requer), 1, t_aluno, len(c_aluno), 0,
         "cima", "baixo", cor="sec", tipo="externa",
         pontos=[(sx + 165, (v := r3())), (px + 160, v)])
    d.fk(t_requer, len(c_requer), 2, t_func, len(c_func), 0,
         "cima", "baixo", cor="sec", tipo="externa",
         pontos=[(sx + 230, (v := r3())), (px + 1120, v)])
    d.fk(t_ativ, len(c_ativ), 1, t_aluno, len(c_aluno), 0,
         "cima", "baixo", cor="sec", tipo="externa",
         pontos=[(sx + 665, (v := r3())), (px + 160, v)])
    d.fk(t_ativ, len(c_ativ), 2, t_func, len(c_func), 0,
         "cima", "baixo", cor="sec", tipo="externa",
         pontos=[(sx + 730, (v := r3())), (px + 1120, v)])

    d.texto("tb_log_auditoria NÃO tem FK para o registro auditado: o "
            "rastro precisa sobreviver à exclusão do que documenta. "
            "Guarda valor antigo e novo, como exige o Módulo 4.",
            sx + 1000, sy + 300, 500, 80)

    # --------------------------------------------------------- LEGENDA
    ly = y3 + 560
    d.texto("LEGENDA", 60, ly, 300, 24, tamanho=14, negrito=True)
    for k, linha in enumerate([
            "PK ....... chave primária",
            "FK ....... chave estrangeira",
            "PF ....... chave primária e estrangeira (tabela associativa)",
            "U  ....... restrição de unicidade",
            "/  ....... coluna gerada (GENERATED ALWAYS AS ... STORED)",
            "",
            "A seta parte da COLUNA que contém a chave estrangeira e "
            "chega na chave primária referenciada.",
            "A cor da linha é a do bloco de ORIGEM, para seguir o "
            "trajeto sem rastrear ponta a ponta.",
            "Linha tracejada indica especialização (aluno, professor e "
            "funcionário são papéis de pessoa).",
            "Arco onde duas linhas se cruzam significa que elas NÃO se "
            "conectam."]):
        if linha:
            d.texto(linha, 60, ly + 32 + k * 22, 900, 20, tamanho=12)

    d.salvar(SAIDA, L, A)
    print(f"  gerado: {SAIDA}")
    print(f"  celulas: {len(d.cells)}")


if __name__ == "__main__":
    main()
