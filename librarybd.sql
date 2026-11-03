-- =========================================================================
-- AULA PRÁTICA: NORMALIZAÇÃO DE DADOS (1FN, 2FN e 3FN) E MAPEAMENTO DER->SQL
-- Contexto: Sistema de Gerenciamento de Biblioteca
-- =========================================================================

DROP DATABASE IF EXISTS BibliotecaDB;

CREATE DATABASE BibliotecaDB;
USE BibliotecaDB;


-- =========================================================================
-- CONCEITO DE NORMALIZAÇÃO DE DADOS
-- "A chave, toda a chave, e nada além da chave!"
-- =========================================================================


-- =========================================================================
-- 1. TABELA CLIENTE (Aplicando 1FN e 3FN)
--
-- ENDEREÇO: atributo composto desmembrado em campos atômicos.
-- CPF: atributo único do cliente.
-- A situação informa se o cliente está regular ou inadimplente.
-- =========================================================================
CREATE TABLE Cliente (
  idCliente INT UNSIGNED NOT NULL PRIMARY KEY,
  nome VARCHAR(125) NOT NULL,
  CPF CHAR(11) NOT NULL UNIQUE,
  telefone VARCHAR(20) NOT NULL,

  -- Endereço desmembrado (1FN)
  logradouro VARCHAR(150) NOT NULL,
  numero VARCHAR(10) NOT NULL,
  bairro VARCHAR(60) NOT NULL,
  cidade VARCHAR(60) NOT NULL,
  uf CHAR(2) NOT NULL,
  cep CHAR(8) NOT NULL,

  situacao ENUM('regular', 'inadimplente') NOT NULL DEFAULT 'regular'
);


-- =========================================================================
-- 2. TABELA FUNCIONARIO
--
-- Os funcionários são classificados como gerente ou recepcionista.
-- O gerente possui acesso total; o recepcionista executa as operações
-- de atendimento, empréstimo, registro de atraso/avaria e recebimento.
-- As permissões efetivas devem ser verificadas pela aplicação.
-- =========================================================================
CREATE TABLE Funcionario (
  idFuncionario INT UNSIGNED NOT NULL PRIMARY KEY,
  nome VARCHAR(125) NOT NULL,
  funcao ENUM('gerente', 'recepcionista') NOT NULL
);


-- =========================================================================
-- 3. TABELA LIVRO
--
-- Guarda os dados do acervo e a quantidade total de exemplares.
-- A quantidade disponível pode ser calculada descontando os exemplares
-- que estão emprestados e ainda não foram devolvidos.
-- =========================================================================
CREATE TABLE Livro (
  idLivro INT UNSIGNED NOT NULL PRIMARY KEY,
  titulo VARCHAR(150) NOT NULL,
  autor VARCHAR(125) NOT NULL,
  quantidadeEstoque INT UNSIGNED NOT NULL
);


-- =========================================================================
-- 4. TABELA EMPRESTIMO
--
-- Registra a retirada feita por um cliente e o funcionário responsável.
-- O prazo inicial é de 1 mês. A prorrogação pode acrescentar mais 1 mês,
-- sem ultrapassar 2 meses contados da data do empréstimo.
--
-- dataProrrogacao guarda a nova data-limite quando houver prorrogação.
-- =========================================================================
CREATE TABLE Emprestimo (
  idEmprestimo INT UNSIGNED NOT NULL PRIMARY KEY,
  dataEmprestimo DATE NOT NULL,
  dataLimiteDevolucao DATE NOT NULL,
  dataProrrogacao DATE NULL,
  status ENUM('em_andamento', 'finalizado') NOT NULL DEFAULT 'em_andamento',

  idCliente INT UNSIGNED NOT NULL,
  idFuncionario INT UNSIGNED NOT NULL,

  CONSTRAINT fk_emprestimo_cliente
    FOREIGN KEY (idCliente)
    REFERENCES Cliente(idCliente),

  CONSTRAINT fk_emprestimo_funcionario
    FOREIGN KEY (idFuncionario)
    REFERENCES Funcionario(idFuncionario)
);


-- =========================================================================
-- 5. TABELA ITEM_EMPRESTIMO (Aplicando a 2FN)
--
-- Resolve o relacionamento N:M entre Emprestimo e Livro.
-- A chave primária é composta por idEmprestimo + idLivro.
-- A quantidade depende da combinação do empréstimo com o livro.
-- A data de devolução é registrada para cada livro emprestado.
-- =========================================================================
CREATE TABLE ItemEmprestimo (
  idEmprestimo INT UNSIGNED NOT NULL,
  idLivro INT UNSIGNED NOT NULL,
  quantidade INT UNSIGNED NOT NULL,
  dataDevolucao DATE NULL,
  situacaoItem ENUM('emprestado', 'devolvido', 'avariado')
    NOT NULL DEFAULT 'emprestado',

  PRIMARY KEY (idEmprestimo, idLivro),

  CONSTRAINT fk_item_emprestimo
    FOREIGN KEY (idEmprestimo)
    REFERENCES Emprestimo(idEmprestimo),

  CONSTRAINT fk_item_livro
    FOREIGN KEY (idLivro)
    REFERENCES Livro(idLivro)
);


-- =========================================================================
-- 6. TABELA MULTA
--
-- Registra multas por atraso ou avaria em um livro de determinado
-- empréstimo. O funcionário responsável registra a ocorrência e o
-- recebimento. dataPagamento permanece NULL enquanto não houver pagamento.
-- =========================================================================
CREATE TABLE Multa (
  idMulta INT UNSIGNED NOT NULL PRIMARY KEY,
  idEmprestimo INT UNSIGNED NOT NULL,
  idLivro INT UNSIGNED NOT NULL,
  idFuncionario INT UNSIGNED NOT NULL,

  tipo ENUM('atraso', 'avaria') NOT NULL,
  descricao VARCHAR(255) NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  dataRegistro DATE NOT NULL,
  dataPagamento DATE NULL,
  statusPagamento ENUM('pendente', 'paga') NOT NULL DEFAULT 'pendente',

  CONSTRAINT fk_multa_item_emprestimo
    FOREIGN KEY (idEmprestimo, idLivro)
    REFERENCES ItemEmprestimo(idEmprestimo, idLivro),

  CONSTRAINT fk_multa_funcionario
    FOREIGN KEY (idFuncionario)
    REFERENCES Funcionario(idFuncionario)
);


-- =========================================================================
-- 7. INSERÇÃO DE DADOS (DML) - POVOAMENTO DO BANCO DE DADOS
-- =========================================================================

-- Clientes: endereço dividido em atributos atômicos (1FN).
INSERT INTO Cliente
(idCliente, nome, CPF, telefone, logradouro, numero, bairro, cidade, uf, cep, situacao)
VALUES
(1, 'Carlos Eduardo Silva', '12345678901', '84999990001',
 'Rua das Flores', '120', 'Centro', 'Canguaretama', 'RN', '59190000', 'regular'),
(2, 'Maria Fernanda Oliveira', '23456789012', '84999990002',
 'Av. Brasil', '150', 'Centro', 'Canguaretama', 'RN', '59190000', 'inadimplente'),
(3, 'Joao Pedro Santos', '34567890123', '84999990003',
 'Rua do Sol', '45', 'Areia Branca', 'Canguaretama', 'RN', '59190000', 'regular');

-- Funcionários: gerente e recepcionista.
INSERT INTO Funcionario (idFuncionario, nome, funcao) VALUES
(1, 'Ana Souza', 'gerente'),
(2, 'Paulo Lima', 'recepcionista');

-- Livros do acervo.
INSERT INTO Livro (idLivro, titulo, autor, quantidadeEstoque) VALUES
(10, 'O Pequeno Principe', 'Antoine de Saint-Exupery', 5),
(20, 'Dom Casmurro', 'Machado de Assis', 3),
(30, 'Capitaes da Areia', 'Jorge Amado', 4);

-- Empréstimos: data-limite inicial de aproximadamente um mês após a retirada.
INSERT INTO Emprestimo
(idEmprestimo, dataEmprestimo, dataLimiteDevolucao, dataProrrogacao,
 status, idCliente, idFuncionario)
VALUES
(101, '2026-11-01', '2026-12-01', NULL, 'em_andamento', 1, 2),
(102, '2026-11-02', '2026-12-02', NULL, 'em_andamento', 2, 2),
(103, '2026-11-03', '2026-12-03', NULL, 'em_andamento', 3, 2);

-- Itens de cada empréstimo.
INSERT INTO ItemEmprestimo
(idEmprestimo, idLivro, quantidade, dataDevolucao, situacaoItem)
VALUES
(101, 10, 1, NULL, 'emprestado'),
(101, 20, 1, NULL, 'emprestado'),
(102, 30, 2, NULL, 'emprestado'),
(103, 10, 1, '2026-11-03', 'devolvido');

-- Multa de exemplo por avaria, registrada por um recepcionista.
INSERT INTO Multa
(idMulta, idEmprestimo, idLivro, idFuncionario, tipo, descricao,
 valor, dataRegistro, dataPagamento, statusPagamento)
VALUES
(1, 101, 20, 2, 'avaria', 'Capa do livro danificada', 15.00,
 '2026-11-03', NULL, 'pendente');


-- =========================================================================
-- 8. CONSULTAS DEMONSTRATIVAS (DQL)
-- =========================================================================

-- -------------------------------------------------------------------------
-- DEMONSTRAÇÃO DA 1FN
-- Exibe os dados do cliente com o endereço em campos atômicos.
-- -------------------------------------------------------------------------
SELECT
    nome AS 'Cliente',
    CPF,
    telefone,
    logradouro,
    numero,
    bairro,
    cidade,
    uf,
    cep
FROM Cliente
WHERE idCliente = 1;


-- -------------------------------------------------------------------------
-- DEMONSTRAÇÃO DA 2FN E 3FN
-- Reconstrói os dados do empréstimo com JOIN.
-- O nome do cliente, do funcionário e do livro não é duplicado
-- na tabela ItemEmprestimo.
-- -------------------------------------------------------------------------
SELECT
    e.idEmprestimo AS 'Nº Empréstimo',
    e.dataEmprestimo AS 'Data do Empréstimo',
    e.dataLimiteDevolucao AS 'Prazo Inicial',
    e.dataProrrogacao AS 'Prazo Prorrogado',
    c.nome AS 'Cliente',
    f.nome AS 'Funcionário Responsável',
    l.titulo AS 'Livro',
    ie.quantidade AS 'Quantidade',
    ie.situacaoItem AS 'Situação do Item'
FROM Emprestimo e
INNER JOIN Cliente c
    ON e.idCliente = c.idCliente
INNER JOIN Funcionario f
    ON e.idFuncionario = f.idFuncionario
INNER JOIN ItemEmprestimo ie
    ON e.idEmprestimo = ie.idEmprestimo
INNER JOIN Livro l
    ON ie.idLivro = l.idLivro
ORDER BY e.idEmprestimo;


-- -------------------------------------------------------------------------
-- CONSULTA DE ESTOQUE
-- Calcula quantos exemplares estão disponíveis, descontando os que
-- continuam emprestados.
-- -------------------------------------------------------------------------
SELECT
    l.idLivro,
    l.titulo AS 'Livro',
    l.quantidadeEstoque AS 'Quantidade no Acervo',
    l.quantidadeEstoque -
      COALESCE(SUM(
        CASE
          WHEN ie.situacaoItem = 'emprestado' THEN ie.quantidade
          ELSE 0
        END
      ), 0) AS 'Quantidade Disponível'
FROM Livro l
LEFT JOIN ItemEmprestimo ie
    ON l.idLivro = ie.idLivro
GROUP BY l.idLivro, l.titulo, l.quantidadeEstoque
ORDER BY l.titulo;


-- -------------------------------------------------------------------------
-- CONSULTA DO LIMITE MENSAL DE LIVROS POR CLIENTE
-- Conta a quantidade de exemplares retirados no mês atual.
-- Cliente regular: limite de 10 livros por mês.
-- Cliente inadimplente: limite de 2 livros por mês.
-- -------------------------------------------------------------------------
SELECT
    c.idCliente,
    c.nome AS 'Cliente',
    c.situacao AS 'Situação',
    COALESCE(SUM(ie.quantidade), 0) AS 'Livros Retirados no Mês',
    CASE
      WHEN c.situacao = 'inadimplente' THEN 2
      ELSE 10
    END AS 'Limite Mensal'
FROM Cliente c
LEFT JOIN Emprestimo e
    ON c.idCliente = e.idCliente
    AND YEAR(e.dataEmprestimo) = YEAR(CURRENT_DATE())
    AND MONTH(e.dataEmprestimo) = MONTH(CURRENT_DATE())
LEFT JOIN ItemEmprestimo ie
    ON e.idEmprestimo = ie.idEmprestimo
GROUP BY c.idCliente, c.nome, c.situacao
ORDER BY c.nome;


-- -------------------------------------------------------------------------
-- CONSULTA DE MULTAS
-- Exibe atrasos/avarias, valor devido, situação do pagamento e responsável.
-- -------------------------------------------------------------------------
SELECT
    m.idMulta,
    c.nome AS 'Cliente',
    l.titulo AS 'Livro',
    m.tipo AS 'Motivo',
    m.descricao AS 'Descrição',
    m.valor AS 'Valor',
    m.dataRegistro AS 'Data do Registro',
    m.dataPagamento AS 'Data do Pagamento',
    m.statusPagamento AS 'Situação do Pagamento',
    f.nome AS 'Funcionário Responsável'
FROM Multa m
INNER JOIN Emprestimo e
    ON m.idEmprestimo = e.idEmprestimo
INNER JOIN Cliente c
    ON e.idCliente = c.idCliente
INNER JOIN Livro l
    ON m.idLivro = l.idLivro
INNER JOIN Funcionario f
    ON m.idFuncionario = f.idFuncionario
ORDER BY m.statusPagamento, m.dataRegistro;


-- -------------------------------------------------------------------------
-- CONSULTA DE EMPRÉSTIMOS COM DEVOLUÇÃO EM ATRASO
-- Considera a data prorrogada quando ela existir; caso contrário,
-- considera a data-limite inicial.
-- -------------------------------------------------------------------------
SELECT
    e.idEmprestimo,
    c.nome AS 'Cliente',
    l.titulo AS 'Livro',
    COALESCE(e.dataProrrogacao, e.dataLimiteDevolucao) AS 'Data Limite',
    DATEDIFF(
      CURRENT_DATE(),
      COALESCE(e.dataProrrogacao, e.dataLimiteDevolucao)
    ) AS 'Dias de Atraso'
FROM Emprestimo e
INNER JOIN Cliente c
    ON e.idCliente = c.idCliente
INNER JOIN ItemEmprestimo ie
    ON e.idEmprestimo = ie.idEmprestimo
INNER JOIN Livro l
    ON ie.idLivro = l.idLivro
WHERE ie.situacaoItem = 'emprestado'
  AND COALESCE(e.dataProrrogacao, e.dataLimiteDevolucao) < CURRENT_DATE()
ORDER BY `Dias de Atraso` DESC;


-- =========================================================================
-- OBSERVAÇÕES SOBRE AS REGRAS DE NEGÓCIO
--
-- 1. O limite mensal é calculado pela soma da quantidade de livros
--    emprestados ao cliente no mês: 10 para regular e 2 para inadimplente.
-- 2. O prazo inicial de devolução é de 1 mês. A prorrogação pode levar
--    a data-limite até, no máximo, 2 meses após dataEmprestimo.
-- 3. A aplicação deve validar o limite mensal, a disponibilidade do acervo,
--    a prorrogação máxima e as permissões de gerente/recepcionista antes
--    de efetivar cada operação.
-- 4. A multa fica pendente até o recebimento. Após o pagamento, devem ser
--    atualizados statusPagamento para 'paga' e dataPagamento.
-- =========================================================================

