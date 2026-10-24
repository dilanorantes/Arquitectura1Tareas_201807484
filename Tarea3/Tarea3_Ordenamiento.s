.global _start
.data
    // arreglo desordenado de 10 numeros de 64 bits para probar
    arr_datos:      .quad 42, 15, 89, 4, 23, 77, 56, 11, 33, 19
    tamano:         .quad 10

    // mensajes de texto para cumplir con el syscall write de la rúbrica
    msg_inicio:     .ascii "--- ARREGLO ANTES DE ORDENAR ---\n"
    len_inicio      = . - msg_inicio
    msg_fin:        .ascii "--- ARREGLO DESPUES DE ORDENAR ---\n"
    len_fin         = . - msg_fin

.text
_start:
    // imprimo en pantalla el aviso usando syscall write (syscall 64)
    mov x8, #64         // numero de syscall write
    mov x0, #1          // descriptor de salida estandar (stdout)
    ldr x1, =msg_inicio // direccion del texto inicial
    mov x2, #len_inicio // tamaño del texto
    svc #0              // llamada al kernel para imprimir

    // le paso la direccion del arreglo a x0 y el tamano a x1 para burbuja
    ldr x0, =arr_datos
    ldr x1, =tamano
    ldr x1, [x1]
    bl burbuja

    // imprimo en pantalla el aviso de que ya se proceso
    mov x8, #64
    mov x0, #1
    ldr x1, =msg_fin
    mov x2, #len_fin
    svc #0

    // vuelvo a cargar los datos para probar la funcion de seleccion
    ldr x0, =arr_datos
    ldr x1, =tamano
    ldr x1, [x1]
    bl seleccion

    // salida limpia del programa
    mov x8, #93
    mov x0, #0
    svc #0


// funcion ordenamiento por burbuja (bubble sort)
burbuja:
    // guardo el marco de pila y direccion de retorno
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    mov x2, x1          // x2 es el contador de pasadas (i = tamano)

burbuja_ciclo_externo:
    sub x2, x2, #1
    cbz x2, burbuja_fin // si el contador llega a 0 ya termino todo

    mov x3, #0          // x3 es el indice del elemento actual (j = 0)

burbuja_ciclo_interno:
    cmp x3, x2
    b.ge burbuja_ciclo_externo

    // cargo arr[j] en x4 y arr[j+1] en x6 (multiplico x8 bytes con lsl #3)
    ldr x4, [x0, x3, lsl #3]
    add x5, x3, #1
    ldr x6, [x0, x5, lsl #3]

    cmp x4, x6
    b.le burbuja_no_intercambiar // si el izquierdo es menor o igual no los muevo

    // si era mayor los intercambio de posicion en memoria
    str x6, [x0, x3, lsl #3]
    str x4, [x0, x5, lsl #3]

burbuja_no_intercambiar:
    add x3, x3, #1
    b burbuja_ciclo_interno

burbuja_fin:
    // restaura la pila y regresa a donde la llamaron
    ldp x29, x30, [sp], #16
    ret


// funcion ordenamiento por seleccion (selection sort)
seleccion:
    // guardo la pila y resguardo x19 por convencion
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]

    mov x2, #0          // x2 es el indice inicial (i = 0)

seleccion_ciclo_externo:
    sub x3, x1, #1
    cmp x2, x3
    b.ge seleccion_fin

    mov x4, x2          // x4 guarda la posicion del menor encontrado (min = i)
    add x5, x2, #1      // x5 avanza revisando el resto (j = i + 1)

seleccion_ciclo_interno:
    cmp x5, x1
    b.ge seleccion_verificar_intercambio

    // cargo arr[j] en x6 y arr[min] en x7
    ldr x6, [x0, x5, lsl #3]
    ldr x7, [x0, x4, lsl #3]

    cmp x6, x7
    b.ge seleccion_no_es_menor
    mov x4, x5          // si encontre uno mas pequeño actualizo mi posicion del menor

seleccion_no_es_menor:
    add x5, x5, #1
    b seleccion_ciclo_interno

seleccion_verificar_intercambio:
    cmp x4, x2
    b.eq seleccion_siguiente_i // si el menor sigue siendo el mismo no hago nada

    // intercambio el elemento actual con el menor que halle
    ldr x6, [x0, x2, lsl #3]
    ldr x7, [x0, x4, lsl #3]
    str x7, [x0, x2, lsl #3]
    str x6, [x0, x4, lsl #3]

seleccion_siguiente_i:
    add x2, x2, #1
    b seleccion_ciclo_externo

seleccion_fin:
    // restaura registros y regresa
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
