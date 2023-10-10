EXEC CargarDatosATablaPaciente
EXEC CargarDatosASchemaMedico
EXEC GenerarValoresAleatoriosReserva
EXEC CargarDatosATablaPaciente
EXEC GenerarValoresAleatoriosPrestador
EXEC GenerarValoresAleatoriosCobertura
EXEC [Pacientes].[AutorizarEstudio] 

SELECT * FROM Turnos.Reserva
SELECT * FROM Pacientes.Prestador
SELECT * FROM Pacientes.cobertura
SELECT * FROM Pacientes.PAciente

GenerarInformeTurnosAtendidos 'OSDE', '2023-01-01', '2023-12-31';