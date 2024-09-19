use veterinario;
-- Criação das tabelas (Pacientes, veterinarios e consultar)
CREATE TABLE Pacientes (
    id_paciente INT PRIMARY KEY AUTO_INCREMENT, 
    nome VARCHAR(100), 
    especie VARCHAR(50), 
    idade INT 
);

CREATE TABLE Veterinarios (
    id_veterinario INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100), 
    especialidade VARCHAR(50)
);

CREATE TABLE Consultas (
    id_consulta INT PRIMARY KEY AUTO_INCREMENT, 
    id_paciente INT, 
    id_veterinario INT, 
    data_consulta DATE, 
    custo DECIMAL(10,2), 
    FOREIGN KEY (id_paciente) REFERENCES Pacientes(id_paciente), 
    FOREIGN KEY (id_veterinario) REFERENCES Veterinarios(id_veterinario) 
);

-- Agendamento de consultas
DELIMITER //

CREATE PROCEDURE agendar_consulta(
    IN p_id_paciente INT,
    IN p_id_veterinario INT,
    IN p_data_consulta DATE,
    IN p_custo DECIMAL(10, 2)
)
BEGIN
    INSERT INTO Consultas (id_paciente, id_veterinario, data_consulta, custo)
    VALUES (p_id_paciente, p_id_veterinario, p_data_consulta, p_custo);
END //

DELIMITER ;


-- Atualizar paciente
DELIMITER //

CREATE PROCEDURE atualizar_paciente(
    IN p_id_paciente INT,
    IN p_novo_nome VARCHAR(100),
    IN p_nova_especie VARCHAR(50),
    IN p_nova_idade INT
)
BEGIN
    UPDATE Pacientes
    SET nome = p_novo_nome,
        especie = p_nova_especie,
        idade = p_nova_idade
    WHERE id_paciente = p_id_paciente;
END //

DELIMITER ;

-- Remover pacientes
DELIMITER //

CREATE PROCEDURE remover_consulta(
    IN p_id_consulta INT
)
BEGIN
    DELETE FROM Consultas
    WHERE id_consulta = p_id_consulta;
END //

DELIMITER ;

-- Function somando todos os gastos do paciente
DELIMITER //

CREATE FUNCTION total_gasto_paciente(p_id_paciente INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(10,2);
    SELECT COALESCE(SUM(custo), 0) INTO total
    FROM Consultas
    WHERE id_paciente = p_id_paciente;
    RETURN total;
END //

DELIMITER ;

-- Criação do Trigger para verificar idade do paciente
DELIMITER //

CREATE TRIGGER verificar_idade_paciente
BEFORE INSERT ON Pacientes
FOR EACH ROW
BEGIN
    IF NEW.idade <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A idade do paciente deve ser um número positivo.'; -- Se enviar um número negativo, enviara uma mensagem de erro com uma mensagem.
    END IF;
END //

DELIMITER ;

-- Criação do Trigger para atualizar custo da consulta
DELIMITER //

CREATE TRIGGER atualizar_custo_consulta
AFTER UPDATE ON Consultas
FOR EACH ROW
BEGIN
    IF OLD.custo <> NEW.custo THEN
        INSERT INTO Log_Consultas (id_consulta, custo_antigo, custo_novo)
        VALUES (NEW.id_consulta, OLD.custo, NEW.custo);
    END IF;
END //

DELIMITER ;

-- TESTES 1 ------------------------------

SELECT * FROM Pacientes WHERE id_paciente = 1;
INSERT INTO Pacientes (nome, especie, idade) 
VALUES ('Paciente 1', 'Cachorro', 3);

SELECT * FROM Veterinarios WHERE id_veterinario = 1;
INSERT INTO Veterinarios (nome, especialidade) 
VALUES ('Veterinario 1', 'Clínica Geral');

CALL agendar_consulta(1, 1, '2024-09-18', 300.00);

SELECT * FROM Consultas WHERE id_paciente = 1 AND id_veterinario = 1;

CALL atualizar_paciente(1, 'ScoobyDoo', 'Cachorro', 5);

SELECT * FROM Pacientes WHERE id_paciente = 1;

CALL remover_consulta(1);

SELECT total_gasto_paciente(1);

INSERT INTO Pacientes (nome, especie, idade) VALUES ('Teste', 'Cachorro', -2);

UPDATE Consultas SET custo = 350.00 WHERE id_consulta = 1;

-- PARTE 2 DO TRABALHO ----------------------------------------------------------------------------------------------------
-- Criar 3 tabelas que façam sentido com o BD
-- Tabela produtos que contem medicamentos, vacinas e outros suprimentos.
CREATE TABLE Produtos (
    id_produto INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    descricao VARCHAR(255),
    preco DECIMAL(10,2) NOT NULL,
    estoque INT DEFAULT 0,
    categoria VARCHAR(50)
);

-- Tabela de tratamento de animais
CREATE TABLE Tratamentos (
    id_tratamento INT PRIMARY KEY AUTO_INCREMENT,
    id_consulta INT,
    descricao VARCHAR(255) NOT NULL,
    custo DECIMAL(10,2) NOT NULL,
    data_tratamento DATE,
    FOREIGN KEY (id_consulta) REFERENCES Consultas(id_consulta)
);

-- Tabela funcionarios, tudo relacionado ao funcionario

CREATE TABLE Funcionarios (
    id_funcionario INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    cargo VARCHAR(50) NOT NULL,
    salario DECIMAL(10,2) NOT NULL,
    data_admissao DATE
);

-- 5 Triggers
-- Trigger para verificar preço do produto antes de inserir
DELIMITER //

CREATE TRIGGER verificar_preco_produto
BEFORE INSERT ON Produtos
FOR EACH ROW
BEGIN
    IF NEW.preco < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O preço do produto deve ser um valor positivo.';
    END IF;
END //

DELIMITER ;

-- Trigger para atualizar estoque do produto após um tratamento
DELIMITER //

CREATE TRIGGER atualizar_estoque_tratamento
AFTER INSERT ON Tratamentos
FOR EACH ROW
BEGIN
    UPDATE Produtos
    SET estoque = estoque - 1 
    WHERE id_produto = (SELECT id_produto FROM Produtos WHERE nome = 'Produto Usado no Tratamento'); 
END //

DELIMITER ;

-- Trigger para verificar o salário do funcionário ao inserir ou atualizar
DELIMITER //

CREATE TRIGGER verificar_salario_funcionario
BEFORE INSERT ON Funcionarios
FOR EACH ROW
BEGIN
    IF NEW.salario < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O salário do funcionário deve ser um valor positivo.';
    END IF;
END //

DELIMITER ;

-- Trigger para registrar a data de tratamento como a data atual
DELIMITER //

CREATE TRIGGER registrar_data_tratamento
BEFORE INSERT ON Tratamentos
FOR EACH ROW
BEGIN
    SET NEW.data_tratamento = CURDATE(); 
END //

DELIMITER ;


-- Trigger para calcular o custo total do tratamento
DELIMITER //

CREATE TRIGGER calcular_custo_total_tratamento
AFTER INSERT ON Tratamentos
FOR EACH ROW
BEGIN
    DECLARE total DECIMAL(10,2);
    SELECT (NEW.custo + (SELECT COALESCE(SUM(custo), 0) FROM Consultas WHERE id_consulta = NEW.id_consulta)) INTO total;
    UPDATE Tratamentos
    SET custo = total
    WHERE id_tratamento = NEW.id_tratamento;
END //

DELIMITER ;

-- 5 procedures
-- Procedure para cadastrar uma novo produto
DELIMITER //

CREATE PROCEDURE adicionar_produto(
    IN p_nome VARCHAR(100),
    IN p_descricao VARCHAR(255),
    IN p_preco DECIMAL(10,2),
    IN p_estoque INT,
    IN p_categoria VARCHAR(50)
)
BEGIN
    INSERT INTO Produtos (nome, descricao, preco, estoque, categoria)
    VALUES (p_nome, p_descricao, p_preco, p_estoque, p_categoria);
END //

DELIMITER ;

-- Procedimento para registrar um tratamento
DELIMITER //

CREATE PROCEDURE registrar_tratamento(
    IN p_id_consulta INT,
    IN p_descricao VARCHAR(255),
    IN p_custo DECIMAL(10,2),
    IN p_data_tratamento DATE
)
BEGIN
    INSERT INTO Tratamentos (id_consulta, descricao, custo, data_tratamento)
    VALUES (p_id_consulta, p_descricao, p_custo, p_data_tratamento);
END //

DELIMITER ;

-- Procedimento para atualizar informações de um funcionário
DELIMITER //

CREATE PROCEDURE atualizar_funcionario(
    IN p_id_funcionario INT,
    IN p_novo_nome VARCHAR(100),
    IN p_novo_cargo VARCHAR(50),
    IN p_novo_salario DECIMAL(10,2),
    IN p_nova_data_admissao DATE
)
BEGIN
    UPDATE Funcionarios
    SET nome = p_novo_nome,
        cargo = p_novo_cargo,
        salario = p_novo_salario,
        data_admissao = p_nova_data_admissao
    WHERE id_funcionario = p_id_funcionario;
END //

DELIMITER ;

-- Procedimento para remover um produto
DELIMITER //

CREATE PROCEDURE remover_produto(
    IN p_id_produto INT
)
BEGIN
    DELETE FROM Produtos
    WHERE id_produto = p_id_produto;
END //

DELIMITER ;

--  Procedimento para listar todos os tratamentos de um paciente
DELIMITER //

CREATE PROCEDURE listar_tratamentos_paciente(
    IN p_id_paciente INT
)
BEGIN
    SELECT T.id_tratamento, T.descricao, T.custo, T.data_tratamento
    FROM Tratamentos T
    JOIN Consultas C ON T.id_consulta = C.id_consulta
    WHERE C.id_paciente = p_id_paciente;
END //

DELIMITER ;

-- TESTES 2 ---

-- Trigger para atualizar estoque de produtos
UPDATE Produtos
SET preco = preco * 1.10  
WHERE id_produto = 1;

-- Trigger para registrar log de tratamentos
INSERT INTO Tratamentos (id_consulta, descricao, custo, data_tratamento) VALUES (2, 'Tratamento de dentes', 150.00, CURDATE());

-- Trigger para atualizar salario do funcionario
UPDATE Funcionarios
SET salario = salario * 1.10  
WHERE id_funcionario = 1; 

-- Trigger para atualizar o custo de um tratamento
UPDATE Tratamentos
SET custo = custo * 1.05  
WHERE id_tratamento = 1; 

-- Trigger para verificar demissão de um funcionário
DELETE FROM Funcionarios
WHERE id_funcionario = 1; 

-- TESTES 5 PRECEDURES 
-- Agendar Consulta
CALL agendar_consulta(1, 1, CURDATE(), 100.00); 

-- Atualizar Paciente
CALL atualizar_paciente(1, 'Novo Nome', 'Nova Espécie', 5);

-- Remover Consulta
CALL remover_consulta(1);

-- Total Gasto pelo Paciente
SELECT total_gasto_paciente(1); 

-- Registrar Tratamento
INSERT INTO Tratamentos (id_consulta, descricao, custo, data_tratamento)
VALUES (3, 'Tratamento de dentes', 150.00, CURDATE());












