(*---------------------------------------------------------------------------
   Copyright (c) 2026 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** Promise values optimized for the happy path.

    A promise ['a Promise.t] is an asynchronous computation that
    resolves to a value of type ['a] or raises on rejection.

    This module provides a JavaScript promise-oriented API on top of
    {!Fut}. It preserves Brr's sound implementation strategy while
    making the success path easier to compose. *)

(** {1:promises Promises} *)

type 'a t
(** The type for promises with values of type ['a]. *)

exception Reject of Jv.t
(** Raised for JavaScript promise rejections that are not instances of
    JavaScript {!Jv.Error.t}. *)

val create : unit -> 'a t * ('a -> unit) * (exn -> unit)
(** [create ()] is [(p, resolve, reject)] with [p] the promise value
    and [resolve] and [reject] the functions to settle it. The latter
    can only be called once, a {!Jv.exception-Error} is thrown otherwise. *)

val return : 'a -> 'a t
(** [return v] is a promise that resolves to [v]. *)

val fail : exn -> 'a t
(** [fail e] is a promise that rejects with [e]. *)

val await : 'a t -> ('a -> unit) -> unit
(** [await p k] waits for [p] to resolve to [v] and continues with [k
    v]. If [p] rejects the rejection exception is raised asynchronously.
    If [p] never settles [k] is not invoked. *)

val map : ('a -> 'b) -> 'a t -> 'b t
(** [map fn p] maps [fn] over the resolution value of [p]. If [fn]
    raises the resulting promise rejects with that exception. *)

val bind : 'a t -> ('a -> 'b t) -> 'b t
(** [bind p fn] binds the resolution value of [p] to [fn]. If [fn]
    raises the resulting promise rejects with that exception. *)

val catch : 'a t -> (exn -> 'a t) -> 'a t
(** [catch p fn] handles rejections of [p] with [fn]. If [fn] raises
    the resulting promise rejects with that exception. *)

val pair : 'a t -> 'b t -> ('a * 'b) t
(** [pair p0 p1] resolves with the values of [p0] and [p1]. The
    result rejects as soon as one of the promises rejects. *)

val all : 'a t list -> 'a list t
(** [all ps] resolves with the values of all promises in [ps] in the
    same order. The result rejects as soon as one of the promises
    rejects. *)

val race : 'a t list -> 'a t
(** [race ps] settles with the first promise in [ps] to settle. If
    [ps] is empty the result never settles. *)

(** {1:converting Converting} *)

val of_fut_result : ('a, exn) Fut.result -> 'a t
(** [of_fut_result f] is [f] viewed as a promise. *)

val of_fut_result' : error:('e -> exn) -> ('a, 'e) Fut.result -> 'a t
(** [of_fut_result' ~error f] is [f] viewed as a promise after mapping
    future errors with [error]. *)

val to_fut_result : 'a t -> ('a, exn) Fut.result
(** [to_fut_result p] is [p] viewed as a future result. *)

val of_promise : ok:(Jv.t -> 'a) -> Jv.Promise.t -> 'a t
(** [of_promise ~ok p] is a promise for the JavaScript promise [p]. If
    [p] rejects with a JavaScript {!Jv.Error.t}, {!Jv.Error} is raised.
    Other rejection values raise {!Reject}. *)

val to_promise : ok:('a -> Jv.t) -> 'a t -> Jv.Promise.t
(** [to_promise ~ok p] is a JavaScript promise for [p]. Rejections are
    turned back into JavaScript rejections. {!Reject} uses its payload
    as the rejection value, {!Jv.Error} uses {!Jv.of_error}, other
    exceptions are converted to JavaScript [Error] objects with
    {!Printexc.to_string}. *)

(** {1:syntax Promise syntax} *)

module Syntax : sig
  val ( let* ) : 'a t -> ('a -> 'b t) -> 'b t
  (** [let*] is {!bind}. *)

  val ( and* ) : 'a t -> 'b t -> ('a * 'b) t
  (** [and*] is {!pair}. *)

  val ( let+ ) : 'a t -> ('a -> 'b) -> 'b t
  (** [let+] is {!map}. *)

  val ( and+ ) : 'a t -> 'b t -> ('a * 'b) t
  (** [and+] is {!pair}. *)
end
