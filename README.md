## 🗄️ Banco de Dados II (CCO072) — IESB 2026/2

**Professor:** Rodrigo Gonçalves  
**Ambiente:** PostgreSQL 17 + pgAdmin 4 (via Docker Compose)  
**Banco de Dados:** `matricula`

---

**Alunos:**
	
  * Alexandre Vieira Da Silva.  
  * Antônio Alexandre Cavalcante Leite.  
  * Carlos Eduardo (...).  
---

## 📂 Estrutura de Pastas e Arquivos


```
projeto/
├── .gitignore             # Filtros de arquivos ignorados pelo Git (macOS, Windows, Linux)
├── README.md              # Documentação principal do repositório
├── docker-compose.yml     # Orquestração dos containers PostgreSQL 17 e pgAdmin 4
├── sql/                   # Scripts SQL do projeto
│   ├── 01_marco1_ddl_esquema.sql
│   ├── 02_carga_dados_iniciais.sql
│   └── 03_queries_relatorios.sql
└── ai-prompts/            # Transparência e registro do uso de IA
    ├── aluno-1/           # Histórico e prompts do Aluno 1
    ├── aluno-2/           # Histórico e prompts do Aluno 2
    └── aluno-3/           # Histórico e prompts do Aluno 3
```

## 📝 Descrição dos Componentes

* `sql/:` Contém todos os arquivos de script de banco de dados (.sql). Os arquivos são salvos diretamente no disco para sincronização via Git.

* `ai-prompts/:` Pastas individuais para cada integrante do grupo anexar os históricos de prompts (em .md ou .pdf) utilizados durante as atividades.

* `docker-compose.yml:` Configuração automatizada para subir o banco PostgreSQL 17 e o gerenciador pgAdmin 4 sem necessidade de instalação local.

## 🚀 Como Baixar o Projeto e Conectar com a Nuvem
1. Clonar o Repositório (Primeira Vez)

Para baixar os arquivos do GitHub para a sua máquina local, abra o terminal (ou Prompt de Comando/PowerShell no Windows) e execute:
```
git clone https://github.com/TotonhoMilk/BD_II.git
cd BD_II
```

# 📖 Guia Básico do Git (Fluxo Diário de Trabalho)

Antes de iniciar qualquer alteração nos arquivos, lembre-se de atualizar seu repositório local:
```
git pull origin main
```

Após realizar suas alterações ou criar novos scripts/prompts, siga a rotina de envio para a nuvem:
```
git status
git add .
git commit -m "feat: cria tabela de alunos"
git push origin main
```

## 🤖 Registro de Prompts de Inteligência Artificial

Em alinhamento com as diretrizes do curso, o uso de ferramentas de IA é liberado e incentivado. Todos os membros do grupo mantêm o registro de suas interações com as IAs nas pastas dedicadas dentro de `ai-prompts/:`

ai-prompts/aluno-1/: Registros do Aluno 1

ai-prompts/aluno-2/: Registros do Aluno 2

ai-prompts/aluno-3/: Registros do Aluno 3

## Dicas das dicas do Professor

Use o `docker compose down` apenas se quiser limpar completamente o ambiente Docker para reconfigurá-lo ou liberar espaço do sistema.

```bash
# Para desligar no fim do dia (apenas para a execução)
docker compose stop

# Para voltar a trabalhar no dia seguinte
docker compose start
```
