;-------------------------------------------------
; snake.asm
;-------------------------------------------------
; - Juego del snake en modo comando
;-------------------------------------------------
; 2023-junio
;-------------------------------------------------

dosseg
.model small

;-------------------------------------------------
; @pausa: invoca servicio 08h-INT21h
; parámetros: ---
; registros: ah
;-------------------------------------------------
@pausa MACRO
	   push ax
	   mov ah, 08h
	   int 21h
	   pop ax
	   ENDM
;-------------------------------------------------
; @emitir_mensaje: invoca servicio 09h-INT21h
; parámetros: 
; cadena -> etiqueta de cadena finalizada en '$'
; registros: ah y dx
;-------------------------------------------------
@emitir_mensaje MACRO cadena
	   lea dx, cadena
	   mov ah, 09h
	   int 21h
	   ENDM
;-------------------------------------------------
; @ubicar_cursor: invoca servicio 02h-INT10h
; parámetros: ---
; registros: ah
;-------------------------------------------------
@ubicar_cursor MACRO
	   mov ah, 02h
       int 10h
	   ENDM
;-------------------------------------------------
; @cursor_fuera: cursor fuera con 02h-INT10h
; parámetros: ---
; registros: ah
;-------------------------------------------------
@cursor_fuera MACRO
       mov dx, 25*256+80
	   mov bh, 0
	   mov ah, 02h
       int 10h
	   ENDM
;-------------------------------------------------
; @print_char: invoca servicio 09h-INT10h
; parámetros: ---
; registros: ah
;-------------------------------------------------
@print_char MACRO
	   mov ah, 09h
       int 10h
	   ENDM
;-------------------------------------------------
; @clear_scr: invoca servicio 00h-INT10h
; parámetros: ---
; registros: ah y al
;-------------------------------------------------
@clear_scr MACRO
	   mov al, 03h
	   mov ah, 00h
	   int 10h
	   ENDM

.stack 100h
.data
	;títulos, mensajes y diálogos
    cadena_titulo db " SNAKE $"
    cadena_estado db " Pulse F para salir $"
    cadena_inicio db " Pulse E para empezar a jugar $"
    cadena_nueva db " Pulse E para jugar de nuevo $"
    cadena_juega db " W(Arr)-S(Aba)-A(Izq)-D(Der) $"
    cadena_score db " Score: $"

    ;interfase gráfica
    ;tablero de juego
    anchotablero EQU 32
    altotablero EQU 16
    xtablero EQU 23
    ytablero EQU 2
    xytablero EQU ytablero*256+xtablero
    ;atributo del tablero
    ;|---fondo---|--carácter--|
    ;parpadeo-RGB-intensidad 
    atributotablero EQU 02h
    ;línea de diálogo
    atributodialogo EQU 62h
    atributomanzana EQU 0Bh
    ydialogo EQU 22
    xcompleto EQU 1

    ;datos del juego
    ;coordenadas 5-25 corresponden con coordenadas 0-0 para snake
    xy0 EQU (ytablero+1)*256+(xtablero+1)
    ;representación de la serpiente (? es nodo vacío)
    snake dw 513 dup (?)    ;reservamos uno mas para cuando tenga longitud 512
    longitud dw 3
    anterior db 'S'
    ;puntuación y su representación
    score dw 0  
    ascii_score DB 30h, 30h, 30h, '$'

    ;manzana y número aleatorio
    manzana dw ?
    mult dw 149
    suma dw 1

.code
;PROCEDIMINETOS
;-------------------------------------------------
; Nombre: coord_en_snake
; Descripción: comprueba si algún nodo del 
;              snake está en las coordenadas
;-------------------------------------------------
; Argumentos:
; 1.- Val. (word) = columna [bp+4] 0 en [bp+5]
; 2.- Val. (word) = tipo [bp+6]
;-------------------------------------------------
; Variables locales: ---
;-------------------------------------------------
; Retorno: ax - 0000h (no coincide) o FFFFh (coincide)
;-------------------------------------------------
coord_en_snake proc
    push bp             ;salvo marco de pila
    mov bp, sp          ;nuevo marco de pila

    ;salvo los registros que voy a usar
    push bx
    push cx
    push dx
	push si

    xor ax, ax          ;si no se modifica se devolverá cero por defecto

    mov dx, [bp+4]      ;coordenadas relativas a comprobar
	mov cx, longitud
	mov si, cx          
	sub cx, [bp+6]	    ;si tipo vale 1, no comprobaremos el último nodo
	dec si
	shl si, 1           ;tomamos el índice para el primer nodo ("cabeza")
	no_choca:
	mov bx, snake[si]
	sub bx, dx
	jz choca            ;si son iguales chocan
	sub si, 2
	loop no_choca
	jmp comprobado      ;si terminamos de recorrer snake y no detectamos iguales, no hay choque
	choca:
	not ax              ;si choca ax=0FFFFh
	comprobado:

    ;recupero los registros usados
	pop si
    pop dx
    pop cx
    pop bx

    mov sp, bp          ;soslayo locales
    pop bp              ;recupero marco de pila
    ret 4
coord_en_snake endp

;-------------------------------------------------
; Nombre: actualizar_score
; Descripción: actualiza el valor de score y
;              ascii_score
;-------------------------------------------------
; Argumentos: ---
;-------------------------------------------------
; Variables locales: ---
;-------------------------------------------------
; Retorno: ---
;-------------------------------------------------
actualizar_score proc
    push bp             ;salvo marco de pila
    mov bp, sp          ;nuevo marco de pila

    ;salvo los registros que voy a usar
    push ax
	push si

    ;actualizamos score
    inc al

    ;actualizamos ascii_score
    mov si, 2
    mov al, ascii_score[2]
    inc al              ;aumentamos las unidades
    cmp al, 3Ah         ;si hay 10 unidades, debemos de añadir una decena
    jne actualizado
    ;no_actualizado:
    dec si
    mov al, 30h         ;quitamos las 10 unidades
    mov ascii_score[2], al
    mov al, ascii_score[1]
    inc al              ;aumentamos las decenas
    cmp al, 3Ah         ;si hay 10 decenas, debemos de añadir una centena
    jne actualizado
    dec si
    mov al, 30h         ;quitamos las 10 decenas
    mov ascii_score[1], al
    mov al, ascii_score[0]
    inc al              ;aumentamos las centenas

    actualizado:
    mov ascii_score[si], al

    ;recupero los registros usados
	pop si
    pop ax

    mov sp, bp          ;soslayo locales
    pop bp              ;recupero marco de pila
    ret 4
actualizar_score endp

;-------------------------------------------------
; Nombre: nueva_coordenada
; Descripción: Devuelve nueva coordenada "cabeza"
;-------------------------------------------------
; Argumentos:
; 1.- Val. (word) = tecla nueva [bp+4]
;-------------------------------------------------
; Variables locales: ---
;-------------------------------------------------
; Retorno: dx - nueva coordenada "cabeza"
;-------------------------------------------------
nueva_coordenada proc
    push bp             ;salvo marco de pila
    mov bp, sp          ;nuevo marco de pila

    ;salvo los registros que voy a usar
    push ax
	push si
    
    mov ax, [bp+4]      ;nueva tecla

    mov si, longitud
	dec si
	shl si, 1           ;tomamos índice de la "cabeza" (que pronto será la anterior)

    ;actualizamos las coordenadas segun la anterior y nueva tecla pulsada
	mov dx, snake[si]
	miroW:
	cmp al, 'W'         ;si nuevo no es W, compruebo si es S
	jne miroS
    cmp anterior, 'S'   ;si es W y anterior no es S, no son opuestos y al es válido
    je noW
    siW:                ;nuevo y anterior no son opuestos
    dec dh
    jmp no_opuesto
    noW:                ;nuevo y anterior son opuestos
    mov al, anterior    ;nuevo será el anterior
    jmp siS             ;como nuevo y anterior son iguales, S es válido

	miroS:
	cmp al, 'S'         ;si nuevo no es S, compruebo si es A
	jne miroA
    cmp anterior, 'W'   ;si es S y anterior no es W, no son opuestos y al es válido
    je noS
    siS:                ;nuevo y anterior no son opuestos
    inc dh              
    jmp no_opuesto
    noS:                ;nuevo y anterior son opuestos
    mov al, anterior    ;nuevo será el anterior
    jmp siW             ;como nuevo y anterior son iguales, W es válido
    
	miroA:
	cmp al, 'A'         ;si nuevo no es A, compruebo si es D
	jne miroD
    cmp anterior, 'D'   ;si es A y anterior no es D, no son opuestos y al es válido
    je noA
    siA:                ;nuevo y anterior no son opuestos
    dec dl
    jmp no_opuesto
    noA:                ;nuevo y anterior son opuestos
    mov al, anterior    ;nuevo será el anterior
    jmp siD             ;como nuevo y anterior son iguales, D es válido
    
	miroD:
    cmp anterior, 'A'   ;si es D y anterior no es A, no son opuestos y al es válido
    je noD
    siD:                ;nuevo y anterior no son opuestos
    inc dl
    jmp no_opuesto
    noD:                ;nuevo y anterior son opuestos
    mov al, anterior    ;nuevo será el anterior
    jmp siA             ;como nuevo y anterior son iguales, A es válido

    no_opuesto:
    mov anterior, al    ;actualizamos anterior    

    ;recupero los registros usados
	pop si
    pop ax

    mov sp, bp          ;soslayo locales
    pop bp              ;recupero marco de pila
    ret 2
nueva_coordenada endp

;-------------------------------------------------
; Nombre: nueva_manzana
; Descripción: Nueva coordenada "aleatoria" para manzana
;-------------------------------------------------
; Argumentos: ---
;-------------------------------------------------
; Variables locales: ---
;-------------------------------------------------
; Retorno: ---
;-------------------------------------------------
nueva_manzana proc
    push bp             ;salvo marco de pila
    mov bp, sp          ;nuevo marco de pila

    ;salvo los registros que voy a usar
    push ax
    push dx

    ;generamos coordenadas "aleatorias"
	mov ax, manzana
	mov dx, mult
	mul dx
	add ax, suma
	and ah, 0Fh
	and al, 1Fh

    mov dx, ax
    hasta_correcta:
    xor ax, ax
    push ax             ;tipo (0 porque comprobamos todo snake)
    push dx             ;coordendas relativas
    call coord_en_snake
    cmp ax, 0           
    je buena            ;si 0, no choca
    ;no_buena:
    ;vamos aumentamos los valores de las coordenadas
    ;hasta que no choque con la serpiente
    inc dl
    cmp dl, 32
    jne hasta_correcta
    xor dl, dl
    inc dh
    cmp dh, 16
    jne hasta_correcta
    xor dh, dh
    jmp hasta_correcta

    buena:
    mov manzana, dx     ;actualizamos manzana

    ;recupero los registros usados
    pop dx
    pop ax

    mov sp, bp          ;soslayo locales
    pop bp              ;recupero marco de pila
    ret 0
nueva_manzana endp

;-------------------------------------------------
; Nombre: desplaz_unit_snake
; Descripción: desplaza el snake (contando con el 
;              nodo nuevo) a la izq un bit
;-------------------------------------------------
; Argumentos: ---
;-------------------------------------------------
; Variables locales: ---
;-------------------------------------------------
; Retorno: ---
;-------------------------------------------------
desplaz_unit_snake proc
    push bp             ;salvo marco de pila
    mov bp, sp          ;nuevo marco de pila

    ;salvo los registros que voy a usar
    push ax
    push cx
    push dx
	push si

	mov si, longitud
	shl si, 1			;índice para abarcar el siguiente nodo al de la "cabeza"

	xor ah, ah
	sahf				;guardamos en ah los flags a cero

	mov cx, longitud
	inc cx
	palabra:
	mov dx, snake[si]
	sahf				;copiamos en el registro de flags los bits de ah
	rcl dx, 1			;rotamos tomando la cf
	lahf				;guardamos en ah el registro de flags
	mov snake[si], dx	

	sub si, 2			;desplazaremos la palabra anterior
	loop palabra

    ;recupero los registros usados
	pop si
    pop dx
    pop cx
    pop ax

    mov sp, bp          ;soslayo locales
    pop bp              ;recupero marco de pila
    ret 0
desplaz_unit_snake endp

;-------------------------------------------------
; Nombre: limpiar_dialogo
; Descripción: limpia los diálogos desde la
;              columna pasada com oargumento
;              y deja el cursor en ella
;-------------------------------------------------
; Argumentos:
; 1.- Val. (word) = columna [bp+4] 0 en [bp+5]
;-------------------------------------------------
; Variables locales: ---
;-------------------------------------------------
; Retorno: ---
;-------------------------------------------------
limpiar_dialogo proc
    push bp             ;salvo marco de pila
    mov bp, sp          ;nuevo marco de pila

    ;salvo los registros que voy a usar
    push ax
    push bx
    push cx
    push dx

    ;ubico el cursor en las coordenadas de inicio
    mov dx, ydialogo*256+0
    add dl, [bp+4]      ;argumento
    mov bh, 0           ;pagina de video
    @ubicar_cursor
    ;borro el diálogo a partir de la columna_argumento
    mov bl, atributodialogo
    mov al, 32          ;caracter ' '
    mov cx, 79
    sub cl, dl
    @print_char
    add dl, 1
    @ubicar_cursor
    ;recupero los registros usados
    pop dx
    pop cx
    pop bx
    pop ax

    mov sp, bp          ;soslayo locales
    pop bp              ;recupero marco de pila
    ret 2
limpiar_dialogo endp

;-------------------------------------------------
; Nombre: repetir_ascii_en_horizontal
; Descripción: repite un ascii en línea horizontal
;-------------------------------------------------
; Argumentos:
; 1.- Val. (word) = coordenadas inicio [bp+4] x, [p+5] y
; 2.- Val. (word) = longitud [bp+6]
; 3.- Val. (word) = caracter [bp+8], atributo [bp+9]
;-------------------------------------------------
; Variables locales: ---
;-------------------------------------------------
; Retorno: ---
;-------------------------------------------------
repetir_ascii_en_horizontal proc
    push bp             ;salvo marco de pila
    mov bp, sp          ;nuevo marco de pila

    ;salvo los registros que voy a usar
    push ax
    push bx
    push cx
    push dx

    ;ubico el cursor en las coordenadas de inicio
    mov dx, [bp+4]      ;dh fila, dl columna
    mov bh, 0           ;pagina de video
    @ubicar_cursor
    mov bl, [bp+9]      ;atributo video
    mov al, [bp+8]      ;cáracter
    mov cx, [bp+6]      ;repetición horizontal
    @print_char

    ;recupero los registros usados
    pop dx
    pop cx
    pop bx
    pop ax

    mov sp, bp          ;soslayo locales
    pop bp              ;recupero marco de pila
    ret 6
repetir_ascii_en_horizontal endp

;-------------------------------------------------
; Nombre: repetir_ascii_en_vertical
; Descripción: repite un ascii en línea vertical
;-------------------------------------------------
; Argumentos:
; 1.- Val. (word) = coordenadas inicio [bp+4] x, [bp+5] y
; 2.- Val. (word) = longitud [bp+6]
; 3.- Val. (word) = caracter [bp+8], atributo [bp+9]
;-------------------------------------------------
; Variables locales: ---
;-------------------------------------------------
; Retorno: ---
;-------------------------------------------------
repetir_ascii_en_vertical proc
    push bp             ;salvo marco de pila
    mov bp, sp          ;nuevo marco de pila

    ;salvo los registros que voy a usar
    push ax
    push bx
    push cx
    push dx

    ;ubico el cursor en las coordenadas de inicio
    mov dx, [bp+4]      ;dh fila, dl columna
    mov bh, 0           ;pagina de video
    @ubicar_cursor
    mov bl, [bp+9]      ;atributo video
    mov al, [bp+8]      ;cáracter
    mov cx, 1
    mov si, [bp+6]      ;repetición horizontal
    bucle:
    @print_char
    inc dh
    @ubicar_cursor
    dec si
    jnz bucle

    ;recupero los registros usados
    pop dx
    pop cx
    pop bx
    pop ax

    mov sp, bp          ;soslayo locales
    pop bp              ;recupero marco de pila
    ret 6
repetir_ascii_en_vertical endp

;-------------------------------------------------
; Nombre: dibujar_reticula
; Descripción: dibuja una reticula en modo texto
;-------------------------------------------------
; Argumentos:
; 1.- Val. (word) = coordenadas inicio [bp+4] x, [bp+5] y
; 2.- Val. (word) = num. filas y col [bp+6] fil, [bp+7] col
; 3.- Val. (word) = ancho y alto [bp+8] anch, [bp+9] alt
; 4.- Val. (word) = atributo y borde [bp+10] atrib, [bp+11] borde
;-------------------------------------------------
; Variables locales: 
; 1.- Val. (word) = anchura [bp-1]
; 2.- Val. (word) = altura [bp-3]
;-------------------------------------------------
; Retorno: ---
;-------------------------------------------------
x0 EQU <[BP+4]>         ;coordenada x esquibna sup izq
y0 EQU <[BP+5]>         ;coordenada y esquibna sup izq
fil EQU <[BP+6]>        ;número de filas
col EQU <[BP+7]>        ;número de columnas
anch EQU <[BP+8]>       ;ancho de la celda
alto EQU <[BP+9]>       ;alto de la celda
atr EQU <[BP+10]>       ;atributo video
bor EQU <[BP+11]>       ;tipo de borde
anchura EQU <[BP-1]>    ;anchura total de la retícula
altura EQU <[BP-3]>     ;altura total de la retícula

dibujar_reticula proc
    push bp             ;salvo marco de pila
    mov bp, sp          ;nuevo marco de pila

    sub sp, 2           ;reserva para 2 locales de tamaño byte

    ;salvo los registros que voy a usar
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ;calculo la anchura total de la retícula
    xor ax, ax
    mov al, col
    xor bx, bx
    mov bl, anch
    inc bl
    mul bl
    inc ax
    mov anchura, ax

    ;calculo la altura total de la retícula
    xor ax, ax
    mov al, fil
    xor bx, bx
    mov bl, alto
    inc bl
    mul bl
    inc ax
    mov altura, ax

    ;doy valor a bx una vez y lo uso siempre
    mov bh, 0           ;página de video
    mov bl, atr         ;atributo de video

    ;dibujar líneas horizontales
    ;número de líneas a dibujar
    xor cx, cx
    mov cl, fil
    inc cl
    ;cargo coordenadas iniciales
    mov dl, x0
    mov dh, y0
    ;determino argumento borde-atributo
    mov ah, bl          ;atributo
    mov al, 196         ;carácter '─'
    cmp byte ptr bor, 1
    je dibujar_horizontales
    mov al, 205         ;carácter '═'
    dibujar_horizontales:
    push ax             ;atributo-cáracter
    push anchura
    push dx             ;coordenadas
    call repetir_ascii_en_horizontal
    add dh, alto
    inc dh
    loop dibujar_horizontales

    ;dibujar líneas verticales
    ;número de líneas a dibujar
    xor cx, cx
    mov cl, col
    inc cl
    ;cargo coordenadas iniciales
    mov dl, x0
    mov dh, y0
    ;determino argumento borde-atributo
    mov ah, bl          ;atributo
    mov al, 179         ;carácter '│'
    cmp byte ptr bor, 1
    je dibujar_verticales
    mov al, 186         ;carácter '║'
    dibujar_verticales:
    push ax             ;atributo-cáracter
    push altura
    push dx             ;coordenadas
    call repetir_ascii_en_vertical
    add dl, anch
    inc dl
    loop dibujar_verticales

    ;número de intersecciones horizontales a dibujar
    xor cx, cx
    mov cl, col
    dec cl
    mov si, cx
    push si             ;lo volveré a usar con las inferiores
    cmp si, 0
    jz calcular_num_inter_verticales

    ;dibujar intersecciones superiores
    ;cargo coordenadas iniciales
    mov dl, x0
    mov dh, y0
    mov cx, 1           ;repetición horizontal
    mov al, 194         ;carácter '┬'
    cmp byte ptr bor, 1
    je dibujar_inter_sup
    mov al, 203         ;carácter '╦'   
    dibujar_inter_sup:
    add dl, anch
    inc dl
    @ubicar_cursor
    @print_char
    dec si
    jnz dibujar_inter_sup

    ;recupero el número de intersecciones
    pop si
    push si             ;lo volveré a usar con las cruces
    ;dibujar intersecciones inferiores
    ;cargo coordenadas iniciales
    mov dl, x0
    mov cx, altura
    add cl, y0
    dec cl
    mov dh, cl
    mov cx, 1           ;repeticion horizontal
    mov al, 193         ;carácter '┴'
    cmp byte ptr bor, 1
    je dibujar_inter_inf
    mov al, 202         ;carácter '╩'   
    dibujar_inter_inf:
    add dl, anch
    inc dl
    @ubicar_cursor
    @print_char
    dec si
    jnz dibujar_inter_inf

    ;número de intersecciones verticales a dibujar
    calcular_num_inter_verticales:
    xor cx, cx
    mov cl, fil
    dec cl
    mov di, cx
    push di             ;lo volveré a usar con las inferiores
    cmp di, 0
    jz dibujar_cruces

    ;dibujar intersecciones izquierda
    ;cargo coordenadas iniciales
    mov dl, x0
    mov dh, y0
    mov cx, 1           ;repetición horizontal
    mov al, 195         ;carácter '├'
    cmp byte ptr bor, 1
    je dibujar_inter_izq
    mov al, 204         ;carácter '╠'   
    dibujar_inter_izq:
    add dh, alto
    inc dh
    @ubicar_cursor
    @print_char
    dec di
    jnz dibujar_inter_izq

    ;recupero el número de intersecciones
    pop di
    push di             ;lo volveré a usar con las cruces
    ;dibujar intersecciones derecha
    ;cargo coordenadas iniciales
    mov cx, anchura
    add cl, x0
    dec cl
    mov dl, cl
    mov dh, y0
    mov cx, 1           ;repeticion horizontal
    mov al, 180         ;carácter '┤'
    cmp byte ptr bor, 1
    je dibujar_inter_dcha
    mov al, 185         ;carácter '╣'   
    dibujar_inter_dcha:
    add dh, alto
    inc dh
    @ubicar_cursor
    @print_char
    dec di
    jnz dibujar_inter_dcha

    dibujar_cruces:
    ;recupero el número de cruces por fila
    pop di
    ;recupero el número de cruces por columna
    pop si
    cmp di, 0
    jz dibujar_esquinas
    cmp si, 0
    jz dibujar_esquinas

    ;cargo coordenadas iniciales
    mov dl, x0
    ;mov dh, y0
    mov cx, 1           ;repetición horizontal
    mov al,197          ;carácter '┼'
    cmp byte ptr bor, 1
    je dibujar_cruces_hor
    mov al, 206         ;carácter '╬'   
    dibujar_cruces_hor:
    add dl, anch
    inc dl
    mov dh, y0
    push si
        dibujar_cruces_ver:
        add dh, alto
        inc dh
        @ubicar_cursor
        @print_char
        dec si
        jnz dibujar_cruces_ver
    pop si
    dec di
    jnz dibujar_cruces_hor

    dibujar_esquinas:
    ;esquina superior izquierda
    mov dl, x0
    mov dh, y0
    @ubicar_cursor
    mov cx, 1           ;repetición horizontal
    mov al,218          ;carácter '┌'
    cmp byte ptr bor, 1
    je dibujar_esq_sup_izq
    mov al, 201         ;carácter '╔'   
    dibujar_esq_sup_izq:
    @print_char

    ;esquina superior derecha
    mov cx, anchura
    add cl, x0
    dec cl
    mov dl, cl
    mov dh, y0
    @ubicar_cursor
    mov cx, 1           ;repetición horizontal
    mov al,191          ;carácter '┐'
    cmp byte ptr bor, 1
    je dibujar_esq_sup_der
    mov al, 187         ;carácter '╗'   
    dibujar_esq_sup_der:
    @print_char

    ;esquina inferior derecha
    mov cx, anchura
    add cl, x0
    dec cl
    mov dl, cl
    mov cx, altura
    add cl, y0
    dec cl
    mov dh, cl
    @ubicar_cursor
    mov cx, 1           ;repetición horizontal
    mov al,217          ;carácter '┘'
    cmp byte ptr bor, 1
    je dibujar_esq_inf_der
    mov al, 188         ;carácter '╝'   
    dibujar_esq_inf_der:
    @print_char
    
    ;esquina inferior izquierda
    mov dl, x0
    mov cx, altura
    add cl, y0
    dec cl
    mov dh, cl
    @ubicar_cursor
    mov cx, 1           ;repetición horizontal
    mov al, 192         ;carácter '└'
    cmp byte ptr bor, 1
    je dibujar_esq_inf_izq
    mov al, 200         ;carácter '╚'   
    dibujar_esq_inf_izq:
    @print_char

    ;recupero los registros usados
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    mov sp, bp          ;soslayo locales
    pop bp              ;recupero marco de pila
    ret 8
dibujar_reticula endp

inicio:
	mov ax, @data
	mov ds, ax

    ;-------------------------------------------------
    ; INTERFASE GRÁFICA
    ;-------------------------------------------------

	@clear_scr

    ;todo el fondo de color uniforme
    ;coordenadas de iniciales
    mov dx, 0
    ;anchura de la pantalla
    mov bx, 80
    ;atributo y cáracter (fondo negro sobre cáracter negro)
    mov ah, 0
    mov al, 32          ;cáracter ' '   
    ;número de líneas a dibujar
    xor cx, cx
    mov cl, 25
    dibujar_lineas_fondo:
    push ax
    push bx
    push dx
    call repetir_ascii_en_horizontal
    inc dh
    loop dibujar_lineas_fondo

    ;enmarco toda la pnatalla con línea doble
    ;borde-atributo (2:doble-atributotablero)
    mov ax, 2*256+atributotablero
    push ax
    ;alto-ancho (23:alto-78:ancho)
    mov ax, 23*256+78
    push ax
    ;columnas-filas (1:columna-1:fila)
    mov ax, 0101h
    push ax
    ;coordenadas (y:0-x:0)
    mov ax, 0
    push ax
    call dibujar_reticula

    mov ax, xcompleto
    push ax
    call limpiar_dialogo

    ;línea de título
    ;muevo el cursor a las coordenadas 0,36
    mov dx, 0*256+37    ;fila 0-columna 36
    mov bh, 0           ;página de video
    @ubicar_cursor
    @emitir_mensaje cadena_titulo
    ;línea de estado
    ;muevo el cursor a las coordenadas 24,2
    mov dx, 24*256+2   ;fila 24-columna 2
    mov bh, 0           ;página de video
    @ubicar_cursor
    @emitir_mensaje cadena_estado 

    ;retícula 
    ;borde-atributo (1:sencillo-atributotablero)
    mov ax, 1*256+atributotablero
    push ax
    ;alto-ancho (altotablero-anchotablero)
    mov ax, altotablero*256+anchotablero
    push ax
    ;columnas-filas (1:columna-1:fila)
    mov ax, 1*256+1
    push ax
    ;coordenadas (xytablero)
    mov ax, xytablero
    push ax
    call dibujar_reticula

    mov dx, ydialogo*256+2
	mov bh, 0
	@ubicar_cursor
    @emitir_mensaje cadena_inicio

    ;-------------------------------------------------
    ; PARTIDA
    ;-------------------------------------------------
    
    ;primera_partida
    mov dx, 7*256+15    ;mitad del tablero
    add dx, xy0         ;coordenadas absolutas
    mov bh, 0           ;página video
    @ubicar_cursor
    mov bl, atributotablero
    mov cx, 1           ;repetición horizontal
    mov al, 254         ;carácter '■'
    @print_char
    @cursor_fuera

    comienzo: 
    mov ah, 06h         
    mov dl, 0FFh        ;entrada de carácter no bloqueante sin eco
    int 21h

    lahf
	inc cx              ;crea la semilla "aleatoria"
	sahf

    je comienzo
    mov manzana, cx

    and al, 11011111b   ;aseguramos que sea mayúscula
    cmp al, 'F'
    jne comprobar_E
    jmp salir
    comprobar_E:
    cmp al, 'E'
    jne comienzo

    ;inicializamos la serpiente según su longitud
    mov dx, 7*256+15    ;mitad del tablero
    mov cx, longitud
    dec cx
	xor si, si
    ;damos coordenadas fuera del mapa a todas menos a la ultima
	inicio_snake:
	mov snake[si], 25*256+80;al inicio no borraremos el nodo del medio hasta que movamos toda la serpiente
	add si, 2
	loop inicio_snake
    mov snake[si], dx   ;la "cabeza" tiene las coordenadas buenas que heredarán los otros nodos

    add dx, xy0         ;coordenadas absolutas
    mov bh, 0           ;página video
    @ubicar_cursor
    mov bl, atributotablero
    mov cx, 1           ;repetición horizontal
    mov al, 254         ;carácter '■'
    @print_char
    @cursor_fuera       ;cursor fuera de la interfaz

    ;limpiamos el mapa por si no es la primera partida jugada
    ;coordenadas de iniciales
    mov dx, xy0
    ;anchura de la pantalla
    mov bx, 32
    ;atributo y cáracter (fondo negro sobre cáracter negro)
    mov ah, 0
    mov al, 32          ;cáracter ' '   
    ;número de líneas a dibujar
    xor cx, cx
    mov cl, 16
    vaciar_tablero:
    push ax
    push bx
    push dx
    call repetir_ascii_en_horizontal
    inc dh
    loop vaciar_tablero

    ;mostramos cadena de juego en la partida
    mov dx, ydialogo*256+2  
	mov bh, 0
	@ubicar_cursor          
    @emitir_mensaje cadena_juega
    
    ;mostramos y creamos nueva manzana
    call nueva_manzana
    mov dx, manzana
    add dx, xy0         ;coordenadas absolutas
    mov bh, 0           ;página video
    @ubicar_cursor
    mov bl, atributomanzana
    mov cx, 1           ;repetición horizontal
    mov al, 111          ;carácter 'o'
    @print_char

    ;cadena de puntuación
    mov dx, ydialogo*256+58    ;fila 5-columna 60
    mov bh, 0           ;página de video
    @ubicar_cursor
    @emitir_mensaje cadena_score

    partida:
    ;mostramos valor en ascii de score
    mov dx, ydialogo*256+65    ;fila 5-columna 60
    mov bh, 0           ;página de video
    @ubicar_cursor
    @emitir_mensaje ascii_score
    @cursor_fuera       ;cursor fuera de la interfaz

    ;pasando ciclos para esperar al siguiente paso
    xor cx, cx          ;hara 2^16 iteraciones por cada ax
    mov ax, 3
	espera:
	nop
	loop espera
	dec ax
	jnz espera

    ;tomamos en al la tecla pulsada (si la hay)
	mov ah, 06h
	mov dl, 0ffh
	int 21h
    jne pulsado

    ;no_pulsado:
    mov al, anterior    ;como no se ha pulsado continuamos con la anterior

    pulsado:
    and al, 11011111b   ;aseguramos que sea mayúscula
    cmp al, 'F'
    jne no_salir
    ;salir:
    jmp salir
    no_salir:

    ;conseguimos nuevas coordenadsas de la "cabeza" en dx
	xor ah, ah
    push ax             ;pasamos la nueva tecla
    call nueva_coordenada;calculamos la siguiente posicion de la cabeza
    
    ;comprobamos que no choque con el resto de la serpiente
    xor ax, ax
    inc ax
    push ax             ;tipo de comprobación
    push dx             ;coordenadas relativas
    call coord_en_snake
    cmp ax, 0           ;si 0, entonces no choca
    je no_autochoca
    jmp derrota
    no_autochoca:

	;comprobamos que no chocamos con los bordes del mapa
	add dx, xy0			;coordenadas absolutas
	cmp dh, ytablero
	je noValido
    cmp dh, ytablero+altotablero+1
    je noValido
    cmp dl, xtablero
    je noValido
    cmp dl, xtablero+anchotablero+1
    je noValido
	jmp valido

	noValido:
	jmp derrota

	valido:
    sub dx, xy0         ;volvemos a las coordenadas relativas
    add si, 2
	mov snake[si], dx	;guardamos nuevas coordenadas

    ;comprobamos si comemos manzana
    cmp dx, manzana     ;comparamos coordenadas relativas
    jne no_manzana

    call actualizar_score   ;actualizamos la puntuación y el ascii_score
    inc longitud        ;actualizamos la longitud
    call nueva_manzana  ;creamos nuevo random para manzana
    ;mostramos nuevo valor de la manzana
    mov dx, manzana     ;ubicación relativa
	add dx, xy0			;ubicacion absoluta
    mov bh, 0			;página video
    @ubicar_cursor
    mov bl, atributomanzana;atributo
    mov cx, 1			;rep
    mov al, 111			;cáracter 'o'
    @print_char
    jmp snake_actualizada

    ;si no comemos manzana desplazamos 
    no_manzana:
    ;borramos el último de la cola
	mov dx, snake[0]	;ubicación relativa
	add dx, xy0			;ubicacion absoluta
    mov bh, 0			;página video
    @ubicar_cursor
    mov bl, atributotablero;atributo
    mov cx, 1			;rep
    mov al, 32			;cáracter ' '
    @print_char

    ;desplazamos snake 16 bits a la izquierda
	mov cx, 16
	desplaz_unitario:
	call desplaz_unit_snake
	loop desplaz_unitario

    snake_actualizada:
	;pintamos el nuevo
    mov si, longitud
    dec si
    shl si, 1

	mov dx, snake[si]
	add dx, xy0			;coordenadas absolutas
	mov bh, 0			;página video
    @ubicar_cursor
    mov bl, atributotablero;atributo
    mov cx, 1			;rep
    mov al, 254			;cáracter '■'
    @print_char
	jmp partida

    derrota:
    ;reseteamos valores de la partida
    mov longitud, 3
    mov score, 0
    mov ascii_score[0], 30h
    mov ascii_score[1], 30h
    mov ascii_score[2], 30h
    mov anterior, 'S'

    ;cadena de volver a jugar
    mov dx, ydialogo*256+2    ;fila 5-columna 60
    mov bh, 0           ;página de video
    @ubicar_cursor
    @emitir_mensaje cadena_nueva
    @cursor_fuera

    jmp comienzo

    salir:
	mov ah, 4Ch
	int 21h
end inicio