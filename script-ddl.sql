-- ============================================================================
-- SCRIPT DDL - SISTEMA DE GERENCIAMENTO DE BIBLIOTECA
-- SGBD: MySQL 8.0+
-- Objetivo: criar a estrutura do banco, suas chaves e restricoes.
-- ============================================================================

DROP DATABASE IF EXISTS BibliotecaDB;
CREATE DATABASE BibliotecaDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE BibliotecaDB;

-- 1. CATEGORIA: tabela-pai do catalogo de livros.
CREATE TABLE CategoriaLivro (
    idCategoria INT UNSIGNED NOT NULL,
    nome VARCHAR(80) NOT NULL,
    descricao VARCHAR(255) NOT NULL,
    ativo TINYINT(1) NOT NULL DEFAULT 1,
    dataCadastro DATE NOT NULL,
    CONSTRAINT pk_categoria_livro PRIMARY KEY (idCategoria),
    CONSTRAINT uq_categoria_nome UNIQUE (nome),
    CONSTRAINT ck_categoria_ativo CHECK (ativo IN (0, 1))
) ENGINE=InnoDB;

-- 2. CLIENTE: dados pessoais e situacao para aplicacao do limite mensal.
CREATE TABLE Cliente (
    idCliente INT UNSIGNED NOT NULL,
    nome VARCHAR(125) NOT NULL,
    CPF CHAR(11) NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    email VARCHAR(120) NOT NULL,
    logradouro VARCHAR(150) NOT NULL,
    numero VARCHAR(10) NOT NULL,
    bairro VARCHAR(60) NOT NULL,
    cidade VARCHAR(60) NOT NULL,
    uf CHAR(2) NOT NULL,
    cep CHAR(8) NOT NULL,
    situacao ENUM('regular', 'inadimplente') NOT NULL DEFAULT 'regular',
    dataCadastro DATE NOT NULL,
    CONSTRAINT pk_cliente PRIMARY KEY (idCliente),
    CONSTRAINT uq_cliente_cpf UNIQUE (CPF),
    CONSTRAINT uq_cliente_email UNIQUE (email),
    CONSTRAINT ck_cliente_uf CHECK (CHAR_LENGTH(uf) = 2)
) ENGINE=InnoDB;

-- 3. FUNCIONARIO: gerente ou recepcionista.
CREATE TABLE Funcionario (
    idFuncionario INT UNSIGNED NOT NULL,
    nome VARCHAR(125) NOT NULL,
    CPF CHAR(11) NOT NULL,
    email VARCHAR(120) NOT NULL,
    funcao ENUM('gerente', 'recepcionista') NOT NULL,
    dataAdmissao DATE NOT NULL,
    ativo TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT pk_funcionario PRIMARY KEY (idFuncionario),
    CONSTRAINT uq_funcionario_cpf UNIQUE (CPF),
    CONSTRAINT uq_funcionario_email UNIQUE (email),
    CONSTRAINT ck_funcionario_ativo CHECK (ativo IN (0, 1))
) ENGINE=InnoDB;

-- 4. LIVRO: cada livro pertence a uma categoria.
CREATE TABLE Livro (
    idLivro INT UNSIGNED NOT NULL,
    titulo VARCHAR(150) NOT NULL,
    autor VARCHAR(125) NOT NULL,
    ISBN CHAR(13) NOT NULL,
    anoPublicacao SMALLINT UNSIGNED NOT NULL,
    quantidadeEstoque INT UNSIGNED NOT NULL DEFAULT 0,
    idCategoria INT UNSIGNED NOT NULL,
    CONSTRAINT pk_livro PRIMARY KEY (idLivro),
    CONSTRAINT uq_livro_isbn UNIQUE (ISBN),
    CONSTRAINT ck_livro_estoque CHECK (quantidadeEstoque >= 0),
    CONSTRAINT ck_livro_isbn CHECK (ISBN REGEXP '^[0-9]{13}$'),
    CONSTRAINT fk_livro_categoria FOREIGN KEY (idCategoria)
        REFERENCES CategoriaLivro (idCategoria)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 5. EMPRESTIMO: registra o cliente e o funcionario que realizou a operacao.
CREATE TABLE Emprestimo (
    idEmprestimo INT UNSIGNED NOT NULL,
    dataEmprestimo DATE NOT NULL,
    dataLimiteDevolucao DATE NOT NULL,
    dataProrrogacao DATE NULL,
    status ENUM('em_andamento', 'finalizado') NOT NULL DEFAULT 'em_andamento',
    idCliente INT UNSIGNED NOT NULL,
    idFuncionario INT UNSIGNED NOT NULL,
    CONSTRAINT pk_emprestimo PRIMARY KEY (idEmprestimo),
    CONSTRAINT ck_emprestimo_prazo CHECK (dataLimiteDevolucao >= dataEmprestimo),
    CONSTRAINT ck_emprestimo_prorrogacao CHECK (
        dataProrrogacao IS NULL OR dataProrrogacao >= dataLimiteDevolucao
    ),
    CONSTRAINT fk_emprestimo_cliente FOREIGN KEY (idCliente)
        REFERENCES Cliente (idCliente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_emprestimo_funcionario FOREIGN KEY (idFuncionario)
        REFERENCES Funcionario (idFuncionario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 6. ITEM_EMPRESTIMO: resolve o relacionamento N:M entre emprestimo e livro.
CREATE TABLE ItemEmprestimo (
    idEmprestimo INT UNSIGNED NOT NULL,
    idLivro INT UNSIGNED NOT NULL,
    quantidade INT UNSIGNED NOT NULL,
    dataDevolucao DATE NULL,
    situacaoItem ENUM('emprestado', 'devolvido', 'avariado') NOT NULL DEFAULT 'emprestado',
    CONSTRAINT pk_item_emprestimo PRIMARY KEY (idEmprestimo, idLivro),
    CONSTRAINT ck_item_quantidade CHECK (quantidade > 0),
    CONSTRAINT ck_item_devolucao CHECK (
        (situacaoItem = 'emprestado' AND dataDevolucao IS NULL)
        OR (situacaoItem IN ('devolvido', 'avariado') AND dataDevolucao IS NOT NULL)
    ),
    CONSTRAINT fk_item_emprestimo FOREIGN KEY (idEmprestimo)
        REFERENCES Emprestimo (idEmprestimo)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_item_livro FOREIGN KEY (idLivro)
        REFERENCES Livro (idLivro)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 7. MULTA: ocorrencia por atraso ou avaria de um item do emprestimo.
CREATE TABLE Multa (
    idMulta INT UNSIGNED NOT NULL,
    idEmprestimo INT UNSIGNED NOT NULL,
    idLivro INT UNSIGNED NOT NULL,
    idFuncionario INT UNSIGNED NOT NULL,
    tipo ENUM('atraso', 'avaria') NOT NULL,
    descricao VARCHAR(255) NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    dataRegistro DATE NOT NULL,
    dataPagamento DATE NULL,
    statusPagamento ENUM('pendente', 'paga') NOT NULL DEFAULT 'pendente',
    CONSTRAINT pk_multa PRIMARY KEY (idMulta),
    CONSTRAINT ck_multa_valor CHECK (valor > 0),
    CONSTRAINT ck_multa_pagamento CHECK (
        (statusPagamento = 'pendente' AND dataPagamento IS NULL)
        OR (statusPagamento = 'paga' AND dataPagamento IS NOT NULL)
    ),
    CONSTRAINT ck_multa_data_pagamento CHECK (
        dataPagamento IS NULL OR dataPagamento >= dataRegistro
    ),
    CONSTRAINT fk_multa_item_emprestimo FOREIGN KEY (idEmprestimo, idLivro)
        REFERENCES ItemEmprestimo (idEmprestimo, idLivro)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_multa_funcionario FOREIGN KEY (idFuncionario)
        REFERENCES Funcionario (idFuncionario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 8. RESERVA: permite reservar um livro e vincular a reserva ao emprestimo
-- correspondente quando ela for atendida.
CREATE TABLE Reserva (
    idReserva INT UNSIGNED NOT NULL,
    idCliente INT UNSIGNED NOT NULL,
    idLivro INT UNSIGNED NOT NULL,
    idFuncionario INT UNSIGNED NOT NULL,
    idEmprestimo INT UNSIGNED NULL,
    dataReserva DATE NOT NULL,
    dataEncerramento DATE NULL,
    status ENUM('ativa', 'atendida', 'cancelada') NOT NULL DEFAULT 'ativa',
    observacao VARCHAR(255) NULL,
    CONSTRAINT pk_reserva PRIMARY KEY (idReserva),
    CONSTRAINT uq_reserva_emprestimo UNIQUE (idEmprestimo),
    CONSTRAINT ck_reserva_status CHECK (
        (status = 'ativa' AND dataEncerramento IS NULL AND idEmprestimo IS NULL)
        OR (status = 'atendida' AND dataEncerramento IS NOT NULL AND idEmprestimo IS NOT NULL)
        OR (status = 'cancelada' AND dataEncerramento IS NOT NULL AND idEmprestimo IS NULL)
    ),
    CONSTRAINT ck_reserva_data CHECK (
        dataEncerramento IS NULL OR dataEncerramento >= dataReserva
    ),
    CONSTRAINT fk_reserva_cliente FOREIGN KEY (idCliente)
        REFERENCES Cliente (idCliente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_reserva_livro FOREIGN KEY (idLivro)
        REFERENCES Livro (idLivro)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_reserva_funcionario FOREIGN KEY (idFuncionario)
        REFERENCES Funcionario (idFuncionario)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_reserva_emprestimo FOREIGN KEY (idEmprestimo)
        REFERENCES Emprestimo (idEmprestimo)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Fim do DDL: o banco BibliotecaDB possui 8 tabelas.
