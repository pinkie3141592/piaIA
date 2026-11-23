(define (domain robot-barista)
  (:requirements :strips :typing)
  (:types robot ubicacion taza)

  (:predicates
    (robot-en ?r - robot ?u - ubicacion)
    (conectado ?a - ubicacion ?b - ubicacion)
    (taza-en ?t - taza ?u - ubicacion)
    (sosteniendo ?r - robot ?t - taza)
    (mano-libre ?r - robot)
    (vacia ?t - taza)
    (con-cafe ?t - taza)
    (con-leche ?t - taza)
    (estacion-cafe ?u - ubicacion)
    (estacion-leche ?u - ubicacion)
  )

  (:action mover
    :parameters (?r - robot ?a - ubicacion ?b - ubicacion)
    :precondition (and (robot-en ?r ?a) (conectado ?a ?b))
    :effect (and (robot-en ?r ?b) (not (robot-en ?r ?a)))
  )

  (:action tomar
    :parameters (?r - robot ?t - taza ?u - ubicacion)
    :precondition (and (robot-en ?r ?u) (taza-en ?t ?u) (mano-libre ?r))
    :effect (and (sosteniendo ?r ?t) (not (taza-en ?t ?u)) (not (mano-libre ?r)))
  )

  (:action soltar
    :parameters (?r - robot ?t - taza ?u - ubicacion)
    :precondition (and (robot-en ?r ?u) (sosteniendo ?r ?t))
    :effect (and (taza-en ?t ?u) (mano-libre ?r) (not (sosteniendo ?r ?t)))
  )

  (:action servir-cafe
    :parameters (?r - robot ?t - taza ?u - ubicacion)
    :precondition (and (robot-en ?r ?u) (estacion-cafe ?u)
                       (sosteniendo ?r ?t) (vacia ?t))
    :effect (and (con-cafe ?t) (not (vacia ?t)))
  )

  (:action agregar-leche
    :parameters (?r - robot ?t - taza ?u - ubicacion)
    :precondition (and (robot-en ?r ?u) (estacion-leche ?u)
                       (sosteniendo ?r ?t) (con-cafe ?t))
    :effect (con-leche ?t)
  )
)