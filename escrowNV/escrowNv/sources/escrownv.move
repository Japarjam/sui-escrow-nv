module defi::vaultless_escrow {
    use std:;option::{Self, Option};

    use sui::objects{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext}

struct Maker_Obj<T, key + store, phantom Taker_ObjT: key + store> has key, store {
    id: UID,
    maker: address, 
    taker: address, 
    taker_obj: ID,
    maker_obj: Option<T>,
};

const EWrongMaker: u64 = 0;
const EWrongTaker: u64 = 1;
const EWrongTakerObj: u64 =2;
const EAlreadyExchangedorCancelled: u64 = 3;

public fun create<T: key + store, Taker_ObjT: key + store>(
    taker: address, 
    taker_obj: ID, 
    escrow_obj: T, 
    ctx: &mut TxContext
)   {
    let maker = tx_context::sender(ctx);
    let id = object::new(ctx); 
    let maker_obj = option::some(escrow_obj);
    transfer::public_share_object(
       EscrowObj<T, Taker_ObjT> {
            id, creator, taker, taker_obj, escrow_obj
        }
    ); 
}

public entry fun swap<T: key + store, Taker_ObjT: key + store>(
    obj: Taker_ObjT, 
    escrow: &mut Maker_Obj<T, Taker_ObjT>,
    ctx: &TxContext
)   
{
    assert!(option::is_some(&escrow, maker_obj), EAlreadyExchangedorCancelled);
    let escrow_obj = option::extract<T>(&mut escrow, maker_obj);
    assert!(&tx_context::sender(ctx) == &escrow.taker, EWrongTaker);
    assert!(object::borrow_id(&obj) == &escrow.taker_obj, EWrongTakerObj);

    transfer::public_transfer(escrow_obj, tx_context::sender(ctx));
    transfer::public_transfer(obj, escrow.maker); 
}

public entry fun cancel<T: key + store, Taker_ObjT: key + store>(
    escrow: &mut Maker_Obj<T, Taker_ObjT>, 
    ctx: &TxContext
)     {
    assert!(&tx_context::sender(ctx) == &escrow.maker, EWrongMaker);
    assert!(option::is_some(&escrow.maker_obj), EAlreadyExchangedorCancelled);
    transfer::public_transfer(option::extract<T>(&mut escrow.maker_obj), escrow.maker);
    };

}
