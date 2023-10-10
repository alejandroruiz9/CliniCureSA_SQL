-- Creación de la base de Datos

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ClinicaCureSA')
BEGIN
	CREATE DATABASE ClinicaCureSA;
END
GO
use ClinicaCureSA;

ALTER DATABASE ClinicaCureSA COLLATE latin1_general_ci_ai


-- Creamos tres esquemas para organizar de forma lógica los objetos de la base de datos.
-- Pacientes: contendrá todo lo referido a su cobertura, domicilio, estudios, credenciales de usuario, etc.
-- Turnos: tendrá los objetos que se refieren a la reserva, estado del turno y tipo de turno.
-- Medicos: contiene los objetos referidos a los médicos y su especialidad, días que atienden por sede y sedes de atención.
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Pacientes')
BEGIN
	EXEC('CREATE SCHEMA Pacientes');
END

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Medicos')
BEGIN
	EXEC('CREATE SCHEMA Medicos');
END

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Turnos')
BEGIN
	EXEC('CREATE SCHEMA Turnos');
END

-- Creación de las tablas y sus atributos
--Pacientes

IF OBJECT_ID(N'[Pacientes].[paciente]', N'U') IS NULL 
    CREATE TABLE Pacientes.paciente(
		idHistoriaClinica char(7) primary key,
		nombre varchar(50),
		apellido varchar(50),
		apellidoMaterno varchar(50),
		fechaNacimiento DATE,
		tipoDocumento char(3) CHECK (tipoDocumento IN ('DNI', 'LE', 'LC')),
		numeroDocumento char(15),
		sexoBiologico char(9) CHECK (sexoBiologico IN('Masculino', 'Femenino')),
		genero char(6) CHECK (genero IN ('Hombre', 'Mujer') ),
		nacionalidad varchar(30),
		rutaFotoDePerfil varchar(255),
		mail varchar(50),
		fechaDeRegistro DATE,
		fechaDeActualizacion DATE,
		usuarioActualizacion varchar(50),
		usuarioID char(7)
	);
-- Debido a que el telefono es un atributo multivaluado, decidimos crear otra tabla que tenga una referencia al paciente.
IF OBJECT_ID(N'[Pacientes].[telefono]', N'U') IS NULL 
	CREATE TABLE Pacientes.telefono(
		id char(7) primary key,
		telefonoFijo char(14),
		telefonoAlternativo char(14),
		telefonoLaboral char(14),
		FOREIGN KEY (id) REFERENCES Pacientes.paciente(idHistoriaClinica)
	);
-- Creación de la tabla usuario.
IF OBJECT_ID(N'[Pacientes].[usuario]', N'U') IS NULL 
	CREATE TABLE Pacientes.usuario(
		idUsuario char(7) primary key,
		contraseña varchar(50),
		fechaCreacion DATE,
		id_HistoriaClinica char(7),
		FOREIGN KEY (id_HistoriaClinica) REFERENCES Pacientes.paciente(idHistoriaClinica)
	);
IF OBJECT_ID(N'[Pacientes].[estudio]', N'U') IS NULL 
	CREATE TABLE Pacientes.estudio(
		idEstudio char(4) primary key,
		fecha DATE,
		nombreEstudio varchar(50),
		autorizado BIT,
		rutaDocumentoResultado varchar(255),
		rutaImagenResultado varchar(255),
		Paciente_idHistoriaClinica char(7)
		FOREIGN KEY (Paciente_idHistoriaClinica) REFERENCES Pacientes.paciente(idHistoriaClinica)
	);
IF OBJECT_ID(N'[Pacientes].[prestador]', N'U') IS NULL 
	CREATE TABLE Pacientes.prestador(
		idPrestador char(6) primary key,
		nombrePrestador varchar(50),
		planPrestador varchar(50),
	);
IF OBJECT_ID(N'[Pacientes].[cobertura]', N'U') IS NULL 
	CREATE TABLE Pacientes.cobertura(
		idCobertura char(6),
		rutaImagenCredencial varchar(255),
		nroSocio char(7) PRIMARY KEY,
		fechaRegistro DATE,
		FOREIGN KEY (nroSocio) REFERENCES Pacientes.paciente(idHistoriaClinica),
		FOREIGN KEY (idCobertura) REFERENCES Pacientes.Prestador(idPrestador)
	);
IF OBJECT_ID(N'[Pacientes].[domicilio]', N'U') IS NULL 
	CREATE TABLE Pacientes.domicilio(
		idDomicilio char(7) primary key,
		calle varchar(50),
		numero char(40),
		piso char(3),
		depto char(3),
		codigoPostal char(4),
		pais varchar(50),
		provincia varchar(50),
		localidad varchar(50),
		id_HistoriaClinica char(7),
		FOREIGN KEY (id_HistoriaClinica) REFERENCES Pacientes.paciente(idHistoriaClinica)
	);




--- fin de tabla esquema pacientes

--Medicos
IF OBJECT_ID(N'[Medicos].[especialidad]', N'U') IS NULL 
    CREATE TABLE Medicos.especialidad(
    idEspecialidad char(6) primary key,
    nombreEspecialidad varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS
)

IF OBJECT_ID(N'[Medicos].[medico]', N'U') IS NULL 
    CREATE TABLE Medicos.medico(
    idMedico char(6) primary key,
    nombreMedico varchar(50),
    apellidoMedico varchar(50),
    nroMatricula char(6),
    idEspecialidad char(6),
    FOREIGN KEY (idEspecialidad) REFERENCES Medicos.especialidad(idEspecialidad)

)
IF OBJECT_ID(N'[Medicos].[sedeDeAtencion]', N'U') IS NULL 
    CREATE TABLE Medicos.sedeDeAtencion(
    idSede char(6) primary key,
    nombreSede char(20),
    direccionSede char(50)
)
IF OBJECT_ID(N'[Medicos].[diasXsede]', N'U') IS NULL 
    CREATE TABLE Medicos.diasXsede(
    idSede char(6),
    idMedico char(6),
    dia DATE,
    horaInicio time,
    idEspecialidad char(6),
    FOREIGN KEY (idMedico) REFERENCES Medicos.medico(idMedico),
    FOREIGN KEY (idEspecialidad) REFERENCES Medicos.especialidad(idEspecialidad),
    FOREIGN KEY (idSede) REFERENCES Medicos.sedeDeAtencion(idSede),
    PRIMARY KEY (idSede, idMedico, dia, horaInicio,idEspecialidad)
)
--- fin de tabla esquema Medicos

--Turnos
IF OBJECT_ID(N'[Turnos].[TipoTurno]', N'U') IS NULL 
CREATE TABLE Turnos.TipoTurno(
    idTipoTurno char(6) primary key,
    nombreTipoTurno char (10) CHECK (nombreTipoTurno IN('Presencial', 'Virtual'))
)
IF OBJECT_ID(N'[Turnos].[EstadoTurno]', N'U') IS NULL 
CREATE TABLE Turnos.EstadoTurno(
    idEstado char(3) primary key,
    nombreEstado char(9) CHECK (nombreEstado in ('Atendido', 'Ausente', 'Cancelado'))
)
IF OBJECT_ID(N'[Turnos].[Reserva]', N'U') IS NULL 
CREATE TABLE Turnos.Reserva(
    idTurno char(24) primary key,
    fecha DATE,
    hora time,
    id_Medico char(6),
	id_Especialidad char(6),
	id_direccion_atencion char(6),
	id_estado_turno char(3),
	id_tipo_turno char(6),
	id_Paciente char(7),
	FOREIGN KEY (id_direccion_atencion, id_Medico,fecha, hora,id_Especialidad) REFERENCES Medicos.DiasXsede(idSede, idMedico, dia, horaInicio,idEspecialidad),
    FOREIGN KEY (id_estado_turno) REFERENCES Turnos.EstadoTurno(idEstado),
	FOREIGN KEY (id_Paciente) REFERENCES Pacientes.Paciente(idHistoriaClinica),
    FOREIGN KEY (id_tipo_turno) REFERENCES Turnos.TipoTurno(idTipoTurno)
);
--- fin de tabla esquema Turnos