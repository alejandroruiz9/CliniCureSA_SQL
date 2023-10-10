
--Creacion de Store Procedures para llenar las tablas creadas
CREATE OR ALTER PROCEDURE CargarDatosATablaPaciente
AS
BEGIN
	DECLARE @Nombre varchar(50);
	DECLARE @Apellido varchar(50);
	DECLARE @FechaNacimiento char(10);
	DECLARE @TipoDocumento char(3);
	DECLARE @NumeroDocumento char(15);
	DECLARE @SexoBiologico char(9);
	DECLARE @nacionalidad varchar(30);
	DECLARE @mail varchar(50);

	DECLARE @CalleYNro varchar(100);
    DECLARE @Localidad varchar(50); 
    DECLARE @Provincia varchar(50); 

	DECLARE @ID_HistoriaClinica INT;
	DECLARE @ID_Domicilio INT;
	DECLARE @TotalRegistros INT;
	DECLARE @Contador INT;
	CREATE TABLE #TempPacientes (
	Nombre nvarchar(500) COLLATE latin1_general_ci_ai,
    Apellido nvarchar(600) COLLATE latin1_general_ci_ai,
	FechaNacimiento char(10),
    TipoDocumento varchar(600),
    NumeroDocumento varchar(600),
    SexoBiologico varchar(600),
    Genero varchar(600),
    TelefonoFijo varchar(600),
    Nacionalidad varchar(600),
    Mail varchar(600),
	CalleYNro varchar(50),
	Localidad varchar(50),
	Provincia varchar(50),

);

BULK INSERT #TempPacientes
FROM 'C:\Pacientes.csv'
WITH (
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2,
	CODEPAGE = '65001'
);
	-- Este update es para cambiar el formato dd/mm/aaaa por mm/dd/aaaa
	UPDATE #TempPacientes
	SET FechaNacimiento = 
		CASE 
			WHEN LEN(FechaNacimiento) >= 8 AND FechaNacimiento LIKE '%/%/____' -- Verifica si cumple con el patrón.
			THEN 
				CASE 
					WHEN CONVERT(INT, SUBSTRING(FechaNacimiento, CHARINDEX('/', FechaNacimiento) + 1, CHARINDEX('/', FechaNacimiento, CHARINDEX('/', FechaNacimiento) + 1) - CHARINDEX('/', FechaNacimiento) - 1)) <= 12
					THEN 
						CONCAT(
							RIGHT('00' + SUBSTRING(FechaNacimiento, CHARINDEX('/', FechaNacimiento) + 1, CHARINDEX('/', FechaNacimiento, CHARINDEX('/', FechaNacimiento) + 1) - CHARINDEX('/', FechaNacimiento) - 1), 2), 
							'/', 
							LEFT(FechaNacimiento, CHARINDEX('/', FechaNacimiento) - 1), 
							'/', 
							SUBSTRING(FechaNacimiento, CHARINDEX('/', FechaNacimiento, CHARINDEX('/', FechaNacimiento) + 1) + 1, LEN(FechaNacimiento))
						)
					ELSE NULL
				END
			ELSE NULL 
		END;

	-- Obtener el total de registros en la tabla temporal
	SELECT @TotalRegistros = COUNT(*) FROM #TempPacientes;

	-- Inicializar contador
	SET @Contador = 1;

	-- Bucle para procesar cada registro del csv e insertarlo en Pacientes.paciente
	WHILE @Contador <= @TotalRegistros
	BEGIN
		-- Obtener valores del registro actual
		SELECT TOP 1
			@Nombre = Nombre,
			@Apellido = Apellido,
			@FechaNacimiento = FechaNacimiento,
			@TipoDocumento = TipoDocumento,
			@NumeroDocumento = NumeroDocumento,
			@SexoBiologico = SexoBiologico,
			@Nacionalidad = Nacionalidad,
			@mail = Mail,

			@CalleYNro = CalleYNro,
            @Localidad = Localidad, 
            @Provincia = Provincia 
		FROM #TempPacientes
		ORDER BY (SELECT NULL);

		--SET @FechaNacimiento = CONVERT(DATE, @FechaNacimiento,103); -- 103 es el formato dd/mm/yyyy


		-- Obtener el próximo ID_HistoriaClinica
		SELECT @ID_HistoriaClinica = ISNULL(MAX(CONVERT(INT, idHistoriaClinica)), 0) + 1
		FROM Pacientes.paciente;


		--Insertar el nuevo paciente
	   INSERT INTO Pacientes.paciente (idHistoriaClinica, nombre, apellido, fechaNacimiento, tipoDocumento, numeroDocumento, sexoBiologico, nacionalidad, mail)
	   VALUES (
			RIGHT('0000000' + CAST(@ID_HistoriaClinica AS varchar(7)), 7),
			@Nombre,
			@Apellido,
			@FechaNacimiento,
			@TipoDocumento,
			@NumeroDocumento,
			@SexoBiologico,
			@nacionalidad,
			@mail
		);

		-- Obtener el próximo ID_HistoriaClinica
		SELECT @ID_Domicilio = ISNULL(MAX(CONVERT(INT, idDomicilio)), 0) + 1
		FROM Pacientes.domicilio;

		-- SEPARAR LA CALLE DEL NUMERO

		DECLARE @Direccion varchar(100);
		SET @Direccion = @CalleYNro;

		DECLARE @NombreCalle varchar(100);
		DECLARE @Numero varchar(10);

		IF LEFT(@Direccion, 5) = 'CALLE'
		BEGIN
			SET @NombreCalle = SUBSTRING(@Direccion, 7, LEN(@Direccion)-6);
			SET @Numero = RIGHT(@Direccion, CHARINDEX(' ', REVERSE(@Direccion)) - 1);
		END
		ELSE
		BEGIN
			SET @NombreCalle = LEFT(@Direccion, LEN(@Direccion) - CHARINDEX(' ', REVERSE(@Direccion)));
			SET @Numero = RIGHT(@Direccion, CHARINDEX(' ', REVERSE(@Direccion)) - 1);
		END

		-- Insertar en la tabla de domicilio
        INSERT INTO Pacientes.domicilio (idDomicilio, calle, numero, piso, depto, codigoPostal, pais, provincia, localidad, id_HistoriaClinica)
        VALUES (
            RIGHT('0000000' + CAST(@ID_Domicilio AS varchar(7)), 7),
            @NombreCalle,
			@Numero,
			NULL,
			NULL,
			NULL,
			NULL,
			@Provincia,
            @Localidad,
            RIGHT('0000000' + CAST(@ID_HistoriaClinica AS varchar(7)), 7)
        );

		DELETE FROM #TempPacientes
		WHERE NumeroDocumento = @NumeroDocumento;
    
		SET @Contador = @Contador + 1;
	END;
	DROP TABLE #TempPacientes
END;

--
CREATE OR ALTER PROCEDURE CargarDatosJSON
	-- Crear la tabla si no existe
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TempJSON]') AND type in (N'U'))
	BEGIN
		CREATE TABLE [dbo].[TempJSON](
			[_id] NVARCHAR(50)  ,
			[Area] NVARCHAR(50)  COLLATE latin1_general_ci_ai,
			[Estudio] NVARCHAR(100)  COLLATE latin1_general_ci_ai,
			[Prestador] NVARCHAR(50)  COLLATE latin1_general_ci_ai,
			[Plan] NVARCHAR(50)  COLLATE latin1_general_ci_ai,
			[Porcentaje Cobertura] INT ,
			[Costo] INT ,
			[Requiere autorizacion] BIT 
		) ON [PRIMARY]
	END

	BULK INSERT TempJSON 
	FROM 'C:\Centro_Autorizaciones.Estudios clinicos.json'
	WITH (
		FIELDTERMINATOR = ',',
		ROWTERMINATOR = '\n'
	);

	SELECT *
	FROM TempJSON

	DECLARE @JSONData NVARCHAR(MAX) 

	-- Leer el contenido del archivo JSON y asignarlo a la variable
	SELECT @JSONData = BulkColumn COLLATE Latin1_General_BIN
	FROM OPENROWSET (BULK 'C:\Centro_Autorizaciones.Estudios clinicos.json', 
	SINGLE_CLOB, 
	CODEPAGE = '65001') as j

	SELECT @JSONData = REPLACE(@JSONData, 'Ã¡', 'á')
	SELECT @JSONData = REPLACE(@JSONData, 'Ã©', 'é')
	SELECT @JSONData = REPLACE(@JSONData, 'Ã­', 'í')
	SELECT @JSONData = REPLACE(@JSONData, 'Ã³', 'ó')
	SELECT @JSONData = REPLACE(@JSONData, 'Ãº', 'ú')
	SELECT @JSONData = REPLACE(@JSONData, 'Ã¼', 'ü')

	SELECT @JSONData

	-- Insertar datos en la tabla TempJSON
	INSERT INTO TempJSON (_id, Area, Estudio, Prestador, [Plan], [Porcentaje Cobertura], Costo, [Requiere autorizacion])
	SELECT 
		JSON_VALUE([value], '$._id."$oid"') AS _id,
		JSON_VALUE([value], '$.Area') AS Area,
		JSON_VALUE([value], '$.Estudio') AS Estudio,
		JSON_VALUE([value], '$.Prestador') AS Prestador,
		JSON_VALUE([value], '$.Plan') AS [Plan],
		JSON_VALUE([value], '$."Porcentaje Cobertura"') AS [Porcentaje Cobertura],
		JSON_VALUE([value], '$.Costo') AS Costo,
		JSON_VALUE([value], '$."Requiere autorizacion"') AS [Requiere autorizacion]
	FROM OPENJSON(@JSONData)
END;



--Cardar datos en tablas schema medicos
CREATE OR ALTER PROCEDURE CargarDatosASchemaMedico
AS
BEGIN
-- Crear una tabla temporal para almacenar los datos del CSV
CREATE TABLE #TempMedicos (
    nombre CHAR(30),
	apellido CHAR(30),
	especialidad NvarCHAR(30) COLLATE SQL_Latin1_General_CP1_CI_AS,
	colegiado  CHAR(30)
);

BULK INSERT #TempMedicos
FROM 'C:\Medicos.csv'
WITH (
    FIRSTROW = 2,          -- Opcional: Si el archivo CSV tiene una fila de encabezado, omítela.
     DATAFILETYPE = 'char',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001'
);


--Insertamos en la tabla especialidad asignando un ID incremental utilizando el row num como id y leyendo el resto de los datos de la #TempMedicos
insert into Medicos.especialidad(idEspecialidad,nombreEspecialidad)
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS ID,a.especialidad
FROM (select distinct especialidad from #TempMedicos) a





--Insertamos en la tabla medico utilziando como id del medico el row number y leyendo el resto de los datos de #TempMedicos
insert into Medicos.medico (idMedico,nombreMedico,apellidoMedico,nroMatricula,idEspecialidad)
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS ID,
	apellido,
	case 
	when nombre like 'Dr.%' then substring(nombre,5,LEN(nombre)-4)
	when nombre like 'Dra.%' then substring(nombre,6,LEN(nombre)-5)
	when nombre like 'Lic.%' then substring(nombre,6,LEN(nombre)-5)
	when nombre like 'Kgo.%' then substring(nombre,6,LEN(nombre)-5)
	else nombre end as nombre,
	colegiado,
	(select idEspecialidad from Medicos.especialidad ES where ES.nombreEspecialidad = TM.especialidad) as idesp
from #TempMedicos TM


--Creamos tabla tmp para poder cargar lo leido desde el csv sedes
CREATE TABLE #TempSedes (
    sede CHAR(30),
	direccion CHAR(35),
	localidad CHAR(30),
	provincia  CHAR(30)
);

BULK INSERT #TempSedes
FROM 'C:\Sedes.csv'
WITH (
    FIRSTROW = 2,          -- Opcional: Si el archivo CSV tiene una fila de encabezado, omítela.
     DATAFILETYPE = 'char',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001'
);

--Insertamos las sedes leyendo desde el #TempSedes y utilizando row number como id de la sede
insert into Medicos.sedeDeAtencion(idSede,nombreSede,direccionSede)
select 
	ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS ID,
	case when substring(sede,1,1) = ' ' then substring(sede,2,LEN(sede)-1)
	else sede end as sede,
	direccion
	
from #TempSedes



--Insericon de tabla dias X sede

--para esto vamos a tomar al azar id's de la tabla medico y sede y asignarle una fecha y horario aleatorio a partir de Nov-1 con rango 
--de horario cada 15 minutos


DECLARE @FechaInicio DATE = '2023-11-01';

-- Definir el número de registros que deseas insertar
DECLARE @NumRegistros INT = 50; -- Cambia este valor al número deseado de registros

-- Variable de contador
DECLARE @Contador INT = 1;

-- Iniciar el bucle de inserción
WHILE @Contador <= @NumRegistros
BEGIN
    -- Variables para valores aleatorios
    DECLARE @IdSede CHAR(6);
    DECLARE @IdMedico CHAR(6);
    DECLARE @Dia DATE;
    DECLARE @HoraInicio TIME;
    DECLARE @IdEspecialidad CHAR(6);

    -- Generar valores aleatorios
    SELECT 
        @IdSede = (SELECT TOP 1 idSede FROM Medicos.sedeDeAtencion ORDER BY NEWID()),
        @IdMedico = (SELECT TOP 1 idMedico FROM Medicos.medico ORDER BY NEWID()),
        @Dia = DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 30, @FechaInicio),
        @HoraInicio = FORMAT(DATEADD(MINUTE, (ABS(CHECKSUM(NEWID())) % 36) * 15, '15:00'), 'HH:mm'),
        @IdEspecialidad = (SELECT TOP 1 idEspecialidad FROM Medicos.especialidad ORDER BY NEWID());

    -- Insertar el registro solo si no existe una combinación igual
    IF NOT EXISTS (
        SELECT 1
        FROM Medicos.diasXsede
        WHERE idSede = @IdSede
          AND idMedico = @IdMedico
          AND dia = @Dia
          AND horaInicio = @HoraInicio
    )
    BEGIN
        -- Insertar el registro
        INSERT INTO Medicos.diasXsede (idSede, idMedico, dia, horaInicio, idEspecialidad)
        VALUES (@IdSede, @IdMedico, @Dia, @HoraInicio, @IdEspecialidad);
    END;

    -- Incrementar el contador
    SET @Contador = @Contador + 1;

	
END;
select * from Medicos.diasXsede
	select * from Medicos.medico
	select * from Medicos.especialidad
	select * from Medicos.sedeDeAtencion
END;
--Cardar datos de reserva de Turno
CREATE OR ALTER PROCEDURE GenerarValoresAleatoriosReserva
AS
BEGIN
    -- Declara las variables
    DECLARE @idTurno char(24);
    DECLARE @fecha DATE;
    DECLARE @hora time;
    DECLARE @id_Medico char(6);
    DECLARE @id_Especialidad char(6);
    DECLARE @id_direccion_atencion char(6);
    DECLARE @id_estado_turno char(3);
    DECLARE @id_tipo_turno char(6);
    DECLARE @id_Paciente char(7);

    -- Inicia un bucle para insertar 15 registros
    DECLARE @i int = 1;
    WHILE @i <= 15
    BEGIN
        -- Genera un idTurno único
        SET @idTurno = CONCAT('TURNO', RIGHT('0000' + CAST(@i AS varchar), 4));

        -- Selecciona valores aleatorios de las tablas relacionadas
        SELECT TOP 1 
            @id_Medico = idMedico, 
            @fecha = dia, 
            @hora = horaInicio, 
            @id_Especialidad = idEspecialidad, 
            @id_direccion_atencion = idSede 
        FROM Medicos.diasXsede ORDER BY NEWID();

        SELECT TOP 1 @id_estado_turno = idEstado FROM Turnos.EstadoTurno ORDER BY NEWID();
        SELECT TOP 1 @id_tipo_turno = idTipoTurno FROM Turnos.TipoTurno ORDER BY NEWID();
        SELECT TOP 1 @id_Paciente = idHistoriaClinica FROM Pacientes.Paciente ORDER BY NEWID();

        -- Inserta los valores aleatorios en la tabla Turnos.Reserva
        INSERT INTO Turnos.Reserva
            (idTurno, fecha, hora, id_Medico, id_Especialidad, id_direccion_atencion, id_estado_turno, id_tipo_turno, id_Paciente)
        VALUES
            (@idTurno, @fecha, @hora, @id_Medico, @id_Especialidad, @id_direccion_atencion, @id_estado_turno, @id_tipo_turno, @id_Paciente);

        -- Incrementa el contador
        SET @i = @i + 1;
    END;
END;

--Cardar datos de Prestadores
CREATE OR ALTER PROCEDURE GenerarValoresAleatoriosPrestador
AS
BEGIN
    -- Declara las variables
    DECLARE @idPrestador char(6);
    DECLARE @nombrePrestador varchar(50);
    DECLARE @planPrestador varchar(50);

    -- Define una lista de posibles nombres de prestadores y planes
    DECLARE @nombresPrestador TABLE (nombre varchar(50));
    INSERT INTO @nombresPrestador VALUES ('Galeno'), ('Hospital Italiano'), ('OSDE'), ('Swiss Medical'), ('Medicus');

    DECLARE @planesPrestador TABLE (plann varchar(50));
    INSERT INTO @planesPrestador VALUES ('Plan 1'), ('Plan 2'), ('Plan 3'), ('Plan 4'), ('Plan 5');

    -- Inicia un bucle para insertar registros
    DECLARE @i int = 1;
    WHILE @i <= 15
    BEGIN
        -- Genera un idPrestador único
        SET @idPrestador = RIGHT('000000' + CAST(@i AS varchar), 4);

        -- Verifica si el idPrestador ya existe en la tabla
        IF NOT EXISTS (SELECT 1 FROM Pacientes.prestador WHERE idPrestador = @idPrestador)
        BEGIN
            -- Selecciona valores aleatorios de las listas de nombres y planes
            SELECT TOP 1 @nombrePrestador = nombre FROM @nombresPrestador ORDER BY NEWID();
            SELECT TOP 1 @planPrestador = plann FROM @planesPrestador ORDER BY NEWID();

            -- Inserta los valores aleatorios en la tabla Pacientes.prestador
            INSERT INTO Pacientes.prestador
                (idPrestador, nombrePrestador, planPrestador)
            VALUES
                (@idPrestador, @nombrePrestador, @planPrestador);
        END;

        -- Incrementa el contador
        SET @i = @i + 1;
    END;
END;

--Cardar datos de Cobertura
CREATE OR ALTER PROCEDURE GenerarValoresAleatoriosCobertura
AS
BEGIN
    -- Declara las variables
    DECLARE @idCobertura char(6);
    DECLARE @rutaImagenCredencial varchar(255);
    DECLARE @nroSocio char(7);
    DECLARE @fechaRegistro DATE;

    -- Inicia un bucle para insertar registros
    DECLARE @i int = 1;
    WHILE @i <= 300
    BEGIN
        -- Selecciona valores aleatorios de las tablas relacionadas
        SELECT TOP 1 @idCobertura = idPrestador FROM Pacientes.Prestador ORDER BY NEWID();
        SELECT TOP 1 @nroSocio = idHistoriaClinica FROM Pacientes.paciente ORDER BY NEWID();

        -- Genera una fecha de registro aleatoria
        SET @fechaRegistro = DATEADD(DAY, (ABS(CHECKSUM(NEWID())) % 365), '2023-01-01');

        -- Inserta los valores aleatorios en la tabla Pacientes.cobertura
        INSERT INTO Pacientes.cobertura
            (idCobertura, rutaImagenCredencial, nroSocio, fechaRegistro)
        VALUES
            (@idCobertura, NULL, @nroSocio, @fechaRegistro);

        -- Incrementa el contador
        SET @i = @i + 1;
    END;
END;

