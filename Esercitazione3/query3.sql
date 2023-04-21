USE uni_db;

-- Transazione: scrivere una transazione che assegni al prof. meno impegnato l'unico corso scoperto
START TRANSACTION;

SELECT @prof := matricola, sum(cfu) as cfu_tot
FROM professori p 
INNER JOIN corsi c 
ON c.professore=p.matricola
GROUP BY professore
ORDER BY cfu_tot asc
LIMIT 1;

UPDATE corsi
SET professore = @prof
WHERE professore IS NULL;

COMMIT;

-- Stored Procedure 1: scrivere una stored procedure che restituisca le medie ponderate ed aritmetiche di tutti gli studenti
DELIMITER $$
CREATE PROCEDURE CalcoloMedie()
BEGIN
	SELECT s.matricola, s.nome, s.cognome, 
	SUM(e.voto*c.cfu)/SUM(c.cfu) as mp,
	AVG(e.voto) as ma
	FROM studenti s INNER JOIN esami e 
	ON s.matricola = e.studente
		INNER JOIN corsi c ON e.corso = c.codice
	GROUP BY e.studente;
END $$
DELIMITER ;

-- Stored Procedure 2: scrivere na stored procedure che restituisca in una variabile passata il monte di ore di un dato docente 
-- (se il docente non esiste bisogna lanciare un errore)
DELIMITER $$
CREATE PROCEDURE MonteOre(IN docente INT, OUT ore INT)
BEGIN
	SELECT SUM(cfu*8)
    INTO ore
    FROM corsi c
    WHERE professore=docente;
    IF ore IS NULL THEN
        SIGNAL SQLSTATE "02000"
        SET MESSAGE_TEXT = "Docente not found!";
    END IF;
END $$
DELIMITER ;

-- User Defined Function 1: scrivere una user defined function che restituisca il corso di laurea di uno studente
DELIMITER $$

CREATE FUNCTION cdl(matricola char(9))
RETURNS CHAR(4) DETERMINISTIC
BEGIN
    RETURN SUBSTRING(matricola, 1, 4);
END $$

DELIMITER ;


-- User Defined Function 2: scrivere una user defined function che restituisca la media ponderata di uno studente
DELIMITER $$

CREATE FUNCTION media_ponderata(matricola char(9))
RETURNS float DETERMINISTIC
BEGIN
	DECLARE mp float;
    SELECT SUM(c.cfu * e.voto) / SUM(c.cfu)
    INTO mp
    FROM esami e INNER JOIN corsi s
    ON e.corso = s.codice
    WHERE e.studente = matricola;
    RETURN (mp);
END $$

DELIMITER ;


-- User Defined Function 3: scrivere una user defined function che restituisca il rank di uno studente nel suo corso di laurea in base alla sua media ponderata
DELIMITER $$

CREATE FUNCTION rank_cdl(matricola char(9))
RETURNS INT DETERMINISTIC
BEGIN
	DECLARE r INT;
    SELECT COUNT(*)
    INTO r
	FROM studenti s
	WHERE cdl(s.matricola) = cdl(matricola) AND
	media_ponderata(s.matricola) >= media_ponderata(matricola);
    RETURN (r);
END $$

DELIMITER ;

-- Trigger 1: scrivere un trigger per tenere traccia delle assunzioni (data di inserimento di un docente nel DB = data di assunzione)
CREATE TABLE assunzioni(
    matricola INT(4) PRIMARY KEY,
    data_assunzione DATE
);

DELIMITER $$

CREATE TRIGGER trg_data_assunzione
AFTER INSERT ON professori
FOR EACH ROW BEGIN
	INSERT INTO assunzioni VALUES (matricola, CURDATE());
END $$

DELIMITER ;


-- Trigger 2: scrivere un trigger che, nel momento in cui viene inserito un corso scoperto (cioè senza professore), 
-- lo assegna ad un prof. che non ha corsi (non importa a quale)
DELIMITER $$

CREATE TRIGGER trg_corso_scoperto
BEFORE INSERT ON corsi
FOR EACH ROW BEGIN
    IF NEW.professore IS NULL THEN
        SELECT matricola INTO @profe
        FROM professori
        WHERE matricola NOT IN (
	        SELECT DISTINCT professore
            FROM corsi
            WHERE professore IS NOT NULL
        ) 
        LIMIT 1;
        SET NEW.professore = @profe;
	END IF;
END $$
DELIMITER ;