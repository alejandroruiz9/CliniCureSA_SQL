
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
GO
--Procedures para insertar, eliminar o actualizar registros de tablas

--Schema Turnos
---SP para tabla TipoTurno
CREATE OR ALTER PROCEDURE InsertarTipoTurno 
@idTipoTurno char(6), 
@nombreTipoTurno char(10)
AS
IF NOT EXISTS (SELECT * FROM Turnos.TipoTurno WHERE idTipoTurno = @idTipoTurno)
    INSERT INTO Turnos.TipoTurno(idTipoTurno, nombreTipoTurno) VALUES (@idTipoTurno, @nombreTipoTurno)
ELSE
    THROW 50000, 'El tipo de turno ya existe', 1;
GO
CREATE OR ALTER PROCEDURE ModificarTipoTurno 
@idTipoTurno char(6), 
@nombreTipoTurno char(10)
AS
IF EXISTS (SELECT * FROM Turnos.TipoTurno WHERE idTipoTurno = @idTipoTurno)
    UPDATE Turnos.TipoTurno SET nombreTipoTurno = @nombreTipoTurno WHERE idTipoTurno = @idTipoTurno
ELSE
    THROW 50000, 'El tipo de turno no existe', 1;
GO
CREATE OR ALTER PROCEDURE EliminarTipoTurno 
@idTipoTurno char(6)
AS
IF EXISTS (SELECT * FROM Turnos.TipoTurno WHERE idTipoTurno = @idTipoTurno)
    DELETE FROM Turnos.TipoTurno WHERE idTipoTurno = @idTipoTurno
ELSE
    THROW 50000, 'El tipo de turno no existe', 1;
GO
---SP para tabla TipoTurno
CREATE OR ALTER PROCEDURE InsertarEstadoTurno 
@idEstado char(3), 
@nombreEstado char(9)
AS
IF NOT EXISTS (SELECT * FROM Turnos.EstadoTurno WHERE idEstado = @idEstado)
    INSERT INTO Turnos.EstadoTurno(idEstado, nombreEstado) VALUES (@idEstado, @nombreEstado)
ELSE
    THROW 50000, 'La reserva ya existe', 1;
GO
CREATE OR ALTER PROCEDURE ModificarEstadoTurno 
@idEstado char(3), 
@nombreEstado char(9)
AS
IF EXISTS (SELECT * FROM Turnos.EstadoTurno WHERE idEstado = @idEstado)
    UPDATE Turnos.EstadoTurno SET nombreEstado = @nombreEstado WHERE idEstado = @idEstado
ELSE
    THROW 50000, 'La estado no existe', 1;
GO
CREATE OR ALTER PROCEDURE EliminarEstadoTurno 
@idEstado char(3)
AS
IF EXISTS (SELECT * FROM Turnos.EstadoTurno WHERE idEstado = @idEstado)
    DELETE FROM Turnos.EstadoTurno WHERE idEstado = @idEstado
ELSE
    THROW 50000, 'La estado no existe', 1;
GO
---SP para tabla Reserva
CREATE OR ALTER PROCEDURE InsertarReserva 
@idTurno char(24), @fecha DATE, @hora time, 
@id_Medico char(6),@id_Especialidad char(6),
@id_direccion_atencion char(6),@id_estado_turno char(3),
@id_tipo_turno char(6),@id_Paciente char(7)
AS
IF NOT EXISTS (SELECT * FROM Turnos.Reserva WHERE idTurno = @idTurno)
    INSERT INTO Turnos.Reserva(idTurno, fecha, hora, id_Medico,id_Especialidad,id_direccion_atencion,id_estado_turno,id_tipo_turno,id_Paciente) VALUES (@idTurno, @fecha, @hora, @id_Medico,@id_Especialidad,@id_direccion_atencion,@id_estado_turno,@id_tipo_turno,@id_Paciente)
ELSE
    THROW 50000, 'La Reserva ya existe', 1;
GO
CREATE OR ALTER PROCEDURE ModificarReserva 
@idTurno int, @fecha DATE, @hora time, @id_Medico char(6),
@id_Especialidad char(6),@id_direccion_atencion char(6),
@id_estado_turno char(3),@id_tipo_turno char(6),@id_Paciente char(7)
AS
IF EXISTS (SELECT * FROM Turnos.Reserva WHERE idTurno =  @idTurno)
    UPDATE Turnos.Reserva SET fecha = @fecha, hora = @hora, id_Medico =  @id_Medico,id_Especialidad =  @id_Especialidad,id_direccion_atencion =  @id_direccion_atencion,id_estado_turno =  @id_estado_turno,id_tipo_turno =  @id_tipo_turno,id_Paciente =  @id_Paciente WHERE idTurno =  @idTurno
ELSE
    THROW 50000, 'La reserva no existe', 1;
GO
CREATE OR ALTER PROCEDURE EliminarReserva  
@idTurno int
AS
IF EXISTS (SELECT * FROM Turnos.Reserva WHERE idTurno =  @idTurno)
    DELETE FROM Turnos.Reserva WHERE idTurno =  @idTurno
ELSE
    THROW 50000, 'La Reserva ya existe', 1;
GO
--Schema Medicos
---SP para tabla Medico
CREATE or alter PROCEDURE EliminarMedico
    @NroMatricula CHAR(6)
	
AS
BEGIN
DECLARE     @NombreMedico VARCHAR(50)
DECLARE     @ApellidoMedico VARCHAR(50)
    -- Verificar si el número de matrícula ya existe
    IF EXISTS (SELECT 1 FROM Medicos.medico WHERE nroMatricula = @NroMatricula)       
	BEGIN
		SET @NombreMedico = (SELECT nombreMedico FROM Medicos.medico WHERE nroMatricula = @NroMatricula)
		SET @ApellidoMedico = (SELECT apellidoMedico FROM Medicos.medico WHERE nroMatricula = @NroMatricula)

       DELETE FROM Medicos.medico WHERE nroMatricula = @NroMatricula  
	   PRINT 'El/La medico/a '+@ApellidoMedico+','+@NombreMedico+' MN:'+@NroMatricula+' ha sido eliminado'
    END
	ELSE
	-- Si el número de matrícula NO existe, mostrar un mensaje de error
     THROW 50000, 'El o la medica NO existe en la base de datos', 1;
	
END;
GO
---SP para tabla Especialidad
CREATE or alter PROCEDURE CrearEspecialidad
    @Especialidad varchar(30)	
AS
BEGIN

declare	@idEspecialidad CHAR(6)
IF NOT EXISTS (SELECT 1 FROM Medicos.especialidad WHERE nombreEspecialidad = @Especialidad)
		BEGIN 
			
			SET @idEspecialidad = CAST((select MAX(cast(idEspecialidad  AS INT)) from Medicos.especialidad) AS INT)+1
			SET @idEspecialidad = RIGHT('000000' + CAST(@idEspecialidad AS CHAR(6)),6);

			INSERT INTO Medicos.especialidad(idEspecialidad,nombreEspecialidad)
			values (@idEspecialidad,@Especialidad)

			PRINT 'Nueva especialidad '+@Especialidad+' creada';
end
else 
	THROW 50000, 'La especialidad ya existe', 1;
end
GO
CREATE or alter PROCEDURE EliminarEspecialidad
    @Especialidad varchar(30)	
AS
BEGIN

declare	@idEspecialidad CHAR(6)
IF EXISTS (SELECT 1 FROM Medicos.especialidad WHERE nombreEspecialidad = @Especialidad)
		BEGIN 
			
			delete from Medicos.especialidad WHERE nombreEspecialidad = @Especialidad

			PRINT 'Especialidad '+@Especialidad+' eliminada';
end
else 
	THROW 50000, 'La especialidad no existe', 1;
end

EXEC EliminarEspecialidad @Especialidad='INGENIERO'
GO
CREATE or alter PROCEDURE CrearSede
    @Sede varchar(30),
    @direccionSede char(50)
AS
BEGIN

declare	@idSede CHAR(6)
IF NOT EXISTS (SELECT 1 FROM Medicos.sedeDeAtencion WHERE nombreSede = @Sede)
		BEGIN 
			
			SET @idSede = CAST((select MAX(cast(idSede  AS INT)) from Medicos.sedeDeAtencion) AS INT)+1
			SET @idSede = RIGHT('000000' + CAST(@idSede AS CHAR(6)),6);

			INSERT INTO Medicos.sedeDeAtencion(idSede,nombreSede,direccionSede)
			values (@idSede,@Sede,@direccionSede)

			PRINT 'Nueva sede '+@Sede+' con direccion '+@direccionSede+' creada';
end
else 
	THROW 50000, 'La sede ya existe', 1;
end
GO
---SP para tabla sedeDeAtencion
CREATE or alter PROCEDURE ActualizarDireccionSede
    @Sede varchar(30),
    @nuevaDireccionSede char(50)
AS
BEGIN

IF EXISTS (SELECT 1 FROM Medicos.sedeDeAtencion WHERE nombreSede = @Sede)
		BEGIN 
			
			update Medicos.sedeDeAtencion SET direccionSede = @nuevaDireccionSede WHERE nombreSede = @Sede
			PRINT 'Sede '+@Sede+' con direccion '+@nuevaDireccionSede+' actualizada';
		end

else 
	THROW 50000, 'La sede no existe', 1;
end
GO
CREATE or alter PROCEDURE EliminarSede
    @Sede varchar(30)	
AS
BEGIN

declare	@idEspecialidad CHAR(6)
IF EXISTS (SELECT 1 FROM Medicos.sedeDeAtencion WHERE nombreSede = @Sede)
		BEGIN 
			
			delete from Medicos.sedeDeAtencion WHERE nombreSede = @Sede

			PRINT 'Sede '+@Sede+' eliminada';
end
else 
	THROW 50000, 'La sede no existe', 1;
end



















