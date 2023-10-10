
--Generar XML para exportar los turnos
CREATE OR ALTER PROCEDURE GenerarInformeTurnosAtendidos
    @nombrePrestador varchar(50),
    @fechaInicio date,
    @fechaFin date
AS
BEGIN
    SELECT 
        P.apellido AS 'Paciente/Apellido',
        P.nombre AS 'Paciente/Nombre',
        P.numeroDocumento AS 'Paciente/DNI',
        M.nombreMedico AS 'Medico/Nombre',
        M.apellidoMedico AS 'Medico/Apellido',
        M.nroMatricula AS 'Medico/Matricula',
        T.fecha AS 'Turno/Fecha',
        T.hora AS 'Turno/Hora',
        E.nombreEspecialidad AS 'Especialidad'
    FROM 
        Turnos.Reserva T
    INNER JOIN 
        Pacientes.Paciente P ON T.id_Paciente = P.idHistoriaClinica
    INNER JOIN 
        Medicos.medico M ON T.id_Medico = M.idMedico
    INNER JOIN 
        Medicos.especialidad E ON M.idEspecialidad = E.idEspecialidad
    INNER JOIN 
        Pacientes.cobertura C ON P.idHistoriaClinica = C.nroSocio
    INNER JOIN 
        Pacientes.prestador Pr ON C.idCobertura = Pr.idPrestador
    WHERE 
        Pr.nombrePrestador = @nombrePrestador AND
        T.fecha BETWEEN @fechaInicio AND @fechaFin
    FOR XML PATH('Turno'), ROOT('Turnos')
END;


--EN Desarrollo--


CREATE OR ALTER PROCEDURE [Pacientes].[InsertarEstudio]
    @fecha DATE,
    @nombreEstudio VARCHAR(50),
    @autorizado BIT,
    @rutaDocumentoResultado VARCHAR(255),
    @rutaImagenResultado VARCHAR(255),
    @Paciente_idHistoriaClinica CHAR(7)
AS
BEGIN
    SET NOCOUNT ON;

    -- Declarar variable para el idEstudio
    DECLARE @idEstudio CHAR(4)

    -- Obtener el máximo idEstudio actual
    SELECT @idEstudio = ISNULL(MAX(idEstudio), '0000')
    FROM Pacientes.estudio

    -- Incrementar el idEstudio
    SET @idEstudio = RIGHT('0000' + CAST(CONVERT(INT, @idEstudio) + 1 AS VARCHAR(4)), 4)

    -- Insertar el nuevo registro
    INSERT INTO Pacientes.estudio (idEstudio, fecha, nombreEstudio, autorizado, rutaDocumentoResultado, rutaImagenResultado, Paciente_idHistoriaClinica)
    VALUES (@idEstudio, @fecha, @nombreEstudio, @autorizado, @rutaDocumentoResultado, @rutaImagenResultado, @Paciente_idHistoriaClinica)
END

EXEC [Pacientes].[InsertarEstudio]
    @fecha = '2023-10-06',
    @nombreEstudio = 'Análisis de sangre',
    @autorizado = 1,
    @rutaDocumentoResultado = 'ruta/resultado.pdf',
    @rutaImagenResultado = 'ruta/resultado.jpg',
    @Paciente_idHistoriaClinica = '0000001'

SELECT *
FROM Pacientes.estudio

CREATE OR ALTER PROCEDURE [Pacientes].[AutorizarEstudio] 
    @codigoEstudio CHAR(4),
    @dniPaciente CHAR(15),
    @plan VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Autorizado NVARCHAR(50)
	DECLARE @nombreEstudio NVARCHAR(50)

	DECLARE @nombrePrestador VARCHAR(50)

    SELECT @nombrePrestador = p.nombrePrestador
    FROM Pacientes.prestador p
    INNER JOIN Pacientes.cobertura c ON p.idPrestador = c.id_Cobertura
    INNER JOIN Pacientes.paciente pa ON pa.id_HistoriaClinica = c.id_HistoriaClinica
    WHERE pa.idHistoriaClinica = @Paciente_idHistoriaClinica

    -- Verificar si el estudio requiere autorización
    SELECT @Autorizado = 
        CASE 
            WHEN tj.[Requiere autorizacion] = 1 THEN 'Solicitud pendiente'
            ELSE 'No requiere'
        END
    FROM TempJSON tj
    WHERE tj.Estudio = @codigoEstudio

    -- Actualizar el campo Autorizado
    UPDATE Estudios
    SET Autorizado = @Autorizado
    WHERE idEstudio = @codigoEstudio
        AND Paciente_idHistoriaClinica IN (SELECT idHistoriaClinica FROM Pacientes.paciente WHERE numeroDocumento = @dniPaciente AND [Plan] = @plan)
END