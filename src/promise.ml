(*---------------------------------------------------------------------------
   Copyright (c) 2026 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

type 'a t = ('a, exn) Fut.result

exception Reject of Jv.t

let error_cons = Jv.get Jv.global "Error"

let exn_of_jv v =
  if Jv.instanceof v ~cons:error_cons then Jv.Error (Jv.to_error v) else Reject v

let jv_of_exn = function
| Jv.Error e -> Jv.of_error e
| Reject v -> v
| e -> Jv.of_error (Jv.Error.v (Jstr.v (Printexc.to_string e)))

let create () =
  let p, set = Fut.create () in
  let resolve v = set (Ok v) in
  let reject e = set (Error e) in
  p, resolve, reject

let return = Fut.ok
let fail = Fut.error

let await p k = Fut.await p @@ function
| Ok v -> k v
| Error e -> raise e

let map fn p = Fut.map (function
  | Ok v -> (try Ok (fn v) with e -> Error e)
  | Error e -> Error e)
  p

let bind p fn = Fut.bind p @@ function
| Ok v -> (try fn v with e -> fail e)
| Error e -> fail e

let catch p fn = Fut.bind p @@ function
| Ok v -> return v
| Error e -> (try fn e with e -> fail e)

let pair p0 p1 =
  let p, resolve, reject = create () in
  let settled = ref false in
  let v0 = ref None in
  let v1 = ref None in
  let try_resolve () = match !settled, !v0, !v1 with
  | false, Some v0, Some v1 -> settled := true; resolve (v0, v1)
  | _ -> ()
  in
  let reject_once e = if not !settled then (settled := true; reject e) in
  Fut.await p0 (function
    | Ok v -> v0 := Some v; try_resolve ()
    | Error e -> reject_once e);
  Fut.await p1 (function
    | Ok v -> v1 := Some v; try_resolve ()
    | Error e -> reject_once e);
  p

let all ps =
  let len = List.length ps in
  if len = 0 then return [] else
  let p, resolve, reject = create () in
  let settled = ref false in
  let remaining = ref len in
  let values = Array.make len None in
  let reject_once e = if not !settled then (settled := true; reject e) in
  let resolve_if_done () =
    if not !settled && !remaining = 0
    then begin
      settled := true;
      resolve (Array.to_list (Array.map Option.get values))
    end
  in
  List.iteri (fun i p ->
    Fut.await p @@ function
    | Ok v when not !settled ->
        values.(i) <- Some v;
        decr remaining;
        resolve_if_done ()
    | Ok _ -> ()
    | Error e -> reject_once e)
    ps;
  p

let race ps =
  match ps with
  | [] ->
      let p, _, _ = create () in
      p
  | _ ->
      let p, resolve, reject = create () in
      let settled = ref false in
      let settle = function
      | Ok v when not !settled -> settled := true; resolve v
      | Error e when not !settled -> settled := true; reject e
      | _ -> ()
      in
      List.iter (fun p -> Fut.await p settle) ps;
      p

let of_fut_result p = p
let of_fut_result' ~error p = Fut.map (Result.map_error error) p
let to_fut_result p = p

let of_promise ~ok p = Fut.of_promise' ~ok ~error:exn_of_jv p
let to_promise ~ok p = Fut.to_promise' ~ok ~error:jv_of_exn p

module Syntax = struct
  let ( let* ) = bind
  let ( and* ) = pair
  let ( let+ ) p fn = map fn p
  let ( and+ ) = ( and* )
end
