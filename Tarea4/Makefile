# Nombres de archivos y herramientas para ARM64
AS = aarch64-linux-gnu-as
LD = aarch64-linux-gnu-ld
QEMU = qemu-aarch64

TARGET = Tarea4_strings
SRC = Tarea4_strings.s
OBJ = Tarea4_strings.o

# Regla principal para compilar y enlazar
all: $(TARGET)

# Paso 1: Ensamblar el archivo .s a objeto .o (con símbolos de depuración -g para GDB)
$(OBJ): $(SRC)
	$(AS) -g $(SRC) -o $(OBJ)

# Paso 2: Enlazar el objeto para generar el ejecutable final
$(TARGET): $(OBJ)
	$(LD) $(OBJ) -o $(TARGET)

# Regla para ejecutar el programa limpiamente
run: $(TARGET)
	$(QEMU) ./$(TARGET)

# Regla para levantar QEMU en modo depuración (esperando conexión GDB en el puerto 1234)
debug: $(TARGET)
	$(QEMU) -g 1234 ./$(TARGET)

# Regla para limpiar archivos binarios y objetos generados
clean:
	rm -f $(OBJ) $(TARGET)

.PHONY: all run debug clean
