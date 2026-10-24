.global _start
.data
    buffer:             .space 256
    buffer_destino:     .space 256
    
    msg_prompt:         .ascii "Ingrese un texto: "
    len_prompt          = . - msg_prompt

    msg_len:            .ascii "1. Longitud del string: "
    len_msg_len         = . - msg_len

    msg_copy:           .ascii "2. String copiado (destino): "
    len_msg_copy        = . - msg_copy

    msg_comp:           .ascii "3. Comparacion con 'Hola' (0=igual, 1=difiere): "
    len_msg_comp        = . - msg_comp

    msg_rev:            .ascii "4. String invertido (in-place): "
    len_msg_rev         = . - msg_rev

    msg_up:             .ascii "5. String en mayusculas: "
    len_msg_up          = . - msg_up

    str_comparacion:    .ascii "Hola\0"
    newline:            .ascii "\n"
    len_nl              = 1

.text
_start:
    // solicito y leo el texto ingresado por consola
    ldr x0, =msg_prompt
    mov x1, #len_prompt
    bl print_msg

    mov x8, #63         // numero de syscall read
    mov x0, #0          // descriptor de entrada (stdin)
    ldr x1, =buffer     // buffer de destino
    mov x2, #256        // tamaño maximo a leer
    svc #0

    // limpio el salto de linea '\n' remanente de la consola
    ldr x0, =buffer
    mov x1, x0
limpiar_newline:
    ldrb w2, [x1]
    cbz w2, fin_limpiar
    cmp w2, #10
    b.eq reemplazar_nulo_nl
    add x1, x1, #1
    b limpiar_newline
reemplazar_nulo_nl:
    mov w2, #0
    strb w2, [x1]
fin_limpiar:

    // --- PRUEBA 1: str_len ---
    ldr x0, =msg_len
    mov x1, #len_msg_len
    bl print_msg

    ldr x0, =buffer
    bl str_len          // calculo la longitud del string[cite: 17]
    bl print_num        // imprimo el resultado numerico

    ldr x0, =newline
    mov x1, #len_nl
    bl print_msg

    // --- PRUEBA 2: str_copy ---
    ldr x0, =msg_copy
    mov x1, #len_msg_copy
    bl print_msg

    ldr x0, =buffer_destino // x0 = destino[cite: 17]
    ldr x1, =buffer         // x1 = origen[cite: 17]
    bl str_copy             // copio la cadena

    ldr x0, =buffer_destino
    bl imprimir_string_z    // imprimo el string copiado

    ldr x0, =newline
    mov x1, #len_nl
    bl print_msg

    // --- PRUEBA 3: str_compare ---
    ldr x0, =msg_comp
    mov x1, #len_msg_comp
    bl print_msg

    ldr x0, =buffer         // cadena 1[cite: 17]
    ldr x1, =str_comparacion // cadena 2 ("Hola")[cite: 17]
    bl str_compare          // comparo cadenas (0=igual, 1=difiere)[cite: 17, 19]
    bl print_num

    ldr x0, =newline
    mov x1, #len_nl
    bl print_msg

    // --- PRUEBA 4: str_reverse ---
    ldr x0, =msg_rev
    mov x1, #len_msg_rev
    bl print_msg

    ldr x0, =buffer
    bl str_reverse          // invierto in-place usando el stack[cite: 17]

    ldr x0, =buffer
    bl imprimir_string_z

    ldr x0, =newline
    mov x1, #len_nl
    bl print_msg

    // --- PRUEBA 5: str_to_upper ---
    ldr x0, =msg_up
    mov x1, #len_msg_up
    bl print_msg

    ldr x0, =buffer
    bl str_to_upper         // convierto a mayusculas con logica ARM[cite: 17]

    ldr x0, =buffer
    bl imprimir_string_z

    ldr x0, =newline
    mov x1, #len_nl
    bl print_msg

    // salida limpia del programa usando syscall exit (93)
    mov x8, #93
    mov x0, #0
    svc #0


// =============================================================
// FUNCION AUXILIAR: print_msg
// Imprime un mensaje en pantalla usando syscall write.
// Entrada: x0 = direccion del mensaje, x1 = tamaño
// =============================================================
print_msg:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x2, x1          // tamaño del texto
    mov x1, x0          // direccion del texto
    mov x0, #1          // descriptor stdout (1)
    mov x8, #64         // numero de syscall write
    svc #0
    ldp x29, x30, [sp], #16
    ret


// =============================================================
// FUNCION 1: str_len
// Calcula la longitud de una cadena terminada en NULL.
// Entrada: x0 = direccion base del string[cite: 17]
// Salida:  x0 = longitud del string[cite: 17]
// =============================================================
str_len:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    mov x1, x0
    mov x0, #0

str_len_loop:
    ldrb w2, [x1], #1
    cbz w2, str_len_fin
    add x0, x0, #1
    b str_len_loop

str_len_fin:
    ldp x29, x30, [sp], #16
    ret


// =============================================================
// FUNCION 2: str_copy
// Copia una cadena de origen a destino.
// Entrada: x0 = destino, x1 = origen[cite: 17]
// =============================================================
str_copy:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    mov x2, x0

str_copy_loop:
    ldrb w3, [x1], #1
    strb w3, [x2], #1
    cbz w3, str_copy_fin
    b str_copy_loop

str_copy_fin:
    ldp x29, x30, [sp], #16
    ret


// =============================================================
// FUNCION 3: str_compare
// Compara dos cadenas carácter a carácter.
// Entrada: x0 = cadena 1, x1 = cadena 2[cite: 17]
// Salida:  x0 = 0 si son iguales, 1 si difieren[cite: 17, 19]
// =============================================================
str_compare:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

str_compare_loop:
    ldrb w2, [x0], #1
    ldrb w3, [x1], #1

    cmp w2, w3
    b.ne str_compare_difieren

    cbz w2, str_compare_iguales
    b str_compare_loop

str_compare_iguales:
    mov x0, #0
    b str_compare_fin

str_compare_difieren:
    mov x0, #1

str_compare_fin:
    ldp x29, x30, [sp], #16
    ret


// =============================================================
// FUNCION 4: str_reverse
// Invierte una cadena in-place usando el stack como almacenamiento.
// Entrada: x0 = dirección base del string[cite: 17]
// =============================================================
str_reverse:
    // Guardar marco de pila y registros callee-saved (x19, x20, x21)
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    str x19, [sp, #16]
    str x20, [sp, #24]
    str x21, [sp, #32]

    mov x19, x0         // x19 guarda la dirección base original

    bl str_len          // obtener la longitud N de la cadena
    mov x20, x0         // x20 = longitud N
    cbz x20, str_reverse_fin // si la cadena está vacía, terminar

    // Calcular bytes necesarios: N + 1 (para '\0') y alinear estrictamente a 16 bytes
    mov x1, x20         
    add x1, x1, #1      
    add x1, x1, #15     
    bic x1, x1, #15     
    mov x21, x1         // x21 guarda el total de bytes reservados en la pila

    sub sp, sp, x21     // reservar espacio temporal en el stack

    // Copiar el string original al buffer temporal en la pila
    mov x2, sp          
    mov x3, x19         
str_rev_copy_loop:
    ldrb w4, [x3], #1   
    strb w4, [x2], #1   
    cbz w4, str_rev_copy_done
    b str_rev_copy_loop
str_rev_copy_done:

    // Escribir de vuelta al string original en orden inverso
    mov x2, sp          
    add x2, x2, x20     
    sub x2, x2, #1      // apuntar al último carácter válido (antes de '\0')
    mov x3, x19         
    mov x5, x20         // contador N

str_rev_write_loop:
    ldrb w4, [x2], #-1  
    strb w4, [x3], #1   
    subs x5, x5, #1     
    b.gt str_rev_write_loop

    // Restaurar el puntero de pila original liberando el espacio reservado
    add sp, sp, x21

str_reverse_fin:
    // Restaurar registros callee-saved y marco de pila
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    ldr x21, [sp, #32]
    ldp x29, x30, [sp], #48
    ret

// =============================================================
// FUNCION 5: str_to_upper
// Convierte caracteres a mayúsculas usando operaciones lógicas ARM.
// Entrada: x0 = dirección base del string
// =============================================================
str_to_upper:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    mov x1, x0

str_to_upper_loop:
    ldrb w2, [x1]
    cbz w2, str_to_upper_fin

    cmp w2, #'a'
    b.lt str_to_upper_siguiente
    cmp w2, #'z'
    b.gt str_to_upper_siguiente

    bic w2, w2, #0x20   // limpia el bit 5 usando bic (convierte a mayuscula)
    strb w2, [x1]

str_to_upper_siguiente:
    add x1, x1, #1
    b str_to_upper_loop

str_to_upper_fin:
    ldp x29, x30, [sp], #16
    ret


// =============================================================
// FUNCION AUXILIAR: imprimir_string_z
// Imprime un string terminado en nulo usando syscall write.
// =============================================================
imprimir_string_z:
    stp x29, x30, [sp, #-32]!
    mov x29, sp

    mov x1, x0
    mov x3, x1
    mov x2, #0
imp_str_len_loop:
    ldrb w4, [x3], #1
    cbz w4, imp_str_done
    add x2, x2, #1
    b imp_str_len_loop
imp_str_done:

    mov x8, #64
    mov x0, #1
    svc #0

    ldp x29, x30, [sp], #32
    ret


// =============================================================
// FUNCION AUXILIAR: print_num
// Imprime un entero de 64 bits convirtiéndolo a ASCII decimal.
// =============================================================
print_num:
    stp x29, x30, [sp, #-32]!
    mov x29, sp

    mov x1, x0
    mov x2, sp
    add x2, x2, #16
    mov w3, #0
    strb w3, [x2]

    cmp x1, #0
    b.ne print_num_loop
    sub x2, x2, #1
    mov w3, #'0'
    strb w3, [x2]
    b print_num_print

print_num_loop:
    cbz x1, print_num_print
    mov x4, #10
    udiv x5, x1, x4
    msub x6, x5, x4, x1
    add w6, w6, #'0'
    sub x2, x2, #1
    strb w6, [x2]
    mov x1, x5
    b print_num_loop

print_num_print:
    mov x1, x2
    mov x3, x1
    mov x4, #0
print_num_len_calc:
    ldrb w5, [x3], #1
    cbz w5, print_num_len_end
    add x4, x4, #1
    b print_num_len_calc
print_num_len_end:
    mov x8, #64
    mov x0, #1
    mov x2, x4
    svc #0

    ldp x29, x30, [sp], #32
    ret

