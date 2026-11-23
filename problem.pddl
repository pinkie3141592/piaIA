(define (problem pedido-dos-bebidas)
  (:domain robot-barista)
  (:objects
    bot - robot
    barra cafetera lechera mesa1 mesa2 - ubicacion
    t1 t2 - taza)

  (:init
    (robot-en bot barra) (mano-libre bot)
    (taza-en t1 barra) (taza-en t2 barra)
    (vacia t1) (vacia t2)
    (estacion-cafe cafetera) (estacion-leche lechera)
    (conectado barra cafetera) (conectado cafetera barra)
    (conectado cafetera lechera) (conectado lechera cafetera)
    (conectado lechera mesa1) (conectado mesa1 lechera)
    (conectado lechera mesa2) (conectado mesa2 lechera)
    (conectado mesa1 mesa2) (conectado mesa2 mesa1))

  (:goal (and
    (taza-en t1 mesa1) (con-leche t1)    ; latte en mesa 1
    (taza-en t2 mesa2) (con-cafe t2)))   ; americano en mesa 2
)